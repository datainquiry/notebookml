# 📝 Programming Interfaces (Weeks 1-3)

This document defines the public procedures and data types for the modules that will be implemented in Weeks 1-3, as per the technical specifications.

---

## 1. `database.nim`

Handles all interactions with the SQLite database (`notebookml.db`).

### Types (Week 1)

```nim
type
  Database* = object
    db*: DbConn

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
    embedding*: seq[float] # Week 2: Added
```

### Types (Week 3)
```nim
type
  NotebookEntry* = object
    id*: int
    documentId*: int
    query*: string
    answer*: string
    createdAt*: string
```

### Procedures (Week 1)

```nim
proc getDatabase*(dbName: string = "notebookml.db"): Database
  ## Creates and returns a new Database object.

proc `=destroy`*(database: Database)
  ## Closes the database connection when the Database object is destroyed.

proc setupDatabase*(database: Database)
  ## Initializes the database and creates the `documents` and `chunks` tables if they don't exist.

proc tableExists*(database: Database, tableName: string): bool
  ## Checks if a table with the given name exists in the database.

proc addDocument*(database: Database, filePath: string): int64
  ## Adds a new document record to the `documents` table.

proc addChunk*(database: Database, docId: int64, index: int, text: string)
  ## Inserts a single text chunk into the `chunks` table, linked to a document.

proc addChunks*(database: Database, docId: int64, chunks: seq[string])
  ## A helper proc that iterates over a sequence of chunk texts and adds them to the database.

proc listDocuments*(database: Database): seq[Document]
  ## Retrieves all document records from the database.

proc findChunkByText*(database: Database, query: string): Option[Chunk]
  ## Searches for a chunk containing the given text (`LIKE` query).
```

### Procedures (Week 2)
```nim
proc addChunkWithEmbedding*(database: Database, docId: int64, index: int, text: string, embedding: seq[float])
  ## Inserts a chunk with its corresponding vector embedding.

proc findSimilarChunks*(database: Database, queryVector: seq[float], topK: int = 5): seq[Chunk]
  ## Finds the `topK` most similar chunks to a given query vector using cosine similarity.
```

### Procedures (Week 3)
```nim
proc addNotebookEntry*(database: Database, docId: int, query: string, answer: string): int64
  ## Adds a new query-answer pair to the notebook history.

proc getNotebookHistory*(database: Database, docId: int): seq[NotebookEntry]
  ## Retrieves the full Q&A history for a specific document.

proc updateDocumentTags*(database: Database, docId: int, tags: string)
  ## Updates the tags for a specific document.

proc deleteDocument*(database: Database, docId: int)
  ## Deletes a document and all its associated chunks and history.

proc renameDocument*(database: Database, docId: int, newName: string)
  ## Renames a document file.
```

---

## 2. `chunker.nim` (Week 1)

Responsible for splitting raw text content into manageable chunks.

### Procedures

```nim
proc chunkText*(text: string, chunkSize: int = 300): seq[string]
  ## Splits a large string of text into a sequence of smaller strings (chunks).
```

---

## 3. `dochandler.nim` (Week 1)

Manages file-specific operations like text extraction.

### Procedures

```nim
proc extractText*(filePath: string): string
  ## Extracts the full text content from a given file.
```

---

## 4. `clihandler.nim` (CLI Handler)

Handles the command-line interface logic.

### Procedures (Week 1)

```nim
proc handleUpload*(filePath: string)
  ## Orchestrates the document upload process.

proc handleList*()
  ## Formats and prints the list of documents to the console.

proc handleAsk*(query: string)
  ## Finds and prints a chunk matching the query.
```

### Procedures (Week 2 & 3)
```nim
proc handleAsk*(query: string)
  ## Updated to use `query.answerQuery` to provide LLM-generated answers.

proc handleNotebook*(docId: int)
  ## Displays the Q&A history for a given document.

proc handleDelete*(docId: int)
  ## Deletes a document from the database.

proc handleTag*(docId: int, tags: string)
  ## Adds or updates tags for a document.

proc handleRename*(docId: int, newName: string)
  ## Renames a document.
```

---

## 5. `embeddings.nim` (Week 2)

Handles communication with an external embedding model (e.g., Ollama).

### Procedures

```nim
proc getEmbedding*(text: string): seq[float]
  ## Generates a vector embedding for a given string of text.
```

---

## 6. `query.nim` (Week 2)

Orchestrates turning a user query into a context-aware AI-generated answer.

### Procedures

```nim
proc answerQuery*(query: string): string
  ## 1. Gets an embedding for the user's query.
  ## 2. Finds relevant chunks from the vector store.
  ## 3. Constructs a prompt and sends it to the LLM.
  ## 4. Returns the final answer.
```

