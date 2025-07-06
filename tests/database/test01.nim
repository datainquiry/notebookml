#
# @file test_database.nim
# @author Jaime Lopez
# @brief Unit tests for the database module.
#

import unittest
import os
import options
import db_connector/db_sqlite
import strutils
import std/json
import ../../src/database
import ../../src/config

const testDbFile = "test_notebook.db"
const docPath = "/tmp/test_doc.txt"
var db: Database

proc setup() =
  # Ensure we start with a clean slate for each test.
  if fileExists(testDbFile):
    removeFile(testDbFile)
  # Override the default dbFile constant for testing purposes.
  loadConfig()
  db = getDatabase(testDbFile)
  db.setupDatabase()
  # Creating a test text file
  let textBlock = "This is a sentence to be repeated for testing purposes.".repeat(20)
  writeFile(docPath, textBlock)


proc teardown() =
  # Clean up the test database file after tests are done.
  if fileExists(testDbFile):
    removeFile(testDbFile)

suite "Database Module Tests (Week 1 & 2)":
  setup: setup()
  teardown: teardown()

  test "Setup database creates tables":
    check db.tableExists("documents")
    check db.tableExists("chunks")

  test "Add a new document":
    let docId = db.addDocument(docPath)
    check docId > 0

    let docs = db.listDocuments()
    check docs.len == 1
    check docs[0].filePath == docPath
    check docs[0].fileName == "test_doc.txt"

  test "Adding a duplicate document raises an exception":
    discard db.addDocument(docPath)
    expect(DbError):
      discard db.addDocument(docPath)

  test "Add a single chunk":
    let docId = db.addDocument("/tmp/chunk_doc.txt")
    let chunkText = "This is the first chunk."
    db.addChunk(docId, 0, chunkText)

    let foundChunk = db.findChunkByText("first chunk").get()
    check foundChunk.text == chunkText
    check foundChunk.documentId == docId
    check foundChunk.chunkIndex == 0

  test "Add multiple chunks using the helper proc":
    let docId = db.addDocument("/tmp/multi_chunk.txt")
    let chunks = @["Chunk one.", "Chunk two.", "Chunk three."]
    db.addChunks(docId, chunks)

    let chunk1 = db.findChunkByText("one").get()
    let chunk2 = db.findChunkByText("two").get()
    let chunk3 = db.findChunkByText("three").get()

    check chunk1.chunkIndex == 0
    check chunk2.chunkIndex == 1
    check chunk3.chunkIndex == 2

  test "List multiple documents":
    discard db.addDocument("/tmp/doc1.txt")
    discard db.addDocument("/tmp/doc2.txt")
    discard db.addDocument("/tmp/doc3.txt")
    
    let docs = db.listDocuments()
    check docs.len == 3

  test "Find chunk by text returns correct chunk":
    let docId = db.addDocument("/tmp/search_doc.txt")
    db.addChunk(docId, 0, "The quick brown fox.")
    db.addChunk(docId, 1, "Jumps over the lazy dog.")

    let found = db.findChunkByText("lazy dog").get()
    check found.text == "Jumps over the lazy dog."

  test "Find chunk by text returns none for no match":
    let docId = db.addDocument("/tmp/no_match.txt")
    db.addChunk(docId, 0, "Some random text.")
    
    let notFound = db.findChunkByText("nonexistent")
    check notFound.isNone()

  test "Add chunk with embedding":
    let docId = db.addDocument("/tmp/embedding_doc.txt")
    let embedding = @[1.0, 2.0, 3.0]
    db.addChunkWithEmbedding(docId, 0, "Chunk with embedding.", embedding)

    let rawEmbedding = db.db.getValue(sql"SELECT embedding FROM chunks WHERE document_id = ?", docId)
    let parsedEmbedding = to(parseJson(rawEmbedding), seq[float])
    check parsedEmbedding == embedding

  test "Find similar chunks returns top K results":
    let docId = db.addDocument("/tmp/similarity_doc.txt")
    # Add chunks with embeddings that have clear similarity scores
    db.addChunkWithEmbedding(docId, 0, "cat", @[1.0, 0.0, 0.0]) # Most similar
    db.addChunkWithEmbedding(docId, 1, "dog", @[0.9, 0.1, 0.0]) # Second most
    db.addChunkWithEmbedding(docId, 2, "car", @[0.0, 1.0, 0.0]) # Not similar
    db.addChunkWithEmbedding(docId, 3, "truck", @[0.1, 0.9, 0.0]) # Not similar
    db.addChunkWithEmbedding(docId, 4, "feline", @[0.95, 0.05, 0.0]) # Third most

    let queryVector = @[1.0, 0.0, 0.0] # Query for "cat"
    let similarChunks = db.findSimilarChunks(queryVector, topK = 3)

    check similarChunks.len == 3
    check similarChunks[0].text == "cat"
    check similarChunks[1].text == "feline"
    check similarChunks[2].text == "dog"

