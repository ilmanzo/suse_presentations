#!/usr/bin/env python3
import time
from datetime import datetime

FILE = "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj"

def read_energy():
    with open(FILE, "r") as f:
        return int(f.read().strip())

v0 = read_energy()
while True:
  time.sleep(1)
  timestamp = datetime.now().strftime("%H:%M:%S")
  v1 = read_energy()
  print(f"{timestamp} Potenza media: {(v1-v0)/1e6:.1f} W")
  v0 = v1

