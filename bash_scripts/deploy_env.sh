#!/bin/bash

# This script can be used as a starting point for a deployment script for interactive deployment.

SCRIPT_NAME=$(basename "$0")
set -eET -o pipefail

# Color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m' 
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
BUILD_VERSION=""
CONFIRMATION=false
DEPLOY=true
USER_UPPERCASE=${USER^^}
DATE_STR=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
EXTRA_ARGS="arg1=foo,arg2=bar"

ALLOWED_REGIONS=("eu" "us")
REGION="eu"

declare -A REGION_ENVS
REGION_ENVS["eu"]="dev-eu"
REGION_ENVS["us"]="dev-us"


usage() {
    echo "Usage: ${SCRIPT_NAME} -b <build_version> [-v] [-h] [-y]" >&2
    echo "  -b <build_version>  Specify the build version to use" >&2
    echo "  -c <extra_args>     Specify extra args to pass to the build script" >&2
    echo "  -v                  Print verbose output" >&2
    echo "  -h                  Print this help message" >&2
    echo "  -y                  Skip confirmation" >&2
    echo "  -n                  Skip deploymeny (build only)" >&2
    echo "  -r                  Deployment region (default: ${REGION})" >&2
    echo "" >&2
    echo "Example: ${SCRIPT_NAME} -b 1.2.3 -v" >&2
}

# Parse command line arguments
while getopts "b:hvynr:c:" opt; do
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
    r)
        REGION=$OPTARG
        ;;
    # -n to skip deployment
    n)
        DEPLOY=false
        ;;
    # -h switch for help
    c) 
        EXTRA_ARGS=$OPTARG 
        ;;
    h)
        usage
        exit 0
        ;;
    # Invalid options
    \?)
        echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
        usage
        exit 1
        ;;
    esac
done

#split extra args
IFS=',' read -ra EXTRA_ARGS_ARRAY <<< "$EXTRA_ARGS"
echo "Extra args array: ${EXTRA_ARGS_ARRAY[*]}"
#append --earg to each arg
for i in "${!EXTRA_ARGS_ARRAY[@]}"; do 
    echo "i: $i"
    EXTRA_ARGS_ARRAY[$i]="--earg ${EXTRA_ARGS_ARRAY[$i]}"
done
#merge array into string
EXTRA_ARGS=$(printf " %s" "${EXTRA_ARGS_ARRAY[@]}") 
echo "Extra args: $EXTRA_ARGS"

# Check for ambiguous options
if [[ $DEPLOY == false && $CONFIRMATION == true ]]; then
    echo -e "${RED}Skiping deployment (-n) and bypassing confirmation (-y) at the same time is not a valid choice${NC}" >&2
    usage
    exit 1
fi

# Validate region input
if [[ ! " ${ALLOWED_REGIONS[@]} " =~ " ${REGION} " ]]; then
    echo -e "${RED}Invalid region. \"${REGION}\". Allowed regions are: ${ALLOWED_REGIONS[*]}${NC}" >&2
    usage
    exit 1
fi

# Lookup environment name from region
ENVIRONMENT=${REGION_ENVS[$REGION]}

# Validate build version input
if ! [[ $BUILD_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || $BUILD_VERSION == "latest" ]]; then
    echo -e "${RED}Invalid version number. It must be a valid sematic version, ex. \"1.2.3\" or \"latest\"${NC}" >&2
    usage
    exit 1
fi

# check if npm is installed
if ! command -v npm &>/dev/null; then
    echo -e "${RED}npm could not be found. Please install npm before running this script.${NC}" >&2
    exit 1
fi

echo "**************************************************"
echo "Build version: $BUILD_VERSION"
echo "Region: $REGION"
echo "Deploying to environment: $ENVIRONMENT"
echo "BUILD_VERSION: $BUILD_VERSION"
echo "USER: $USER_UPPERCASE"
echo "DATE: $DATE_STR"
echo "**************************************************"

# do non-dangerous stuff
echo -e "${GREEN}Building version ${BUILD_VERSION}${NC}"

if [[ $DEPLOY == false ]]; then
    echo -e "${GREEN}Deployment skipped${NC}"
    exit 0
fi

#Prompt for confirmation if -y not specified
if [[ $CONFIRMATION == false ]]; then
    read -p "Are you sure you want to deploy version $BUILD_VERSION? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborting deployment${NC}"
        echo -e "${BLUE}Tip: You can skip deployment by using the -n flag${NC}"
        exit 1
    else
        echo -e "${BLUE}Tip: You can skip confirmation by using the -y flag${NC}"
    fi
fi
echo -e "${GREEN}Deploying version ${BUILD_VERSION}${NC}"
echo "Command: deploy --version $BUILD_VERSION --env $ENVIRONMENT $EXTRA_ARGS"
# do dangerous stuff
