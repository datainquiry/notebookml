#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
CLI_PATH="./notebookml"
TEST_DB="test_acceptance.db"
TEST_DOC="test_document.txt"
CONFIG_FILE="test_config.json"

# Function to clean up
cleanup() {
    echo -e "${GREEN}Cleaning up...${NC}"
    rm -f "$CLI_PATH" "$TEST_DB" "$TEST_DOC" "$CONFIG_FILE"
    echo -e "${GREEN}Cleanup complete.${NC}"
}

# Register cleanup function to be called on EXIT
trap cleanup EXIT

echo -e "${GREEN}Starting Acceptance Test for Spiral 2 & 3 Deliverables...${NC}"

# 1. Check if Ollama is running
echo -e "${GREEN}Checking if Ollama is running...${NC}"
if ! curl -s http://localhost:11434 > /dev/null; then
    echo -e "${RED}Ollama is not running. Please start Ollama and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}Ollama is running.${NC}"

# Create a test config file
echo -e "${GREEN}Creating test config file: $CONFIG_FILE${NC}"
cat <<EOF > "$CONFIG_FILE"
{
  "ollamaUrl": "http://localhost:11434",
  "ollamaEmbeddingModel": "mxbai-embed-large",
  "ollamaQueryModel": "llama2",
  "ollamaTemperature": 0.0,
  "databasePath": "$TEST_DB"
}
EOF

# Compile the Nim application
echo -e "${GREEN}Compiling Nim application...${NC}"
nim c -o:$CLI_PATH src/notebookml.nim

# 2. Initialize the database
echo -e "${GREEN}Initializing database...${NC}"
$CLI_PATH --config:"$CONFIG_FILE" --init

# 3. Create a dummy text file
echo -e "${GREEN}Creating dummy text file: $TEST_DOC${NC}"
cat <<EOF > "$TEST_DOC"
The quick brown fox jumps over the lazy dog.
This document is for testing purposes.
It contains information about various animals.
EOF

# 4. Upload the dummy text file
echo -e "${GREEN}Uploading $TEST_DOC...${NC}"
$CLI_PATH --config:"$CONFIG_FILE" --upload:"$TEST_DOC"

# 5. Test Spiral 2 Deliverable: Ask a question with context
echo -e "${GREEN}Testing 'ask' with relevant context...${NC}"
ANSWER=$($CLI_PATH --config:"$CONFIG_FILE" --ask:"What color is the fox?")
echo "LLM Answer: $ANSWER"
if [[ "$ANSWER" == *"brown"* ]]; then
    echo -e "${GREEN}Test Passed: LLM answered correctly with context.${NC}"
else
    echo -e "${RED}Test Failed: LLM did not answer correctly with context. Expected 'brown', got: $ANSWER${NC}"
    exit 1
fi

# 6. Test Spiral 2 Deliverable: Ask a question without relevant context
echo -e "${GREEN}Testing 'ask' without relevant context...${NC}"
ANSWER=$($CLI_PATH --config:"$CONFIG_FILE" --ask:"What is the capital of France?")
echo "LLM Answer: $ANSWER"
if [[ "$ANSWER" == *"couldn't find relevant information"* ]]; then
    echo -e "${GREEN}Test Passed: LLM correctly indicated no relevant information.${NC}"
else
    echo -e "${RED}Test Failed: LLM did not indicate no relevant information. Expected 'couldn't find relevant information', got: $ANSWER${NC}"
    exit 1
fi

echo -e "${GREEN}All Spiral 2 tests passed successfully!${NC}"

# 7. Spiral 3 Deliverable: Note for future implementation
echo -e "${GREEN}Spiral 3 Deliverable (Document notebooks + query history) is not yet implemented in the CLI.${NC}"
echo -e "${GREEN}This test will be extended once the 'notebook' command and related features are available.${NC}"

echo -e "${GREEN}Acceptance Test Complete.${NC}