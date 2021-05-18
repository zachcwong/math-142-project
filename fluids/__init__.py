# NOTE: must run `pyximport.install` before importing
# Cython extension modules, like `simulator`

import pyximport
pyximport.install()

from . import simulator
