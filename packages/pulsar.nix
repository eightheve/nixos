{
  pkgs,
  lib,
  ...
}:
let
  version = "2.4.3";

  runtime = pkgs.dotnetCorePackages.runtime_10_0;

  # Missing libs can be debugged with `LD_DEBUG=libs`.
  runtimeLibs = with pkgs; [
    fontconfig.lib
    freetype
    libGL
    libx11
    libxrandr
    libxi
    libxcursor
    libxext
    libxcb
    libice
    libsm
    libdrm
    libgbm
    vulkan-loader
    dbus
    libpulseaudio
    alsa-lib
    zlib
    icu
    openssl
    stdenv.cc.cc.lib
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "pulsar-se";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/SpaceGT/Pulsar/releases/download/v${version}/pulsar-v${version}-linux-x64.tar.gz";
    hash = "sha256-g8cD1gbzgaKP5tdACIrT42jP9DjbjX5I1WFC/NAsYc8=";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    fontconfig.lib
  ];

  # The release tarball has no top-level directory.
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pulsar
    cp -a . $out/lib/pulsar

    mkdir -p $out/bin
    for flavour in Interim Modern; do
      makeWrapper $out/lib/pulsar/$flavour.bin $out/bin/pulsar-''${flavour,,} \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
        --add-flags "-useHome -noUpdate" \
        --set DOTNET_ROOT "${runtime}/share/dotnet" \
        --suffix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}"
    done

    runHook postInstall
  '';

  meta = {
    description = "Plugin and mod loader for Space Engineers 1 and 2";
    homepage = "https://github.com/SpaceGT/Pulsar";
    # Pulsar is MIT, but the release bundles Valve's libsteam_api.so.
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pulsar-interim";
  };
}
