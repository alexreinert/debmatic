#!/bin/bash

set -e

XML_API_VERSION=2.3

ARCHIVE_TAG="$XML_API_VERSION"

XML_API_DOWNLOAD_URL="https://github.com/homematic-community/XML-API/archive/$ARCHIVE_TAG.tar.gz"

PKG_BUILD=1

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$XML_API_VERSION-$PKG_BUILD

cd "$WORK_DIR"

wget -O xml-api.tar.gz "$XML_API_DOWNLOAD_URL"
tar xzf xml-api.tar.gz
mv "XML-API-$ARCHIVE_TAG" repo

patch -d "$WORK_DIR/repo" -p1 < "$CURRENT_DIR/session.patch"

TARGET_DIR=$WORK_DIR/xml-api-$PKG_VERSION

mkdir -p "$TARGET_DIR/usr/local/addons/xmlapi"
cp -a "$WORK_DIR/repo/xmlapi/." "$TARGET_DIR/usr/local/addons/xmlapi/"
cp -a "$WORK_DIR/repo/VERSION" "$TARGET_DIR/usr/local/addons/xmlapi/"

cp -a "$CURRENT_DIR/xml-api/." "$TARGET_DIR/"

for file in "$TARGET_DIR"/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" "$file"
done

cd "$WORK_DIR"

dpkg-deb --root-owner-group --build "xml-api-$PKG_VERSION"

cp "xml-api-$PKG_VERSION.deb" "$CURRENT_DIR/"

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

