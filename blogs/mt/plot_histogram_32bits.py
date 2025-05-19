import matplotlib.pyplot as plt
import numpy as np

# File path
file_path = "./mt_outputs_2p5M.txt"

# Read the file and filter valid integers
numbers = []
with open(file_path, "r") as file:
    for line in file:
        line = line.strip()
        if line.isdigit():  # Check if the line contains only numbers
            numbers.append(int(line))

# Convert to numpy array for processing
numbers = np.array(numbers)

# Plot histogram
plt.figure(figsize=(10, 6))
plt.hist(numbers, bins=100, edgecolor='k', alpha=0.7)
plt.xlabel("32-bit Integer Values")
plt.ylabel("Frequency")
plt.title("Histogram of 32-bit Integers")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()
