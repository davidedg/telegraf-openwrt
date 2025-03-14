# telegraf-openwrt
This repo contains a Makefile for building [Telegraf](https://github.com/influxdata/telegraf
) for [OpenWRT](https://openwrt.org/).
\
\
The rationale for this project is the ability to tweak the build to the dependencies we want, using [build-tags](https://github.com/influxdata/telegraf/blob/master/docs/CUSTOMIZATION.md#via-go-build).
\
\
This allows for a huge reduction in the on-disk and ram footprint of the produced binary.
\
The resulting binary is ~3.5MB (as opposed to ~19MB un-compressed or ~48MB for the GL-iNET version and ~250MB for a standard build).

## Building Instructions
Tested instructions for setting up a build environment are provided, based on the [GL-iNET SDK](https://github.com/gl-inet/sdk).
\
I am assuming the building user has sudo privileges, adjust to your environment.

### Install Building OS
Linux Ubuntu amd64 24.04 LTS standard server, fully upgraded to 14.Mar.2025

### Install build dependencies
Install these packages:

| Dependency | Notes |
| ---------- | ----- |
| build-essential | base building deps |
| zlib1g-dev libssl-dev libbz2-dev libsqlite3-dev libreadline-dev | to build python 2 |
| libncurses-dev | to build the SDK |
| upx | to further shrink the binary |

\
All in one go:

	sudo apt -y install build-essential \
		zlib1g-dev libssl-dev libbz2-dev libsqlite3-dev libreadline-dev \
		libncurses-dev \
		upx

### Install GO compiler

I tested with version 1.24.1

	wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
	rm -rf $HOME/golang/go && mkdir $HOME/golang && tar -C $HOME/golang -xzf go1.24.1.linux-amd64.tar.gz
	cat $HOME/.profile | grep -v ^# | grep PATH | grep '$HOME/golang/go/bin' || cat <<EOF >> $HOME/.profile

	# GO
	export PATH=\$HOME/golang/go/bin:\$PATH
	EOF

	. ~/.profile
	go version


### Install PyENV
	curl https://pyenv.run | bash

	cat $HOME/.profile | grep -v ^# | grep PATH | grep 'PYENV_ROOT' || cat <<EOF >> $HOME/.profile

	# PYENV
	export PYENV_ROOT="\$HOME/.pyenv"
	[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
	eval "\$(pyenv init -)"
	EOF

	. ~/.profile

### Install Python 2 via PyENV

	pyenv install 2
	pyenv global 2


### GL-iNET OpenWRT SDK

Install the GL-iNET building SDK and pick your target (set TARGET,VERSION - mine is for an XE300 GL-INET LTE router):
  
    cd
    git clone https://github.com/gl-inet/sdk.git
        
    TARGET=ath79
    VERSION=1907
    
    cd sdk && ./download.sh $TARGET-$VERSION

### Download this repo into the packages directory

    cd ~/sdk/sdk/$VERSION/$TARGET
    git clone https://github.com/davidedg/telegraf-openwrt.git feeds/packages/utils/telegraf

### Tweak the package to your needs

The Makefile supports VARIANTS: you define the list of VARIANT builds to create along with which BUILD TAGS it should be built with.
\
See the provided Makefile for an example (the "fake" variant is there just to show how to create more than 1 variant)
\
\
Refer to the [Telegraf's Custom Builder documentation](https://github.com/influxdata/telegraf/tree/master/tools/custom_builder) for how to get the correct minimum build tags from an existing config file.
\
(You can use the `--dry-run` argument to just create the tags.)

### Update Feeds

    cd ~/sdk/sdk/$VERSION/$TARGET
    ./scripts/feeds update -f

### Build

    cd ~/sdk/ && ./builder.sh -d ~/sdk/sdk/$VERSION/$TARGET/feeds/packages/utils/telegraf -t $TARGET-$VERSION -v

### Install

Transfer the built packages (found under ~/sdk/sdk/$VERSION/$TARGET/bin/packages/) to the target device and install with

    $ opkg install <package_name>.ipk

### Binary Releases

You can check if a binary is already present here https://github.com/davidedg/telegraf-openwrt-builds
\
You can also request a new build there (via Issues request)
