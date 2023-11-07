# `petalinux container`
A simple docker abstraction script to make building Petalinux as portable as possible.
This script helps to enable a "portable" Petalinux development environment by providing a "pre-built" ubuntu image.

# Script Dependencies
- python3
- http.server (`pip3 install http.server`)
- expect (`sudo apt install expect`)



# Compatibility
The script initially requires building of the included Dockerfile and downloading the desired 
Petalinux installer.
After a successful initial build, the image can then be pushed to DockerHub for easy reuse.

# Usage
1. Check out this repository to the folder you wish to execute Petalinux builds in
2. Download the [Petalinux installer](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html) of choice then place the `.run` file in a directory called `installers`
3. Define your `container-params` file based off of `container-params.sample`
4. Always run `./container` from the directory you wish to store your Petalinux build outputs.

The script creates a folder in the directory it is run from named `yocto` it then configures the container to run with:

- Your user account
- Your `/home` folder

# Help dialog
Below is the help dialog of `container` at the time of writing:

```
Usage: container [ARGS]

Options:
   --help         print this message
   --pull         pull latest container from Docker Hub
   --info         print various info about the environment you're in
   --build        create an image from the Dockerfile (utilizes cache)
   --rebuild      create an image from the Dockerfile (fresh build)
   [no args]      run with CLI
   --hidden       run in the background
   --stop         stop
```

# Sources
- https://github.com/carlesfernandez/docker-petalinux2/