#!/bin/bash

# Script to test Hugo build with minimal configuration

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Hugo build with minimal configuration...${NC}"

# Clean any previous build
rm -rf public

# Create basic config file
cat > config.yaml << EOL
baseURL: "/"
languageCode: "en-us"
title: "MCP Documentation"
theme: "mcp-theme"
EOL

echo -e "${BLUE}Building site with simplified configuration...${NC}"
hugo --config config.yaml -d public

if [ -d "public" ]; then
  echo -e "${GREEN}Success: Hugo build created the public directory${NC}"
  echo -e "${BLUE}Contents of public directory:${NC}"
  ls -la public/
else
  echo -e "${RED}Error: Hugo build failed to create the public directory${NC}"
  echo -e "${YELLOW}Check the error messages above for more details${NC}"
fi