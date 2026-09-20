{...}: {
  services.xserver.xkb.extraLayouts.uspt = {
    description = "US with Portuguese dead keys";
    languages = ["eng" "por"];
    symbolsFile = ./xkb/uspt;
  };
}
