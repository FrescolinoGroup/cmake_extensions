##Softinstall

Provides a function __install2()__ and a target __softinstall__. Targets using
__install2__ instead of the default __install__ will exhibit the standard
__CMake__ behaviour, but are also softinstall-enabled: when running __make
softinstall__, the files will be symlinked instead of copied to their
destination. This allows for convenient testing without __make install__ after
every edit on the source tree.
