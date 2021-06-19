DOCKER = no

all: debian-build

debian-build:
	@echo "Running Debian autobake-deb"
	apt-get update
	apt-get install --yes --no-install-recommends build-essential dpkg-dev devscripts ccache equivs eatmydata
	# Check if build dependencies are met and if not, attempt to install them
	# NOTE! This must happen as the last step after all debian/control
	# customizations are done.
	if ! dpkg-checkbuilddeps;	then mk-build-deps debian/control -t "apt-get -y -o Debug::pkgProblemResolver=yes --no-install-recommends" -r -i;	fi
	export CCACHE_DIR="$(pwd)/.ccache";	update-ccache-symlinks; ccache -z
	./debian/autobake-deb.sh
	cmake --graphviz dependencies.dot .
	ccache -s

clang-build:
	@echo "Running clang-build"
	apt-get update
	apt-get install --yes --no-install-recommends build-essential dpkg-dev devscripts ccache equivs eatmydata clang
	# Check if build dependencies are met and if not, attempt to install them
	# NOTE! This must happen as the last step after all debian/control
	# customizations are done.
	if ! dpkg-checkbuilddeps;	then mk-build-deps debian/control -t "apt-get -y -o Debug::pkgProblemResolver=yes --no-install-recommends" -r -i;	fi
	mkdir builddir; cd builddir
	export CCACHE_DIR="$(pwd)/.ccache";	update-ccache-symlinks; ccache -z
	export CC=/usr/lib/ccache/cc CXX=/usr/lib/ccache/c++
	export CXX=${CXX:-clang++}
	export CC=${CC:-clang}
	export CXX_FOR_BUILD=${CXX_FOR_BUILD:-clang++}
	export CC_FOR_BUILD=${CC_FOR_BUILD:-clang}
	export CFLAGS='-Wno-unused-command-line-argument'
	export CXXFLAGS='-Wno-unused-command-line-argument'
	eatmydata cmake --parallel -DCMAKE_INSTALL_PREFIX=/tmp/install -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache .
	eatmydata cmake --parallel --build .
	eatmydata cmake --parallel --install .
	eatmydata cmake --graphviz dependencies.dot .
	ccache -s

ninja-build:
	@echo "Running Ninja-build"
	apt-get update
	apt-get install --yes --no-install-recommends build-essential dpkg-dev devscripts ccache equivs eatmydata ninja-build
	# Check if build dependencies are met and if not, attempt to install them
	# NOTE! This must happen as the last step after all debian/control
	# customizations are done.
	if ! dpkg-checkbuilddeps;	then mk-build-deps debian/control -t "apt-get -y -o Debug::pkgProblemResolver=yes --no-install-recommends" -r -i;	fi
	mkdir builddir; cd builddir
	export CCACHE_DIR="$(pwd)/.ccache";	update-ccache-symlinks; ccache -z
	export CC=/usr/lib/ccache/cc CXX=/usr/lib/ccache/c++
	eatmydata cmake --parallel -DCMAKE_INSTALL_PREFIX=/tmp/install -DCOMPILER=/usr/bin/ccache -G Ninja .
	eatmydata ninja -t graph > ../dependencies.dot
	eatmydata ninja
	eatmydata ninja install
	ccache -s
