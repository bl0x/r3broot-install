#!/bin/bash

#
# This script will install the R3BROOT package including
# the FAIRROOT dependency in the current directory
# 
# Author: Bastian LÃher <b.loeher@gsi.de>
# Date: Thu Feb 12 11:46:18 CET 2015
#

set -e
set -u

r3broot_version=$1
r3broot_versions=('trunk' 'sep12' 'apr13' 'feb14')
fairsoft_versions=('jul14p3' 'jul14p3' 'jul14p3' 'jul14p3')
fairroot_versions=('v-14.11' 'v-14.11' 'v-14.11' 'v-14.11')

function die { echo -e $1; exit; }
function join { local IFS="$1"; shift; echo "$*"; }

CWD=$(pwd)

# Check arguments
if [ $# -ne 1 ] ; then
	tmp=$(echo ${r3broot_versions[@]})
	die "Usage: $0 [$tmp]"
fi

# Do we have a suitable version?
ok=0
i=0
for v in ${r3broot_versions[@]} ; do
	if [ "$v" == "$r3broot_version" ] ; then
		ok=1
		break
	fi
	((i++))
done
if [ $ok -eq 0 ] ; then
	die "Not a supported version $r3broot_version"
fi
fairsoft_version=${fairsoft_versions[i]}
echo "Selected corresponding fairsoft version $fairsoft_version"
fairroot_version=${fairroot_versions[i]}
echo "Selected corresponding fairroot version $fairroot_version"

# Export SIMPATH
export SIMPATH=/cvmfs/fairroot.gsi.de/fairsoft/$fairsoft_version


# ------------------------------------------------------------------

# Install FAIRROOT
echo "Installing FAIRROOT"

# Make the source directory
ok="y"
srcdir=fairroot
echo "Sources are placed in a directory '$srcdir/$fairroot_version' inside the current dir."
echo -n "OK? [Y/n]"
read ok
if [ "$ok" != "y" ] && [ ! -z $ok ] ; then
	die "Aborting..."
fi

mkdir -p $srcdir

cd $CWD/$srcdir

# Get the source
gitpath=http://github.com/FairRootGroup/FairRoot.git
if [ -d "$fairroot_version" ] ; then
	echo "Source dir $fairroot_version already exists."
else
	echo -n "FAIRROOT This will take a few minutes..."
	git clone -q -b "$fairroot_version" $gitpath $fairroot_version \
		|| die "FAILED\nCould not checkout the sources from github"
	echo "DONE"
fi
cd $CWD/$srcdir/$fairroot_version
git checkout tags/$fairroot_version || die "Could not checkout tag"
cd $CWD/$srcdir

# Build
builddir=$CWD/fairroot_build/$fairroot_version
installdir=$CWD/fairroot_install/$fairroot_version
echo "FAIRROOT Creating build directory $CWD/$builddir"

cd $CWD
mkdir -p $builddir
cd $builddir

echo "FAIRROOT Running cmake..."
cmake -DCMAKE_INSTALL_PREFIX="$installdir" $CWD/$srcdir/$fairroot_version \
	|| die "cmake FAILED"

echo "FAIRROOT Running make"
make -j || die "make FAILED"

# Install
mkdir -p $installdir
echo "FAIRROOT Installing to $installdir"
make install || die "make install FAILED"

cd $CWD
echo "FAIRROOT Finished"

# Export FAIRROOTPATH
export FAIRROOTPATH=$CWD/fairroot_install/$fairroot_version

# ------------------------------------------------------------------

# Install R3BROOT

echo "Installing R3BROOT"

# Make the source directory
ok="y"
srcdir=r3broot
echo "Sources are placed in a directory '$srcdir/$r3broot_version' inside the current dir."
echo -n "OK? [Y/n]"
read ok
if [ "$ok" != "y" ] && [ ! -z $ok ] ; then
	die "Aborting..."
fi

mkdir -p $srcdir

CWD=$(pwd)
cd $srcdir

# Get the source
echo -n "R3BROOT This will take a few minutes..."
svnpath=https://subversion.gsi.de/fairroot/r3broot
if [ "$r3broot_version" != "trunk" ] ; then
	svnpath=$svnpath/release
fi
svn co -q $svnpath/$r3broot_version $r3broot_version \
	|| die "FAILED\nCould not checkout the sources from SVN"
echo "DONE"

# Build
builddir=r3broot_build/$r3broot_version
echo "R3BROOT Creating build directory $CWD/$builddir"

cd $CWD
mkdir -p $builddir
cd $builddir

echo "R3BROOT Running cmake..."
cmake $CWD/$srcdir/$r3broot_version || die "cmake FAILED"

echo "R3BROOT Running make"
make -j || die "make FAILED"

cd $CWD
echo "R3BROOT Finished"

echo -e "\n\n"
echo "###############################################"
echo "#  Building finished successfully"
echo "#  "
echo "#  Add the following lines to your ~/.profile"
echo "\\  -------------------------------------------/"
echo ""
echo "# BEGIN setup R3BROOT"
echo "export FAIRROOTPATH=$CWD/fairroot_install/$fairroot_version"
echo "export SIMPATH=/cvmfs/fairroot.gsi.de/fairsoft/$fairsoft_version"
echo "# END setup R3BROOT"
echo ""
echo "/  -------------------------------------------\\"
echo "###############################################"
echo -e "\n\n"
echo "For testing, you can now run"
echo "cd $builddir/macros/r3b ; ./r3bsim.sh"
echo -e "\n\n"
