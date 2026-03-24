final: prev: let
  version = "0.24.5-slskdn.97";
  src = prev.fetchurl {
    url = "https://github.com/snapetech/slskdn/releases/download/${version}/slskdn-main-linux-x64.zip";
    sha256 = "sha256-raVO12qOMs2/NcvtQipi66B5xHZmd+xj04RVTTbaJB4=";
  };
in {
  slskd = prev.slskd.overrideAttrs (oldAttrs: {
    pname = "slskdn";
    inherit version;
    src = src;
    nativeBuildInputs = [prev.unzip prev.autoPatchelfHook prev.makeWrapper prev.patchelf];
    dontStrip = true;
    buildInputs = [
      prev.curl
      prev.icu
      prev.krb5
      prev.lttng-ust.out
      prev.libunwind
      prev.openssl
      prev.stdenv.cc.cc
      prev.util-linux
      prev.zlib
    ];
    unpackPhase = "unzip $src";
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out/libexec/slskdn $out/bin
      cp -r * $out/libexec/slskdn/
      chmod +x $out/libexec/slskdn/slskd

      patchelf \
        --replace-needed liblttng-ust.so.0 liblttng-ust.so.1 \
        $out/libexec/slskdn/libcoreclrtraceptprovider.so

      makeWrapper $out/libexec/slskdn/slskd $out/bin/slskd \
        --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0 \
        --prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [
        prev.curl
        prev.icu
        prev.krb5
        prev.lttng-ust.out
        prev.libunwind
        prev.openssl
        prev.stdenv.cc.cc
        prev.util-linux
        prev.zlib
      ]}
    '';
  });
}
