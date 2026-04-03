#!/usr/bin/env python3
from math import sqrt

def isPrime(n):
  for j in range(3,int(sqrt(n)+1),2):
    if n % j == 0:
      return False
  return True

n,i = 2,3
while n < 1_000_000:
    i += 2
    if isPrime(i):
        n += 1
print("Mth Prime is ", i)
