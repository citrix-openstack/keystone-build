#!/bin/sh

set -ex

dest_rpm="$1"
spec="$2"
sources="$3"

arch=$(basename "$dest_rpm" .rpm)
arch=$(echo "$arch" | sed -e 's/^.*\.//')

dest_rpm_dir=$(dirname "$dest_rpm")
dest_srpm_dir="${dest_rpm_dir/RPMS\/$arch/SRPMS}"

dest_srpm_file=$(basename "$dest_rpm")
dest_srpm_file="${dest_srpm_file/$arch/src}"

thisdir=$(dirname "$0")

if [ "${QUICK-no}" = "yes" ]
then
  tempdir=/tmp/quick-keystone-build
  mkdir -p "$tempdir"
else
  tempdir=$(mktemp -d)
fi
chmod a=rwx "$tempdir"

cleanup()
{
  rm -rf /obj/build-keystone
  rm -rf "$tempdir"
  rm -f /etc/mock/build-keystone.cfg
}

if [ "${QUICK-no}" != "yes" ]
then
  # To prevent cleanup, comment out the next line.
  trap cleanup EXIT
fi

MOCK="mock -vvv -r build-keystone --resultdir=$tempdir"

mkdir -p "$dest_rpm_dir"
mkdir -p "$dest_srpm_dir"
cp -f "$thisdir/build-keystone.cfg" /etc/mock

if [ "${QUICK-no}" != "yes" ] || [ ! -d /obj/build-keystone ]
then
  rm -rf /obj/build-keystone
  $MOCK --init
fi

$MOCK --no-clean --no-cleanup-after --buildsrpm --spec "$spec" --sources "$sources"
$MOCK --no-clean --no-cleanup-after --rebuild "$tempdir/$dest_srpm_file"

mv "$tempdir/"*.src.rpm "$dest_srpm_dir"
mv "$tempdir/"*.rpm "$dest_rpm_dir"

createrepo $(dirname "$dest_srpm_dir")
