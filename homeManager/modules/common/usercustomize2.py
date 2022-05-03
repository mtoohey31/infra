# -*- coding: utf-8 -*-
try:
    sys
    sys.ps1 = 'py2 \x1b[33m>\x1b[0m '
    sys.ps2 = '      '
except NameError:
    import sys
    sys.ps1 = 'py2 \x1b[33m>\x1b[0m '
    sys.ps2 = '      '
    del sys
