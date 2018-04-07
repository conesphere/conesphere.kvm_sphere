#!/bin/bash
read -r CMD FS SNAP FOO <<< "${SSH_ORIGINAL_COMMAND}"
zfs-pull-server.sh "${FS}" "${SNAP}"

