# 📝 Programming Interfaces (Week 1)

This document defines the public procedures and data types for the modules that will be implemented in Week 1, as per the technical specifications.

---

## 1. `database.nim`

Handles all interactions with the SQLite database (`nimnotebook.db`).

### Types

```nim
type
  Document* = object
    id*: int
    fileName*: string
    filePath*: string
    createdAt*: string

  Chunk* = object
    id*: int
    documentId*: int
    chunkIndex*: int
    text*: string
```

### Procedures

```nim
proc setupDatabase*()
  ## Initializes the database and creates the `documents` and `chunks` tables if they don't exist.

proc addDocument*(filePath: string): int64
  ## Adds a new document record to the `documents` table.
  ## Returns the `id` of the newly inserted document.
  ## Throws an exception if the file path already exists.

proc addChunk*(docId: int64, index: int, text: string)
  ## Inserts a single text chunk into the `chunks` table, linked to a document.

proc addChunks*(docId: int64, chunks: seq[string])
  ## A helper proc that iterates over a sequence of chunk texts and adds them to the database.

proc listDocuments*(): seq[Document]
  ## Retrieves all document records from the database.

proc findChunkByText*(query: string): Option[Chunk]
  ## Searches for a chunk containing the given text (`LIKE` query).
  ## Returns the first matching chunk, if any.
```

---

## 2. `chunker.nim`

Responsible for splitting raw text content into manageable chunks.

### Procedures

```nim
proc chunkText*(text: string, chunkSize: int = 300): seq[string]
  ## Splits a large string of text into a sequence of smaller strings (chunks).
  ## Aims for chunks of `chunkSize` words, breaking at sentence boundaries where possible.
```

---

## 3. `dochandler.nim` (Document Handler)

Manages file-specific operations like text extraction.

### Procedures

```nim
proc extractText*(filePath: string): string
  ## Extracts the full text content from a given file.
  ## It dispatches to the correct parser based on the file extension (`.txt`, `.md`, `.pdf`).
  ## Throws an exception if the file format is not supported or if `pdftotext` fails.
```

---

## 4. `main.nim` (CLI)

The main entry point, responsible for parsing command-line arguments and orchestrating the application's workflow.

### Procedures (Internal Logic)

While most of the logic will be in the main execution block, we can conceptualize the command handlers as separate procedures.

```nim
proc handleUpload(filePath: string)
  ## Orchestrates the document upload process:
  ## 1. Calls `dochandler.extractText`.
  ## 2. Calls `chunker.chunkText`.
  ## 3. Calls `database.addDocument` and `database.addChunks`.
  ## Prints success or error messages to the console.

proc handleList()
  ## 1. Calls `database.listDocuments`.
  ## 2. Formats and prints the list of documents to the console.

proc handleAsk(query: string)
  ## 1. Calls `database.findChunkByText`.
  ## 2. Prints the found chunk's text or a "not found" message.
```
