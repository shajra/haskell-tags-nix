{ lib
, writeTextFile
}:

let

    shortName = d: lib.pipe d.src [
        builtins.unsafeDiscardStringContext
        (x: builtins.elemAt (builtins.match "\\.*(.*)" x) 0)
        (builtins.split "[^[:alnum:]+._?=-]+")
        (lib.strings.concatMapStrings (s: if lib.isList s then "-" else s))
        (x: lib.strings.substring (lib.max (lib.strings.stringLength x - 207) 0) (-1) x)
        (x: if lib.strings.stringLength x == 0 then "unknown" else x)
    ];

in rec {

    fromList = ds:
        let toEntry = d: { name = shortName d; value = d; };
        in builtins.listToAttrs (builtins.map toEntry ds);

    has = d: builtins.hasAttr (shortName d);

    insert = d: s: s // { "${shortName d}" = d; };

}
