import heapq
import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image
from collections import Counter
import pickle

# =========================================================
# HUFFMAN CORE
# =========================================================

def build_huffman_tree(probabilities):
    heap = []
    counter = 0  # tie-breaker to avoid int vs tuple comparison

    for symbol, prob in probabilities.items():
        heap.append((prob, counter, symbol))
        counter += 1

    heapq.heapify(heap)

    while len(heap) > 1:
        p1, _, left = heapq.heappop(heap)
        p2, _, right = heapq.heappop(heap)

        heapq.heappush(heap, (p1 + p2, counter, (left, right)))
        counter += 1

    return heap[0][2]


def generate_codes(node, current_code, codes):
    if isinstance(node, int):  # leaf node
        codes[node] = current_code
        return

    left, right = node
    generate_codes(left, current_code + "0", codes)
    generate_codes(right, current_code + "1", codes)


def decode_bits(bitstream, tree):
    decoded = []
    node = tree

    for bit in bitstream:
        node = node[0] if bit == "0" else node[1]
        if isinstance(node, int):
            decoded.append(node)
            node = tree

    return bytes(decoded)

# =========================================================
# COMPRESSION
# =========================================================

def compress_image():
    path = filedialog.askopenfilename(
        filetypes=[("Images", "*.png *.jpg *.jpeg *.bmp")]
    )
    if not path:
        return

    img = Image.open(path).convert("RGB")
    raw_bytes = img.tobytes()

    original_bits = len(raw_bytes) * 8

    counts = Counter(raw_bytes)
    total = len(raw_bytes)
    probabilities = {k: v / total for k, v in counts.items()}

    tree = build_huffman_tree(probabilities)

    codes = {}
    generate_codes(tree, "", codes)

    encoded_bits = "".join(codes[b] for b in raw_bytes)
    compressed_bits = len(encoded_bits)

    out_file = path + ".huff"
    with open(out_file, "wb") as f:
        pickle.dump({
            "tree": tree,
            "bitstream": encoded_bits,
            "size": img.size,
            "mode": img.mode
        }, f)

    compression_ratio = original_bits / compressed_bits

    messagebox.showinfo(
        "Compression Complete",
        f"Original size: {original_bits} bits\n"
        f"Compressed size: {compressed_bits} bits\n"
        f"Compression ratio: {compression_ratio:.2f}"
    )

# =========================================================
# DECOMPRESSION
# =========================================================

def decompress_image():
    path = filedialog.askopenfilename(
        filetypes=[("Huffman Files", "*.huff")]
    )
    if not path:
        return

    with open(path, "rb") as f:
        obj = pickle.load(f)

    tree = obj["tree"]
    bitstream = obj["bitstream"]
    size = obj["size"]
    mode = obj["mode"]

    decoded_bytes = decode_bits(bitstream, tree)

    img = Image.frombytes(mode, size, decoded_bytes)
    out_path = path.replace(".huff", "_decoded.png")
    img.save(out_path)

    messagebox.showinfo(
        "Decompression Complete",
        f"Image successfully restored:\n{out_path}"
    )

# =========================================================
# GUI
# =========================================================

root = tk.Tk()
root.title("Huffman Image Compressor")
root.geometry("360x220")

tk.Button(
    root,
    text="Compress Image",
    command=compress_image,
    width=30,
    height=2
).pack(pady=20)

tk.Button(
    root,
    text="Decompress .huff File",
    command=decompress_image,
    width=30,
    height=2
).pack(pady=10)

root.mainloop()
