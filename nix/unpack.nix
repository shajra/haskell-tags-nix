{ gnutar, lib, stdenv }:

rec {

    isTarball = d:
        d ? src
        && lib.isDerivation d.src
        && (lib.hasSuffix ".tar.gz" d.src.name
            || lib.hasSuffix ".tar.bz2" d.src.name
            || lib.hasSuffix ".tar.xz" d.src.name);

    unpackTarball = d: stdenv.mkDerivation {
        name = "${d.src.name}-unpacked";
        phases = [ "installPhase" ];
        nativeBuildInputs = [ gnutar ];
        installPhase = ''
            mkdir "$out"
            tar xf "${d.src}" --strip-components=1 -C "$out"
        '';
    };

    unpackMaybe = d: if isTarball d then unpackTarball d else d.src;

}
