#!/bin/bash

#echo "DEBUG: $@" >&2

cd "$(dirname "$0")"

TEST_USER_SERVER="$1"
TEST_ACTION="$2"
TEST_FILE="$3"
TEST_DATE="$(date +%Y%m%d-%H%M%S)"

case "$TEST_ACTION" in

  save)

    cat > "file__""$TEST_FILE""@$TEST_DATE.bin"

  ;;

  get)

    cat "file__""$TEST_FILE"".bin"

  ;;

  search)

    (ls ./file__*.bin|sed -e 's@^\./file__@@' -e 's@\.bin$@@') 2> /dev/null

  ;;

esac

