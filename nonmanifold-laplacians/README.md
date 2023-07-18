 ## This is the set up script, so you can run tufted-idt executable in Matlab on Linux system.
 see also tufted_wrapper
 
 by Qiongjing (Jenny) Zou, Sep 2021
 

 Copyright (C) 2023, Danuser Lab - UTSouthwestern 

 This file is part of uSignal3DPackage.
 
 uSignal3DPackage is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 uSignal3DPackage is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with uSignal3DPackage.  If not, see <http://www.gnu.org/licenses/>.

 
 
### On your Linux command line, type below commands:
`cd ~`

`mkdir bin`

`cd bin`

`pwd`

### Edit below two lines as needed:
These are to copy tufted executable and bash command from your Matlab extern folder to the bin folder in your Linux home directory.

For UTSW_BioHPC users, bin can be set in the /home2/s111111/bin, you should replace s111111 with the BioHPC user number.

`copyfile u-signal3D-master/nonmanifold-laplacians/tufted-idt /home2/s111111/bin`

`copyfile u-signal3D-master/nonmanifold-laplacians/tufted /home2/s111111/bin`

### You should only need to set up below steps once on your Linux command line:
These are to make sure the executive tufted files are executable in Matlab. 

The “export PATH=something:$PATH” command modifies the PATH environment variable of the current system. The “PATH” variable contains the list of directories that the operating system searches for specific executable files.

`!export PATH=$PATH":/home2/s111111/bin"`

`!echo $PATH`

`!chmod +x tufted`

`!. ~/.bash_profile`
