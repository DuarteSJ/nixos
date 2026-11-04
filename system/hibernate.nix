# Hibernate (suspend-to-disk): RAM goes to a swapfile on the root ext4 and the
# machine powers off fully; booting the same NixOS entry restores the session.
# Survives booting Windows in between (it can't touch ext4) as long as no NTFS
# partition is mounted here while hibernated.
{config, ...}: {
  # Holds the image (31 GiB RAM, kernel shrinks it to image_size ~2/5 of RAM,
  # this leaves room for a full one).
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 33 * 1024;
    }
  ];

  # Swapfile → resume from the filesystem holding it, at the file's first
  # physical extent (`sudo filefrag -v /var/lib/swapfile`, row 0, physical_offset).
  # Changes if the swapfile is ever recreated.
  boot = {
    resumeDevice = config.fileSystems."/".device;
    kernelParams = ["resume_offset=60772352"];
  };
}
