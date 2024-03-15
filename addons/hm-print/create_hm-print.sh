#!/bin/bash
#set -vx

pkgNAME="hm-print"
pkgVERSION=2.6
pkgBUILD="1"

dlURL="https://github.com/homematic-community/${pkgNAME}/releases/download/${pkgVERSION}/${pkgNAME}-${pkgVERSION}.tar.gz"

currDIR="$(pwd)"
workDIR="$(mktemp -d)"

cd "${workDIR}"

wget -O ${pkgNAME}.tar.gz ${dlURL}
tar xzf ${pkgNAME}.tar.gz
rm ${pkgNAME}.tar.gz

targetDIR="${workDIR}/${pkgNAME}-${pkgVERSION}-${pkgBUILD}"
addonDIR="${targetDIR}/usr/local/addons/${pkgNAME}"

mkdir -p "${addonDIR}"
cp -a ${workDIR}/addon/* "${addonDIR}"
cp -a ${workDIR}/rc.d/*  "${addonDIR}"
cp -a ${workDIR}/www/*   "${addonDIR}"

# inside ${workDIR}/rc.d there is "programmedrucken"
# we don't need "mount" commands and not RCD_DIR
# so we can use it inside DEBIAN "postinst" and "prerm" scripts
sed -i '/mount/d; /RCD_DIR/d' ${addonDIR}/programmedrucken
chmod 755 ${addonDIR}/programmedrucken

cp -a ${currDIR}/hm-print/* "${targetDIR}"

for sedFILE in ${targetDIR}/DEBIAN/*; do
    sed -i "s/{PKG_VERSION}/${pkgVERSION}-${pkgBUILD}/g" "${sedFILE}"
done

cd "${workDIR}"

dpkg-deb --build ${pkgNAME}-${pkgVERSION}-${pkgBUILD}

cp "${pkgNAME}-${pkgVERSION}-${pkgBUILD}.deb" "${currDIR}"

cd ${currDIR}
rm -R "${workDIR}"

