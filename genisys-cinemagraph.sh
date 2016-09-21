#!/bin/bash

DEFAULT_BASE_URL="https://cdn.octoblu.com/cinemagraphs/"
DEFAULT_MESHBLU_JSON="./meshblu.json"
MIN_MESHBLU_UTIL_VERSION="5.1.0"

assert_meshblu_util(){
  local bin_version="$(meshblu-util --version 2>&1)"

  if [ "$?" != "0" ]; then
    panic "Required dependency meshblu-util >= $MIN_MESHBLU_UTIL_VERSION not installed"
  fi

  local versions="$(printf "$MIN_MESHBLU_UTIL_VERSION\n$bin_version" | gsort --version-sort)"
  local least_version="$(echo "$versions" | head -n 1)"
  if [ "$least_version" != "$MIN_MESHBLU_UTIL_VERSION" ]; then
    panic "meshblu-util is too old ($least_version). Requires >= $MIN_MESHBLU_UTIL_VERSION"
  fi
}

panic(){
  local message="$1"
  echo "$message" 1>&2
  exit 1
}

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

update_cinemagraph(){
  local meshblu_json="$1"
  local base_url="$2"
  local cinemagraph_name="$3"

  local image_url="${base_url}${cinemagraph_name}.png"
  local video_url="${base_url}${cinemagraph_name}.mp4"

  meshblu-util update \
    --data "{\"genisys.options.backgroundImageUrl\": \"$image_url\", \"genisys.options.backgroundVideoUrl\": \"$video_url\"}" \
    "$meshblu_json"
}

usage(){
  echo 'USAGE: gc [options] <cinemagraph-name>'
  echo ''
  echo 'example: gc jade-is-working3'
  echo ''
  echo '  -b, --base-url <url>       base url for images'
  echo '                               env: GENISYS_CINEMAGRAPH_BASE_URL'
  echo "                               default: '$DEFAULT_BASE_URL'"
  echo '  -h, --help                 print this help text'
  echo '  -m, --meshblu-json <path>  path to a meshblu.json file'
  echo '                               env: GENISYS_CINEMAGRAPH_MESHBLU_JSON'
  echo "                               default: '$DEFAULT_MESHBLU_JSON'"
  echo '  -v, --version              print the version'
  echo ''
  echo ''
  echo 'It will use meshblu-util to update the following properties on genisys.options:'
  echo ''
  echo '  - backgroundImageUrl: <base-url>/<cinemagraph-name>.mp4'
  echo '  - backgroundVideoUrl: <base-url>/<cinemagraph-name>.png'
  echo ''
}

version(){
  local directory="$(script_directory)"
  local version=$(cat "$directory/VERSION")

  echo "$version"
  exit 0
}

main() {
  assert_meshblu_util

  local base_url="${GENISYS_CINEMAGRAPH_BASE_URL:-$DEFAULT_BASE_URL}"
  local meshblu_json="${GENISYS_CINEMAGRAPH_MESHBLU_JSON:-$DEFAULT_MESHBLU_JSON}"
  local cinemagraph_name="$1";

  while [ "$1" != "" ]; do
    local param="$1"
    local value="$2"
    case "$param" in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      -b | --base-url)
        base_url="$value"
        ;;
      -m | --meshblu-json)
        meshblu_json="$value"
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        if [ -n "$param" ]; then
          cinemagraph_name="$param"
        fi
        ;;
    esac
    shift
  done

  update_cinemagraph "$meshblu_json" "$base_url" "$cinemagraph_name"
}
main "$@"
