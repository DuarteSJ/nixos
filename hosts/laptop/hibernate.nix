{config, ...}: {
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 33 * 1024;
    }
  ];

  boot = {
    resumeDevice = config.fileSystems."/".device;
    kernelParams = ["resume_offset=60772352"];
  };
}
