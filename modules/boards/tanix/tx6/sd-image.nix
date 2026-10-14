{
  config,
  pkgs,
  sbcPkgs,
  ...
}:
{
  system.build.sdImage = pkgs.callPackage (
    {
      stdenv,
      e2fsprogs,
      util-linux,
      uboot,
      zstd,
    }:
    let
      name = "nixos-sd-${config.sbc.board.vendor}-${config.sbc.board.model}";
      compress = true;
      imageName = "${name}-v${config.sbc.version}.raw";
    in
    stdenv.mkDerivation {
      inherit name;
      nativeBuildInputs = [
        e2fsprogs
        util-linux
        zstd
      ];
      buildInputs = [ uboot ];

      buildCommand = ''
        root_fs=${config.system.build.rootfsImage}

        mkdir -p $out/nix-support $out/sd-image
        export img=$out/sd-image/${imageName}

        echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
        echo "file sd-image $img${if compress then ".zst" else ""}" >> $out/nix-support/hydra-build-products

        # Allwinner boot ROM reads the SPL from raw 8 KiB (LBA 16). That region
        # overlaps a GPT entry table, so this image uses an MBR (dos) label.
        # The root partition starts at 8 MiB, clear of the bootloader.
        rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
        rootPartStart=16384
        rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))
        imageSize=$((rootPartEnd + 128))
        imageSizeB=$((imageSize * 512))

        truncate -s $imageSizeB $img

        sfdisk --no-reread --no-tell-kernel $img <<EOF
        label: dos
        start=$rootPartStart, size=$rootSizeBlocks, type=83, bootable
        EOF

        dd conv=notrunc if=${uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8
        dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart

        if [ ${builtins.toString compress} = 1 ]; then
          zstd --rm -T$NIX_BUILD_CORES -19 $img
        fi
      '';
    }
  ) { uboot = sbcPkgs.ubootTanixTx6; };
}
