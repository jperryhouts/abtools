#!/usr/bin/env python

"""
Cleans PocketSphinx output into a simpler, more
human-readable format.
"""

import fileinput, datetime, sys

def time(s):
    return '\n>> %s\n'%(str(datetime.timedelta(seconds=s)))

ignore = False
last_t = 0.0

sys.stdout.write(time(0))
sys.stdout.flush()

for line in fileinput.input():
    if ignore:
        if line.startswith('</s>'):
            ignore = False
    elif line.startswith('<s>'):
        ignore = True
        t = float(line.split()[1])
        if t-last_t > 60:
            sys.stdout.write(time(t))
            sys.stdout.flush()
            last_t = t
    elif len(line.strip()) > 0:
        sys.stdout.write(line)
        sys.stdout.flush()

