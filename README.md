#CMake Extensions

This module provides the following modules:

### Explicit Instantiation

Was built to reduce compile time of template-heavy __c++__ code drastic
by instantiating the time-consuming templates in separate compilation units.
This mechanism is completely unintrusive__ for the __c++__ code! Its a pure
__cmake__ optimisation for __c++__ code.

### Softinstall

This module provides a function ___install2___ that can be used instead of 
__cmake__'s __install__ function. It does extends the __install__ function by 
adding a ___softinstall___ target. If one runs ___make softinstall___, an 
installation will take place, but instead of copying the 
libraries/headers/folders/executables, only links will be generated at the 
installation site. This the installation behaves as if one would run __make install__
after every change in the original code.


See the beginning of the corresponding source files for the detailed usage/documentation.

