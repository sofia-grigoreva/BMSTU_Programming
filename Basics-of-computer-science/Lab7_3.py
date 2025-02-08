#!/usr/bin/python3
import sys
from random_str import random_str

if __name__=="__main__":
        str_length = int(sys.argv[1])
        str_amount = int(sys.argv[2])

        for i in range(str_amount):
                print(random_str(str_length))
