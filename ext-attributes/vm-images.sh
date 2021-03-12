#!/bin/sh

# Locates VM images on a users machine with the below file extensions and lists them out with thier size.

find /Users/ -type f \(  -name "*.hds" -o -name "*.vmdk" -o -name "*.vdi" -o -name "*.vhd" \) -exec du -sh {} \; > /tmp/vminfo

echo "<result>"
cat /tmp/vminfo
echo "</result>"

exit 0