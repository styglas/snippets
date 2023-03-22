#!/bin/bash
SCRIPT_NAME=$(basename "$0")
#set -eET -o pipefail 

# Color variables
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
BUILD_VERSION=""

usage() {
    echo "Usage: ${SCRIPT_NAME} -b <build_version> [-v]" >&2
    echo "  -b, --build-version <build_version>  Specify the build version to use" >&2
    echo "  -v, --verbose                        Print verbose output" >&2
    echo "  -h, --help                           Print this help message" >&2
    echo "" >&2    
    echo "Example: ${SCRIPT_NAME} -b 1.2.3 -v" >&2    
}

# Parse command line arguments

while getopts "b:hv" opt; do
    case $opt in
    # -b switch for build version
    b)
        BUILD_VERSION=$OPTARG
        ;;
    # -v switch for verbose output
    v) set -x ;;
    # -h switch for help
    h)
        usage        
        exit 0
        ;;
    \?)
        echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
        usage
        exit 1        
        ;;
    esac
done

# Validate build version input

if ! [[ $BUILD_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Invalid version number. It must be a valid sematic version, ex. 1.2.3${NC}" >&2
    usage
    exit 1    
fi

echo "BUILD_VERSION: $BUILD_VERSION"