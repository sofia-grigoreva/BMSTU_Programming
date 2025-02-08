import random
import string

char = string.ascii_letters + string.punctuation + string.digits

def random_str(str_length):
    str = ''
    for i in range(str_length):
        str += random.choice(char)
    return str
