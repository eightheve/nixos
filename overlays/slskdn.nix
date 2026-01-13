final: prev:
let
  version = "0.24.1-slskdn.34";
  src = prev.fetchurl {
    url = "https://github.com/snapetech/slskdn/releases/download/${version}/slskdn-${version}-linux-x64.zip";
    sha256 = "sha256-n3iAW8Bvn2J/0gw5F79Te3EFvw45g5qGn+5UskibWkk=";
  };
in
{
  slskd = prev.slskd.overrideAttrs (oldAttrs: {
    pname = "slskdn";
    inherit version;
    src = src;
    nativeBuildInputs = [ prev.unzip prev.autoPatchelfHook prev.makeWrapper ];
    buildInputs = [ prev.icu prev.openssl prev.zlib prev.stdenv.cc.cc.lib ];
    unpackPhase = "unzip $src";
    configurePhase = "true";
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out/libexec/slskdn $out/bin
      cp -r * $out/libexec/slskdn/
      chmod +x $out/libexec/slskdn/slskd
      makeWrapper $out/libexec/slskdn/slskd $out/bin/slskd \
        --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0 \
        --prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath [ prev.icu prev.openssl prev.zlib ]}
    '';
  });
}
