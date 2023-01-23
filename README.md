# HyperHDR

Installing HyperHDR on LibreElec

Example usage:

- Download and install latest HyperHDR release:		install_hyperhdr_libreelec.sh
- Download and install specific HyperHDR release:	install_hyperhdr_libreelec.sh 18.0.0.0
- Install a specific HyperHDR LOCAL tar.gz file:	install_hyperhdr_libreelec.sh HyperHDR-18.0.0.0-Linux-x86_64.tar.gz

May need to pass video= option to grub as rulz ms2109 grabber sometimes is used for video, resulting on no picture or black screen.
- head /sys/class/drm/*/status
- mount -o remount,rw /flash/
- vi /flash/syslinux.cfg # append video=<outputfrom  head /sys/class/drm/*/status , which is the primary display> e.g.:
- #root=/dev/ram0 rdinit=/init usbcore.autosuspend=-1 BOOT_IMAGE=/KERNEL boot=UUID=CD61-A0A7  video=HDMI-A-1:d video=DP-3:1920x1080@60:D

Grub video options explanation:
- http://distro.ibiblio.org/fatdog/web/faqs/boot-options.html
