#!/bin/bash

# This script can be used as a starting point for a deployment script for interactive deployment.

SCRIPT_NAME=$(basename "$0")
set -eET -o pipefail

# Color variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
BUILD_VERSION=""
CONFIRMATION=false
USER_UPPERCASE=${USER^^}
DATE_STR=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
ENVIRONMENT="dev"

usage() {
    echo "Usage: ${SCRIPT_NAME} -b <build_version> [-v] [-h] [-y]" >&2
    echo "  -b <build_version>  Specify the build version to use" >&2
    echo "  -v                  Print verbose output" >&2
    echo "  -h                  Print this help message" >&2
    echo "  -y                  Skip confirmation" >&2
    echo "" >&2
    echo "Example: ${SCRIPT_NAME} -b 1.2.3 -v" >&2
}

# Parse command line arguments
while getopts "b:hvy" opt; do
    case $opt in
    # -b switch for build version
    b)
        BUILD_VERSION=$OPTARG
        ;;
    # -v switch for verbose output
    v) set -x ;;

    # -y to skip confirmation
    y)
        CONFIRMATION=true
        ;;
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

# check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm could not be found. Please install npm before running this script.${NC}" >&2
    exit 1
fi

echo "**************************************************"
echo "Build version: $BUILD_VERSION"
echo "Deploying to environment: $ENVIRONMENT"
echo "BUILD_VERSION: $BUILD_VERSION"
echo "USER: $USER_UPPERCASE"
echo "DATE: $DATE_STR"
echo "**************************************************"

#Prompt for confirmation if -y not specified
if [[ $CONFIRMATION == false ]]; then
    read -p "Are you sure you want to deploy version $BUILD_VERSION? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborting deployment${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}Deploying version ${BUILD_VERSION}${NC}"

# do dangerous stuff
