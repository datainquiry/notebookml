#
# @file database.nim
# @author Jaime Lopez
# @brief Handles all interactions with the SQLite database.
#

import strutils
import db_connector/db_sqlite
import os
import options

var dbFile* = "notebookml.db"
var db: DbConn

#region Types

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

#endregion

#region Private Procs

proc getDbConn*(): DbConn =
  if db.isNil:
    try:
      db = open(dbFile, "", "", "")
    except DbError as e:
      echo "Error opening database: ", e.msg
      quit(1)
  return db

#endregion

#region Public Procs

proc tableExists*(db: DbConn, tableName: string): bool =
  ## Checks if a table exists in the database.
  let query = sql"SELECT name FROM sqlite_master WHERE type='table' AND name = ?"
  let result = db.getValue(query, tableName)
  return result == tableName

proc setupDatabase*() =
  ## Initializes the database and creates the `documents` and `chunks` tables if they don't exist.
  let db = getDbConn()
  db.exec(sql"DROP TABLE IF EXISTS documents")
  db.exec(sql"DROP TABLE IF EXISTS chunks")
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS documents (
      id INTEGER PRIMARY KEY,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL UNIQUE,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  """)
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS chunks (
      id INTEGER PRIMARY KEY,
      document_id INTEGER,
      chunk_index INTEGER NOT NULL,
      text TEXT NOT NULL,
      FOREIGN KEY (document_id) REFERENCES documents(id)
    )
  """)
  db.close()

proc addDocument*(filePath: string): int64 =
  let db = getDbConn()
  let fileName = filePath.extractFilename()
  let id = db.tryInsertId(sql"INSERT INTO documents (file_name, file_path) VALUES (?, ?)", fileName, filePath)
  if id == -1:
    dbError(db)
  db.close()
  return id

proc addChunk*(docId: int64, index: int, text: string) =
  ## Inserts a single text chunk into the `chunks` table, linked to a document.
  let db = getDbConn()
  db.exec(sql"INSERT INTO chunks (document_id, chunk_index, text) VALUES (?, ?, ?)", docId, index, text)
  db.close()

proc addChunks*(docId: int64, chunks: seq[string]) =
  ## A helper proc that iterates over a sequence of chunk texts and adds them to the database.
  let db = getDbConn()
  db.exec(sql"BEGIN TRANSACTION")
  try:
    for i, chunkText in chunks:
      addChunk(docId, i, chunkText)
    db.exec(sql"COMMIT")
  except:
    db.exec(sql"ROLLBACK")
    raise
  finally:
    db.close()

proc listDocuments*(): seq[Document] =
  ## Retrieves all document records from the database.
  let db = getDbConn()
  result = newSeq[Document]()
  for row in db.fastRows(sql"SELECT id, file_name, file_path, created_at FROM documents ORDER BY created_at DESC"):
    result.add(Document(
      id: parseInt(row[0]),
      fileName: row[1],
      filePath: row[2],
      createdAt: row[3]
    ))
  db.close()

proc findChunkByText*(query: string): Option[Chunk] =
  ## Searches for a chunk containing the given text (`LIKE` query).
  ## Returns the first matching chunk, if any.
  let db = getDbConn()
  let likeQuery = "%" & query & "%"
  for row in db.fastRows(sql"SELECT id, document_id, chunk_index, text FROM chunks WHERE text LIKE ? LIMIT 1", likeQuery):
    return some(Chunk(
      id: parseInt(row[0]),
      documentId: parseInt(row[1]),
      chunkIndex: parseInt(row[2]),
      text: row[3]
    ))
  db.close()
  return none(Chunk)

#endregion
