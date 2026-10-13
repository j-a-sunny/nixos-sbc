{
  buildSBCUBoot,
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
    defconfig = "sun50i_h6_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    extraConfig = ''
      CONFIG_DEFAULT_DEVICE_TREE="allwinner/sun50i-h6-tanix-tx6"
      CONFIG_ENV_IS_NOWHERE=y
      CONFIG_SYS_BOOTM_LEN=0x6000000
    '';
    inherit version;
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
