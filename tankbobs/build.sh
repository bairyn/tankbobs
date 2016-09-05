#!/bin/bash
set -ue -o pipefail

# TODO: build.sh + CMakeLists.txt => Makefile!

typeset SCRIPT_BASE_VERSION="0.1.0"

typeset SCRIPT
typeset SCRIPT_DIR

typeset -i is_bash=0 is_zsh=0
if [[ "${ZSH_VERSION+y}"  == 'y' ]]; then is_zsh=1;  fi
if [[ "${BASH_VERSION+y}" == 'y' ]]; then is_bash=1; fi
if (( $is_bash == $is_zsh )); then {
  echo "${SCRIPT:-0}: Error detecting shell configuration: is_bash: $is_bash; is_zsh: $is_zsh."
  exit 7
} 1>&2; fi

if (( $is_bash )); then
  set -ue -o pipefail

  SCRIPT="${BASH_SOURCE[0]-$0}"
else
  set -ue
  set -o warn_create_global -o ignore_close_braces -o nomatch
  set -o no_global_export   -o short_loops         -o err_exit
  set -o err_return         -o local_options       -o multios
  set -o pipe_fail          -o no_unset            -o no_autopushd
  if [[ "${zsh_eval_context[0]}" != 'toplevel' ]]; then
    {
      echo "${SCRIPT:-0}: Error: not run at toplevel.  Was it sourced?"
      exit 7
    } 1>&2
  fi

  # http://stackoverflow.com/a/23259585
  SCRIPT="${(%):-%N}"
fi

typeset -ir true=1 false=0
typeset -ir success=0 failure=1

id()
{
  local -r cmd="${1-true}"
  if (( $# >= 1 )); then shift; fi

  local -i code="$success"

  if "${cmd}" "$@" || code="$?"; then true; fi
  return $code
}

nop()
{
  true
}

discard-error()
{
  local -r cmd="${1-true}"
  if (( $# >= 1 )); then shift; fi

  if "${cmd}" "$@" &>> /dev/null; then true; fi

  true
}

silence()
{
  local -r cmd="${1-true}"
  if (( $# >= 1 )); then shift; fi

  local -i code="$success"

  if "${cmd}" "$@" &>> /dev/null || code="$?"; then true; fi
  return $code
}

status-code()
{
  local -i code="$success"

  if silence "$@" || code="$?"; then true; fi
  echo "${code}"

  true
}

exists()
{
  local arg

  if (( $# < 1 )); then
    return $failure
  fi

  for arg in "$@"; do
    if ! silence which "$arg"; then
      return $failure
    fi
  done

  return $success
}

is-set()
{
  local arg

  if (( $# < 1 )); then
    return $failure
  fi

  for arg in "$@"; do
    if [[ "$(eval "printf '%s' \"\${${arg}+y}\"")" != 'y' ]]; then
      return $failure
    fi
  done

  return $success
}

fail()
{
  local -ir code="${1:-$failure}"
  if (( $# >= 1 )); then shift; fi

  local arg

  {
    for arg in "$@"; do
      printf '%s: %s\n' "${SCRIPT:-0}" "${arg}"
    done
  } 1>&2

  exit $code
}

require-basic()
{
  local -r cmd="${1-true}"
  if (( $# >= 1 )); then shift; fi

  local suppress
  if exists chronic; then
    suppress='chronic'
  else
    suppress='silence'
  fi

  if ! "${suppress}" "${cmd}" "$@" ; then
    fail 8 "Error: $0: assertion failed: $@"
  fi

  true
}

require()
{
  if ! { eval "$@" ;} &>> /dev/null; then
    fail 8 "Error: $0: assertion failed: $*"
  fi

  true
}

require-tag()
{
  local -r tag="${1-"(empty)"}"
  if (( $# >= 1 )); then shift; fi

  if ! { eval "$@" ;} &>> /dev/null; then
    fail 8 "Error: ${tag}: assertion failed: $*"
  fi

  true
}

if-then-else-with()
{
  require-tag "$0 when_true when_false command [args]" "(( $# >= 3 ))"

  local -r when_true="$1";  shift
  local -r when_false="$1"; shift

  if { eval "$@" ;} &>> /dev/null; then
    local -i code="$success"
    if eval "$when_true" || code="$?"; then true; fi

    return $code
  else
    local -i code="$success"
    if eval "$when_false" || code="$?"; then true; fi

    return $code
  fi
}

if-print-else-with()
{
  require-tag "$0 when_true when_false command [args]" "(( $# >= 3 ))"

  local -r when_true="$1";  shift
  local -r when_false="$1"; shift

  if { eval "$@" ;} &>> /dev/null; then
    echo "${when_true}"
    true
  else
    echo "${when_false}"
    true
  fi
}

pushdir()
{
  if (( $# <= 0 )); then
    pushd 1>> /dev/null
  else
    local arg

    for arg in "$@"; do
      pushd "${arg}" 1>> /dev/null
    done
  fi
}

# popdir [num]
popdir()
{
  local -i i
  local -i num="${1-1}"

  require-tag "$0" "(( $# == 0 || $# == 1 ))"

  for (( i = 0; i < num; ++i )); do
    popd 1>> /dev/null
  done
}

chronic-do()
{
#   if exists chronic; then
#     chronic "$@"
#   else
#     local -i code="$success"
#     local    output
#
#     if output="$("$@" 2>&1)" || code="$?"; then true; fi
#
#     if ((code != success)); then
#       printf '%s\n' "${output}" 1>&2
#     fi
#
#     return $code
#   fi

  local -i code="$success"
  local    output

  if output="$(eval "$@" 2>&1)" || code="$?"; then true; fi

  if ((code != success)); then
    printf '%s\n' "${output}" 1>&2
  fi

  return $code
}

require exists dirname
require 'exists realpath || exists readlink'

eval typeset -a path_command="$(if-print-else-with '(realpath)' '(readlink -f)' exists realpath)"

SCRIPT_DIR="$(dirname "$("${path_command[@]}" "${SCRIPT}")")"
require '[[ -d "${SCRIPT_DIR}" ]]'

BASE_DIR="${SCRIPT_DIR}"

pushdir "${SCRIPT_DIR}"

# ################################################################

directory-require()
{
  local arg

  for arg in "$@"; do
    if [[ ! -d "${arg}" ]]; then
      mkdir "${arg}"
    fi
  done
}

directory()
{
  local arg

  if (( $# <= 0 )); then
    set -- .
  fi

  for arg in "$@"; do
    directory-require "${arg}"
    pushdir "${arg}"
  done
}

base-directory-require()
{
  local arg

  for arg in "$@"; do
    local dir="${BASE_DIR}/${arg}"
    if [[ ! -d "${dir}" ]]; then
      mkdir "${dir}"
    fi
  done
}

base-directory()
{
  local arg

  if (( $# <= 0 )); then
    set -- .
  fi

  for arg in "$@"; do
    local dir="${BASE_DIR}/${arg}"
    directory "${dir}"
  done
}

debug()
{
  {
    local -i code="$success"

    printf '%s: ' "$*"

    if eval"$@" || code="$?"; then true; fi
    return $code
  } 1>&2
}

dir-require()      { directory-require      "$@" 2>> /dev/null ;}
dir()              { directory              "$@" 2>> /dev/null ;}
base-dir-require() { base-directory-require "$@" 2>> /dev/null ;}
base-dir()         { base-directory         "$@" 2>> /dev/null ;}
dir-pop()          { popdir                 "$@" 2>> /dev/null ;}
cmd-exists()       { exists                 "$@" 2>> /dev/null ;}

# ################################################################

BUILD_DIR="${BUILD_DIR-"${BASE_DIR}/build"}"

typeset -a OPT_SRCS
typeset -a COMMON_SRCS_HEAD
typeset -a COMMON_SRCS_TAIL
typeset -a SERVER_SRCS
typeset -a CLIENT_SRCS
typeset -a COPYDATA
OPT_SRCS=(src/lib/LuaJIT/jit/opt.lua src/lib/LuaJIT/jit/opt_inline.lua)
#SERVER_SRCS=(src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_files.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_ai.lua src/common/c_world.lua src/common/c_protocol.lua src/common/lom.lua src/server/init.lua src/server/main.lua src/server/commands.lua src/server/client.lua src/server/st_main.lua)
#CLIENT_SRCS=(src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_files.lua src/common/c_tcm.lua src/client/game.lua src/common/c_weapon.lua src/common/c_ai.lua src/common/c_world.lua src/common/c_protocol.lua src/common/lom.lua src/client/gui.lua src/client/init.lua src/client/main.lua src/client/renderer.lua src/client/st_exit.lua src/client/st_help.lua src/client/st_level.lua src/client/st_background.lua src/client/st_internet.lua src/client/st_online.lua src/client/st_options.lua src/client/st_play.lua src/client/st_selected.lua src/client/st_set.lua src/client/st_title.lua)
COMMON_SRCS_HEAD=(src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_files.lua src/common/c_tcm.lua)
COMMON_SRCS_TAIL=(src/common/c_weapon.lua src/common/c_ai.lua src/common/c_world.lua src/common/c_protocol.lua src/common/lom.lua)
SERVER_SRCS=("${COMMON_SRCS_HEAD[@]}" "${COMMON_SRCS_TAIL[@]}" src/server/init.lua src/server/main.lua src/server/commands.lua src/server/client.lua src/server/st_main.lua)
CLIENT_SRCS=("${COMMON_SRCS_HEAD[@]}" src/client/game.lua "${COMMON_SRCS_TAIL[@]}" src/client/gui.lua src/client/init.lua src/client/main.lua src/client/renderer.lua src/client/st_exit.lua src/client/st_help.lua src/client/st_level.lua src/client/st_background.lua src/client/st_internet.lua src/client/st_online.lua src/client/st_options.lua src/client/st_play.lua src/client/st_selected.lua src/client/st_set.lua src/client/st_title.lua)
COPYDATA=(mod-client mod-server)

VERSION="$(cat VERSION)"
ZIPFLAGS="${ZIPFLAGS-"-9r"}"

# Files to copy to build directory.
typeset -a STATIC_DATA_FILES
STATIC_DATA_FILES=(CHANGELOG COPYING NOTICE mod-client mod-server modules modules64 modules-win modules64-win data)
# Files to archive in optional binary distribution.
typeset -a BDISTFILES
BDISTFILES=(CHANGELOG COPYING NOTICE mod-client mod-server modules modules64 modules-win modules64-win client server libmtankbobs.so libtstr.so jit data-tankbobs-v*-r*.tpk tankbobs* trmc*)

REVISION="$(git rev-list master | wc -l)"
PAKNAME="data-tankbobs-v${VERSION}-r${REVISION}.tpk"
BDISTFILE="tankbobs-build-v${VERSION}-r${REVISION}.tar.gz"
CMAKEFLAGS="-D PEDANTIC=TRUE${OTHER_CMAKE_FLAGS+" ${OTHER_CMAKE_FLAGS}"}"

ZIP="${ZIP:-"zip"}"
if ! is-set LUAC; then
  if cmd-exists "luac-5.1"; then
    LUAC="${LUAC:-"luac-5.1"}"
  elif cmd-exists "luac5.1"; then
    LUAC="${LUAC:-"luac5.1"}"
  else
    LUAC="${LUAC:-"luac5.1"}"
  fi
fi
LUAC="${LUAC:-"luac5.1"}"
CMAKE="${CMAKE:-"cmake"}"

SCRIPT_VERSION="${SCRIPT_BASE_VERSION}-${VERSION}"

# ################################################################

function opts()
{
  local arg

  typeset -gi phelp=0
  typeset -gi version=0
  typeset -gi debug=0
  typeset -gi nojit=1
  typeset -gi bdist=0
  typeset -gi verbose=1
  typeset -g  target=all

  typeset -gi nonoptsc=0
  typeset -ga nonoptsv

  for arg in "$@"; do
    case "${arg}" in
      --help)
        phelp=1
        ;;
      --no-help)
        phelp=0
        ;;
      --help=*)
        phelp="$(( ${arg##--help=} ))"
        ;;

      --version)
        version=1
        ;;
      --no-version)
        version=0
        ;;
      --version=*)
        version="$(( ${arg##--version=} ))"
        ;;

      --debug)
        debug=1
        ;;
      --no-debug)
        debug=0
        ;;
      --debug=*)
        debug="$(( ${arg##--debug=} ))"
        ;;

      --jit)
        nojit=0
        ;;
      --no-jit)
        nojit=1
        ;;
      --jit=*)
        nojit="$(( ! ${arg##--jit=} ))"
        ;;

      --bdist)
        bdist=1
        ;;
      --no-bdist)
        bdist=0
        ;;
      --bdist=*)
        bdist="$(( ${arg##--bdist=} ))"
        ;;

      --phelp)
        phelp=1
        ;;
      --no-phelp)
        phelp=0
        ;;
      --phelp=*)
        phelp="$(( ${arg##--phelp=} ))"
        ;;

      --verbose)
        verbose=1
        ;;
      --no-verbose)
        verbose=0
        ;;
      --verbose=*)
        verbose="$(( ${arg##--verbose=} ))"
        ;;

      --target=*)
        target="${arg##--target=}"
        ;;

      --*)
        fail 9 "$0: Unrecognized option: (long option): ${arg}"
        ;;

      -[a-zA-Z0-9]*)
        local shortopt

        local -i i
        local -a shortopts
        for (( i = 1; i < ${#arg}; ++i )); do
          shortopts+=("${arg:$i:1}")
        done

        for shortopt in "${shortopts[@]}"; do
          case "${shortopt}" in
            h) phelp=1 ;;
            \?) phelp=1 ;;
            H) phelp=1 ;;
            V) version=1 ;;
            d) debug=1 ;;
            D) debug=0 ;;
            j) nojit=0 ;;
            J) nojit=1 ;;
            n) nojit=1 ;;
            N) nojit=0 ;;
            b) bdist=1 ;;
            B) bdist=0 ;;
            v) verbose=1 ;;

            *)
              fail 11 "$0: Unrecognized option: (short option): ${shortopt} in ${arg}"
              ;;
          esac
        done
        ;;

      -*)
        fail 10 "$0: Unrecognized option: ${arg}"
        ;;

      *)
        nonoptsv+=("${arg}")
        ((++nonoptsc))
        ;;
    esac
  done

  if ((phelp)); then
    cat <<EOM
Build Tankbobs:

1) Compiles lua.
2) Compiles third party libraries.
3) Wraps cmake to build Tankbobs.
4) Copies data files to build directory.
5) Compiles maps.
6) Creates data archive containing compiled maps.
7) Optionally creates binary tarball containing the build.

Usage: $0 [-d] [-n] [-t] [MAKE ARGS]

Example: ./build.sh -t VERBOSE=1

-t: Create binary tarball containing the build
-T: Skip binary tarball containing the build (current default)
-d: Enable debugging
-D: Disable debugging
-j: Enable Lua JIT
-J: Disable Lua JIT (current default)
EOM
    exit 1
  fi

  if ((version)); then
    echo "${SCRIPT_VERSION}"
    true
    exit
  fi
}

opts "$@"

require is-set phelp
require is-set version
require is-set debug
require is-set nojit
require is-set bdist
require is-set verbose
require is-set target
require is-set nonoptsc
require 'is-set nonoptsv || (( nonoptsc <= 0 ))'

if (( nonoptsc ))
  then set -- "${nonoptsv[@]}"
  else set --
fi

require "(( $# == nonoptsc ))"

# ################################################################

PHYSFS_CMAKE_FLAGS="-Wno-dev -DPHYSFS_BUILD_WX_TEST=FALSE${PHYSFS_CMAKE_FLAGS+" ${PHYSFS_CMAKE_FLAGS}"}"
if ((!debug)); then
  LUAFLAGS="-s${LUAFLAGS+" ${LUAFLAGS}"}"
  SDLNET_CFLAGS="-fPIC -g -O2${SDLNET_CFLAGS+" ${SDLNET_CFLAGS}"}"
  BOX2D_CXXFLAGS="-O2 -fPIC${BOX2D_CXXFLAGS+" ${BOX2D_CXXFLAGS}"}"
	CMAKEFLAGS="-D CMAKE_BUILD_TYPE=Release${CMAKEFLAGS+" ${CMAKEFLAGS}"}"
else
  LUAFLAGS="${LUAFLAGS+"${LUAFLAGS}"}"
  SDLNET_CFLAGS="-fPIC -g -O2${SDLNET_CFLAGS+" ${SDLNET_CFLAGS}"}"
  BOX2D_CXXFLAGS="-g -fPIC${BOX2D_CXXFLAGS+" ${BOX2D_CXXFLAGS}"}"
	CMAKEFLAGS="-D CMAKE_BUILD_TYPE=Debug${CMAKEFLAGS+" ${CMAKEFLAGS}"}"
fi

if ((nojit)); then
	CMAKEFLAGS="-D NOJIT=True${CMAKEFLAGS+" ${CMAKEFLAGS}"}"
else
	CMAKEFLAGS="-D NOJIT=False${CMAKEFLAGS+" ${CMAKEFLAGS}"}"
fi

if ((verbose)); then
  MAKEFLAGS="VERBOSE=1${MAKEFLAGS+" ${MAKEFLAGS}"}"
else
  MAKEFLAGS="${MAKEFLAGS+"${MAKEFLAGS}"}"
fi

# ################################################################

base-directory-require './build'

# Build all.
function target-all()
{
  : Build all :

  base-dir
  {
    target-build-deps   "$@"
    target-lua          "$@"
    target-dependencies "$@"
    target-tankbobs     "$@"
  }; dir-pop
}

# Ensure dependencies are installed.
function target-build-deps()
{
  : Ensure dependencies are installed :

  if ! cmd-exists "${ZIP}"; then
    fail 16 "$0: Missing zip: '${ZIP}'.  Is '${ZIP}' installed?"
  fi

  if ! cmd-exists "${CMAKE}"; then
    fail 16 "$0: Missing cmake: '${CMAKE}'.  Is '${CMAKE}' installed?"
  fi

  if ! cmd-exists "${LUAC}"; then
    fail 16 "$0: Missing Lua compiler (LUAC): ${LUAC}: Is Lua of the correct version installed?"
  fi

  if cmd-exists egrep && cmd-exists ldconfig; then
    {
      if ! { ldconfig -p | egrep -q -i 'sdl_ttf' ;}; then
        echo "$0: Warning: sdl_ttf not in ldconfig cache.  This project depends on 'sdl_ttf' (for SDL version 1).  Is it installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'sdl_image' ;}; then
        echo "$0: Warning: sdl_image not in ldconfig cache.  This project depends on 'sdl_image' (for SDL version 1).  Is it installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'sdl_mixer' ;}; then
        echo "$0: Warning: sdl_mixer not in ldconfig cache.  This project depends on 'sdl_mixer' (for SDL version 1).  Is it installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'sdl-' ;}; then
        echo "$0: Warning: sdl version 1 not in ldconfig cache.  This project depends on 'sdl' (version 1).  Are the development packages for SDL installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'png' ;}; then
        echo "$0: Warning: png not in ldconfig cache.  This project depends on 'libpng'.  Are the development packages installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'ncurses' ;}; then
        echo "$0: Warning: ncurses not in ldconfig cache.  This project depends on 'ncurses'.  Are the development packages installed?"
      fi

      if ! { ldconfig -p | egrep -q -i 'freetype' ;}; then
        echo "$0: Warning: freetype not in ldconfig cache.  This project depends on 'freetype2'.  Are the development packages installed?"
      fi
    } 1>&2
  fi
}

# Build lua.
function target-lua()
{
  : Build lua modules :

  base-dir
  {
    "${LUAC}" ${LUAFLAGS} -o ./build/server "${SERVER_SRCS[@]}"
    "${LUAC}" ${LUAFLAGS} -o ./build/client "${CLIENT_SRCS[@]}"
  }; dir-pop
}

# Build dependencies.
function target-dependencies()
{
  : Build dependencies :

  base-dir
  {
    target-box2d   "$@"
    target-luajit  "$@"
    target-physfs  "$@"
    target-sdl-net "$@"
  }; dir-pop
}

## Box2D
function target-box2d()
{
  : : Build Box2D : :

  base-dir src/lib/Box2D/Source
  {
    make -C . CXXFLAGS="${BOX2D_CXXFLAGS}"
  }; dir-pop
}

## LuaJIT
function target-luajit()
{
  : : LuaJIT : :
  base-dir src/lib/LuaJIT
  {
    if ((!nojit)); then
      make -C . linux
    fi
  }; dir-pop
}

## PhysFS
function target-physfs()
{
  : : Build PhysFS : :

  base-dir src/lib/physfs-2.0.0
  {
    cmake ${PHYSFS_CMAKE_FLAGS} .
    make -C .
  }; dir-pop
}

## SDL_net
function target-sdl-net()
{
  : : Build SDL_net : :

  base-dir src/lib/SDL_net-1.2.8
  {
    dir-require local
    CFLAGS="${SDLNET_CFLAGS}" ./configure --prefix="$(pwd)/local" --exec-prefix="$(pwd)/local" --disable-sdltest
    make -C .
    make -C . install
  }; dir-pop
}

# Tankbobs
function target-tankbobs()
{
  : Tankbobs :

  dir "${BUILD_DIR}"
  {
    target-tankbobs-bin   "$@"
    target-tankbobs-data  "$@"
    target-tankbobs-bdist "$@"
  }; dir-pop
}

## Binaries.
function target-tankbobs-bin()
{
  : Tankbobs binaries :

  dir "${BUILD_DIR}"
  {
    "${CMAKE}" ${CMAKEFLAGS} "${BASE_DIR}"
    make -C . ${MAKEFLAGS}
  }; dir-pop
}

## Tankbobs data.
function target-tankbobs-data()
{
  : : Tankbobs data : :

  dir "${BUILD_DIR}"
  {
    target-tankbobs-data-static  "$@"
    target-tankbobs-maps         "$@"
    target-tankbobs-data-archive "$@"
  }; dir-pop
}

### Copy static data files to build directory.
function target-tankbobs-data-static()
{
  : : : Copy static data files to build directory : : :

  dir "${BUILD_DIR}"
  {
    # Remove directories from build before coping.
    rm -fr data

    dir "${BASE_DIR}"
    {
      cp -a -t "${BUILD_DIR}" "${STATIC_DATA_FILES[@]}"
    }; dir-pop
  }; dir-pop
}

### Compile maps.
function target-tankbobs-maps()
{
  : : : Compile maps : : :
  dir "${BUILD_DIR}"
  {
    find ./data/tcm/ -name '*.trm' -exec ./trmc -f '{}' '+'
    find ./data/tcm/ -name '*.trm' -exec rm        '{}' '+'
  }; dir-pop
}

### Pack data archive.
function target-tankbobs-data-archive()
{
  : : : Pack data archive : : :
  dir "${BUILD_DIR}/data"
  {
    find .. -maxdepth 1 -name 'data-tankbobs-*.tpk' -exec rm '{}' '+'
    "${ZIP}" ${ZIPFLAGS} "../${PAKNAME}" *
  }; dir-pop
}

## Optionally create binary tarball.
function target-tankbobs-bdist()
{
  : : : Optionally create binary tarball : : :
  dir "${BUILD_DIR}"
  {
    if ((bdist)); then
      find . -maxdepth 1 -name 'tankbobs-build-*.tar.gz' -exec rm {} +
      tar -zc -h -f "${BDISTFILE}" "${BDISTFILES[@]}"
      cd $OLDPWD
    fi
  }; dir-pop
}

set -x

if ((nonoptsc)); then
  target-"${target-all}" "${nonoptsv[@]}"
else
  target-"${target-all}"
fi
