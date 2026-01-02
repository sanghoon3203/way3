# -*- coding: utf-8 -*-
import sys
print("Python version:", sys.version)
try:
    s = "안녕하세요"
    print("String length:", len(s))
    print("Encoded:", s.encode('utf-8'))
except Exception as e:
    print("Error:", e)
