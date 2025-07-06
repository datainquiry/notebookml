#
# @file database.nim
# @author Jaime Lopez
# @brief Handles all interactions with the SQLite database.
#

import strutils
import db_connector/db_sqlite
import os
import options
import json
import math
import algorithm
import config

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
    embedding*: seq[float]

proc getDbConn(dbName: string): DbConn =
  try:
    result = open(dbName, "", "", "")
  except DbError as e:
    echo "Error opening database: ", e.msg
    quit(1)

proc `=destroy`*(database: Database) =
  ## Closes the database connection when the Database object is destroyed.
  try:
    database.db.close()
  except DbError as e:
    echo "Error closing database: ", e.msg

proc getDatabase*(dbName: string = ""): Database =
  let config = getConfig()
  let finalDbName = if dbName.len > 0: dbName else: config.databasePath
  let db = getDbConn(finalDbName)
  result = Database(db: db)

proc tableExists*(database: Database, tableName: string): bool =
  echo "Checking if table exists: ", tableName
  let query = "SELECT name FROM sqlite_master WHERE type='table' AND name = ?"
  let returnedName = database.db.getValue(sql(query), tableName)
  result = returnedName == tableName

proc setupDatabase*(database: Database) =
  ## Initializes the database and creates the `documents` and `chunks` tables if they don't exist.
  let db = database.db
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
      embedding TEXT,
      FOREIGN KEY (document_id) REFERENCES documents(id)
    )
  """)

proc addDocument*(database: Database, filePath: string): int64 =
  let db = database.db
  let fileName = filePath.extractFilename()
  let id = db.tryInsertId(sql"INSERT INTO documents (file_name, file_path) VALUES (?, ?)", fileName, filePath)
  if id == -1:
    dbError(db)
  return id

proc addChunk*(database: Database, docId: int64, index: int, text: string) =
  database.db.exec(sql"INSERT INTO chunks (document_id, chunk_index, text) VALUES (?, ?, ?)", docId, index, text)

proc addChunks*(database: Database, docId: int64, chunks: seq[string]) =
  ## A helper proc that iterates over a sequence of chunk texts and adds them to the database.
  let db = database.db
  db.exec(sql"BEGIN TRANSACTION")
  try:
    for i, chunkText in chunks:
      database.addChunk(docId, i, chunkText)
    db.exec(sql"COMMIT")
  except:
    db.exec(sql"ROLLBACK")
    raise

proc addChunkWithEmbedding*(database: Database, docId: int64, index: int, text: string, embedding: seq[float]) =
  ## Inserts a chunk with its corresponding vector embedding.
  let embeddingJson = %*(embedding)
  database.db.exec(sql"INSERT INTO chunks (document_id, chunk_index, text, embedding) VALUES (?, ?, ?, ?)", docId, index, text, embeddingJson)

proc listDocuments*(database: Database): seq[Document] =
  ## Retrieves all document records from the database.
  result = newSeq[Document]()
  for row in database.db.fastRows(sql"SELECT id, file_name, file_path, created_at FROM documents ORDER BY created_at DESC"):
    result.add(Document(
      id: parseInt(row[0]),
      fileName: row[1],
      filePath: row[2],
      createdAt: row[3]
    ))

proc findChunkByText*(database: Database, query: string): Option[Chunk] =
  ## Searches for a chunk containing the given text (`LIKE` query).
  ## Returns the first matching chunk, if any.
  let likeQuery = "%" & query & "%"
  for row in database.db.fastRows(sql"SELECT id, document_id, chunk_index, text FROM chunks WHERE text LIKE ? LIMIT 1", likeQuery):
    return some(Chunk(
      id: parseInt(row[0]),
      documentId: parseInt(row[1]),
      chunkIndex: parseInt(row[2]),
      text: row[3],
      embedding: @[]
    ))
  result = none(Chunk)

proc cosineSimilarity(a, b: seq[float]): float =
  var dotProduct: float = 0.0
  var normA: float = 0.0
  var normB: float = 0.0
  for i in 0 ..< a.len:
    dotProduct += a[i] * b[i]
    normA += a[i] * a[i]
    normB += b[i] * b[i]
  if normA == 0 or normB == 0:
    return 0.0
  result = dotProduct / (sqrt(normA) * sqrt(normB))

proc findSimilarChunks*(database: Database, queryVector: seq[float], topK: int = 5): seq[Chunk] =
  ## Finds the `topK` most similar chunks to a given query vector using cosine similarity.
  var allChunks = newSeq[tuple[chunk: Chunk, similarity: float]]()

  for row in database.db.fastRows(sql"SELECT id, document_id, chunk_index, text, embedding FROM chunks WHERE embedding IS NOT NULL"):
    let embeddingJson = row[4]
    var chunkEmbedding: seq[float]
    try:
      chunkEmbedding = to(parseJson(embeddingJson), seq[float])
    except JsonParsingError:
      continue

    let similarity = cosineSimilarity(queryVector, chunkEmbedding)
    allChunks.add((
      chunk: Chunk(
        id: parseInt(row[0]),
        documentId: parseInt(row[1]),
        chunkIndex: parseInt(row[2]),
        text: row[3],
        embedding: chunkEmbedding
      ),
      similarity: similarity
    ))
  
  allChunks.sort(proc(a, b: tuple[chunk: Chunk, similarity: float]): int =
    cmp(b.similarity, a.similarity)
  )

  result = newSeq[Chunk]()
  for i in 0 ..< min(topK, allChunks.len):
    result.add(allChunks[i].chunk)
