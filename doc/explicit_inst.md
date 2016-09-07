##Explicit Instantiation

Drastically reduce recompilation time of template-heavy C++ code by
instantiating user-specified time-consuming templates in separate compilation
units. This mechanism is a pure __CMake__ optimisation and __completely
unintrusive__ for the C++ code!

### Example

Add the module path to the top level CMakeLists.txt...
~~~{.cmake}
    list(APPEND CMAKE_MODULE_PATH /path/to/cmakescripts)
~~~

...such that this include works
~~~{.cmake}
    include(fsc/explicit_inst)
~~~
One can now instantiate a template (__A__) with the desired types (__int__, __char__)
from a header (__A.hpp__) for some targets (__example1__, __example2__)
~~~{.cmake}
    explicit_inst("example1 example2" foo/A.hpp A<int> A<char>)
~~~

### Arguments

Lets assume we have the following file structure and the examples use __A.hpp__
that contains a very complex template __A__ that takes a long time to compile:
    
    ├── CMakeLists.txt
    ├── example
    │   ├── CMakeLists.txt
    │   ├── example1.cpp
    │   └── example2.cpp
    └── src
        └── foo
            └── A.hpp
#### Targets

The first argument is the target. If multiple targets are supplied, they __have to be
passed in quotes__!
~~~{.cmake}
    explicit_inst( example1  ...)          # ok
    explicit_inst("example1" ...)          # ok
    explicit_inst("example1 example2" ...) # ok
    explicit_inst( example1 example2  ...) # bad! will not work
~~~

#### Source

The second argument is the source, that contains the definition of the 
template, and can be specified 

__absolute__:
~~~{.cmake}
    explicit_inst(... /abs_path_to_project/src/foo/A.hpp ...)
~~~
__relative__ (we assume here that this line is in _example/CMakeLists.txt_):
~~~{.cmake}
    explicit_inst(... ../src/foo/A.hpp ...)
~~~
via __include_directories__:
~~~{.cmake}
    include_directory(${PROJECT_SOURCE_DIR}/src)
    ...
    explicit_inst(... foo/A.hpp ...)
~~~

The last method allows for file movement (as long as they are still included the same way)
without having to change the explicit_inst input. I.e. one only needs to change it
if the includes in the source (`#include <foo/A.hpp>`) need to be changed as well.

#### Instances

All arguments that follow are instances.
They have to be __specified with namespace__!

~~~{.cmake}
    include_directory(${PROJECT_SOURCE_DIR}/src)
    ...
    explicit_inst(... A<int>)
    explicit_inst(... A<int> A<float>)
    explicit_inst(... std::vector<int>)
~~~
(the last example only works if you know where the exact source file is)

### How it works

The downside to templates regarding compile-time is the fact, that each compilation
unit instantiates maybe the same template and the linker removes all but one
instantiation...

To prevent this from happening, we let each compile unit know, that there will be
an instantiation provided while linking with, such that it __does not__ instantiate:

~~~{.cpp}
    extern template class A<int>;
~~~

We add another compilation unit (_A_int.cpp_ which is generated automatic):

~~~{.cpp}
    #include<foo/A.hpp>
    
    template class A<int>;
~~~

That explicitly instantiates the template. Now only this unit takes up 
compile-time for A<int>. We only have to link to the original target.
