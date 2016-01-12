These instructions cover how to install [Debian 'jessie' 8.x](https://www.debian.org/) onto a [Microsoft Surface Pro 4](https://www.microsoft.com/surface/devices/surface-pro-4).

The instructions assume you are not new to Debian, though you may have no experience of UEFI and SecureBoot (I did not until now!).

## What is Working

 * dual booting
 * typing cover keyboard
  * multitouch touchpad (two finger scrolling, etc)
  * special keys
 * 2D and 3D (OpenGL) acceleration
 * hardware video decoding
 * power and volume buttons on the screen
 * audio (including the microphone)
 * wireless (is a 88W8897, a wireless/bluetooth combo module)
     * bluetooth - this only appears once you use the wireless card firmware from [firmware-libertas (20151207-1~bpo8+1) [pcie8897_uapsta.bin version 15.68.4.p112]](https://packages.debian.org/jessie-backports/firmware-libertas)
 * microSD reader - presented as a USB reader appearing when you insert a card
 * suspend, hibernate and resume works

## Outstanding Issues

 * hot plugging the typing cover, or going through a sleep/resume cycle, often results in it no longer responding
 * camera - hides on the PCI bus at [8086:1926](http://pci-ids.ucw.cz/read/PC/8086/1926)
 * touchscreen - hides on the PCI bus at 8086:9d3e
      * pen - though you can pair with it, you only get the eraser switch event
 * sensors
      * although detected, [something in 4.3 breaks](https://lkml.org/lkml/2015/12/17/808) the IIO sensors though from producing any output
      * auto-orientation screen rotation
 * SecureBoot is not enabled
 * need to improve power saving
      * suspend uses lots of power (will not last 24 hours)
      * suspend is only accessible via closing the lid, S3 is not exposed via ACPI (means `echo mem > /sys/power/state` does not work)
      * wireless power saving is disabled
      * `i915.enable_rc6=7` works it seems, need to give it more testing
      * CPU cannot go lower than C2 sleep state otherwise it causes the GPU whilst modeset'ing to black out the screen and crash the system
 * on resume, the reverse scroll is removed (USB reconnect probably)
 * wifi can occasionly still a bit iffy on resume
 * gparted lockup investigation

## Related Links

 * because of the high resolution screen it is worth reading through some [HiDPI related materials](https://wiki.archlinux.org/index.php/HiDPI) otherwise you will very quickly go short sighted
 * wishing for a matte screen, I got the [iLLumiShield](http://www.amazon.co.uk/gp/product/B0169CKLBK) and find it does the job great
 * patches based on
      * [Surface Pro 3](https://github.com/neoreeps/surface-pro-3/blob/master/wily_surface.patch) instructions
      * [[PATCH v3] surface pro 4: Add support for Surface Pro 4 Buttons](https://lkml.org/lkml/2015/12/27/136)
      * [[PATCH v2 14/16] mfd: intel-lpss: Pass SDA hold time to I2C host controller driver](https://lkml.org/lkml/2015/11/30/436)
 * [iio-sensor-proxy](https://github.com/hadess/iio-sensor-proxy) - `systemctl enable iio-sensor-proxy.service`
 * Hibernation
      * [Ubuntu Hibernation](https://help.ubuntu.com/community/PowerManagement/Hibernate)
      * [ArchLinux pm-utils](https://wiki.archlinux.org/index.php/Pm-utils)
 * [reverse scrolling](https://n00bsys0p.wordpress.com/2011/07/26/reverse-xorg-scrolling-in-linux-natural-scrolling/)
 * [reddit - Surface Linux: Penguins like nice things too](https://www.reddit.com/r/surfacelinux)

# Preflight

You will require:

 * an external USB keyboard, as the typing cover is not supported by Debian's kernel
 * a USB hub as there is only one USB port
 * a USB key `dd`'ed with the amd64 live ISO for [gparted](http://gparted.sourceforge.net/); I used `gparted-live-0.24.0-2-amd64.iso`
 * a USB key `dd`'ed with the [non-free amd64 Debian network installer](http://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current/amd64/iso-cd/); I used `firmware-8.2.0-amd64-netinst.iso`
 * an (open, WEP or WPA PSK) wireless network you can connect to (or an USB Ethernet adaptor)

## Prepping Windows 10

The aim here is to shrink down the Windows partition to make room for Debian.

I wanted to keep Windows as Microsoft are constantly releasing updated firmwares which will only apply from under Windows.  Of course if you plan not on dual booting you could skip all this, though I would not recommend to have something to apply those firmware updates with.

Lets start by disabling Bitlocker (you can re-enable it after the resize) so that gparted can resize the partition later.  This is done by clicking on Start, and clicking on 'File Manager'.  From here you will be able to go to where drive `C:` is located, and right-clicking on it will give you an option to 'Manage Bitlocker'.  From there you will be able to click on 'Disable Bitlocker'.

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

**WARNING:** `gparted-live-0.24.0-2-amd64.iso` seems to lock up after a few minutes of running, you do *NOT* want this midway through the resize.  All I can recommend is 'be quick', sorry.

Once shrunk, you should test that you can still boot into Windows, and if you can, we are ready to move on.  If not, you will have to figure out what is wrong.

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

**N.B.** I would recommend keeping the ~2.5GB recovery partition so if you ever need to return the laptop, you will find the process dead easy; though it seems you could move the partition to external media or download it from the Microsoft website

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

**N.B.** until you install a newer (backports) kernel  GRUB will not detect and boot Windows

# Configuring

## Add Additional Repositories

You need to add [Debian backports](http://backports.debian.org/) and stretch, as well as some suitable pinning, this is done with the files:

 * [`/etc/apt/sources.list`](etc/apt/sources.list)
 * [`/etc/apt/sources.list.d/debian-backports.list`](etc/apt/sources.list.d/debian-backports.list)
 * [`/etc/apt/sources.list.d/debian-stretch.list`](etc/apt/sources.list.d/debian-stretch.list)
 * [`/etc/apt/sources.list.d/debian-multimedia.list`](etc/apt/sources.list.d/debian-multimedia.list)
 * [`/etc/apt/preferences.d/pin`](etc/apt/preferences.d/pin)

Now run:

    sudo apt-get update

## Networking

All you need to do is copy the contents of [`interfaces.d`](etc/network/interfaces.d) into `/etc/network/interfaces.d/`; plus create a suitable `/etc/wpa_supplicant/wpa_supplicant.conf` file (if you are not using any network management tool).

**N.B.** to make the wireless networking responsive, you need to disable power saving with `iw dev mlan0 set power_save off`; this has already been slipped into [`/etc/network/interfaces.d/mlan0`](etc/network/interfaces.d/mlan0) for you

## Kernel

First you need to set some kernel boot arguments which are set in [`/etc/default/grub`](etc/default/grub):

    resume=/dev/mapper/lvm--quatermain-swap i915.preliminary_hw_support=1 intel_idle.max_cstate=2

**N.B.** you must adjust the `resume` argument to match where your swap space is, or if you plan not to use hibernation, replace it with `noresume`

Also, so that your keyboard works before the root filesystem is mounted, edit your [`/etc/initramfs-tools/modules`](etc/initramfs-tools/modules) file to include `hid_multitouch`.

Run the following to get your system ready to compile a kernel:

    sudo apt-get install build-essential fakeroot kernel-package
    sudo apt-get install linux-source-4.3 firmware-libertas/jessie-backports firmware-misc-nonfree intel-microcode
    tar -C /usr/src -xf /usr/src/linux-source-4.3.tar.xz
    cd /usr/src/linux-source-4.3
    find /usr/src/debian-mssp4/patches -type f | sort | xargs -t -I{} sh -c "cat {} | patch -p1"
    xzcat ../linux-config-4.3/config.amd64_none_amd64.xz > .config
    
    cat <<'EOF' >> .config
    CONFIG_BLK_DEV_NVME=y
    CONFIG_SURFACE_PRO_BUTTON=m
    CONFIG_MFD_INTEL_LPSS_ACPI=m
    CONFIG_MFD_INTEL_LPSS_PCI=m
    EOF

Now run `make oldconfig` so the button/lpss modules are properly included (we make `nvme` built in so hibernation works).

Time to compile the kernel (this will take about 40 minutes):

    CONCURRENCY_LEVEL=`getconf _NPROCESSORS_ONLN` fakeroot make-kpkg --initrd --append-to-version=-mssp4 kernel_image kernel_headers

Once compiled, you should install your new kernel:

    sudo dpkg -i /usr/src/linux-image-4.3.3-mssp4_4.3.3-mssp4-10.00.Custom_amd64.deb

Now reboot into your new kernel.

## Power

### Resume

When suspended, the laptop can be woken up by installing [`/etc/udev/rules.d/90-mssp4-typing-cover.rules`](etc/udev/rules.d/90-mssp4-typing-cover.rules); to spare a reboot just disconnect and reconnect the typing cover.

You can confirm this is working if you see `enabled` from both the following commands:

    cat /sys/bus/usb/devices/usb1/1-7/power/wakeup
    cat /sys/bus/usb/devices/usb1/power/wakeup

### Hibernation

Install the needed packages:

    sudo apt-get install uswsusp pm-utils

Now copy to [`/etc/pm/sleep.d`](etc/pm/sleep.d) a number of helper files.

You should be able to hiberate (`sudo pm-hibernate`) and resume now.

**N.B.** if it does not work and stalls on boot, there probably is a problem with your `resume` kernel parameter (did you compile the kernel with `nvme` built in?), so to break the stalling add `noresume`

#### Screen Locking

To lock your X11 console, you will need a few packages:

    sudo apt-get install xautolock xss-lock

Then set your [`~/.xsession`](misc/xsession) accordingly to run these.

## Graphics

### Console

All you need to do is so run:

    sudo dpkg-reconfigure console-setup

Then select the 'Terminus' font, and the 16x32 sizing.

**N.B.** you can set the keyboard mapping for the console (and Xorg) with `localectl ...`

Unfortunately there is an outstanding bug ([console-setup w/ systemd forgets font setting](https://bugs.debian.org/759657)) which means you have to slip in [`/etc/udev/rules.d/90-setupcon.rules`](etc/udev/rules.d/90-setupcon.rules) to stop them being shrunk again (and the keyboard mapping being forced back to US)

### Xorg

Start off by installing Xorg (the pinning will bring it in from stretch):

    sudo apt-get install xserver-xorg xserver-xorg-input-multitouch xserver-xorg-video-intel libgl1-mesa-dri libgl1-mesa-glx big-cursor

You should be able to start Xorg (I recommend installing the [lightdm](http://freedesktop.org/wiki/Software/LightDM/) package) and it will have 2D and 3D acceleration enabled.  You can check this by running:

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

If this does not work then you should check that the apt pinning brought in `libdrm-intel1` and`libgl1-mesa-{dri,glx}` from stretch and `xserver-xorg-video-intel` from jessie-backports.

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

#### Hardware Video Decoding

Lets install the drivers and a video player:

    sudo apt-get install mpv/jessie-backports libva1 i965-va-driver vainfo

Test if you have VA-API acceleration available with:

    vainfo

If so, now configure `mpv` to use the API.

    mkdir ~/.config/mpv
    echo hwdec=vaapi > ~/.config/mpv/mpv.conf

When you play videos, you should find the CPU utilisation drops substantially (I saw 35% down to 10%).
