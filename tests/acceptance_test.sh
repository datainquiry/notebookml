#!/bin/bash

# 1. Initialize the database
./notebookml init

# 2. Upload a PDF file
./notebookml --upload=tests/dochandler/test.pdf

# 3. Ask a question and save the output
./notebookml --ask="Nim Destructors and Move Semantics" > outputGotten.txt
