# Bootloaders build tools

Scripts to build various bootloaders (A-TF, U-Boot, OP-TEE)

Dependencies:
``` {.sh}
$ sudo apt install bc bison build-essential curl flex git libssl-dev python3 python3-pip meson wget -y
$ pip3 install pycryptodome pyelftools shyaml --user
```

## Build bl31
``` {.sh}
usage: build_bl31.sh [options]

$ build_bl31.sh --config=config/boards/am62x.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
```

## Build tiboot3
``` {.sh}
usage: build_tiboot.sh [options]

$ build_tiboot.sh --config=config/boards/am62x.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
```

## Build optee
``` {.sh}
usage: build_optee.sh [options]

$ build_optee.sh --config=config/boards/am62x.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
```

## Build tispl
``` {.sh}
usage: build_tispl.sh [options]

$ build_tispl.sh --config=config/boards/am62x.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
```

## Build ALL
``` {.sh}
usage: build_all.sh [options]

$ build_all.sh --config=config/boards/am62x.yaml

Options:
  --config   board config file
  --clean    (OPTIONAL) clean before build
  --mode     (OPTIONAL) [release|debug] mode (default: release)
  --help     (OPTIONAL) display usage
```

## Release Android
``` {.sh}
usage: release_android.sh [options]

$ release_android.sh --aosp=<path-to-android-root>

Options:
  --aosp     Android Root path
  --commit   (OPTIONAL) commit binaries in AOSP
  --config   (OPTIONAL) release ONLY for this board config file
  --help     (OPTIONAL) display usage
  --no-build (OPTIONAL) don't rebuild the images
  --silent   (OPTIONAL) silent build commands
```

## Setup Android
``` {.sh}
usage: setup_android.sh [options]

$ setup_android.sh --aosp==<path-to-android-root> --branch=<user-name>/update-binaries

Options:
  --aosp     Android Root path
  --branch   Branch name
  --clean    (OPTIONAL) clean up AOSP projects
  --help     (OPTIONAL) display usage
```

## Commit Binaries

``` {.sh}
usage: commit-binaries.sh [options]

$ commit-binaries.sh --from-repo=<repo root directory> --to-repo=<repo root directory> --to-project=<project sub-path>

Options:
  --from-repo     Absolute path to the source repo
  --from-projects (OPTIONAL) space-separated list of relative source projects. Defaults to all
  --to-repo       Absolute path to the destination repo
  --to-project    Relative path in the destination repo where git commit is ran
  --title-prefix  (OPTIONAL) commit message title prefix. Defaults to "generic"
  --dry-run       (OPTIONAL) don't commit, pass --dry-run to git instead
  --help          (OPTIONAL) display usage

Examples:
  $ commit-binaries.sh --from-repo=/home/user/src/android-common-kernel --from-projects='common hikey-modules' \
                       --to-repo=/home/user/src/aosp --to-project=device/amlogic/yukawa-kernel
```
