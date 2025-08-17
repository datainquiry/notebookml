import std/[os, strutils, strformat]
import database, dochandler, chunker, embeddings, query, history

proc handleInit*(): string =
  let db = getDatabase()
  setupDatabase(db)
  result = "Database initialized successfully."

## Orchestrates the document upload process:
## 1. Calls `dochandler.extractText`.
## 2. Calls `chunker.chunkText`.
## 3. Calls `database.addDocument` and `database.addChunks`.
## Prints success or error messages to the console.
proc handleUpload*(filePath: string): string =
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
    result = "Successfully uploaded, chunked, and embedded file: " & filePath
  except Exception as e:
    echo "Error during upload: ", e.msg

## 1. Calls `database.listDocuments`.
## 2. Formats and prints the list of documents to the console.
proc handleList*(tag: string = ""): string =
  let db = getDatabase()
  let documents = db.listDocuments(tag)
  if documents.len == 0:
    return "No documents found."
  var output = "Documents:\n"
  for doc in documents:
    var tagsStr = ""
    if doc.tags.len > 0:
      tagsStr = ", **Tags**: `" & doc.tags.join("`, `") & "`"
    output &= $ "- **ID**: {doc.id}, **File**: `{doc.fileName}` (`{doc.filePath}`), **Created**: {doc.createdAt}{tagsStr}\n"
  result = output

proc handleAsk*(queryText: string): string =
  result = answerQuery(queryText)

proc handleNotebook*(docId: int): string =
  ## Displays the Q&A history for a specific document.
  result = displayDocumentHistory(docId)

proc handleDelete*(docId: int): string =
  ## Deletes a document and its associated data.
  try:
    let db = getDatabase()
    db.deleteDocument(docId)
    result = "Document **" & $docId & "** and its associated data deleted successfully."
  except Exception as e:
    result = "Error deleting document: " & e.msg

proc handleTag*(docId: int, tag: string, action: string): string =
  ## Adds or removes a tag from a document.
  try:
    let db = getDatabase()
    case action:
    of "add":
      db.addTag(docId, tag)
      result = $"Tag `{tag}` added to document **{docId}**."
    of "remove":
      db.removeTag(docId, tag)
      result = $"Tag `{tag}` removed from document **{docId}**."
    else:
      result = "Invalid tag action. Use 'add' or 'remove'."
  except Exception as e:
    result = "Error tagging document: " & e.msg

proc handleRename*(docId: int, newName: string): string =
  ## Renames a document.
  try:
    let db = getDatabase()
    db.renameDocument(docId, newName)
    result = fmt"Document **{docId}** renamed to `{newName}` successfully."
  except Exception as e:
    result = "Error renaming document: " & e.msg

proc handleTags*(): string =
  ## Lists all unique tags in the database.
  let db = getDatabase()
  let tags = db.listTags()
  if tags.len == 0:
    result = "No tags found."
  else:
    var output = "Tags:\n"
    for tag in tags:
      output &= $"- `{tag}`\n"
    result = output
