pkg load image;
pkg load communications;

% STEP 1: Download/Load Image
imageFileName = 'Pattern.jpg';

% STEP 2: Read Image and Convert to Grayscale
originalImage = imread(imageFileName);
[rows, cols, channels] = size(originalImage);

if channels == 3
    grayImage = rgb2gray(originalImage);
else
    grayImage = originalImage;
end
grayImage = uint8(grayImage);

% --- SAVE IMAGE 1: Original Grayscale ---
imwrite(grayImage, 'Original_Gray_e20130.jpg');
disp('Saved: Original_Gray_e20130.jpg');

figure(1);
subplot(1, 2, 1); imshow(grayImage); title('Original');

% STEP 3: Crop 16x16 Sub-image
N = 16;
startRow = 60;
startCol = 120;
croppedImage = grayImage(startRow : startRow+N-1, startCol : startCol+N-1);

% --- SAVE IMAGE 2: Cropped Image ---
imwrite(croppedImage, 'Cropped_e20130.jpg');
disp('Saved: Cropped_e20130.jpg');

subplot(1, 2, 2); imshow(croppedImage, 'InitialMagnification', 1000); title('Cropped');
disp('Step 3: Image Cropped.');

% STEP 4: Quantize to 8 Levels
numLevels = 8;
binSize = 256 / numLevels;
quantizedImage = floor(double(croppedImage) / binSize);
disp(['Step 4: Quantized to ' num2str(numLevels) ' levels.']);

% STEP 5: Find Probability Distribution
symbols = 0:7;
flatPixels = quantizedImage(:);
totalPixels = numel(flatPixels);
counts = zeros(1, 8);

for k = 1:length(symbols)
    counts(k) = sum(flatPixels == symbols(k));
end

probabilities = counts / totalPixels;

disp('Step 5: Symbol Probabilities');
disp('Symbol | Probability');
for k = 1:8
    fprintf('   %d   |   %.4f\n', symbols(k), probabilities(k));
end

% STEP 6: Construct Huffman Tree
validIndices = find(probabilities > 0);
p = probabilities(validIndices);
s = symbols(validIndices);

forest = cell(1, length(p));
for i = 1:length(p)
    forest{i} = struct('type', 'leaf', 'symbol', s(i), 'prob', p(i), 'code', '');
end

while length(forest) > 1
    currentProbs = cellfun(@(x) x.prob, forest);
    [sortedProbs, sortIdx] = sort(currentProbs);
    forest = forest(sortIdx);

    node1 = forest{1};
    node2 = forest{2};
    parentNode = struct('type', 'parent', 'prob', node1.prob + node2.prob, ...
                        'left', node1, 'right', node2, 'code', '');
    forest(1:2) = [];
    forest{end+1} = parentNode;
end

huffmanTree = forest{1};
myCodebook = cell(length(p), 2);
stack = {huffmanTree, ''};
idx = 1;

while ~isempty(stack)
    currData = stack(end,:);
    stack(end,:) = [];
    node = currData{1};
    codeStr = currData{2};

    if strcmp(node.type, 'leaf')
        myCodebook{idx, 1} = node.symbol;
        myCodebook{idx, 2} = codeStr;
        idx = idx + 1;
    else
        stack(end+1, :) = {node.left, [codeStr '0']};
        stack(end+1, :) = {node.right, [codeStr '1']};
    end
end

disp('Step 6: Huffman Codes Generated.');
disp('-----------------------------');
disp('Symbol | Binary Code');
disp('-----------------------------');

[~, sortOrder] = sort([myCodebook{:,1}]);
sortedCodebook = myCodebook(sortOrder, :);

for i = 1:size(sortedCodebook, 1)
    fprintf('   %d   | %s\n', sortedCodebook{i, 1}, sortedCodebook{i, 2});
end
disp('-----------------------------');

% STEP 7: Compress Images (Manual)
fastCodebook = cell(1, 8);
validSymbols = [myCodebook{:, 1}];
for i = 1:size(myCodebook, 1)
    fastCodebook{myCodebook{i, 1} + 1} = myCodebook{i, 2};
end

croppedFlat = quantizedImage(:);
encodedCropped = strjoin(fastCodebook(croppedFlat + 1), '');
disp(['Step 7a: Cropped Bits Length: ' num2str(length(encodedCropped))]);

quantizedOriginal = floor(double(grayImage) / binSize);
quantizedOriginal(quantizedOriginal > 7) = 7;

missingValues = setdiff(unique(quantizedOriginal), validSymbols);
if ~isempty(missingValues)
    for val = missingValues'
        [~, minIdx] = min(abs(validSymbols - val));
        quantizedOriginal(quantizedOriginal == val) = validSymbols(minIdx);
    end
end

originalFlat = quantizedOriginal(:);
encodedOriginal = strjoin(fastCodebook(originalFlat + 1), '');
disp(['Step 7b: Original Bits Length: ' num2str(length(encodedOriginal))]);

% STEP 8: Save to Text Files
fid1 = fopen('compressed_cropped.txt', 'w');
fprintf(fid1, '%s', encodedCropped);
fclose(fid1);

fid2 = fopen('compressed_original.txt', 'w');
fprintf(fid2, '%s', encodedOriginal);
fclose(fid2);
disp('Step 8: Files saved.');

% STEP 9: Compress using Inbuilt Function
validIdx = probabilities > 0;
p_inbuilt = probabilities(validIdx);
p_inbuilt = p_inbuilt / sum(p_inbuilt);
s_inbuilt = symbols(validIdx);

dict = huffmandict(s_inbuilt, p_inbuilt);
[tf, sig_indices] = ismember(originalFlat, s_inbuilt);
comp_inbuilt = huffmanenco(sig_indices, dict);
str_inbuilt = sprintf('%d', comp_inbuilt);

fid3 = fopen('compressed_inbuilt.txt', 'w');
fprintf(fid3, '%s', str_inbuilt);
fclose(fid3);

disp(['Step 9: Inbuilt Compressed Length: ' num2str(length(str_inbuilt)) ' bits']);

% STEP 10: Decompress Images
function decompressedData = decompressManual(bitString, rootNode, numPixels)
    decompressedData = zeros(1, numPixels);
    currentNode = rootNode;
    pixelIdx = 1;
    for i = 1:length(bitString)
        bit = bitString(i);
        if bit == '0'
            currentNode = currentNode.left;
        else
            currentNode = currentNode.right;
        end
        if strcmp(currentNode.type, 'leaf')
            decompressedData(pixelIdx) = currentNode.symbol;
            pixelIdx = pixelIdx + 1;
            currentNode = rootNode;
        end
    end
end

fid = fopen('compressed_cropped.txt', 'r');
bitsCropped = fscanf(fid, '%s');
fclose(fid);
decodedCroppedFlat = decompressManual(bitsCropped, huffmanTree, 16*16);
reconstructedCropped = reshape(decodedCroppedFlat, 16, 16);

fid = fopen('compressed_original.txt', 'r');
bitsOriginal = fscanf(fid, '%s');
fclose(fid);
decodedOriginalFlat = decompressManual(bitsOriginal, huffmanTree, rows*cols);
reconstructedOriginal = reshape(decodedOriginalFlat, rows, cols);

% Convert Reconstructed Images back to 0-255 range for Display/Saving
imgReconCropped = uint8(reconstructedCropped * binSize);
imgReconOriginal = uint8(reconstructedOriginal * binSize);

% --- SAVE IMAGE 3: Decompressed Cropped ---
imwrite(imgReconCropped, 'Decompressed_Cropped_e20130.jpg');
disp('Saved: Decompressed_Cropped_e20130.jpg');

% --- SAVE IMAGE 4: Decompressed Original ---
imwrite(imgReconOriginal, 'Decompressed_Original_e20130.jpg');
disp('Saved: Decompressed_Original_e20130.jpg');

figure(3);
subplot(1, 2, 1);
imshow(imgReconCropped, 'InitialMagnification', 1000);
title('Decompressed Cropped');
subplot(1, 2, 2);
imshow(imgReconOriginal);
title('Decompressed Original');
disp('Step 10: Images Decompressed.');

% STEP 11: Calculate Entropy
validP = probabilities(probabilities > 0);
entropyVal = -sum(validP .* log2(validP));
disp(['Step 11: Entropy of Source: ' num2str(entropyVal) ' bits/symbol']);

% STEP 12: Evaluate PSNR
imgOrig = double(grayImage);
imgRecon = double(reconstructedOriginal) * binSize;
err = imgOrig - imgRecon;
mse = mean(err(:).^2);

MAX_I = 255;
if mse == 0
    psnrVal = Inf;
else
    psnrVal = 10 * log10((MAX_I^2) / mse);
end

disp(['Step 12: MSE: ' num2str(mse)]);
disp(['Step 12: PSNR Value: ' num2str(psnrVal) ' dB']);

compressionRatio = (rows * cols * 8) / length(encodedOriginal);
disp(['Compression Ratio: ' num2str(compressionRatio) ':1']);

% --- DISCUSSION DATA GENERATION ---

disp('--- Discussion Data: Entropy ---');
img1 = uint8(grayImage);
counts1 = imhist(img1);
p1 = counts1 / numel(img1);
p1 = p1(p1 > 0);
H_original = -sum(p1 .* log2(p1));
disp(['i.   Entropy of Original Image:     ' num2str(H_original) ' bits/symbol']);

img2 = uint8(croppedImage);
counts2 = imhist(img2);
p2 = counts2 / numel(img2);
p2 = p2(p2 > 0);
H_cropped = -sum(p2 .* log2(p2));
disp(['ii.  Entropy of Cropped Image:      ' num2str(H_cropped) ' bits/symbol']);

img3 = uint8(reconstructedOriginal);
counts3 = imhist(img3);
p3 = counts3 / numel(img3);
p3 = p3(p3 > 0);
H_decompressed = -sum(p3 .* log2(p3));
disp(['iii. Entropy of Decompressed Image: ' num2str(H_decompressed) ' bits/symbol']);


disp('--- Discussion Data: Average Length ---');
avgLength = 0;
symbols = 0:7;
for i = 1:length(symbols)
    sym = symbols(i);
    prob = probabilities(i);
    codeIndex = find([myCodebook{:,1}] == sym);
    if ~isempty(codeIndex)
        codeStr = myCodebook{codeIndex, 2};
        lenCode = length(codeStr);
        avgLength = avgLength + (prob * lenCode);
    end
end
disp(['Average Length of Cropped Image: ' num2str(avgLength) ' bits/symbol']);


disp('--- Discussion Data: Performance Comparison ---');
uncompressedOriginalBits = rows * cols * 8;
uncompressedCroppedBits = 16 * 16 * 8;

len_ManualOriginal = length(encodedOriginal);
len_InbuiltOriginal = length(str_inbuilt);
len_ManualCropped = length(encodedCropped);

CR_Manual_Original = uncompressedOriginalBits / len_ManualOriginal;
CR_Inbuilt_Original = uncompressedOriginalBits / len_InbuiltOriginal;
CR_Manual_Cropped = uncompressedCroppedBits / len_ManualCropped;

disp('Performance Comparison Table:');
disp('---------------------------------------------------------------');
fprintf('%-20s | %-15s | %-15s\n', 'Metric', 'Manual Algo', 'Inbuilt Algo');
disp('---------------------------------------------------------------');
fprintf('%-20s | %-15d | %-15d\n', 'Compressed Bits', len_ManualOriginal, len_InbuiltOriginal);
fprintf('%-20s | %-15.4f | %-15.4f\n', 'Compression Ratio', CR_Manual_Original, CR_Inbuilt_Original);
disp('---------------------------------------------------------------');

disp(['Manual Cropped Ratio: ' num2str(CR_Manual_Cropped) ':1']);
disp('---------------------------------------------------------------');
