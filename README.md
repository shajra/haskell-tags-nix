- [About this project](#sec-1)
- [Haskell and Nix](#sec-2)
- [Usage](#sec-3)
  - [Installation and setup](#sec-3-1)
  - [Calling `nix-haskell-tags`](#sec-3-2)
  - [The tags generation script](#sec-3-3)
  - [Caveats for Emacs users](#sec-3-4)
  - [Fully static tags files](#sec-3-5)
  - [Using the generated tags file](#sec-3-6)
  - [Integrating with Language Server Protocol (LSP) servers](#sec-3-7)
  - [Using this project as a Nix library](#sec-3-8)
- [Command-line reference](#sec-4)
- [Prior art](#sec-5)
- [Regarding legacy and the future](#sec-6)
- [Release](#sec-7)
- [License](#sec-8)
- [Contribution](#sec-9)

[![img](https://github.com/shajra/nix-haskell-tags/workflows/CI/badge.svg)](https://github.com/shajra/nix-haskell-tags/actions)

# About this project<a id="sec-1"></a>

This project helps generate a [tags file](https://en.wikipedia.org/wiki/Ctags) for [Haskell](https://www.haskell.org) projects that are built with [Nix](https://nixos.org/nix) that can be used to navigate source code within editors like [Vim](https://www.vim.org) or [Emacs](https://www.gnu.org/software/emacs).

The generated tags file will have all the transitive dependencies of the project(s) generated for. This allows us to seamlessly hop from functions and types in our own Haskell projects into declarations in source for third-party dependencies.

There's two problems addressed to build such a tags file:

-   downloading the source code for all transitive dependencies
-   generating accurate references despite Haskell's complex syntax.

This project relies on Nix to solve the first problem of retrieving the right source code. There's a lot of reasons to use Nix to manage a software project, from repeatability to language/platform support. Nix manages dependencies exceptionally well, and also builds everything from source. So if we're already using Nix to manage our Haskell projects, we can just ask Nix what the dependencies are and where Nix has saved the source code to.

Tags file generators like `etags` and `ctags` often use regex-like grammars for loosely parsing source code. This often works surprisingly well enough, but languages like Haskell with non-trivially complex syntax can break these parses. This project uses [fast-tags](https://hackage.haskell.org/package/fast-tags) to generate a tags file using a parser tailored more for the Haskell language.

Ultimately, this project is a bit of scripting glue, delegating heavily to Nix and `fast-tags`.

# Haskell and Nix<a id="sec-2"></a>

There's two main ways to manage Haskell projects with Nix. This project supports both:

-   [Nixpkgs's Haskell Infrastructure](https://nixos.org/manual/nixpkgs/stable/#haskell) build functions
-   [IOHK's Haskell.nix](https://input-output-hk.github.io/haskell.nix/reference/modules/) project.

[Nixpkgs](https://github.com/NixOS/nixpkgs) is the standard library for Nix, and is curated by community volunteers. Dependencies in Nixpkgs are pinned to a curated set. Because Nixpkgs is a Git repository, when you select a commit of Nixpkgs to use, you are also pinning all your dependencies to a snapshot of this curated set.

Haskell.nix takes a different approach. It resolves dependencies by delegating to [Cabal](https://www.haskell.org/cabal/) or [Stack](https://docs.haskellstack.org/en/stable/README/), exactly matching the dependencies one would use if Nix was not used at all. This is a primary difference between Haskell.nix and Nixpkgs, though Haskell.nix has a lot of other differences not covered here.

If you're new to Nix, see [the provided documentation on Nix](doc/nix.md) for more on what Nix is, why we're motivated to use it, and how to get set up with it for this project. For example, it explains the `nix run` commands we'll use in this document.

It's beyond the scope of this project to explain how to set up a Haskell project with Nix. The best resources are the [Nixpkgs](https://nixos.org/nixpkgs/manual) and [Haskell.nix](https://input-output-hk.github.io/haskell.nix/reference/modules/) manuals. However, the [tests of this project](./test) provide an small [example Haskell project](./test/example) and [a Nix expression that builds it](./test/default.nix) both with Nixpkgs as well as with Haskell.nix. This example project has a small dependency on the `void` package.

You can build and run the Nixpkgs-style build of this example project with the following command:

```shell
nix run --file test build.nixpkgs --command nix-haskell-tags-example
```

    Hello! This output proves the example project builds and runs.

And similarly, you can build and run the Haskell.nix build of this project with the following command:

```shell
nix run \
    --file test build.haskell-nix.components.exes \
    --command nix-haskell-tags-example
```

    Hello! This output proves the example project builds and runs.

Note that a Haskell.nix build breaks up a Haskell package into separate components (library, executables, tests, …), each of which is a separate Nix derivation. The Nixpkgs build of a Haskell package generally makes just one Nix derivation.

# Usage<a id="sec-3"></a>

## Installation and setup<a id="sec-3-1"></a>

[The provided documentation on Nix](doc/nix.md) not only explains how to install and configure Nix, but also explains how to run and install the `nix-haskell-tags` executable provided by this project.

Once you have `nix-haskell-tag` available to call, you can use it to generate a tags file for a Nix-based Haskell project.

## Calling `nix-haskell-tags`<a id="sec-3-2"></a>

The main argument `nix-haskell-tags` requires is a Nix path to import that has the Nix expression for your build. This is passed in with the `--file` switch. In our example, that Nix expression can be found at `./test`. Note that the "./" prefix is needed because paths in Nix syntax must contain at least one slash character.

If the Nix expression found at the provided path contains multiple derivations, then by default all these derivations are considered *target packages*. The target package is the root package that we start with to find all dependencies. We can select a target out with the `--attr` switch. You can use the `--attr` switch multiple times to select out multiple targets.

Here we build a tags file for the Nixpkgs build of our example project:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs
```

    LINKING SCRIPT: /nix/store/r015hir2xrr5l2w39zwp1i3xkngj55b7-nix-haskell-tags-generate/bin/nix-haskell-tags-generate ->
        /home/tnks/src/shajra/nix-haskell-tags/run/tags-generate
    
    SOURCES in /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps:
    - /nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps
    
    SOURCES in /nix/store/nms3fscgs70hfsqp4s6nwy0bxjbcqfh4-tags-deps:
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/nms3fscgs70hfsqp4s6nwy0bxjbcqfh4-tags-deps

By default in the current working directory, you'll see two files generated, a `tags` file and a *tags generation* script symlinked at `run/tags-generate`. The script can be run to update or regenerate the tags file.

Tags can come from three types of source code:

-   your target packages (specified by `--file` and `--attr`)
-   dependencies of your target packages
-   libraries provided by GHC.

The tags file by default only has tags for the dependencies. Our example project depends on the `void` package, so all our tags are only for that package:

```shell
cat tags
```

    !_TAG_FILE_SORTED	1	//
    MIN_VERSION_base	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	16;"	D
    MIN_VERSION_semigroups	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	20;"	D
    …
    vacuous	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	98;"	f
    vacuousM	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	103;"	f

If you want to include tags for your target packages, you can call `nix-haskell-tags` with `--include-targets`. In our example, this would include tags for the example project itself:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs --include-targets
```

    LINKING SCRIPT: /nix/store/40i5bsb01bfn044h9xd950dw235qgc0z-nix-haskell-tags-generate/bin/nix-haskell-tags-generate ->
        /home/tnks/src/shajra/nix-haskell-tags/run/tags-generate
    
    SOURCES in /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps:
    - /nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps
    
    SOURCES in /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps:
    - /home/tnks/src/shajra/nix-haskell-tags/test/example
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps

```shell
cat tags
```

    !_TAG_FILE_SORTED	1	//
    Example	/home/tnks/src/shajra/nix-haskell-tags/test/example/src/Example.hs	3;"	m
    Hello	/home/tnks/src/shajra/nix-haskell-tags/test/example/src/Example.hs	6;"	F
    …
    vacuous	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	98;"	f
    vacuousM	/nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/src-old/Data/Void.hs	103;"	f

Additionally, if you want tags for GHC you can call `nix-haskell-tags` with `--include-ghc`.

By default the generated tags file is in the Vi-style "ctags" format. You can use the `--emacs` switch if you want to generate the Emacs-style "etags" format:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs --emacs
```

The default name for the tags file is "tags" for the ctags format and "TAGS" for the etags format. But you can change the name with the `--output` switch.

Lastly, if you have a Haskell.nix build, you need to use the `--haskell-nix` switch. Here's an example of generating tags from the Haskell.nix build of our example project:

```shell
nix-haskell-tags --file ./test --attr build.haskell-nix --haskell-nix
```

## The tags generation script<a id="sec-3-3"></a>

It may seem odd that the `nix-haskell-tags` script creates another *tags generation* script symlinked at `run/tags-generate` that then can be called to generate your tags file.

There's a few of problems that this design solves:

-   evaluating Nix expressions can sometimes take a few seconds

-   source code that our tags file points to is in `/nix/store` and could be deleted by `nix-collect-garbage`

-   we may not want our tags file in `/nix/store` which would make it read-only.

The tags generation script has hard-coded references to the location of source code both inside and outside `/nix/store`. This means that by using this script, we don't need to evaluate a Nix expression again. The generation script directly calls `fast-tags`.

Also, the generation script is located in `/nix/store` and set up as an indirect GC root (under `/nix/var/nix/gcroots/auto`). This prevents any source in `/nix/store` referenced by the generation script from being deleted by `nix-collect-garbage`.

If you'd like to free these sources for collection, you can delete the generation script symlink before calling `nix-collect-garbage`. Alternatively, you can call `nix-haskell-tags` with the `--no-script-link`, which will create and run the script, but not link it as `run/tags-generate` or set it up as a GC root.

If you want a different name or location for the generation script, you can set it explicitly with the `--script-link` switch.

The tags generation script makes makes tags in two steps. The first step populates tags referencing source within `/nix/store`. The second step populates tags referencing source outside `/nix/store`. Source stored within `/nix/store` is typically downloaded source for third-party libraries. The source outside `/nix/store` is typically code you are actively developing.

Calling the tags generation script by default only regenerates tags for source outside `/nix/store`:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs --include-targets
```

```shell
run/tags-generate
```

    
    SOURCES in /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps:
    - /home/tnks/src/shajra/nix-haskell-tags/test/example
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps

But if you use the `--all` switch with the tags generation script, all tags will be updated, which might be useful if you've deleted your tags file:

```shell
run/tags-generate --all
```

    
    SOURCES in /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps:
    - /nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps
    
    SOURCES in /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps:
    - /home/tnks/src/shajra/nix-haskell-tags/test/example
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o tags < /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps

Note that because the tags generation script has explicit references to dependencies, the script can become stale if dependencies change in your Nix expression. When this happens, you can rerun `nix-haskell-tags` to regenerate the script and all tags.

## Caveats for Emacs users<a id="sec-3-4"></a>

`fast-tags`'s implementation of merging tags files is only implemented for the Vi-style ctags format. Subsequent calls of `fast-tags` will overwrite the tags file when using the `--emacs` switch.

To deal with this limitation of `fast-tags` we have the option of generating two separate tags files, one for the tags that reference source within `/nix/store` and another for tags of source outside `/nix/store`. `nix-haskell-tags` does this automatically when you use the `--emacs` switch. We can see this when we use both the `--emacs` and `--include-targets` switches with our example project:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs --emacs --include-targets
```

    LINKING SCRIPT: /nix/store/8sj4d58lp9vq8wmbwkm5hwplca9krm6q-nix-haskell-tags-generate/bin/nix-haskell-tags-generate ->
        /home/tnks/src/shajra/nix-haskell-tags/run/tags-generate
    
    SOURCES in /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps:
    - /nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o TAGS --emacs < /nix/store/jfszvflrcbjalnr736hqxzm417rgw7xd-tags-deps
    
    SOURCES in /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps:
    - /home/tnks/src/shajra/nix-haskell-tags/test/example
    RUNNING: /nix/store/aja0dimyn0sg5b9zf1cav4k43p8h5xqc-findutils-4.7.0/bin/xargs /nix/store/57lgx8wca051p5s8snjrh3wvkhfap2gz-fast-tags-2.0.0/bin/fast-tags -R -o TAGS.local --emacs < /nix/store/ypdr6x5m0vchrdim854z98b1zddzvp8m-tags-deps

For Emacs, by default a tags file named "TAGS" stores tags for source code within `/nix/store`.

```shell
cat TAGS
```

    
    /nix/store/bcafhvfwa2zdalycazj8hqkn807z0jzy-void-0.7.3.tar.gz-unpacked/Setup.lhs,63
    > module Main (main) whereMain2,22
    …
    unsafeVacuous :: Functor f => f Void -> f aunsafeVacuous34,976
    #define UNSAFEUNSAFE3,102

A tags file named "TAGS.local" has references to our example project:

```shell
cat TAGS.local
```

    
    /home/tnks/src/shajra/nix-haskell-tags/test/example/Setup.hs,29
    main = defaultMainmain2,27
    …
    module Main whereMain1,0
    main :: IO ()main7,52

With the separate "TAGS.local" file, you can call the tags generation script and the whole file tags for your local project will be regenerated from scratch, leaving the tags of dependencies in "TAGS" untouched. However, you don't need to bother with this separation if you use the Vi-style ctags format.

If you prefer different names than "TAGS" or "TAGS.local" you can change both with the `--output` and `--output-local` switches respectively.

## Fully static tags files<a id="sec-3-5"></a>

The default behavior of `nix-haskell-tags` generates writable tags files. With the `--static` switch of `nix-haskell-tags` you can generate a single read-only tags file stored in `/nix/store` and guaranteed to only have references to source also in `/nix/store`. Any source originally located outside `/nix/store` will have a snapshot copied into `/nix/store`.

This tags file is then symlinked into the current working directory.

Note there's no tags generation script involved when using `--static` to generate a static tags files so switches like `--output-local` and `--script-link` are ignored.

## Using the generated tags file<a id="sec-3-6"></a>

Both Emacs and Vim come with built-in support for using generated tags files. For these editors, you'll use `nix-haskell-tags` to generate a tags file in a base folder relative to the file you'd like to have tags available for (often a project's root directory). From there, you use various editor-specific key bindings and commands to use the tags file.

For Emacs users, the manual has a [good discussion of its Xref feature](https://www.gnu.org/software/emacs/manual/html_node/emacs/Xref.html#Xref). Just note that you won't be using Emacs' `etags` program to generate tags. You'll be using `nix-haskell-tags` instead. On a default configuration of Emacs, you can use `Meta-x visit-tags-table` to provide the location of a tags file for your project. You can then use `Meta-x xref-find-definitions` (by default bound to `Meta-.`) to hop to a tagged definition. For a project, consider setting `tags-table-list` to use multiple tags simultaneously. Beyond the manual, you may find the [Emacs Tags wiki page](https://www.emacswiki.org/emacs/EmacsTags) useful.

For Vim users, the official documentation [explains how the `tag` and `tags`](https://vim-jp.org/vimdoc-en/options.html#'tags') settings work. Like Emacs, you can use multiple tags simultaneously with Vim. Note you won't be using Exuberant Ctags' `ctags` program to generate tags. You'll be using `nix-haskell-tags` instead. For a default configuration of Vim, you can use `Ctrl-]` to hop to definitions, and you can use the `:tag` Ex command to search for tags by name.

## Integrating with Language Server Protocol (LSP) servers<a id="sec-3-7"></a>

Tools like [Haskell Language Server (HLS)](https://github.com/haskell/haskell-language-server), which implement's [Microsoft's Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/), offer many features expected in advanced programming environments. One of these features is the exact quick navigation across source files that tags files where designed to address.

Tags files are less than ideal, and it would be nice if something like HLS could deprecate tags file usage. Unfortunately, these tools don't yet download the source code of dependencies. They can only navigate within the source code under development.

So for now, it seems that tags files, despite being arcane and inefficient, are still relevant.

To integrate with an LSP server like HLS, Emacs users using `lsp-mode` may be interested in this [compound xref backend](https://gist.github.com/rossabaker/52d60669192b0590c5c1775b1798ffa4) that queries LSP before falling through to a tags file.

Vim users are likely using [Conquer of Completion (CoC)](https://github.com/neoclide/coc.nvim) to integrate with an LSP server. A simple integration would have CoC's `coc-definition` function mapped to a different keybinding (`gd`) than the `Ctrl-]` binding that uses `:tags`. Then you have the option of using either. Additionally, to get completion support for CoC using identifiers from tags files, you may consider using `coc-tag` from the [`coc-sources` project](https://github.com/neoclide/coc-sources).

It's very difficult to cover the myriad of plugins, alternative configurations, or other editors that support tags files. Hopefully you now have enough information to find the rest of what you need online.

## Using this project as a Nix library<a id="sec-3-8"></a>

Rather than use the provided `nix-haskell-tags` command-line tool, you may want to use the Nix expression directly in your build. The top-level Nix expression of this project provides two functions you can use in your own Nix expressions selected with the "nix-haskell-tags-static" and "nix-haskell-tags-dynamic" attributes.

The `nix-haskell-tags-static` function generates a fully static tags file. Here's an illustration of calling `nix-haskell-tags-static` to get a Nix derivation that builds a tags file for our example project.

```shell
nix build '(
    (import ./.).nix-haskell-tags-static {
	nixExprs = [(import ./test {}).build.nixpkgs];
	haskellNix = false;
	emacs = false;
	includeGhc = false;
	includeTargets = true;
	exclude = [];
	followSymlinks = false;
	noModuleTags = false;
	qualified = false;
	fullyQualified = false;
	srcPrefix = "";
    })'
readlink -f result
```

    /nix/store/rfigln9p6x9cdqd08rr9yrvj4jpz05p8-tags

With `nix-haskell-tags-dynamic` we can make a tags generation script:

```shell
nix build '(
    (import ./.).nix-haskell-tags-dynamic {
	nixExprs = [(import ./test {}).build.nixpkgs];
	tagsStaticPath = "tags";
	tagsDynamicPath = "tags";
	haskellNix = false;
	emacs = false;
	includeGhc = false;
	includeTargets = true;
	exclude = [];
	followSymlinks = false;
	noModuleTags = false;
	qualified = false;
	fullyQualified = false;
	srcPrefix = "";
    })'
readlink -f result
```

    /nix/store/40i5bsb01bfn044h9xd950dw235qgc0z-nix-haskell-tags-generate

In both `nix-haskell-tags-static` and `nix-haskell-tags-dynamic` functions, the only required attribute is `nixExprs`.

# Command-line reference<a id="sec-4"></a>

For reference below is the help message for `nix-haskell-tags`. Most of the switches not discussed above are passed directly to `fast-tags`.

```shell
nix-haskell-tags --help
```

    USAGE: nix-haskell-tags [OPTION]...
    
    DESCRIPTION:
    
        Generate ctags/etags file from a Nix expression
    
    OPTIONS:
    
        -h --help               print this help message
    
        -w --work-dir PATH      directory to use as a working directory
        -f --file PATH          Nix expression of filepath to import
        -A --attr PATH          attr path to target derivations, multiple allowed
    
        -o --output PATH        file for tags to source within /nix/store
        -O --output-local PATH  file for tags to source outside /nix/store
        -s --static             all source in /nix/store, no generation script
        -l --script-link PATH   where to link tags generation script (ignored for -s)
        -L --no-script-link     don't make a script link
        -S --skip-rebuild       skip rebuilding script and tags within /nix/store
    			    (unneeded for -s)
    
        -H --haskell-nix        interpret input as Haskell.nix package
        -e --emacs              generate tags in Emacs format (otherwise Vi)
    
        -g --include-ghc        include tag references from GHC source
        -t --include-targets    include targets as well as their dependencies
        -a --all                same as -g -t
    
        -x --exclude PATTERN    filepaths to exclude (multiple allowed)
        -F --folow-symlinks     follow symlinks
        -T --no-module-tags     do not generate tags for modules
        -q --qualified          qualified with one level of module (M.f)
        -Q --fully-qualified    fully qualified (A.B.C.f)
        -p --src-prefix PATH    path to strip from module names
    
        -N --nix PATH           filepath of 'nix' executable to use

Again for reference below is the help message for the tags generation script:

```shell
run/tags-generate --help
```

    USAGE: nix-haskell-tags-generate [OPTION]...
    
    DESCRIPTION:
    
        Generate ctags/etags for a specific project
    
    OPTIONS:
    
        -h --help  print this help message
        -a --all   regenerate all tags, not just local projects

# Prior art<a id="sec-5"></a>

This project is very similar and takes some ideas from [tek/thax](https://github.com/tek/thax). There's a few important differences though.

Thax uses [`hasktags`](https://hackage.haskell.org/package/hasktags) and not `fast-tags`. Both use parsers tailored for Haskell, but `fast-tags`'s is more hand-rolled which makes its parse less strict, but in theory faster. Also, `fast-tag` supports tagging of some more advanced features of Haskell like type families.

Thax only supports Nixpkgs-built Haskell projects, and not projects built with Haskell.nix.

Thax is closer to the "static" usage of `nix-haskell-tags`. Immutable tags are created in full and stored `/nix/store`. However Thax goes through lengths to modify paths in the tags file so that they point outside `/nix/store` when possible. This is different from the `--static` switch of `nix-haskell-tags`.

Lastly, Thax has built-in support for pruning files from tagging. `nix-haskell-tags` delegates filtering to `fast-tags` with the `--exclude` switch. As currently implemented in `fast-tags`, this is an exact-match comparison to either the unqualified module name (for example, "Setup" or "Main") or a fully qualified path. Due to the unwieldiness of names in `/nix/store`, using a fully qualified path with `--exclude` is not that practical. Maybe in the future `fast-tags` could support regular expression or glob matching.

# Regarding legacy and the future<a id="sec-6"></a>

There's a few languages, Haskell included, that have not been historically developed in what are called Integrated Developer Environments (IDEs) like [Eclipse](https://www.eclipse.org) or one of the [Jetbrains products](https://www.jetbrains.com/). Programmers instead use text editors such as Vim and Emacs. They claim that these editors are more light-weight and highly configurable, so more nimble.

There's a couple of problems with this assumption. First, some people configure their text editors with so many plugins and extensions that they are no longer as light-weight as originally claimed.

Secondly, the features these plugins and extensions piece together can still lack features that are absolutely useful, like easily hopping from familiar code to unfamiliar code in third-party libraries.

Lacking such features may not hinder the expert programmer, but it's not a great experience for new programmers, and we don't want to lose people for avoidable reasons.

Fortunately, Haskell has kept some momentum to provide some IDE-like features but still give people freedom to use the editors of their choice. The latest push in this direction is the [Haskell Language Server (HLS)](https://github.com/haskell/haskell-language-server).

HLS however, doesn't yet solve the problem of downloading source code of dependencies and indexing references. This means the tags file is still relevant and useful. But they are a technological relic, and it would be wonderful to have a better technology to replace them.

In the meantime, some tools may accomplish what `nix-haskell-tags` does, but they seem to make assumptions that the Haskell project is building a certain way with either Cabal or Stack. This project implicitly advocates for Haskell projects to use Nix instead. This is because Nix solves problems that Stack and Cabal do not, so we'd like the freedom to use it.

For the sake of beginners we want to remove complexity that is absolutely unnecessary, and provide features that aid discovery and exploration. But we don't want that to come at the expense of features useful for experts. Its takes a bit of work and socializing to reach a balance.

# Release<a id="sec-7"></a>

The "master" branch of the repository on GitHub has the latest released version of this code. There is currently no commitment to either forward or backward compatibility.

"user/shajra" branches are personal branches that may be force-pushed to. The "master" branch should not experience force-pushes and is recommended for general use.

# License<a id="sec-8"></a>

All files in this "nix-haskell-tags" project are licensed under the terms of GPLv3 or (at your option) any later version.

Please see the [./COPYING.md](./COPYING.md) file for more details.

# Contribution<a id="sec-9"></a>

Feel free to file issues and submit pull requests with GitHub.

There is only one author to date, so the following copyright covers all files in this project:

Copyright © 2020 Sukant Hajra
