# 📝 Implementation Guide – Spiral 3: Robust Storage + Notebook Mode

This guide details the implementation steps for the goals and tasks outlined in Spiral 3 (Week 3.5 – 4.5) of the NimNotebookAI project. The primary focus is on enhancing data storage, introducing a notebook feature for tracking interactions, and implementing document management commands.

## 🎯 Goals for Spiral 3

1.  **Improved Metadata**: Enhance document and chunk metadata to include tags, source information, and positional data.
2.  **Store User Queries & Answers**: Persist a complete log of user queries and AI-generated answers in a dedicated notebook.
3.  **`notebook` Command**: Introduce a CLI command to view past interactions for specific documents.

## 🛠️ Detailed Tasks and Implementation

### Task 1: Extend Database Schema (`database.nim`)

**Objective**: Modify the SQLite database schema to support new metadata fields and a `notebook` table.

**Details**:

*   **`documents` table**: Consider adding columns for more detailed source information (e.g., `source_url`, `original_filename` if different from `file_path`). For now, `file_path` serves as a basic source.
*   **`chunks` table**: Add columns for positional metadata if needed (e.g., `page_number`, `start_offset`, `end_offset`). This will require updates to `dochandler.nim` and `chunker.nim` to extract and store this information during the upload process.
*   **New `notebook` table**: Create a new table to store user interactions. This table should link to `documents` and store the query, the AI's answer, and a timestamp.

    **Proposed `notebook` table schema:**
    ```sql
    CREATE TABLE IF NOT EXISTS notebook (
      id INTEGER PRIMARY KEY,
      document_id INTEGER NOT NULL,
      query_text TEXT NOT NULL,
      answer_text TEXT NOT NULL,
      timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (document_id) REFERENCES documents(id)
    );
    ```

*   **Update `database.nim`**: Implement new `proc`s for:
    *   `addNotebookEntry(docId: int, query: string, answer: string)`: Inserts a new entry into the `notebook` table.
    *   `listNotebookEntries(docId: int): seq[NotebookEntry]`: Retrieves all notebook entries for a given document ID.

**Interfaces to Use/Modify**:

*   `src/database.nim`: Modify `setupDatabase` and add new `proc`s.
*   `src/dochandler.nim`: Potentially modify `extractText` to capture positional data (e.g., page numbers for PDFs) if `page_number` is added to `chunks`.
*   `src/chunker.nim`: If positional data is captured, `chunkText` might need to propagate this information to the chunks.

### Task 2: `history.nim`: Load and Replay Q&A per Document

**Objective**: Create a new module to manage and display the interaction history for documents.

**Details**:

*   Create a new file: `src/history.nim`.
*   This module will primarily interact with the `notebook` table in the database.
*   It should provide a function to retrieve and format the history for display.

**Proposed `history.nim` interfaces:**

```nim
# src/history.nim
import database

proc getDocumentHistory*(docId: int): seq[NotebookEntry] =
  ## Retrieves the Q&A history for a specific document.
  let db = getDatabase()
  return db.listNotebookEntries(docId)

proc displayDocumentHistory*(docId: int) =
  ## Formats and prints the Q&A history for a document to the console.
  ## This will be called by the `notebook` CLI command.
  let history = getDocumentHistory(docId)
  if history.len == 0:
    echo "No history found for this document."
  else:
    echo "\n--- Document History ---"
    for entry in history:
      echo "Query: ", entry.queryText
      echo "Answer: ", entry.answerText
      echo "Timestamp: ", entry.timestamp
      echo "------------------------"
```

**Interfaces to Use/Modify**:

*   `src/history.nim` (new file)
*   `src/clihandler.nim`: Add a new `handleNotebook(docId: int)` proc that calls `history.displayDocumentHistory`.
*   `src/notebookml.nim`: Add a new CLI option `--notebook:<doc_id>` to route to `clihandler.handleNotebook`.

### Task 3: Implement `delete`, `tag`, `rename` Commands

**Objective**: Provide CLI commands for managing documents.

**Details**:

*   **`delete` command**: Allows users to remove a document and all its associated chunks and notebook entries from the database. This will require careful handling of foreign key constraints.
    *   **Proposed CLI**: `notebookml --delete:<doc_id>`
    *   **Implementation**: Add `deleteDocument(docId: int)` to `database.nim`. This `proc` should delete from `chunks` and `notebook` tables first, then from the `documents` table.
*   **`tag` command**: Allows users to add or remove tags from documents. This will likely require a new `tags` table and a many-to-many relationship table (`document_tags`).
    *   **Proposed CLI**: `notebookml --tag:<doc_id> --add:<tag_name>` or `notebookml --tag:<doc_id> --remove:<tag_name>`
    *   **Implementation**: Add `addTag(docId: int, tag: string)` and `removeTag(docId: int, tag: string)` to `database.nim`. Update `Document` type to include `tags: seq[string]`.
*   **`rename` command**: Allows users to change the `file_name` of a document in the database.
    *   **Proposed CLI**: `notebookml --rename:<doc_id> --new_name:<new_file_name>`
    *   **Implementation**: Add `renameDocument(docId: int, newName: string)` to `database.nim`.

**Interfaces to Use/Modify**:

*   `src/database.nim`: Add new `proc`s for `deleteDocument`, `addTag`, `removeTag`, `renameDocument`.
*   `src/clihandler.nim`: Add new `proc`s: `handleDelete(docId: int)`, `handleTag(docId: int, tag: string, action: string)`, `handleRename(docId: int, newName: string)`.
*   `src/notebookml.nim`: Add new CLI options to route to the respective `clihandler` procs.

## 🔍 Risks to Consider

*   **Schema Changes**: Ensure backward compatibility or provide migration scripts if the database schema changes significantly in future spirals.
*   **DB Consistency**: Implement robust error handling and transactions (where appropriate) to maintain data integrity, especially during `delete` operations.
*   **CLI Parsing**: The `parseopt` module needs to handle multiple arguments for commands like `tag` and `rename` effectively.

This guide provides a roadmap for implementing Spiral 3. Remember to write unit tests for all new database interactions and CLI commands to ensure correctness and stability.