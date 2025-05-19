import serial
from datetime import datetime
from tqdm import tqdm

port = "COM4"
baud = 9600
count = 0
target_count = 500_000

with serial.Serial(port, baud, timeout=1) as ser, open("mt_outputs_p5M.txt", "w") as f, tqdm(total=target_count, desc="Receiving", dynamic_ncols=True) as pbar:
    print("Reading UART data. Press Ctrl+C to stop.")
    try:
        while count < target_count:
            if ser.in_waiting >= 4:
                byte = ser.read(4)
                value = int.from_bytes(byte, 'little')
                f.write(f"{value}\n")
                count += 1
                pbar.update(1)

                if count % 20 == 0:
                    tqdm.write(f"Packet {count:07d} --- Binary: {bin(value)[2:].zfill(32)} --- Int:  {value}")
    except KeyboardInterrupt:
        print("\nStopped by user.")

