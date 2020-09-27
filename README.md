- [About this project](#sec-1)
- [Haskell and Nix](#sec-2)
- [Usage](#sec-3)
  - [Installation and setup](#sec-3-1)
  - [Calling `nix-haskell-tags`](#sec-3-2)
  - [Using the generated tags file](#sec-3-3)
- [Using this project as a Nix library](#sec-4)
- [Command-line reference](#sec-5)
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

This project relies on Nix to solve the first problem of retrieving the right source code. There's a lot of reasons to use Nix to manage a software project, from repeatability to language/platform support. Nix manages dependencies exceptionally well, and also builds everything from source. So if we're already using Nix to manage our Haskell projects, we can just ask Nix what the dependencies are and where the source code has been saved to.

Tags file generators like `etags` and `ctags` often use regex-like grammars for loosely parsing source code. This often works surprisingly well enough, but languages like Haskell with non-trivially complex syntax can break these parses. This project uses [fast-tags](https://hackage.haskell.org/package/fast-tags) to generate a tags file using a proper Haskell parser (we could have alternatively used the popular [hasktags](https://hackage.haskell.org/package/hasktags), though the difference may not be that appreciable).

Ultimately, this project is a bit of scripting glue, delegating heavily to Nix and `fast-tags`.

# Haskell and Nix<a id="sec-2"></a>

There's two main ways to manage Haskell projects with Nix. This project supports both:

-   [Nixpkgs's Haskell Infrastructure](https://nixos.org/manual/nixpkgs/stable/#haskell) build functions
-   [IOHK's Haskell.nix](https://input-output-hk.github.io/haskell.nix/reference/modules/) project.

[Nixpkgs](https://github.com/NixOS/nixpkgs) is the standard library for Nix, and is curated by community volunteers. Dependencies in Nixpkgs are pinned to a curated set. Because Nixpkgs is a Git repository, when you select a commit of Nixpkgs to use, you are also pinning all your dependencies to a snapshot of this curated set.

Haskell.nix takes a different approach. It resolves dependencies by delegating to [Cabal](https://www.haskell.org/cabal/) or [Stack](https://docs.haskellstack.org/en/stable/README/), exactly matching the dependencies one would use if Nix was not used at all. This is a primary difference between Haskell.nix and Nixpkgs, though Haskell.nix has a lot of other differences not covered here.

If you're new to Nix, see [the provided documentation on Nix](doc/nix.md) for more on what Nix is, why we're motivated to use it, and how to get set up with it for this project. For example, it explains the `nix run` commands we'll use in this document.

It's beyond the scope of this project to explain how to set up a Haskell project with Nix. The best resources are the [Nixpkgs](https://nixos.org/nixpkgs/manual) and [Haskell.nix](https://input-output-hk.github.io/haskell.nix/reference/modules/) manuals. However, the [tests of this project](./test) provide an small [example Haskell project](./test/example) and [a Nix expression that builds it](./test/default.nix) both with Nixpkgs as well as with Haskell.nix.

You can build and run the Nixpkgs-style build of this project with the following command:

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

Note that a Haskell.nix build breaks up a Haskell package into separate components (library, executables, tests, …), each of which is a separate Nix derivation. The Nixpkgs build of a Haskell package makes just one Nix derivation.

# Usage<a id="sec-3"></a>

## Installation and setup<a id="sec-3-1"></a>

[The provided documentation on Nix](doc/nix.md) not only only explains how to install and configure Nix, but also explains how to run and install the `nix-haskell-tags` executable provided by this project.

Once you have `nix-haskell-tag` available to call, you can use it to generate a tags file for a Nix-based Haskell project.

## Calling `nix-haskell-tags`<a id="sec-3-2"></a>

The main argument `nix-haskell-tags` requires is a Nix path to import that has the Nix expression for your build. This is passed in with the `--file` switch. In our example, that Nix expression can be found at `./test`. Note that you need the "./" prefix for Nix to recognize the expression as path.

If the Nix expression found at the provided path contains multiple derivations, we can select one out with the `--attr` switch. If you want to tag multiple projects in the same tags file, you can use the `--attr` switch multiple times.

In the example below, we build a tags file for the Nixpkgs build:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs
```

The tags file is stored in `/nix/store` an symlinked to the current working directory by default:

```shell
readlink --canonicalize tags
```

    /nix/store/fbdbj7qx2g0axhn1z01f8nk2cz5izlc9-tags

The benefit of this approach is that your tags file becomes a Nix garbage collection root. This prevents unpacked source code from being garbage collected by calls to `nix-collect-garbage`.

By default the generated tags file is in the Vi-style "ctags" format. You can use the `--emacs` switch if you want to generate the Emacs-style "etags" format:

```shell
nix-haskell-tags --file ./test --attr build.nixpkgs --emacs
readlink --canonicalize TAGS
```

    /nix/store/v9czqsh7dd5adk6i0h8n2694ipij7gwp-tags

Also by default, the tag file's name is "tags" for the ctags format and "TAGS" for the etags format. But you can change the name with the `--out-link` switch.

If you have a Haskell.nix build, you need to use the `--haskell-nix` switch:

```shell
nix-haskell-tags --file ./test --attr build.haskell-nix --haskell-nix
```

Note that by default, `nix-haskell-nix` only generates tags for dependencies, and not projects referenced directly by a `--attr` switch. This is because dependencies are static by nature. The code you're developing actively will require more frequent indexing.

The expectation is that you will call a tool like `fast-tags` explicitly to make a separate tags file outside of `/nix/store` for code you're editing locally. Also, tools like [Haskell Language Server](https://github.com/haskell/haskell-language-server) have gotten better support for jumping to declarations and references within a project locally. So you have the option of using these tools to jump within a project, and the tags file generated by `nix-haskell-tags` to jump outside the project.

If for some reason you want everything tagged, you can use the `--all` switch.

## Using the generated tags file<a id="sec-3-3"></a>

Both Emacs and Vim come with built-in support for using generated tags files. For these editors, you'll use `nix-haskell-tags` to generate a tags file in a base folder relative to the file you'd like to have tags available for (often a project's root directory). From there, you use various editor-specific key bindings and commands to use the tags file.

For Emacs users, the manual has a [good discussion of its Xref feature](https://www.gnu.org/software/emacs/manual/html_node/emacs/Xref.html#Xref). Just note that you won't be using Emacs' `etags` program to generate tags. You'll be using `nix-haskell-tags` instead. On a default configuration of Emacs, you can use `Meta-x visit-tags-table` to provide the location of a tags file for your project. You can then use `Meta-x xref-find-definitions` (by default bound to `Meta-.`) to hop to a tagged definition. Beyond the manual, you may find the [Emacs Tags wiki page](https://www.emacswiki.org/emacs/EmacsTags) useful.

For Vim users, official documentation is not as centralized as Emacs. The best documentation for using tags with Vim may be [various blog posts](https://www.google.com?q=vim+tags). Note you won't be using Exuberant Ctags' `ctags` program to generate tags. You'll be using `nix-haskell-tags` instead. For a default configuration of Vim, you can use `Ctrl-]` to hop to definitions, and you can use the `:tag` Ex command to search for tags by name.

This briefly covers basic usage of tags in just plain installations of Emacs and Vim. Not covered are the myriad of plugins, alternative configurations, or other editors that support tags files. Hopefully you now have enough information to find the rest of what you need online.

# Using this project as a Nix library<a id="sec-4"></a>

Rather than use the provided `nix-haskell-tags` command-line tool, you may want to use the Nix expression directly in your build. There's a "nix-haskell-tags-eval" attribute that provides a function you can use.

Here's an illustration of calling the `nix-haskell-tags-eval` function to get a Nix derivation that builds a tags file for our example project.

```shell
nix build '(
    (import ./.).nix-haskell-tags-eval {
	nixExprs = [(import ./test {}).build.nixpkgs];
	haskellNix = false;
	emacs = false;
	includeAll = false;
	exclude = "";
	followSymlinks = false;
	noModuleTags = false;
	qualified = false;
	fullyQualified = false;
	srcPrefix = "";
    })'
readlink -f result
```

    /nix/store/fbdbj7qx2g0axhn1z01f8nk2cz5izlc9-tags

# Command-line reference<a id="sec-5"></a>

For reference below is the help message for `nix-haskell-tags`. Most of the switches not discussed are passed directly to `fast-tags`.

```shell
nix-haskell-tags --help
```

    USAGE: nix-haskell-tags [OPTION] COMMAND
    
    DESCRIPTION:
    
        Generate ctags/etags file from a Nix expression
    
    OPTIONS:
    
        -h --help             print this help messagee
        -H --haskell-nix      interpret as Haskell.nix package
        -a --all              don't exclude input derivations
        -o --out-link PATH    where to output tags file
        -f --file PATH        Nix expression of filepath to import
        -A --attr PATH        attr path to input derivations, multiple allowed
        -e --emacs            generate tags in Emacs format (otherwise Vi)
        -x --exclude PATTERN  filepaths to exclude
        -L --folow-symlinks   follow symlinks
        -T --no-module-tags   do not generate tags for modules
        -q --qualified        qualified with one level of module (M.f)
        -Q --fully-qualified  fully qualified (A.B.C.f)
        -p --src-prefix PATH  path to strip from module names
        -N --nix PATH         filepath of 'nix' executable to use

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
