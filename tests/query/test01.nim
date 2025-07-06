import unittest
import strutils
import httpclient
import std/files
import std/paths
import ../../src/query
import ../../src/database
import ../../src/embeddings
import ../../src/config

proc isOllamaRunning(): bool =
  loadConfig()
  let config = getConfig()
  try:
    let client = newHttpClient()
    defer: client.close()
    let response = client.get(config.ollamaUrl)
    return response.status == "200 OK"
  except HttpRequestError:
    return false

const testDbFile = "test_clihandler_real.db"
var db: Database

proc setup() =
  if fileExists(Path(testDbFile)):
    removeFile(Path(testDbFile))
  loadConfig()
  db = getDatabase(testDbFile)
  db.setupDatabase()

proc teardown() =
  if fileExists(Path(testDbFile)):
    removeFile(Path(testDbFile))

suite "Query Module Tests":
  setup: setup()
  teardown: teardown()

  test "Answer query with context from database":
    if not isOllamaRunning():
      skip()

    # Setup: Add a document with a known chunk to the database
    let docId = db.addDocument("/tmp/query_test_doc.txt")
    let chunkText = "The capital of France is Paris."
    let embedding = getEmbedding(chunkText)
    db.addChunkWithEmbedding(docId, 0, chunkText, embedding)

    # Test the query
    let query = "What is the capital of France?"
    let answer = answerQuery(query)

    check answer.len > 0
    check answer.toLower.contains("paris")

    # Verify notebook entry was added
    let notebookEntries = db.listNotebookEntries(docId.int)
    check notebookEntries.len == 1
    check notebookEntries[0].queryText == query
    check notebookEntries[0].answerText == answer

  test "Answer query with no relevant context":
    if not isOllamaRunning():
      skip()

    # Setup: Ensure an empty database
    # The setup proc already creates a clean database for each test.

    let query = "What is the meaning of life?"
    let answer = answerQuery(query)

    check answer.len > 0
    check answer.toLower.contains("couldn't find relevant information")
    check answer.toLower.contains("meaning of life")

    # Verify no notebook entry was added for no relevant context
    let notebookEntries = db.listNotebookEntries(1) # Assuming docId 1 would be used if an entry was added
    check notebookEntries.len == 0
    
  test "Answer query with multiple relevant contexts logs entries for all documents":
    if not isOllamaRunning():
      skip()

    # Create multiple documents with relevant chunks
    let docId1 = db.addDocument("/tmp/multi_doc1.txt")
    let chunkText1 = "The quick brown fox jumps over the lazy dog."
    let embedding1 = getEmbedding(chunkText1)
    db.addChunkWithEmbedding(docId1, 0, chunkText1, embedding1)

    let docId2 = db.addDocument("/tmp/multi_doc2.txt")
    let chunkText2 = "A fox is a small to medium-sized, omnivorous mammal."
    let embedding2 = getEmbedding(chunkText2)
    db.addChunkWithEmbedding(docId2, 0, chunkText2, embedding2)

    let docId3 = db.addDocument("/tmp/multi_doc3.txt")
    let chunkText3 = "Foxes are generally smaller than some other canids."
    let embedding3 = getEmbedding(chunkText3)
    db.addChunkWithEmbedding(docId3, 0, chunkText3, embedding3)

    let query = "Tell me about foxes."
    let answer = answerQuery(query)

    check answer.len > 0

    # Verify notebook entries for each document
    let entries1 = db.listNotebookEntries(docId1.int)
    check entries1.len == 1
    check entries1[0].queryText == query
    check entries1[0].answerText == answer

    let entries2 = db.listNotebookEntries(docId2.int)
    check entries2.len == 1
    check entries2[0].queryText == query
    check entries2[0].answerText == answer

    let entries3 = db.listNotebookEntries(docId3.int)
    check entries3.len == 1
    check entries3[0].queryText == query
    check entries3[0].answerText == answer

