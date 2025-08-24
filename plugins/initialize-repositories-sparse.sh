#!/bin/bash

# Array of repository URLs to clone
repositories=(
    "git@github.com:katakumby/ticker-archit.git"
    "git@github.com:katakumby/hl-iso20022.git"
    # Add more repositories here
)

# Target folder where repositories will be cloned
target_folder="./cloned_repos"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Repository Cloning Script${NC}"
echo "=========================="

# Create target folder if it doesn't exist
if [ ! -d "$target_folder" ]; then
    echo -e "Creating target folder: ${YELLOW}$target_folder${NC}"
    mkdir -p "$target_folder"
fi

# Change to target directory
cd "$target_folder" || {
    echo -e "${RED}Error: Cannot access target folder $target_folder${NC}"
    exit 1
}

echo -e "Sparse-cloning repositories (README.md + src/) into: ${YELLOW}$(pwd)${NC}"
echo ""

# Counter for statistics
total_repos=${#repositories[@]}
successful_clones=0
failed_clones=0

# Clone each repository
for i in "${!repositories[@]}"; do
    repo_url="${repositories[$i]}"
    repo_name=$(basename "$repo_url" .git)
    
    echo -e "[$((i+1))/$total_repos] Sparse-cloning ${YELLOW}$repo_name${NC} (README.md + src/)..."
    
    # Check if repository already exists
    if [ -d "$repo_name" ]; then
        echo -e "${YELLOW}Warning: Directory '$repo_name' already exists. Skipping...${NC}"
        continue
    fi
    
    # Clone with sparse-checkout for README.md and src/ only
    if git clone --filter=blob:none --no-checkout "$repo_url" 2>/dev/null; then
        cd "$repo_name" || {
            echo -e "${RED}✗ Failed to enter $repo_name directory${NC}"
            ((failed_clones++))
            continue
        }
        
        # Enable sparse-checkout
        git sparse-checkout init --cone 2>/dev/null
        
        # Set sparse-checkout patterns explicitly
        echo "README.md" > .git/info/sparse-checkout
        echo "src/" >> .git/info/sparse-checkout
        echo "src/*" >> .git/info/sparse-checkout
        
        # Checkout the files
        if git checkout 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully cloned $repo_name with sparse-checkout (README.md + src/)${NC}"
            ((successful_clones++))
        else
            echo -e "${RED}✗ Failed to checkout sparse files for $repo_name${NC}"
            ((failed_clones++))
        fi
        
        # Return to parent directory
        cd ..
    else
        echo -e "${RED}✗ Failed to clone $repo_name${NC}"
        echo -e "${RED}  URL: $repo_url${NC}"
        ((failed_clones++))
    fi
    echo ""
done

# Print summary
echo "=========================="
echo -e "${YELLOW}Sparse-Checkout Cloning Summary:${NC}"
echo -e "Total repositories: $total_repos"
echo -e "${GREEN}Successful clones: $successful_clones${NC}"
if [ $failed_clones -gt 0 ]; then
    echo -e "${RED}Failed clones: $failed_clones${NC}"
fi
echo -e "Target folder: ${YELLOW}$(pwd)${NC}"

# Exit with appropriate code
if [ $failed_clones -gt 0 ]; then
    exit 1
else
    exit 0
fi
