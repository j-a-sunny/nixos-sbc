{
  config,
  lib,
  sbcPkgs,
  ...
}:
{
  imports = [
    ./sd-image.nix
  ];

  config = {
    sbc.enable = true;

    boot.kernelPackages = lib.mkDefault sbcPkgs.linuxPackages_latest_tanixTx6;

    # Ethernet goes through the AC200 co-packaged PHY (built as modules).
    boot.kernelModules = [
      "ac200"
      "ac200_phy"
      "ac200_ephy_ctl"
    ];

    hardware.deviceTree.filter = "sun50i-h6-tanix-tx6.dtb";
    hardware.enableRedistributableFirmware = true;

    sbc.board = {
      vendor = "Tanix";
      model = "TX6";
      dtRoot = "oranth,tanix-tx6";

      i2c.devices.i2c3 = {
        status = "okay";
      };

      uart.devices.uart0 = {
        status = "okay";
        baud = 115200;
        deviceName = "ttyS0";
        console = true;
      };
    };
  };
}
