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
      gptfdisk,
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
        gptfdisk
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

        rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
        rootPartStart=16384
        rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))
        imageSize=$((rootPartEnd + 128))
        imageSizeB=$((imageSize * 512))

        truncate -s $imageSizeB $img

        sgdisk -o \
          --set-alignment=2 \
          -n 1:2048:4095 -c 1:uboot-spl \
          -n 2:$rootPartStart:$rootPartEnd -c 2:root -A 2:set:2 \
          $img

        dd conv=notrunc if=${uboot}/spl/sunxi-spl.bin of=$img bs=1024 seek=8
        dd conv=notrunc if=${uboot}/u-boot.itb of=$img bs=1024 seek=40
        dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart

        if [ ${builtins.toString compress} = 1 ]; then
          zstd --rm -T$NIX_BUILD_CORES -19 $img
        fi
      '';
    }
  ) { uboot = sbcPkgs.ubootTanixTx6; };
}
