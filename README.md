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

$ release_android.sh --aosp=/home/julien/Documents/ti/android

Options:
  --aosp     Android Root path
  --commit   (OPTIONAL) commit binaries in AOSP
  --config   (OPTIONAL) release ONLY for this board config file
  --help     (OPTIONAL) display usage
  --silent   (OPTIONAL) silent build commands
```
