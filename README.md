These instructions cover how to install [Debian 'jessie' 8.x](https://www.debian.org/) onto a [Microsoft Surface Pro 4](https://www.microsoft.com/surface/devices/surface-pro-4).

The instructions assume you are not new to Debian, though you may have no experience of UEFI and SecureBoot (I did not until now!).

## What is Working

 * dual booting
 * SecureBoot
 * Touchscreen and Pen
 * typing cover keyboard
     * multitouch touchpad (two finger scrolling, etc)
     * special keys
 * 2D and 3D (OpenGL) acceleration
     * hardware video decoding
 * power and volume buttons on the screen
 * audio (including the microphone)
 * sensors - `dev_rotation` though gives nothing but zeros
 * wireless (is a 88W8897, a wireless/bluetooth combo module)
     * bluetooth - this only appears once you use the wireless card firmware from [firmware-libertas (20151207-1~bpo8+1) [pcie8897_uapsta.bin version 15.68.4.p112]](https://packages.debian.org/jessie-backports/firmware-libertas)
 * microSD reader - presented as a USB reader appearing when you insert a card
 * suspend (rather freeze), hibernate and resume works

## Outstanding Issues

 * camera
     * is on an I2C bus on accessible via the graphics card
     * from the ACPI DSDT you can get information on what the *three* cameras are
     * front camera (`CAMF`) is a [`OV5693 (INT33BE)`](http://www.ovt.com/products/sensor.php?id=185), there is an [Android driver](https://github.com/sayeed99/test/blob/eadd15672fd628eab9ad5bfcaf00d1b7fbafee3f/drivers/external_drivers/camera/drivers/media/i2c/ov5693/ov5693.c)
     * rear camera (`CAMR`) is a [`OV8865 (INT347A)`](http://www.ovt.com/products/sensor.php?id=134), there is an [Android driver](https://github.com/lenovo-yt2-dev/android_kernel_lenovo_baytrail/blob/357b3bc165c76b9cf1f0d2c08e458576018164a3/drivers/external_drivers/camera/drivers/media/i2c/ov8865.c)
     * third camera (`CAM3`) is an IR [`OV7251 (INT347E)`](http://www.ovt.com/products/sensor.php?id=146), there is an [Android driver](https://github.com/ADVANSEE/0066_linux/blob/ba2479578aa7f35be22f6749f7504ba3a68414dc/drivers/media/video/mxc/capture/ov7251_mipi.c)
 * opening the typing cover (or pressing keys) does not not automatically resume
 * [AC adaptor events](https://bugzilla.kernel.org/show_bug.cgi?id=109891)
     * [DSDT changes required to fix this](https://www.reddit.com/r/SurfaceLinux/comments/46o3mh/fix_udev_power_adapter_event_by_patching_acpi/)
     * once done, we can turn turbo boost off on battery via `/sys/devices/system/cpu/intel_pstate/no_turbo`
 * there is an ACPI `INT3420` entry for 'Intel Bluetooth RF Kill' which would be nice to have
 * enable the other I2C (`INT344[2-5]`) and SPI (`INT344[01]`) busses via `drivers/mfd/intel-lpss-acpi.c` maybe?
 * there are a number of hardware sensors via a MAX34407 on the I2C bus
 * there is no [S3 'suspend to RAM'](http://acpi.sourceforge.net/documentation/sleep.html) available as since the Surface Pro 3, [connected standby](https://lwn.net/Articles/580451/) (ACPI state [S0ix](http://www.anandtech.com/show/6355/intels-haswell-architecture/3)) replaces it; [although supported by Linux fundamentally by Linux, some practical work is still needed](http://mjg59.dreamwidth.org/34542.html?thread=1378798#cmt1378798)
     * this means that S3 'suspend to RAM' (`echo mem > /sys/power/state`) is replaced with S1 'power on suspend' (`echo freeze > /sys/power/state`) which uses a lot more juice; 100% charge lasts about 12 hours
     * amending the DSDT manually to remove the conditional that masks out S3 results in `echo mem > /sys/power/state` making the laptop power up as if power cycled.  Probably works better with [`acpi_rev_override` (`_REV=2`)](https://mjg59.dreamwidth.org/34542.html) and `acpi_os_name="Windows 2012"` (or earlier)
 * [Caps Lock key light](https://patchwork.kernel.org/patch/7844371/) - 'fixed' by running `sudo kbd_mode -u`
     * this is not a problem with the `hid-microsoft` driver which if you want to use make sure you are using `xserver-xorg-input-evdev >=2.10` as well as `Option "IgnoreAbsoluteAxes" "on"`
     * we use the `hid-multitouch` driver as it presents separate keyboard and touchpad devices, which means the xorg `evdev` driver does not handle the touchpad and `mtrack` sees it as a touchpad and can handle it
 * Wireless
     * [power saving needs to be turned off](./root/etc/network/interfaces.d/mlan0) otherwise after about a minute of idling, you start seeing 100ms+ first hop latencies
     * `modprobe -r mwifiex_pcie; modprobe mwifiex_pcie` results in a lockup; you need to reset the card inbeteen the unload/load with `echo 1 > /sys/bus/pci/devices/0000\:02\:00.0/reset`
     * on kernel 4.5.x (and I guess 4.6.x too) the [driver is pretty flakey](https://github.com/jimdigriz/debian-mssp4/issues/4) though there is a patch on the linked bugzilla
 * the GRUB with SecureBoot needs some more work, the fonts are bust, plus I need to find the problematic module so we can just load the lot in making the process simpler
 * `gparted` lockup investigation
 * move to using [`triggerhappy`](https://github.com/wertarbyte/triggerhappy) rather than `xbindkeys` so that the [multimedia keys can still work with the screen locked](https://github.com/i3/i3lock/issues/52)
 * reading sensors (such as the ALS) occasionally takes a long time, [which might be related to bad timings](https://github.com/torvalds/linux/commit/56d4b8a24cef5d66f0d10ac778a520d3c2c68a48):

        [10805.080581] i2c_hid i2c-MSHW0030:00: failed to change power setting.
        [10805.080969] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10805.081317] i2c_hid i2c-MSHW0030:00: failed to set a report to device.
        [10805.081609] i2c_hid i2c-MSHW0030:00: failed to set a report to device.
        [10805.081887] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10805.484550] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10810.588300] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10815.691993] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10820.795814] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10825.899475] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10831.003440] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10836.107134] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10841.210879] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
        [10849.482535] i2c_hid i2c-MSHW0030:00: failed to set a report to device.
        [10849.482955] i2c_hid i2c-MSHW0030:00: failed to change power setting.
        [10849.483393] i2c_hid i2c-MSHW0030:00: failed to set a report to device.
        [10849.483781] i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.

## Related Links

 * because of the high resolution screen it is worth reading through some [HiDPI related materials](https://wiki.archlinux.org/index.php/HiDPI) otherwise you will very quickly go short sighted
 * wishing for a matte screen, I got the [iLLumiShield](http://www.amazon.co.uk/gp/product/B0169CKLBK) and find it does the job great
 * for a nice cheap case, I got the blue map motif [MoKo Ultra Slim Lightweight Smart-shell Stand Cover Case (Map F)](https://www.amazon.co.uk/Microsoft-Surface-Pro-Case-Lightweight/dp/B014P2NOLU/)
 * patches based on
      * [IPTS Linux](https://github.com/ipts-linux-org/ipts-linux-new/wiki) driver
      * [[PATCH 1/2] HID: Use multitouch driver for Type Covers](http://lkml.iu.edu/hypermail/linux/kernel/1512.1/05130.html)
      * [[1/2] HID: input: rework HID_QUIRK_MULTI_INPUT](https://patchwork.kernel.org/patch/9081731/)
      * [[2/2] HID: multitouch: enable the Surface 3 Type Cover to report multitouch data](https://patchwork.kernel.org/patch/9081761/)
 * [iio-sensor-proxy](https://github.com/hadess/iio-sensor-proxy) - `systemctl enable iio-sensor-proxy.service`
 * Hibernation
      * [Ubuntu Hibernation](https://help.ubuntu.com/community/PowerManagement/Hibernate)
 * [reverse scrolling](https://n00bsys0p.wordpress.com/2011/07/26/reverse-xorg-scrolling-in-linux-natural-scrolling/)
 * [reddit - Surface Linux: Penguins like nice things too](https://www.reddit.com/r/surfacelinux)
 * [Microsoft Surface Pro 4 update history](https://www.microsoft.com/surface/en-gb/support/install-update-activate/surface-pro-4-update-history)
 * SecureBoot
      * [Using the Linux Foundation's PreLoader](http://www.rodsbooks.com/efi-bootloaders/secureboot.html#preloader)
      * [Accessing UEFI Variables from Linux](http://firmware.intel.com/blog/accessing-uefi-variables-linux)
      * [ArchLinux: Surface Pro 3 - Booting with Secure Boot Enabled](https://wiki.archlinux.org/index.php/Microsoft_Surface_Pro_3#Booting_with_Secure_Boot_Enabled)

# Preflight

You will require:

 * an external USB keyboard, as the typing cover is not supported by Debian's kernel
 * a USB hub as there is only one USB port
 * a USB key `dd`'ed with the amd64 live ISO for [gparted](http://gparted.sourceforge.net/)
      * **WARNING:** `gparted-live-0.24.0-2-amd64.iso` locked up after a few minutes of running, you of course do *not* want this midway through the resize.  All I can recommend if you use this version, is to be quick
      * I have tried to boot `0.25.0-1` but it fails for various reasons whilst `0.25.0-3` the {md5,sha1}sums for the ISOs mis-match which explains why they do not work
 * a USB key `dd`'ed with the [non-free amd64 Debian network installer](http://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current/amd64/iso-cd/); I used `firmware-8.2.0-amd64-netinst.iso`
 * an (open, WEP or WPA PSK) wireless network you can connect to (or an USB Ethernet adaptor)

## Prepping Windows 10

The aim here is to shrink down the Windows partition to make room for Debian.

I wanted to keep Windows as Microsoft are constantly [releasing updated firmwares which will only apply from under Windows](https://www.microsoft.com/surface/en-gb/support/install-update-activate/surface-pro-4-update-history).  Of course if you plan not on dual booting you could skip all this, though I would not recommend to have something to apply those firmware updates with.

Lets start by disabling Bitlocker so that gparted can resize the partition later.  This is done by clicking on Start, and clicking on 'File Manager'.  From here you will be able to go to where drive `C:` is located, and right-clicking on it will give you an option to 'Manage Bitlocker'.  From there you will be able to click on 'Disable Bitlocker'.

**N.B.** if there is an exclamation mark on the drive `C:` icon, you will need to firstly enable Bitlocker before you can fully disable it

Now we need to disable SecureBoot to let us boot Linux later on.

 - Either:
      * from Windows, click on Start -> Power -> (hold down shift) -> click on 'Restart'
           - go to 'Troubleshoot'
           - go to 'Advanced options'
           - select 'UEFI Firmware Settings'
      * whilst powered off, hold down the '+' volume button and turn on the laptop
 - you will be dropped into the Surface UEFI system
 - go to 'Security'
 - under 'Secure Boot', click on 'Change configuration'
 - select 'None' from the menu and click on OK

Before we go and shrink the Windows partition, lets start off by getting the latest updates (including firmwares) installed (I did this on 2015-12-31), so prepare yourself for a long and tediously slow process (hours) of watching progress bars and lots of reboot cycles as Windows 'does its thing'.

We now need to free up a space on drive `C:` and get ready for shrinking by:

 - [turning off the hibernation file](https://support.microsoft.com/kb/920730)
 - [turning off the paging file](http://windows.microsoft.com/en-us/windows/change-virtual-memory-size)
 - [run disk cleanup (including on the system files)](http://windows.microsoft.com/en-us/windows-10/disk-cleanup-in-windows-10) - here you can delete any old versions of Windows which can take up ~25GB
 - run *twice* `CHKDSK` on drive `C:`, this is done by opening a command prompt as administrator and typing `chkdsk /f c:`, you will need to reboot for the chkdsk to work; remember to do it a second time too!

## Shrinking the Windows Partition

Insert the gparted USB key and boot it by either:

 * from Windows, click on Start -> Power -> (hold down shift) -> click on 'Restart'
      - go to 'Use a device'
      - select 'USB Storage'
 * go to the Surface UEFI system by powering on whilst holding down the '+' volume button
      - go to the 'Boot configuration' section
      - left swipe on 'USB Storage' to boot off your USB key

You should be able to boot into gparted now, and get something that lets you reduce the size of the NTFS partition; for me Windows took up 22GB of space so I left it in a 60GB partition to leave it enough room for Windows Update.

Once shrunk, you should test that you can still boot into Windows, and if you can, we are ready to move on (though you may wish to first go back into Window and re-enable hibernation, the paging file and Bitlocker).  If not, you will have to figure out what is wrong.

For reference, my partition table looks like:

    alex@quatermain:~$ sudo fdisk -l /dev/nvme0n1
    Disk /dev/nvme0n1: 238.5 GiB, 256060514304 bytes, 500118192 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: B9B03E80-67C3-41C1-AF4F-367C32AF2CE5
    
    Device             Start       End   Sectors   Size Type
    /dev/nvme0n1p1      2048    534527    532480   260M EFI System
    /dev/nvme0n1p2    534528    796671    262144   128M Microsoft reserved
    /dev/nvme0n1p3    796672 130377727 129581056  61.8G Microsoft basic data
    /dev/nvme0n1p4 494813184 500117503   5304320   2.5G Windows recovery environment
    /dev/nvme0n1p5 130377728 493658111 363280384 173.2G Linux LVM
    /dev/nvme0n1p6 493658112 494813183   1155072   564M Linux filesystem
    
    Partition table entries are not in disk order.

**N.B.** you should set your swap space to about 1.5x the amount of memory you have to make sure you have space to hibernate

# Installing Debian

Boot off your Debian installer USB key and work through it.  Early on though you will be prompted on which Ethernet card you have, select "no Ethernet interface", then the next page you will be prompted to supply details on how to connect to your wireless network then the installation will continue as expected.

**N.B.** I would recommend keeping the ~2.5GB recovery partition so if you ever need to return the laptop, you will find the process dead easy; though it seems you could [move the partition to external media](https://www.microsoft.com/surface/en-ca/support/storage-files-and-folders/create-a-recovery-drive?os=windows-10) or [download it from the Microsoft website](https://www.microsoft.com/surface/en-ca/support/warranty-service-and-recovery/downloadablerecoveryimage)

For your information, I went for a `/boot` partition and put everything else on LVM.

When the installer gets to the point of installing GRUB as your boot loader, it will fail.  To resolve this you will need to 'Execute a shell' and type the following:

    mount --bind /sys /target/sys
    chroot /target /bin/bash
    apt-get install grub-efi
    update-grub
    grub-install /dev/nvme0n1
    exit
    umount /target/sys
    exit

Now click on 'Continue without a bootloader'.

You laptop should reboot and you will see the GRUB bootloader and Debian should boot.

**N.B.** until you install a newer (backports) kernel GRUB will not detect and boot Windows

# Configuring

## Add Additional Repositories

You need to add [Debian backports](http://backports.debian.org/), stretch, sid, as well as some suitable pinning.  So copy into place the required files under [`/etc/apt/`](root/etc/apt/).  Now run:

    sudo apt-get update

## Networking

All you need to do is copy the contents of [`interfaces.d`](root/etc/network/interfaces.d) into `/etc/network/interfaces.d/`; plus create a suitable `/etc/wpa_supplicant/wpa_supplicant.conf` file (if you are not using any network management tool).

## Kernel

First you need to set some kernel boot arguments which are set in [`/etc/default/grub`](root/etc/default/grub):

    resume=/dev/mapper/lvm--quatermain-swap

**N.B.** you must adjust the `resume` argument to match where your swap space is, or if you plan not to use hibernation, replace it with `noresume`

**N.B.** if you are running a kernel earlier than 4.4, you will also need to add `intel_idle.max_cstate=2` otherwise the GPU whilst modeset'ing will black out the screen and crash the system

Also, so that your keyboard works before the root filesystem is mounted, edit your [`/etc/initramfs-tools/modules`](root/etc/initramfs-tools/modules) file to include `hid_multitouch`.

Run the following to get your system ready to compile a kernel:

    sudo apt-get install build-essential git fakeroot kernel-package
    sudo apt-get install firmware-libertas/jessie-backports firmware-misc-nonfree intel-microcode
    wget -P /usr/src http://http.debian.net/debian/pool/main/l/linux/linux-source-4.8_4.8.7-1_all.deb
    
    git clone https://gitlab.com/jimdigriz/linux.git /usr/src/linux
    cd /usr/src/linux
    git checkout mssp4
    ar p /usr/src/linux-source-4.8_4.8.7-1_all.deb data.tar.gz | gunzip -c | tar xO ./usr/src/linux-config-4.8/config.amd64_none_amd64.xz | xzcat > .config
    
    cat <<'EOF' >> .config
    CONFIG_INTEL_IPTS=m
    CONFIG_BLK_DEV_NVME=y
    CONFIG_MODULE_SIG=n
    CONFIG_SYSTEM_TRUSTED_KEYRING=n
    EOF

Now run `make oldconfig` (accept the defaults to all the prompting) so our `.config` changes are incorporated (we make `nvme` built in so hibernation works).

Time to compile the kernel (this will take about 40 minutes):

    CONCURRENCY_LEVEL=`getconf _NPROCESSORS_ONLN` fakeroot make-kpkg --initrd --append-to-version=-mssp4 kernel_image

**N.B.** you can append `kernel_headers` to also build the `linux-headers` package too

Once compiled (roughly 40 minutes), you now need to install your new kernel:

    sudo dpkg -i /usr/src/linux-image-4.9.0-rc7-mssp4+_4.9.0-rc7-mssp4+-10.00.Custom_amd64.deb

Now reboot into your new kernel.

## Power

Install the needed packages:

    sudo apt-get install sleepd

Copy in the [`/lib/systemd/system-sleep`](root/lib/systemd/system-sleep) helper files, [`/etc/systemd/sleep.conf`](root/etc/systemd/sleep.conf) and also [`/etc/default/sleepd`](root/etc/default/sleepd).

You should be able to suspend (`echo freeze | sudo tee /sys/power/state`, or close the typing cover), hibernate (`echo disk | sudo tee /sys/power/state`) and resume (hold the power button for roughly five seconds).

If you have problems, such as stalls at boot time, there probably is a problem with your `resume` kernel parameter (did you compile the kernel with `nvme` built in?), so to break out of the stall add `noresume` to your kernel parameters.

### Screen Locking

To lock your X11 console, you will need a few packages:

    sudo apt-get install xautolock xss-lock

Then set your [`~/.xsession`](root/home/USER/.xsession) accordingly to run these.

### PowerTOP

A number of [PowerTOP](https://01.org/powertop/) suggestions are applied with:

 * [`/etc/sysctl.d/local.conf`](root/etc/sysctl.d/local.conf)
 * [`/etc/modprobe.d/local.conf`](root/etc/modprobe.d/local.conf)
 * [`/etc/udev/rules.d/90-local.rules`](root/etc/udev/rules.d/90-local.rules)

## Graphics

### Console

All you need to do is so run:

    sudo dpkg-reconfigure console-setup

Then select the 'Terminus' font, and the 16x32 sizing.

**N.B.** you can set the keyboard mapping for the console (and Xorg) with `localectl ...`

Unfortunately there is an outstanding bug ([console-setup w/ systemd forgets font setting](https://bugs.debian.org/759657)) which means you have to slip in [`/etc/udev/rules.d/90-setupcon.rules`](root/etc/udev/rules.d/90-setupcon.rules) to stop them being shrunk again (and the keyboard mapping being forced back to US)

### Xorg

Start off by installing Xorg:

    sudo apt-get install xserver-xorg xserver-xorg-input-mtrack xserver-xorg-video-intel libgl1-mesa-dri libgl1-mesa-glx big-cursor

Now populate [`/etc/X11/xorg.conf.d`](root/etc/X11/xorg.conf.d) and then you should be able to start Xorg (I recommend installing the [lightdm](http://freedesktop.org/wiki/Software/LightDM/) package) and it will have 2D and 3D acceleration enabled.  You can check this by running:

    alex@quatermain:~$ grep AIGLX /var/log/Xorg.0.log
    [     5.124] (==) AIGLX enabled
    [     5.183] (II) AIGLX: enabled GLX_MESA_copy_sub_buffer
    [     5.183] (II) AIGLX: enabled GLX_ARB_create_context
    [     5.183] (II) AIGLX: enabled GLX_ARB_create_context_profile
    [     5.183] (II) AIGLX: enabled GLX_EXT_create_context_es2_profile
    [     5.183] (II) AIGLX: enabled GLX_INTEL_swap_event
    [     5.183] (II) AIGLX: enabled GLX_SGI_swap_control and GLX_MESA_swap_control
    [     5.183] (II) AIGLX: enabled GLX_EXT_framebuffer_sRGB
    [     5.183] (II) AIGLX: enabled GLX_ARB_fbconfig_float
    [     5.183] (II) AIGLX: GLX_EXT_texture_from_pixmap backed by buffer objects
    [     5.183] (II) AIGLX: enabled GLX_ARB_create_context_robustness
    [     5.183] (II) AIGLX: Loaded and initialized i965

If this does not work then you should check that the apt pinning brought in `libdrm-intel1`, `libgl1-mesa-{dri,glx}` and `xserver-xorg-video-intel` from jessie-backports.

Then from within X you should see something like:

    alex@quatermain:~$ xdriinfo 
    Screen 0: i965
    
    alex@quatermain:~$ glxinfo | head
    name of display: :0
    display: :0  screen: 0
    direct rendering: Yes
    server glx vendor string: SGI
    server glx version string: 1.4
    server glx extensions:
        GLX_ARB_create_context, GLX_ARB_create_context_profile, 
        GLX_ARB_create_context_robustness, GLX_ARB_fbconfig_float, 
        GLX_ARB_framebuffer_sRGB, GLX_ARB_multisample, 
        GLX_EXT_create_context_es2_profile, GLX_EXT_framebuffer_sRGB, 

#### Backlight

You can use (range from 0 to 937):

    xrandr --output eDP1 --set Backlight 400

If you prefer, you might want to use:

    sudo apt-get install xbacklight

Alternatively, look at `/sys/class/backlight/intel_backlight/{brightness,max_brightness}`.

#### Multimedia Keys

This depends on your environment, though I am using [xbindkeys](http://www.nongnu.org/xbindkeys/xbindkeys.html) which should be pretty usable on all desktop environments.

    sudo apt-get install xbindkeys libnotify-bin

Copy in a [`~/.xbindkeysrc`](root/home/USER/.xbindkeysrc) file and also the screen brightness setting script [`/usr/local/bin/mssp4-backlight`](root/usr/local/bin/mssp4-backlight).

Restart X11 (to pick up the load in your `~/.xsession` file), or run 'xbindkeys' in a terminal.

#### Hardware Video Decoding

Lets install the drivers and a video player:

    sudo apt-get install mpv/jessie-backports libva1 i965-va-driver vainfo

Test if you have VA-API acceleration available with:

    vainfo

If so, now configure `mpv` to use the API.

    mkdir ~/.config/mpv
    echo hwdec=vaapi > ~/.config/mpv/mpv.conf

When you play videos, you should find the CPU utilisation drops substantially; I saw a 3.5x improvement!

If this does not work (you see `Using software decoding.` in the output of `mpv`) it may be because this only works for videos encoded with a codec where VA-API accelerated decoding is available (you will see `Using hardware decoding.` when it works).  For hints, example the output of `vainfo` and compare it to what `mpv` says the video codec is (for example `h264`).

##### Chromium (and Opera)

Lets install Chromium:

    sudo apt-get install chromium

Open a tab to [chrome://gpu](chrome://gpu) and should see [hardware acceleration is off for a number of things](https://bugs.chromium.org/p/chromium/issues/detail?id=137247).  To fix this, go to in another tab [chrome://flags/#ignore-gpu-blacklist](chrome://flags/#ignore-gpu-blacklist) and enable 'Override software rendering list'.  When you click on 'Relauch now' you should see 'Video Decode' is now enable in the [chrome://gpu](chrome://gpu) tab.

Now install the [h264ify](https://chrome.google.com/webstore/detail/h264ify/aleakchihdccplidncghkekgioiakgal) extension and then test by watching [COSTA RICA IN 4K 60fps (ULTRA HD) w/ Freefly Movi](https://youtu.be/iNJdPyoqt8U) and cranking it up to 2160p.  Under the menu option 'stats for nerds' you should see pretty much zero frame drops and your CPU only going to 100%ish, rather than the 250%+ without and the stuttering that goes with software rendering at this resolution.

##### Vivaldi

Similar to the Chromium/Opera instructions (override the software rendering list and install h264ify), you will also need to fetch [vivaldi-snapshot](https://vivaldi.net/en-US/teamblog/132-snapshot-1-3-537-5-improved-proprietary-media-support-on-linux) from the [Vivaldi website](https://vivaldi.com) (it will auto-update afterwards).  Now go and fetch [chromium-codecs-ffmpeg-extra](http://packages.ubuntu.com/wily-updates/chromium-codecs-ffmpeg-extra) from Ubuntu and install it.

    sudo dpkg -i chromium-codecs-ffmpeg-extra_51.0.2704.79-0ubuntu0.15.10.1.1232_amd64.deb

Now install:

    sudo apt-get install libvdpau-va-gl1 vdpauinfo

Now run vivaldi with:

    VDPAU_DRIVER=va_gl vivaldi

##### Firefox

For Firefox, [which does not support any HTML5 video hardware decoding](https://bugzilla.mozilla.org/show_bug.cgi?id=563206), you can persuade the ([non-pepper](https://wiki.debian.org/PepperFlashPlayer)) `flashplugin-nonfree` package to use [hardware acceleration](http://www.webupd8.org/2013/09/adobe-flash-player-hardware.html):

    sudo apt-get install libvdpau-va-gl1 vdpauinfo
    sudo mkdir /etc/adobe
    echo -e "EnableLinuxHWVideoDecode = 1\nOverrideGPUValidation = 1" | sudo tee /etc/adobe/mms.cfg
    sudo sed -i '/va_gl/ s/^# //' /etc/X11/Xsession.d/20vdpau-va-gl

You will now need to logout and back in to get the `VDPAU_DRIVER` environment variable set, or you can quickly test things with:

    VDPAU_DRIVER=va_gl firefox

For me, I get about 20% CPU usage for Flash at 1080p, whilst with HTML5 I get 170%.  It is worth installing one of the many Firefox extensions that force YouTube (and other sites) to use the Flash player to lower battery (and fan!) usage.

**N.B.** it seems that if you go above 1080p, the acceleration is no longer used and there is a significant uptick in CPU utilisation

## Touchscreen and Pen

The driver (`intel-ipts`) is already in the compiled kernel (from the above instructions) so after copying the various binaries described below into place, you should be able to reboot and start using your touchscreen and pen.

**N.B.** you will of course need to pair your the (bluetooth) pen to your laptop

### OpenCL

You will need the OpenCL kernel binaries that are located in your Windows partition at `%WINDIR%\INF\PreciseTouch` and you need to copy the contents of it all to `/lib/firmware/intel/ipts` and add the following symbolic links:

    sudo mkdir -p /lib/firmware/intel/ipts
    mkdir windows
    mount mount -o ro /dev/nvme0n1p3 windows
    sudo cp windows/Windows/INF/PreciseTouch/Intel/SurfaceTouchServicingKernelSKLMSHW0078.bin /lib/firmware/intel/ipts
    sudo cp windows/Windows/INF/PreciseTouch/Intel/SurfaceTouchServicingDescriptorSKLMSHW0078.bin /lib/firmware/intel/ipts
    sudo cp windows/Windows/INF/PreciseTouch/Intel/SurfaceTouchServicingSFTConfigSKLMSHW0078.bin /lib/firmware/intel/ipts
    umount windows
    rmdir windows

    sudo cp /usr/src/linux/firmware/intel/ipts/ipts_fw_config.bin /lib/firmware/intel/ipts
    sudo ln -s iaPreciseTouchDescriptor.bin /lib/firmware/intel/ipts/intel_desc.bin
    sudo ln -s SurfaceTouchServicingDescriptorMSHW0078.bin /lib/firmware/intel/ipts/vendor_desc.bin
    sudo ln -s SurfaceTouchServicingKernelSKLMSHW0078.bin /lib/firmware/intel/ipts/vendor_kernel.bin
    sudo ln -s SurfaceTouchServicingSFTConfigMSHW0078.bin /lib/firmware/intel/ipts/config.bin

Once done, the directory structure should look like:

    $ tree /lib/firmware/intel/ipts
    /lib/firmware/intel/ipts
    +-- config.bin -> SurfaceTouchServicingSFTConfigMSHW0078.bin
    +-- iaPreciseTouchDescriptor.bin
    +-- intel_desc.bin -> iaPreciseTouchDescriptor.bin
    +-- ipts_fw_config.bin
    +-- SurfaceTouchServicingDescriptorMSHW0078.bin
    +-- SurfaceTouchServicingKernelSKLMSHW0078.bin
    +-- SurfaceTouchServicingSFTConfigMSHW0078.bin
    +-- vendor_desc.bin -> SurfaceTouchServicingDescriptorMSHW0078.bin
    \-- vendor_kernel.bin -> SurfaceTouchServicingKernelSKLMSHW0078.bin

### GuC Firmware

Since kernel 4.7, the [GuC firmware version has been bumped from 4.3 to 6.1](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/commit/?id=ab65cce821cc46ccdc0b62f99bb79f75c1c7412c).  Debian jessie does not have this version so you need to [downlownload it](https://01.org/linuxgraphics/downloads/skylake-guc-6.1):

    curl -s -f https://01.org/sites/default/files/downloads/intelr-graphics-linux/sklgucver61.tar.bz2 \
        | tar jxO skl_guc_ver6_1/skl_guc_ver6_1.bin \
        | sudo tee /lib/firmware/i915/skl_guc_ver6_1.bin >/dev/null
    sudo ln -s -f -T skl_guc_ver6_1.bin /lib/firmware/i915/skl_guc_ver6.bin

The MD5 checksum of `/lib/firmware/i915/skl_guc_ver6_1.bin` should be:

    md5sum /lib/firmware/i915/skl_guc_ver6_1.bin
    07fa52bd5b7401868cf17105db7dc3ab  /lib/firmware/i915/skl_guc_ver6_1.bin

## Sensors

### `dev_rotation`

This sensor seems not to do anything for now which means `xrandr` auto-rotation is not available:

    watch -n1 cat /sys/bus/iio/devices/iio\:device*/in_rot_quaternion_raw

**N.B.** of interest though, is that when you rotate the laptop onto its side, if you have the typing cover still plugged in it gets disabled

### `als`

You can check the light level by running the following:

    watch -n1 cat /sys/bus/iio/devices/iio\:device*/in_intensity_both_raw

Interact with the sensor by covering and uncovering sensor located the farthest on the right at the top of the screen.

### `accel_3d`

Move the laptop about whilst running in a terminal:

     watch -n1 cat /sys/bus/iio/devices/iio:device*/in_accel_[xyz]_raw

### `gyro_3d`

Move the laptop about whilst running in a terminal:

     watch -n1 cat /sys/bus/iio/devices/iio:device*/in_anglvel_[xyz]_raw

## SecureBoot

It is possible to get Debian booting with SecureBoot.  However, as well as having the listed restrictions below, it is a bit of a pain to set up, plus to be frank it is a lot of effort and hassle just to avoid seeing a red padlock on boot.  Indeed there is some slight benefit of security, but if you insist on running untrusted code as root under Linux or administrator under Windows, then it hardly is going to save you ;)

Anyway, if you do want to do this, you should be aware of the following constraints:

 * you use the [Linux Foundation Secure Boot System, `PreLoader.efi`](http://blog.hansenpartnership.com/linux-foundation-secure-boot-system-released/)
 * GRUB [cannot load modules](http://askubuntu.com/questions/642653/loopback-module-for-grub-with-secure-boot), so you need to generate a GRUB image with the modules you need built it
     * the solution below needs you to understand how to get GRUB to the point of being able to load `/boot/grub/grub.cfg`; my example below involves just a dedicated unencrypted non-LVM `/boot` mount point, you might need to adapt the `/tmp/grub.cfg` file accordingly for your own setup
     * `grub-mkstandalone` simply puts all the modules in a memdisk, so you still get the same problem
     * building in *all* modules does not work as there is a module (no idea which, let me know if you work it out!) that stops GRUB detecting anything except for procfs
     * it is really difficult to get a definitive list of what modules you need, it is a bit trial and error, plus you may want extras like `cat`, `lspci`, etc
     * every time the grub package updates, you *should* rebuild the image and re-enroll it

Start off by going into GRUB, and before Linux boots, go to the command line (pressing 'c').  On the command line, type `lsmod` and note down the modules loaded, now go back to booting into Linux.

**N.B.** for reference, my list is: `fshelp` `ext2` `part_gpt` `boot` `extcmd` `crypto` `terminal` `gettext` `gzio` `normal` `test` `disk` `loadenv` `video` `bufio` `font` `video_fb` `gfxterm` `efi_gop` `efi_uga` `video_bochs` `video_cirrus` `all_video` `gfxterm` `minicmd`

Once booted, run:

    sudo apt-get install efibootmgr
    
    sudo mkdir -p /boot/efi/EFI/PreLoader
    sudo curl -L -o /boot/efi/EFI/PreLoader/PreLoader.efi http://blog.hansenpartnership.com/wp-uploads/2013/PreLoader.efi
    sudo curl -L -o /boot/efi/EFI/PreLoader/HashTool.efi  http://blog.hansenpartnership.com/wp-uploads/2013/HashTool.efi
    
    sudo efibootmgr -c -d /dev/nvme0n1 -p 1 -L Preloader -l /EFI/PreLoader/PreLoader.efi

Now we generate a suitable GRUB image with built-in configuration we generate and a few extras needed modules:

    cat <<EOF > /tmp/grub.cfg
    search --no-floppy --fs-uuid --set=prefix $(blkid -o udev $(df /boot/grub/grub.cfg | sed '1d; s/ .*//') | awk -F= '/ID_FS_UUID=/ { print $2 }')
    configfile (\$prefix)/grub/grub.cfg
    EOF
    
    sudo grub-mkimage -O x86_64-efi -o /boot/efi/EFI/PreLoader/loader.efi -c /tmp/grub.cfg \
        [list of modules from the GRUB `lsmod` run earlier] \
        configfile search_fs_uuid search ls reboot halt \
        password password_pbkdf2 echo linux linuxefi chain fat efifwsetup

Then reboot into the UEFI GUI interface to configure the boot order to be 'debian' *followed* by 'PreLoader', then under Security, set SecureBoot to 'Microsoft & 3rd party CA'.

**N.B.** we make `debian` the first boot option, so that when you run with SecureBoot disabled, it will boot automatically, whilst with SecureBoot enabled `debian` will be silently skipped and `PreLoader` will be automatically run

Now, when you boot for the first time, you will be asked to enroll `loader.efi`, once done, your laptop will now boot with SecureBoot enabled.

### Troubleshooting

If you get the following when running `efibootmgr`:

    efibootmgr: Could not set variable Boot0006: No such file or directory
    efibootmgr: Could not prepare boot variable: No such file or directory

You will find that if you were to run [`strace`](https://en.wikipedia.org/wiki/Strace) you would find out EFI has run out of space and is coming back with `ENOSPC`.

To clear up some space, use:

    mkdir /tmp/efivars
    mount -t efivarfs none /tmp/efivars
    rm /tmp/efivars/dump-type0-*
    umount /tmp/efivars
    
    rm /sys/fs/pstore/dmesg-efi-*

Now reboot so the EFI firmware can garbage collect and free up the space, then you should be able to continue where you left off.


