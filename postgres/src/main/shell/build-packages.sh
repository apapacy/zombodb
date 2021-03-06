#! /bin/bash

VERSION=$1
BASE=`pwd`
DISTROS="centos6 centos7 ubuntu_trusty ubuntu_precise debian_jessie"
POSTGRES_VERSIONS="9.3 9.4 9.5"

##
# compile ZomboDB for target distros
##
for POSTGRES_VERSION in ${POSTGRES_VERSIONS} ; do
    for distro in ${DISTROS} ; do
        cd $BASE

        mkdir -p $BASE/target/pg${POSTGRES_VERSION}/${distro}

        cd src/main/docker/pg${POSTGRES_VERSION}/zombodb-build-${distro}

        echo "BUILDING: $distro, $POSTGRES_VERSION ****"
        docker build --build-arg user=`whoami` --build-arg uid=`id -u` -t zombodb-build-${POSTGRES_VERSION}-${distro} . > $BASE/target/pg${POSTGRES_VERSION}/${distro}/docker-build.log
        docker run --rm -v $BASE:/mnt -w /mnt -e DESTDIR=target/pg${POSTGRES_VERSION}/${distro} zombodb-build-${POSTGRES_VERSION}-${distro} make clean install &> $BASE/target/pg${POSTGRES_VERSION}/${distro}/compile.log

        # move the zombod.so into the plugins/ directory
        cd $BASE/target/pg${POSTGRES_VERSION}
        cd `dirname $(find ${distro} -name "zombodb.so")`
        mkdir plugins
        cd plugins
        mv ../zombodb.so .

        ##
        # also build a tarball from the Ubuntu_precise version
        ##
        if [ $distro == "ubuntu_precise" ] ; then
            cd $BASE
            cd target/pg${POSTGRES_VERSION}
            rm -rf tarball
            mkdir -p tarball/lib tarball/share
            cp -Rp ubuntu_precise/usr/lib/postgresql/${POSTGRES_VERSION}/lib/* tarball/lib
            cp -Rp ubuntu_precise/usr/share/postgresql/${POSTGRES_VERSION}/* tarball/share
            cd tarball/
            tar czf ../zombodb-precise-pg${POSTGRES_VERSION}-${VERSION}.tgz .
        fi
    done

done