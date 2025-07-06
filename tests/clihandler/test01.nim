import unittest
import os
import strutils
import options
import ../../src/clihandler
import ../../src/database
import ../../src/embeddings
import ../../src/utils

const testDbFile = "test_clihandler.db"

proc setup() =
  # Ensure we start with a clean slate for each test.
  if fileExists(testDbFile):
    removeFile(testDbFile)
  let db = getDatabase(testDbFile)
  db.setupDatabase()

proc teardown() =
  # Clean up the test database file after tests are done.
  if fileExists(testDbFile):
    removeFile(testDbFile)

suite "CLI Handler Tests (Week 2)":
  setup: setup()
  teardown: teardown()

  test "handleUpload should create a document and chunks with embeddings":
    # Create a dummy file to upload
    let testFilePath = "/tmp/clihandler_test_doc.txt"
    writeFile(testFilePath, "This is a test document for the CLI handler.")

    # Run the upload handler
    discard handleUpload(testFilePath)

    # Check the database
    let db = getDatabase(testDbFile)
    let docs = db.listDocuments()
    check docs.len == 1
    check docs[0].filePath == testFilePath

    let foundChunk = db.findChunkByText("This is a test document for the CLI handler.")
    check foundChunk.isSome()
    check foundChunk.get().text == "This is a test document for the CLI handler."
    check foundChunk.get().text == "This is a test document for the CLI handler."


  test "handleAsk should return an AI-generated answer":
    # Setup: Add a document with a known chunk to the database
    let db = getDatabase(testDbFile)
    let docId = db.addDocument("/tmp/clihandler_ask_test.txt")
    let chunkText = "The sky is blue."
    let embedding = getEmbedding(chunkText)
    db.addChunkWithEmbedding(docId, 0, chunkText, embedding)

    # Test the ask handler
    let query = "What color is the sky?"
    # Redirect stdout to a file to capture the output
    let output = captureOutput(proc() =  discard handleAsk(query))
    check output.toLower.contains("blue")

  test "handleUpload should raise an error for a non-existent file":
    let nonExistentFilePath = "/tmp/non_existent_file_12345.txt"
    expect(IOError):
      discard handleUpload(nonExistentFilePath)
