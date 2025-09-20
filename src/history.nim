import database

proc getDocumentHistory*(docId: int): seq[NotebookEntry] =
  let db = getDatabase()
  return db.listNotebookEntries(docId)

proc displayDocumentHistory*(docId: int): string =
  let history = getDocumentHistory(docId)
  if history.len == 0:
    result = "No history found for this document."
  else:
    var output = ""
    for entry in history:
      output &= "Query: " & entry.queryText & " "
      output &= "Answer: " & entry.answerText & " "
      output &= "Timestamp: " & entry.timestamp & " "
      output &= "------------------------"
    result = output
