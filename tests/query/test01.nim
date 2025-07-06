import unittest
import strutils
import httpclient
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

suite "Query Module Tests":
  test "Answer query with context from database":
    if not isOllamaRunning():
      skip()

    # Setup: Add a document with a known chunk to the database
    let db = getDatabase("test_query.db")
    db.setupDatabase()
    let docId = db.addDocument("/tmp/query_test_doc.txt")
    let chunkText = "The capital of France is Paris."
    let embedding = getEmbedding(chunkText)
    db.addChunkWithEmbedding(docId, 0, chunkText, embedding)

    # Test the query
    let query = "What is the capital of France?"
    let answer = answerQuery(query)

    check answer.len > 0
    check answer.toLower.contains("paris")


  test "Answer query with no relevant context":
    if not isOllamaRunning():
      skip()

    # Setup: Clear the database or use a new one with no relevant data
    let db = getDatabase("test_empty_query.db")
    db.setupDatabase() # Ensures an empty database

    let query = "What is the meaning of life?"
    let answer = answerQuery(query)

    check answer.len > 0
    check answer.toLower.contains("couldn't find relevant information")
    check answer.toLower.contains("meaning of life")
    
  teardown:
    # Clean up test databases
    if fileExists("test_query.db"):
      removeFile("test_query.db")
    if fileExists("test_empty_query.db"):
      removeFile("test_empty_query.db")
