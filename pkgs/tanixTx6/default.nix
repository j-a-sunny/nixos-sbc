{
  buildSBCUBoot,
  armTrustedFirmwareAllwinnerH6,
  fetchurl,
  lib,
  linuxKernel,
  linux_6_12,
  ...
}:
let
  version = "2025.07";

  # AC200 (internal Ethernet PHY) patches from Armbian's sunxi-6.12 series,
  # pinned to one Armbian commit. Order matches Armbian's series.conf.
  armbianRev = "e0e9184913b73896e757a398b4c82ef190cd7929";
  armbianPatch =
    name: hash:
    {
      inherit name;
      patch = fetchurl {
        url = "https://raw.githubusercontent.com/armbian/build/${armbianRev}/patch/kernel/archive/sunxi-6.12/patches.armbian/${name}.patch";
        inherit hash;
      };
    };
in
rec {
  # Built from U-Boot's own TX6 defconfig (DDR3-1333, 648 MHz DRAM clock).
  # Do not use another H6 board's defconfig: DRAM init differs (e.g. Orange Pi 3 is LPDDR3).
  ubootTanixTx6 = buildSBCUBoot {
    defconfig = "tanix_tx6_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    buildInputs = [ armTrustedFirmwareAllwinnerH6 ];
    BL31 = "${armTrustedFirmwareAllwinnerH6}/bl31.bin";
    SCP = "/dev/null";
    extraConfig = ''
      CONFIG_SYS_BOOTM_LEN=0x6000000
    '';
    inherit version;
    postPatch = ''
      cp ${../pine64rock64/mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
    '';
    filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
  };

  linuxPackages_latest_tanixTx6 = linuxKernel.packagesFor (
    linux_6_12.override {
      ignoreConfigErrors = true;
      kernelPatches = [
        (armbianPatch "drv-net-stmmac-dwmac-sun8i-second-EMAC-clock-register" "sha256-0JdLiVTd9HO7mPwZaK72IgF75InCHanfWJ5csUK21jw=")
        # Provides clk_hw_register_regmap_gate() and the regmap.h include in clk-provider.h,
        # which the AC200 EPHY control driver needs.
        (armbianPatch "clk-gate-add-support-for-regmap-based-gates" "sha256-CcI0LRJq5q1l9F1i7L0how8oP9Tmm3Z75w0pq2TlD3k=")
        (armbianPatch "mfd-Add-support-for-X-Powers-AC200" "sha256-bJRgUSrV24POffKShSIvqzZrx/0Q4YK3JoekHDyQxKo=")
        (armbianPatch "mfd-Add-support-for-X-Powers-AC200-EPHY-syscon" "sha256-fm7EbZ0ChGAyUpSw+hCKnjOU86sbVELioT/2ciHR8Js=")
        (armbianPatch "net-phy-Add-support-for-AC200-EPHY" "sha256-59u+pZoZe1rMwZlO4FJZUdqN/scBsUxdAqHQWzHFkG0=")
        # Armbian's version of this patch needs an Armbian-only `aliases` node as
        # context, so it is rebased onto mainline here.
        {
          name = "arm64-dts-allwinner-h6-add-ac200-ephy-nodes";
          patch = ./0001-arm64-dts-allwinner-h6-add-ac200-ephy-nodes.patch;
        }
        (armbianPatch "arm64-dts-allwinner-h6-tanix-enable-Ethernet" "sha256-Ac319gFUKyaN5Uxt8iEZdZg/proMFoxQhshfG23fxLc=")
      ];
      structuredExtraConfig = with lib.kernel; {
        MFD_AC200 = module;
        AC200_PHY = module;
        AC200_PHY_CTL = module;
        COMMON_CLK_PWM = lib.mkDefault module;
        PWM_SUN4I = lib.mkDefault module;
        DWMAC_SUN8I = lib.mkDefault module;
      };
    }
  );

  linuxPackages_6_12_tanixTx6 = linuxPackages_latest_tanixTx6;
}
