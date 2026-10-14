# GPU, audio, bluetooth, peripherals.
{pkgs, ...}: {
  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      # VA-API for the Intel iGPU that drives the displays (i7-11850H, Tiger
      # Lake / Gen12: iHD; the legacy i965 driver stops at Gen9).  libva picks
      # iHD on its own, so Firefox/mpv decode there and the dGPU stays asleep.
      extraPackages = [pkgs.intel-media-driver];
      extraPackages32 = [pkgs.driversi686Linux.intel-media-driver];
    };
    nvidia = {
      modesetting.enable = true;
      open = true;
      # Installs nvidia-vaapi-driver, but nothing selects it globally (that
      # woke the dGPU for every VA-API client).  An offloaded app that wants
      # NVDEC opts in per launch:
      #   LIBVA_DRIVER_NAME=nvidia NVD_BACKEND=direct nvidia-offload mpv ...
      videoAcceleration = true;
      powerManagement = {
        # s2idle-only laptop: without this the driver does not preserve VRAM
        # across suspend, so GPU clients resume with lost allocations.  Sets
        # NVreg_PreserveVideoMemoryAllocations=1; with driver >= 595 + open
        # modules, kernelSuspendNotifier (default on) replaces the
        # nvidia-suspend/resume systemd units.
        enable = true;
        # RTD3: power the dGPU off whenever nothing is offloaded to it.  Fits
        # PRIME offload (sync would forbid it) on this Ampere GA107; the driver
        # already reports "Runtime D3 status: Enabled (fine-grained)" through
        # its 0x03 auto default, this pins it (0x02) and adds the runtime-PM
        # udev rules rather than relying on that default.
        finegrained = true;
      };
      # mem_sleep is s2idle only, so let the GPU cut video-memory power while
      # suspended too: VRAM under 256 MB is saved and powered off, more stays
      # in self-refresh.  Platform reports S0ix support; driver default is off.
      moduleParams.nvidia.NVreg_EnableS0ixPowerManagement = 1;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  services = {
    xserver.videoDrivers = ["nvidia"];

    # Tray applet + D-Bus mechanism for the blueman package (polkit-gated
    # adapter/rfkill changes need the system helper).
    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Vial keyboard: let the desktop user talk to its raw HID interface
    # (interface 01, usage page 0xFF60).  The serial alone also matches the
    # typing interface, which would let any user process read keystrokes.
    udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="vial:f64c2b3c", ENV{ID_USB_INTERFACE_NUM}=="01", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };

  security.rtkit.enable = true;
}
