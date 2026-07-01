# slim-nvidia-drivers

This is a Windows script which simply removes the unneeded stuff/bloatware from NVIDIA drivers
package and creates a new archive.

**WARNING**: USE AT YOUR OWN RISK!

**Make sure you get the file from the [Releases section](https://github.com/XhmikosR/slim-nvidia-drivers/releases), otherwise you will have issues with unix line endings!**

## Drivers tested:

* \>= v440.97: use v0.5
* \>= v411.63: use v0.3
* \>= v397.93: use v0.2
* v388 - v391: use v0.1

### Cards tested

Note that the resulting drivers have been tested on GTX 1060, GTX 1070 and MX 150 cards. If you own a newer card that needs other components to be included, please make a Pull Request.

## Requirements:

* a) [7-Zip](https://www.7-zip.org/download.html) installed or b) [7za.exe](https://www.7-zip.org/download.html) in your `%PATH%`, or in the same folder as this script
* A recent Windows version; the script is only tested on Windows 11
* The NVIDIA driver already downloaded somewhere on your computer :)

## Usage:

```bat
slim-nvidia-drivers.bat [-type minimal|slim|all] NVIDIA_DRIVER_FILE.exe
```

Or just drag and drop the `NVIDIA_DRIVER_FILE.exe` on the bat file.

Arguments can be given in any order, and `-type`/`--type` are equivalent, so all of these work:

```bat
slim-nvidia-drivers.bat -type slim NVIDIA_DRIVER_FILE.exe
slim-nvidia-drivers.bat NVIDIA_DRIVER_FILE.exe --type slim
```

`-type` picks which archive(s) to create:

* `minimal` includes only the driver (Display.Driver, NVI2)
* `slim` includes the driver, HDAudio, PhysX and the USB-C HDMI driver (default when `-type` is omitted)
* `all` builds both

## License

[MIT](LICENSE)
