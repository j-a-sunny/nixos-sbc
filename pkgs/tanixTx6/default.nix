{
  buildSBCUBoot,
  armTrustedFirmwareAllwinnerH6,
  lib,
  linuxKernel,
  linux_6_16,
  ...
}:
let
  version = "2025.07";
in
rec {
  ubootTanixTx6 = buildSBCUBoot {
    defconfig = "orangepi_3_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    buildInputs = [ armTrustedFirmwareAllwinnerH6 ];
    BL31 = "${armTrustedFirmwareAllwinnerH6}/bl31.bin";
    extraConfig = ''
      CONFIG_DEFAULT_DEVICE_TREE="sun50i-h6-tanix-tx6"
      CONFIG_OF_LIST="sun50i-h6-tanix-tx6"
      CONFIG_ENV_IS_NOWHERE=y
      CONFIG_SYS_BOOTM_LEN=0x6000000
    '';
    inherit version;
    postPatch = ''
      cp ${../pine64rock64/mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
    '';
    filesToInstall = [
      "u-boot.itb"
      "spl/sunxi-spl.bin"
    ];
  };

  linuxPackages_latest_tanixTx6 = linuxKernel.packagesFor (
    linux_6_16.override {
      ignoreConfigErrors = true;
      structuredExtraConfig = with lib.kernel; {
        ARCH_SUNXI = yes;
        SUNXI = yes;
        ALLWINNER_SRAM = yes;
        AC200_PHY = module;
        PHYLIB = yes;
        NET_VENDOR_ALLWINNER = module;
        SUNGEM = yes;
        ETHERNET = yes;
        STMMAC_ETH = yes;
        DWMAC_SUN8I = yes;
        MMC_SUNXI = yes;
        REGULATOR_AXP20X = yes;
        MFD_AC200 = yes;
        I2C_SUNXI = yes;
        PWM_SUN4I = yes;
        OF_OVERLAY = yes;
      };
    }
  );

  linuxPackages_6_16_tanixTx6 = linuxPackages_latest_tanixTx6;
}
