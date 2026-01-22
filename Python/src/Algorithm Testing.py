import heapq

while True:
    try:
        symbolCount = int(input("Enter number of symbols: "))
        if symbolCount >= 2:
            break
        else:
            print("Number of symbols must be at least 2.")
    except ValueError:
        print("Invalid input. Enter an integer.")


symbols = []
probabilities = []

for i in range(symbolCount):
    symbols.append(f"s{i}")

    while True:
        try:
            p = float(input(f"Enter probability for symbol s{i}: "))
            if 0 < p < 1:
                probabilities.append(p)
                break
            else:
                print("Probability must be between 0 and 1.")
        except ValueError:
            print("Invalid input. Enter a floating-point number.")


total = sum(probabilities)
tolerance = 0.001

if abs(total - 1.0) >= tolerance:
    print("Probabilities must sum to 1.")
    exit()

print("Probabilities accepted.")


heap = list(zip(probabilities, symbols))
heapq.heapify(heap)

print("\nInitial heap:")
print(heap)


while len(heap) > 1:
    p1, left = heapq.heappop(heap)
    p2, right = heapq.heappop(heap)

    merged_prob = p1 + p2
    merged_node = (left, right)

    heapq.heappush(heap, (merged_prob, merged_node))

    print("\nHeap after merging:")
    print(heap)


root_probability, huffman_tree = heap[0]

print("\nFinal Huffman Tree:")
print(huffman_tree)


huffman_codes = {}

def generate_codes(node, current_code):
    # Leaf node (symbol)
    if isinstance(node, str):
        huffman_codes[node] = current_code
        return

    # Internal node → recurse
    left, right = node
    generate_codes(left, current_code + "0")
    generate_codes(right, current_code + "1")

# Start traversal from root
generate_codes(huffman_tree, "")


print("\nHuffman Codes:")
for symbol, code in huffman_codes.items():
    print(f"{symbol} : {code}")
