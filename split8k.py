import sys

BLOCK_LEN = 8192

with open(sys.argv[1], "rb") as f:
    data = f.read()

if (len(data) % BLOCK_LEN) != 0:
    print(f"Can not split binary in blocks of {BLOCK_LEN} bytes")
    sys.exit(42)

count = 1

while len(data) != 0:
    block = data[:8192]
    data = data[8192:]
    with open(f"{sys.argv[2]}{count:02}.bin", "wb") as f:
        f.write(block)
    count += 1