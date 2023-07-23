#!/usr/bin/python3
# a sample slow program to demonstrate hyperfine benchmarking

def isprime(num):
    for n in range(2, int(num**0.5)+1):
        if num % n == 0:
            return False
    return True


primes = [n for n in range(3, 10001) if isprime(n)]

print("The Prime Numbers in the range 3-10000 are ", len(primes))
