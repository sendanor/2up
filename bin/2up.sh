#!/bin/bash
# 2up CLI command
# Copyright 2020 Sendanor <info@sendanor.fi>
#           2020 Jaakko-Heikki Heusala <jheusala@iki.fi>
set -e

CAT=cat
SED=sed
SSH=./test/ssh.sh
NOR_2UP_USER=
NOR_2UP_SERVER=2up.fi
MY_NAME="$(basename $0)"
ACTION=
ARGS=
PARSE_ARGS=0
PARSE_ARGS_AS_FREE=0
NOR_2UP_CONFIG="$HOME/.2up.conf"

if test -f "$NOR_2UP_CONFIG"; then
  . "$NOR_2UP_CONFIG"
fi

# Parse arguments
for arg in "$@"; do
  case "$arg" in

    --help|-h|help)
      ACTION=help
    ;;

    --)

      if test x"$PARSE_ARGS_AS_FREE" = x0; then
        PARSE_ARGS_AS_FREE=1
      else
        if test "x$ARGS" = x; then
          ARGS="$arg"
        else
          ARGS="$ARGS $arg"
        fi
      fi

    ;;

    -*)
      if test x"$PARSE_ARGS_AS_FREE" = x0; then
        echo "ERROR: Unknown argument: $arg" >&2
        exit 1
      else
        if test "x$ARGS" = x; then
          ARGS="$arg"
        else
          ARGS="$ARGS $arg"
        fi
      fi
    ;;

    search|save|get|config|debug)

      if test x"$PARSE_ARGS" = x0; then
        ACTION="$arg"
        PARSE_ARGS=1
      else
        
        if test "x$ARGS" = x; then
          ARGS="$arg"
        else
          ARGS="$ARGS $arg"
        fi

      fi
    ;;

    *)
      if test "x$ARGS" = x; then
        ARGS="$arg"
      else
        ARGS="$ARGS $arg"
      fi
    ;;

  esac
done

# Check arguments
if test "x$ACTION" = x || test "x$ACTION" = xhelp; then
      echo >&2
      echo "USAGE: $MY_NAME [OPTS] search|save|get [FILE[@TIME]]" >&2
      echo >&2
      echo "       $MY_NAME [OPTS] config KEY[=VALUE] [KEY[=VALUE]]" >&2
      echo >&2
      exit 1
fi

if test "x$ACTION" = xdebug; then
  echo ACTION $ACTION
  echo ARGS $ARGS
  exit 0
fi

if test "x$ACTION" = xconfig; then
    MODE=auto

    if test "x$ARGS" = x; then
      echo "user   = $NOR_2UP_USER"
      echo "server = $NOR_2UP_SERVER"
      exit 0
    fi

    echo "$ARGS"|tr ' ' '\n'|while read ARG; do
      case "$ARG" in

        user)
          if test "x$MODE" = xwrite; then
            echo "ERROR: Cannot read and write at the same time." >&2
            exit 1
          fi
          MODE=read
        ;;

        server)
          if test "x$MODE" = xwrite; then
            echo "ERROR: Cannot read and write at the same time." >&2
            exit 1
          fi
          MODE=read
        ;;

        user=*)
          if test "x$MODE" = xread; then
            echo "ERROR: Cannot read and write at the same time." >&2
            exit 1
          fi
          MODE=write
          NOR_2UP_USER="$(echo "x$ARG"|"$SED" -e 's/^xuser=//')"
        ;;

        server=*)
          if test "x$MODE" = xread; then
            echo "ERROR: Cannot read and write at the same time." >&2
            exit 1
          fi
          MODE=write
          NOR_2UP_SERVER="$(echo "x$ARG"|"$SED" -e 's/^xserver=//')"
        ;;

      esac
    done

    if test "x$MODE" = xwrite; then
      (
        echo "NOR_2UP_USER='$NOR_2UP_USER'"
        echo "NOR_2UP_SERVER='$NOR_2UP_SERVER'"
      ) > "$NOR_2UP_CONFIG"
    else

      echo "$ARGS"|tr ' ' '\n'|while read ARG; do
        case "$ARG" in

          user)
            echo "$NOR_2UP_USER"
          ;;

          server)
            echo "$NOR_2UP_SERVER"
          ;;

        esac
      done

    fi

  exit 0
fi

if test "x$NOR_2UP_USER" = x; then
  echo "ERROR: No user configured." >&2
  echo "" >&2
  echo "  Use: 2up config user=bob" >&2
  echo "" >&2
  exit 1
fi

# Perform actions
case "$ACTION" in
  
  get)

    echo "$ARGS"|tr ' ' '\n'|while read ARG; do
      if test -e "$ARG"; then
        echo "ERROR: File exists already: $ARG" >&2
        exit 1
      fi
    done

    echo "$ARGS"|tr ' ' '\n'|while read ARG; do
      "$SSH" "$NOR_2UP_USER"@"$NOR_2UP_SERVER" get "$ARG" > "$ARG"
    done

  ;;


  save)

    echo "$ARGS"|tr ' ' '\n'|while read ARG; do
      if test -e "$ARG"; then
        :
      else
        echo "ERROR: File not found: $ARG" >&2
        exit 1
      fi
    done

    echo "$ARGS"|tr ' ' '\n'|while read ARG; do
      "$CAT" "$ARG" | "$SSH" "$NOR_2UP_USER"@"$NOR_2UP_SERVER" save "$(basename "$ARG")"
    done

  ;;

  search)
      "$SSH" "$NOR_2UP_USER"@"$NOR_2UP_SERVER" search $ARGS
  ;;


esac
