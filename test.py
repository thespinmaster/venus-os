#!/usr/bin/python3 -u
import os
DEBUG = 'TERM_PROGRAM' in os.environ.keys() and os.environ['TERM_PROGRAM'] == 'vscode'

if DEBUG:
    print("debugging")
else:
    print("not debugging")