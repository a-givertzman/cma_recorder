#!/bin/bash
# create a deb package from rust sources
#
############ LIST OF MANAGED VARIABLES REQUIRED FOR DEB PACKAGE ############
name=cma-recorder
# version=x.y.z - reading from first arg $1
descriptionShort="CMA Recorder - the part of the CMA Server"
descriptionExtended="CMA Recorder. The part of the [CMA Server](https://github.com/a-givertzman/fr-service)
- Contains SQL scripts for the fault recorder database for the CMA Server
- Contains deb package for the automated installation required (for CMA Server Recorder service) database configuration"
changeDetails="
- Created scripts for configuring postgres database for CMA Recorder service of the CMA Server
   - create database 'crane_data_server'
   - create user 'crane_data_server' with password
   - create table 'tags' storing id, name, type of all project points (process/logical/diagnosis signals)
   - create tables for the CMA Recorder...
"
copyrightNotice="Copyright 2024 anton lobanov"
maintainer="anton lobanov <lobanov.anton@gmail.com>"
licenseName="GNU GENERAL PUBLIC LICENSE v3.0"
licenseFile="LICENSE"

############ LIST OF MANAGED VARIABLES OPTIONAL FOR DEB PACKAGE ############
#
# preinst, postinst, prerm and postrm scripts:
# preinst="./.github/workflows/packaging/deb/preinst"
postinst="./.github/workflows/packaging/deb/postinst"
prerm="./.github/workflows/packaging/deb/prerm"
postrm="./.github/workflows/packaging/deb/postrm"
#
# list of assets in the format:
# 	<sourcePath> <installPath> <permissions>
assets=(
	"./src/cma-recorder-config.yaml /home/scada/api-server/ 644"
	"./src/cma-server-config.yaml /home/scada/cma-server/ 644"
	"./sql/create_db.sql /etc/cma-recorder/ 644"
	"./sql/create_event_view.sql /etc/cma-recorder/ 644"
	"./sql/create_event.sql /etc/cma-recorder/ 644"
	"./sql/create_grant_user.sql /etc/cma-recorder/ 644"
	"./sql/create_tags.sql /etc/cma-recorder/ 644"
	"./sql/create_user.sql /etc/cma-recorder/ 644"
	"./sql/drop_event_view.sql /etc/cma-recorder/ 644"
	"./sql/drop_event.sql /etc/cma-recorder/ 644"
	"./sql/drop_tags.sql /etc/cma-recorder/ 644"
)
outputDir=target/
# 'any', 'all' or one of the supported architecture (e.g., 'amd64', 'arm64', 'i386', 'armhf')
# you can choose one of the provided by `dpkg-architecture -L` or leave the field blank for automatic detection
arch=
# comma separated list of the package dependecies in the following format:
# "<package_name> [(<<|>>|<=|>=|= <version>)], ..."
# e.g. "foo (>=2.34), bar"
depends="" #"postgres (>=13.14)"
#
############ READING VERSION FROM ARGUMENT ############
RED='\033[0;31m'
BLUE='\033[0;34m'
GRAY='\033[1;30m'
YELLOW='\033[1;93m'
NC='\033[0m' # No Color
version=$1
if [[ "$version" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then 
	echo "Version: $version"
else
	echo -e "${RED}ERROR${NC}: Version not supplied.\nDebian package build script required proper version of your softvare in the format: x.y.z, passed as argument"
fi

# check required variables
echo "Checking reqired variables ..."
missedVarMsg="non-empty value required"
echo "${!name@}=${name:?$missedVarMsg}"
echo "${!version@}=${version:?$missedVarMsg}"
echo "${!descriptionShort@}=${descriptionShort:?$missedVarMsg}"
echo "${!descriptionExtended@}=${descriptionExtended:?$missedVarMsg}"
echo "${!changeDetails@}=${changeDetails:?$missedVarMsg}"
echo "${!copyrightNotice@}=${copyrightNotice:?$missedVarMsg}"
echo "${!maintainer@}=${maintainer:?$missedVarMsg}"
echo "${!licenseName@}=${licenseName:?$missedVarMsg}"
echo "${!licenseFile@}=${licenseFile:?$missedVarMsg}"

echo "Start packaging ..."

############ INITIALIZE THE PACKAGE SOURCE STRUCTURE AND COPY RESOURCES ############

arch=${arch:=$(dpkg --print-architecture)}
debFileName="${name}_${version}_${arch}"
packageRoot=$(readlink -m "/tmp/debian/${debFileName}")

if [[ -d $packageRoot ]]; then
	echo "Freeing the directory for temporary build files ..."
	rm -rf $packageRoot
fi

echo "Creating ${packageRoot} directory for temporary build files ..."
mkdir -p "$packageRoot"
echo "Creating ${packageRoot}/DEBIAN directory ..."
mkdir -p "${packageRoot}/DEBIAN"

copyAsset() {
	sourcePath=$1; targetDir=$2; permissions=$3
	assetPath=$(readlink -m "$sourcePath")
	if [[ ! -d $assetPath && ! -f $assetPath ]]; then
		echo -e "${RED}Asset ${assetPath} not found.${NC}"
		exit 1
	fi
	installPath=$(readlink -m "${packageRoot}/${targetDir}")
	echo "Copying ${assetPath} to ${installPath} ..."
	mkdir -p $installPath && cp -r "$assetPath" "$installPath"
	if [[ -d $assetPath ]]; then
		echo "Applying permissions ${permissions} to dir ${installPath} ..."
		chmod -R "$permissions" "$installPath"
	elif [[ -f $assetPath ]]; then
		echo "Applying permissions ${permissions} to file ${installPath} ..."
		chmod "$permissions" "${installPath}/$(basename ${assetPath})"
	else
		echo -e "${RED}Unknown asset type, can't apply permissions ${permissions} to file${NC} ${installPath} ..."
	fi
}
for asset in "${assets[@]}"; do
	read -ra assetOptions <<< $asset
	copyAsset ${assetOptions[0]} ${assetOptions[1]} ${assetOptions[2]}
done
if [ ! -z "$preinst" ]; then copyAsset "$preinst" "DEBIAN" "755"; fi
if [ ! -z "$postinst" ]; then copyAsset "$postinst" "DEBIAN" "755"; fi
if [ ! -z "$prerm" ]; then copyAsset "$prerm" "DEBIAN" "755"; fi
if [ ! -z "$postrm" ]; then copyAsset "$postrm" "DEBIAN" "755"; fi

############ CREATE A DEB CONTROL FILE ############

echo "Creating ${packageRoot}/DEBIAN/control file ..."
cat > "${packageRoot}/DEBIAN/control" <<- CONTROL
	Section: misc
	Priority: optional
	Version: $version
	Maintainer: $maintainer
	Package: $name
	Architecture: $arch
	Depends: $depends
	Description: $descriptionShort
	$(echo "$descriptionExtended" | sed "s/^/ /")
CONTROL

############ CREATE CHANGELOG AND COPYRIGHT FILES ############

docDir="${packageRoot}/usr/share/doc/${name}"
mkdir -p "$docDir"

echo "Generating changelog file ..."
changelogFile="${docDir}/changelog"
cat > "$changelogFile" <<- CHANGELOG
	$name ($version) unstable; urgency=medium

	$(echo "$changeDetails" | sed "s/^/  * /")

	$(echo " -- $maintainer  $(date -R)")


CHANGELOG
gzip -n --best "$changelogFile"
rm -f "$changelogFile"

echo "Generating copyright file ..."
copyrightFile="${docDir}/copyright"
cat > "$copyrightFile" <<- COPYRIGHT
	Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
	Upstream-Name: $name
	Copyright: $copyrightNotice
	License: $licenseName
	$(cat "$licenseFile" | sed "s/^/ /")
COPYRIGHT

############ CREATE MD5 SUM FILES ############

cd $packageRoot
md5sum $(find . -type f -printf "%P\n" | grep -v "^DEBIAN/") > DEBIAN/md5sums
cd - > /dev/null

############ BUILD A DEB PACKAGE ############
echo "Building deb package ..."
# -Zxz - to to change the compression method from zstd to xz (zstd - supported since debian 12)
mkdir -p "$outputDir"
dpkg-deb -Zxz --build "${packageRoot}" "$outputDir" > /dev/null || exit 1 
echo "Deleting temporary created ${packageRoot} directory"
rm -rf "${packageRoot}"
echo "Debian package created and saved in $(readlink -m "${outputDir}/${debFileName}.deb")"