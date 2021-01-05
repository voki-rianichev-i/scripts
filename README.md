Add script directory to PATH or
```cd \<script_directory\>```   
Make sure script has execution mode, you can run
```
chmod +x <path_to_script>
```
to allow to execute this script.  
Usage: 
```
./run.sh.command [options] <path_to_dir>
Options:
-h, --help    : Print this manual
-b, --build   : Run cmake/mac.sh.command and build project with XCode
-p, --pull    : Pull current repo branch and update submodules
--no-cmake    : Don't run CMake on build step
--no-exec     : Don't execute binary
Example: './run.sh.command -b -p ./repos/MM'
This will pull curent branch of './repos/MM' , update submodules,
run 'cmake/mac.sh.command',build project with XCode and execute the binary.
```
