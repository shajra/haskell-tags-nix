- [About this file](#sec-1)
- [Mac installation](#sec-2)

# About this file<a id="sec-1"></a>

Though `nix.org` is copied across all my Nix projects, not all of the projects support MacOS. So this file has any snippets that reference Macs, which can then be commented out as necessary.

# Mac installation<a id="sec-2"></a>

If you're on a recent release of MacOS, you will need an extra switch:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon \
    --darwin-use-unencrypted-nix-store-volume
```
