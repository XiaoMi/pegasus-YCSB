#!/bin/sh

# get the version of ycsb
version=ycsb-client-`ls pegasus/target/pegasus-binding* | awk -F'binding-' '{print $2}' | awk -F'.jar' '{print $1}'`

# copy files
pkg_dir=pegasus-$version
mkdir $pkg_dir
cp -v pegasus/target/*.jar $pkg_dir
mkdir -p $pkg_dir/dependency
cp -v -R pegasus/target/dependency/* $pkg_dir/dependency
tar cfz $pkg_dir.tar.gz $pkg_dir

# modify the package 
pack_template=""
if [ -n "$MINOS_CONFIG_FILE" ]; then
    pack_template=`dirname $MINOS_CONFIG_FILE`/xiaomi-config/package/pegasus.yaml
fi

ycsb_dir=`pwd`
if [ -f $pack_template ]; then
    echo "Modifying $pack_template ..."
    sed -i "/^artifact:/c artifact: \"pegasus\"" $pack_template
    sed -i "/^version:/c version: \"$version\"" $pack_template
    sed -i "/^build:/c build: \"\.\/pkg_pegasus.sh\"" $pack_template
    sed -i "/^source:/c source: \"$ycsb_dir\"" $pack_template
fi
