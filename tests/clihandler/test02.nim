import unittest
import os
import strutils
import ../../src/clihandler
import ../../src/database
import ../../src/config

const testDbFile = "test_clihandler_real.db"
var db: Database

proc setup() =
  if fileExists(testDbFile):
    removeFile(testDbFile)
  loadConfig()
  db = getDatabase(testDbFile)
  db.setupDatabase()

proc teardown() =
  if fileExists(testDbFile):
    removeFile(testDbFile)

suite "clihandler new features tests":
  setup: setup()
  teardown: teardown()

  test "handleNotebook calls displayDocumentHistory and shows entries":
    # Add a document and some notebook entries
    let docId = db.addDocument("/tmp/notebook_test_doc.txt")
    db.addNotebookEntry(docId.int, "Query 1", "Answer 1")
    db.addNotebookEntry(docId.int, "Query 2", "Answer 2")

    let output = handleNotebook(docId.int)
    check output.contains("--- Document History ---")
    check output.contains("Query: Query 1")
    check output.contains("Answer: Answer 1")
    check output.contains("Query: Query 2")
    check output.contains("Answer: Answer 2")

  test "handleDelete deletes document and associated data":
    let docId = db.addDocument("/tmp/delete_test_doc.txt")
    db.addChunk(docId, 0, "Chunk for deletion")
    db.addNotebookEntry(docId.int, "Query for deletion", "Answer for deletion")

    # Verify existence before deletion
    check db.listDocuments().len == 1
    check db.listNotebookEntries(docId.int).len == 1

    let output = handleDelete(docId.int)
    check output.contains("Document **" & $docId.int & "** and its associated data deleted successfully.")

    # Verify deletion
    check db.listDocuments().len == 0
    check db.listNotebookEntries(docId.int).len == 0

  test "handleTag adds and removes tags":
    let docId = db.addDocument("/tmp/tag_test_doc.txt")

    # Add tag
    discard handleTag(docId.int, "test_tag", "add")
    var docs = db.listDocuments()
    var taggedDoc: Document
    for d in docs:
      if d.id == docId.int:
        taggedDoc = d
        break
    check taggedDoc.tags.len == 1
    check "test_tag" in taggedDoc.tags

    # Remove tag
    discard handleTag(docId.int, "test_tag", "remove")
    docs = db.listDocuments()
    for d in docs:
      if d.id == docId.int:
        taggedDoc = d
        break
    check taggedDoc.tags.len == 0
    check not ("test_tag" in taggedDoc.tags)

  test "handleRename renames document":
    let docId = db.addDocument("/tmp/rename_test_doc.txt")
    let newName = "new_name.txt"

    discard handleRename(docId.int, newName)
    let docs = db.listDocuments()
    var renamedDoc: Document
    for d in docs:
      if d.id == docId.int:
        renamedDoc = d
        break
    check renamedDoc.fileName == newName
    check renamedDoc.filePath == "/tmp/rename_test_doc.txt" # Path should remain the same

  test "handleDelete prints error on exception":
    # Simulate an exception by passing an invalid docId
    let output = handleDelete(-1)
    check output.contains("Error deleting document:")

  test "handleTag prints error on exception":
    # Simulate an exception by passing an invalid docId
    let output = handleTag(-1, "test", "add")
    check output.contains("Error tagging document:")

  test "handleRename prints error on exception":
    # Simulate an exception by passing an invalid docId
    let output = handleRename(-1, "new_name")
    check output.contains("Error renaming document:")
