#
# @file main.nim
# @author Jaime Lopez
# @brief Main entry point for the notebookml CLI.
#

# import options

import os
import database
import dochandler
import chunker
import embeddings
import query

proc handleInit*() =
  ## Initializes the database.
  let db = getDatabase()
  setupDatabase(db)

proc handleUpload*(filePath: string) =
  ## Orchestrates the document upload process:
  ## 1. Calls `dochandler.extractText`.
  ## 2. Calls `chunker.chunkText`.
  ## 3. Calls `database.addDocument` and `database.addChunks`.
  ## Prints success or error messages to the console.
  try:
    echo "Extracting text from: ", filePath
    let text = dochandler.extractText(filePath)
    echo "Text extracted successfully."

    echo "Chunking text..."
    let chunks = chunkText(text)
    echo "Text chunked successfully: ", chunks.len, " chunks created."

    let db = getDatabase()
    let docId = db.addDocument(filePath.absolutePath())
    
    echo "Generating and storing embeddings for each chunk..."
    for i, chunkText in chunks:
      let embedding = getEmbedding(chunkText)
      db.addChunkWithEmbedding(docId, i, chunkText, embedding)
    
    echo "Successfully uploaded, chunked, and embedded file: ", filePath

  except Exception as e:
    echo "Error during upload: ", e.msg

proc handleList*() =
  ## 1. Calls `database.listDocuments`.
  ## 2. Formats and prints the list of documents to the console.
  let db = getDatabase()
  let documents = db.listDocuments()
  if documents.len == 0:
    echo "No documents found."
  else:
    echo "Documents:"
    for doc in documents:
      # echo &"  - {doc.id}: {doc.fileName} ({doc.filePath}) - {doc.createdAt}"
      echo doc

proc handleAsk*(queryText: string) =
  ## 1. Calls `query.answerQuery` to get an AI-generated answer.
  ## 2. Prints the final answer.
  let answer = answerQuery(queryText)
  echo answer
