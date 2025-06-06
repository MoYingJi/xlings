#!/bin/bash

RUN_DIR=`pwd`

# ANSI color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${PURPLE}[xlings]: start detect environment and try to auto config...${RESET}"

# 1. check xmake status
if ! command -v xmake &> /dev/null
then
    echo -e "${PURPLE}[xlings]: start install xmake...${RESET}"
    curl -fsSL https://xmake.io/shget.text | bash
    source ~/.xmake/profile
else
    echo -e "${GREEN}[xlings]: xmake installed${RESET}"
fi

if [ -f $RUN_DIR/install.unix.sh ]; then
    cd ..
    RUN_DIR=`pwd`
fi

if [ "$UID" -eq 0 ];
then
    export XMAKE_ROOT=y
fi

# 2. install xlings
cd $RUN_DIR/core
xmake xlings unused self enforce-install
sudo ln -sf /home/xlings/.xlings_data/bin/xlings /usr/bin/xlings

export PATH="/home/xlings/.xlings_data/bin:$PATH"

# 3. init: install xvm and create xim, xinstall...
xlings self init

# 5. install info
echo -e "${GREEN}[xlings]: xlings installed${RESET}"

echo -e ""
echo -e "\t    run [$YELLOW xlings help $RESET] get more information"
echo -e "\t after restart $YELLOW cmd/shell $RESET to refresh environment"
echo -e ""

cd $RUN_DIR