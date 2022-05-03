try:
    sys
    sys.ps1 = 'py \x1b[33m>\x1b[0m '
    sys.ps2 = '     '
except NameError:
    import sys
    sys.ps1 = 'py \x1b[33m>\x1b[0m '
    sys.ps2 = '     '
    del sys
