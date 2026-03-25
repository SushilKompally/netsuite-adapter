#!/bin/bash
set -e
# Script is ran at the root of the project.

# ----------------------
# SCRIPT ENTRY LOGGING
# ---------------------
echo "----SCRIPT START-----"
echo "Working Dir: $(pwd)"
echo "Script Name: $0"
echo "Target Module Dir: $1"

processing_dir=$(pwd)

echo "Processing modules in current directory:"
echo "${processing_dir}"


echo "----SCRIPT COMPLETE-----"
