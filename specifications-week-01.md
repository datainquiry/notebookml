# 📝 Specifications: Week 1

**Phase:** Spiral 1: CLI MVP – Core Engine
**Focus:** Foundational document parsing, chunking, and storage.
**Goal:** Establish a basic CLI to ingest documents and perform rudimentary text searches without AI integration.

---

## 1. Technical Specifications

### 1.1. CLI Interface (`main.nim`)

The application will be controlled via a command-line interface.

- **`nimnotebook upload <file_path>`**
  - **Action:** Ingests a new document.
  - **Process:**
    1.  Validates the file path and format (`.txt`, `.md`, `.pdf`).
    2.  Extracts text content based on file type.
    3.  Processes the text through the `chunker`.
    4.  Stores document metadata and text chunks in the SQLite database.
  - **Output:** Confirmation message, e.g., `[✓] Extracted N chunks from "document.pdf"`.

- **`nimnotebook list`**
  - **Action:** Displays all documents currently indexed in the database.
  - **Output:** A list of document names and their IDs.

- **`nimnotebook ask "<query_text>"`**
  - **Action:** Performs a simple, non-AI search for chunks containing the query text.
  - **Process:**
    1.  Executes a SQL `LIKE` query against the `text` column in the `chunks` table.
    2.  Retrieves the first matching chunk.
  - **Output:** The text of the matching chunk.

### 1.2. Document Ingestion & Text Extraction

- **Supported Formats:** `.txt`, `.md`, `.pdf`.
- **Extraction Logic:**
  - **`.txt` / `.md`:** Use standard Nim file I/O (`readFile`).
  - **`.pdf`:** Use an external CLI tool (`pdftotext`). The application will execute this tool as a shell command and capture its standard output.

### 1.3. Text Chunking (`chunker.nim`)

- **Strategy:** Fixed-size chunking.
- **Size:** Each chunk should be approximately 250-350 words. The chunker should try to break at the end of a sentence or paragraph to maintain context.
- **Metadata per Chunk:**
  - `document_id`: Foreign key linking to the parent document.
  - `chunk_index`: The sequential position of the chunk within the document (e.g., 0, 1, 2...).
  - `text`: The actual text content of the chunk.

### 1.4. Database Schema (`nimnotebook.db`)

A single SQLite database file will be used for storage.

- **`documents` table:**
  - `id` (INTEGER, PRIMARY KEY)
  - `file_name` (TEXT, NOT NULL)
  - `file_path` (TEXT, NOT NULL, UNIQUE)
  - `created_at` (TEXT, DEFAULT CURRENT_TIMESTAMP)

- **`chunks` table:**
  - `id` (INTEGER, PRIMARY KEY)
  - `document_id` (INTEGER, FOREIGN KEY `documents(id)`)
  - `chunk_index` (INTEGER, NOT NULL)
  - `text` (TEXT, NOT NULL)

### 1.5. Directory Structure

- **`src/main.nim`**: Handles CLI argument parsing and command routing.
- **`src/chunker.nim`**: Contains the logic for splitting text into chunks.
- **`nimnotebook.db`**: The SQLite database file, located in the project root.
- **`documents/`**: A directory in the project root for storing copies of the uploaded raw files (optional for Week 1, but good practice).

---

## 2. Acceptance Criteria

For the week's work to be considered complete, the following conditions must be met:

- [ ] **AC-1:** The `nimnotebook upload <file.txt>` command successfully reads the text file, splits it into chunks, and saves the document info and chunk data to the `nimnotebook.db` database.
- [ ] **AC-2:** The `nimnotebook upload <file.md>` command successfully reads the markdown file and stores its content as chunks.
- [ ] **AC-3:** The `nimnotebook upload <file.pdf>` command successfully calls `pdftotext`, captures the output, and stores the resulting text as chunks.
- [ ] **AC-4:** The `nimnotebook upload` command prints an error message if the specified file does not exist or is of an unsupported format.
- [ ] **AC-5:** The `nimnotebook list` command correctly queries the `documents` table and prints a list of all ingested `file_name` values to the console.
- [ ] **AC-6:** The `nimnotebook ask "some query"` command executes a case-insensitive `LIKE '%some query%'` search on the `chunks.text` column and prints the content of the first matching chunk.
- [ ] **AC-7:** If no chunk matches the `ask` query, the application prints a "No matching content found." message.
- [ ] **AC-8:** The SQLite database `nimnotebook.db` is created on the first run if it does not already exist.
- [ ] **AC-9:** The database schema (tables `documents` and `chunks`) matches the specification.
