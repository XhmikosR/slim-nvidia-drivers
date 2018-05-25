# slim-nvidia-drivers

This is a Windows script which simply removes the unneeded stuff/bloatware from NVIDIA drivers
package and creates a new archive.

**WARNING**: USE AT YOUR OWN RISK!

## Drivers tested:

* v397.93: use v0.2
* v388 - v391: use v0.1

## Requirements:

* a) [7-Zip](https://www.7-zip.org/download.html) installed or b) [7za.exe](https://www.7-zip.org/download.html) in your `%PATH%`, or in the same folder as this script
* A recent Windows version; the script is only tested on Windows 10
* The NVIDIA driver already downloaded somewhere on your computer :)

## Usage:

```
slim-nvidia-drivers.bat NVIDIA_DRIVER_FILE.exe
```

This will create two 7z archives, minimal and slim:

* "minimal" includes only the driver
* "slim" includes the driver, HDAudio and PhysX

## License

MIT
