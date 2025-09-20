import std/[strutils, os, json, options, math, algorithm]
import db_connector/db_sqlite
import config

type
  Database* = object
    db*: DbConn

  Document* = object
    id*: int
    fileName*: string
    filePath*: string
    createdAt*: string
    tags*: seq[string]

  Chunk* = object
    id*: int
    documentId*: int
    chunkIndex*: int
    text*: string
    embedding*: seq[float]

  NotebookEntry* = object
    id*: int
    documentId*: int
    queryText*: string
    answerText*: string
    timestamp*: string

proc setupDatabase*(database: Database) =
  let db = database.db
  db.exec(sql"DROP TABLE IF EXISTS documents")
  db.exec(sql"DROP TABLE IF EXISTS chunks")
  db.exec(sql"DROP TABLE IF EXISTS notebook")
  db.exec(sql"DROP TABLE IF EXISTS tags")
  db.exec(sql"DROP TABLE IF EXISTS document_tags")
  db.exec(sql"""
    CREATE TABLE documents (
      id INTEGER PRIMARY KEY,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL UNIQUE,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  """)
  db.exec(sql"""
    CREATE TABLE chunks (
      id INTEGER PRIMARY KEY,
      document_id INTEGER,
      chunk_index INTEGER NOT NULL,
      text TEXT NOT NULL,
      embedding TEXT,
      FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
    )
  """)
  db.exec(sql"""CREATE TABLE notebook (
      id INTEGER PRIMARY KEY,
      document_id INTEGER NOT NULL,
      query_text TEXT NOT NULL,
      answer_text TEXT NOT NULL,
      timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
    )
  """)
  db.exec(sql"""CREATE TABLE tags (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE
    )
  """)
  db.exec(sql"""CREATE TABLE document_tags (
      document_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      PRIMARY KEY (document_id, tag_id),
      FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
    )
  """)


proc getDbConn(dbName: string): DbConn =
  # Checks if the file exists
  try:
    result = open(dbName, "", "", "")
  except DbError as e:
    echo "Error opening database: ", e.msg
    quit(1)

proc `=destroy`*(database: Database) =
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

proc addDocument*(database: Database, filePath: string): int64 =
  let db = database.db
  let fileName = filePath.extractFilename()
  let id = db.tryInsertId(sql"INSERT INTO documents (file_name, file_path) VALUES (?, ?)",
      fileName, filePath)
  if id == -1:
    dbError(db)
  return id

proc addChunk*(database: Database, docId: int64, index: int, text: string) =
  database.db.exec(sql"INSERT INTO chunks (document_id, chunk_index, text) VALUES (?, ?, ?)",
      docId, index, text)

proc addChunks*(database: Database, docId: int64, chunks: seq[string]) =
  let db = database.db
  db.exec(sql"BEGIN TRANSACTION")
  try:
    for i, chunkText in chunks:
      database.addChunk(docId, i, chunkText)
    db.exec(sql"COMMIT")
  except:
    db.exec(sql"ROLLBACK")
    raise

proc addChunkWithEmbedding*(database: Database, docId: int64, index: int,
    text: string, embedding: seq[float]) =
  let embeddingJson = %*(embedding)
  database.db.exec(sql"INSERT INTO chunks (document_id, chunk_index, text, embedding) VALUES (?, ?, ?, ?)",
      docId, index, text, embeddingJson)

proc listDocuments*(database: Database, filterTag: string = ""): seq[Document] =
  result = newSeq[Document]()
  var query = "SELECT d.id, d.file_name, d.file_path, d.created_at FROM documents d"
  var params: seq[string] = @[]

  if filterTag.len > 0:
    query &= " JOIN document_tags dt ON d.id = dt.document_id JOIN tags t ON dt.tag_id = t.id WHERE t.name = ?"
    params.add(filterTag)

  query &= " ORDER BY d.created_at DESC"

  for row in database.db.fastRows(sql(query), params):
    var doc = Document(
      id: parseInt(row[0]),
      fileName: row[1],
      filePath: row[2],
      createdAt: row[3],
      tags: @[] # Initialize with empty sequence
    )
    for tagRow in database.db.fastRows(sql"SELECT t.name FROM tags t JOIN document_tags dt ON t.id = dt.tag_id WHERE dt.document_id = ?", doc.id):
      doc.tags.add(tagRow[0])
    result.add(doc)

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

proc findSimilarChunks*(database: Database, queryVector: seq[float],
    topK: int = 5): seq[Chunk] =
  var allChunks = newSeq[tuple[chunk: Chunk, similarity: float]]()
  for row in database.db.fastRows(sql"SELECT id, document_id, chunk_index, text, embedding FROM chunks WHERE embedding IS NOT NULL"):
    let embeddingJson = row[4]
    var chunkEmbedding: seq[float]
    try:
      chunkEmbedding = to(parseJson(embeddingJson), seq[float])
    except JsonParsingError:
      continue
    let similarity = cosineSimilarity(queryVector, chunkEmbedding)
    if similarity > 0.2:
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


proc addNotebookEntry*(database: Database, docId: int, query: string,
    answer: string) =
  ## Inserts a new entry into the `notebook` table.
  database.db.exec(sql"INSERT INTO notebook (document_id, query_text, answer_text) VALUES (?, ?, ?)",
      docId, query, answer)

proc listNotebookEntries*(database: Database, docId: int): seq[NotebookEntry] =
  ## Retrieves all notebook entries for a given document ID.
  result = newSeq[NotebookEntry]()
  for row in database.db.fastRows(sql"SELECT id, document_id, query_text, answer_text, timestamp FROM notebook WHERE document_id = ? ORDER BY timestamp ASC", docId):
    result.add(NotebookEntry(
      id: parseInt(row[0]),
      documentId: parseInt(row[1]),
      queryText: row[2],
      answerText: row[3],
      timestamp: row[4]
    ))

proc deleteDocument*(database: Database, docId: int) =
  ## Deletes a document and all its associated chunks and notebook entries.
  let db = database.db
  db.exec(sql"BEGIN TRANSACTION")
  try:
    db.exec(sql"DELETE FROM chunks WHERE document_id = ?", docId)
    db.exec(sql"DELETE FROM notebook WHERE document_id = ?", docId)
    db.exec(sql"DELETE FROM documents WHERE id = ?", docId)
    db.exec(sql"COMMIT")
  except Exception as e:
    db.exec(sql"ROLLBACK")
    raise newException(DbError, "Failed to delete document and its associated data: " & e.msg)

proc addTag*(database: Database, docId: int, tag: string) =
  let db = database.db
  db.exec(sql"BEGIN TRANSACTION")
  try:
    # Insert tag if it doesn't exist
    db.exec(sql"INSERT OR IGNORE INTO tags (name) VALUES (?)", tag)
    # Get tag ID
    let tagId = db.getValue(sql"SELECT id FROM tags WHERE name = ?",
        tag).parseInt()
    # Link document and tag
    db.exec(sql"INSERT OR IGNORE INTO document_tags (document_id, tag_id) VALUES (?, ?)",
        docId, tagId)
    db.exec(sql"COMMIT")
  except Exception as e:
    db.exec(sql"ROLLBACK")
    raise newException(DbError, "Failed to add tag: " & e.msg)

proc removeTag*(database: Database, docId: int, tag: string) =
  let db = database.db
  db.exec(sql"BEGIN TRANSACTION")
  try:
    let tagId = db.getValue(sql"SELECT id FROM tags WHERE name = ?",
        tag).parseInt()
    db.exec(sql"DELETE FROM document_tags WHERE document_id = ? AND tag_id = ?",
        docId, tagId)
    db.exec(sql"COMMIT")
  except Exception as e:
    db.exec(sql"ROLLBACK")
    raise newException(DbError, "Failed to remove tag: " & e.msg)

proc renameDocument*(database: Database, docId: int, newName: string) =
  let db = database.db
  db.exec(sql"UPDATE documents SET file_name = ? WHERE id = ?", newName, docId)

proc listTags*(database: Database): seq[string] =
  result = newSeq[string]()
  for row in database.db.fastRows(sql"SELECT name FROM tags ORDER BY name ASC"):
    result.add(row[0])
