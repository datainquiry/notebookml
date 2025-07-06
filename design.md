# 📘 Design Document – Local NotebookLM Clone in Nim

**Project Name**: `NimNotebookAI`
**Author**: Jaime Lopez
**Purpose**: Create a local application that allows users to upload and query documents (PDF, Markdown, etc.) using natural language. The app will leverage local LLMs (e.g. via Ollama) and embedding search, built primarily in Nim.

---

## 1. 🎯 Objectives

* Enable offline, private AI-powered document querying
* Accept common document types (PDF, TXT, MD)
* Generate local embeddings and store them for semantic search
* Retrieve document context and use a local LLM (e.g., LLaMA 3) to answer questions
* Provide a CLI or desktop UI (CLI MVP → Tauri frontend optional)

---

## 2. 🧱 System Architecture

```
         ┌─────────────┐
         │   Documents │
         └─────┬───────┘
               │
               ▼
     ┌────────────────────┐
     │ Text Extractor     │ ◄───── PDF/MD parser (CLI tools)
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ Text Chunker       │ ◄───── Chunks content into passages
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ Embedder (Ollama)  │ ◄───── HTTP call to local embedding model
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ Vector Store        │ ◄───── SQLite + vector math
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ Query Engine       │ ◄───── Cosine similarity + context fetching
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ LLM (Ollama)       │ ◄───── Prompt + context → Response
     └────────┬───────────┘
              ▼
     ┌────────────────────┐
     │ CLI / UI Output    │
     └────────────────────┘
```

---

## 3. 🧩 Components

### 3.1 Document Ingestion

* **Formats**: `.pdf`, `.md`, `.txt`
* **Tooling**:

  * `pdftotext` or `mutool` for PDF
  * Built-in Nim file reading for `.md`/`.txt`

### 3.2 Text Chunking

* Fixed-size or sentence-aware chunking (e.g. 200–300 words)
* Metadata stored: filename, chunk index, character position

### 3.3 Embedding Generation

* Via **Ollama HTTP API**:

  * Call `http://localhost:11434/api/embeddings`
  * Use `llama3` or `nomic-embed-text`

### 3.4 Vector Store

* Store in **SQLite**:

  * `chunks` table: id, document\_id, text, embedding (array stored as JSON or binary)
* Simple cosine similarity using dot product
* Optional: pre-filter by document ID or tags

### 3.5 Query Engine

* Get embedding for user query
* Find top-k similar chunks via cosine distance
* **Retrieve relevant past queries and answers from the notebook history.**
* Concatenate chunk texts and relevant conversation history as context.
* Send prompt + augmented context to LLM for generation.

### 3.6 LLM Integration

* Call Ollama API (`/generate`)
* Prompt structure (augmented with history):

```text
You are a helpful assistant. Answer the question truthfully and concisely.
If the answer is not in the provided context, respond with 'I couldn't find relevant information for your query.'

Conversation History:
{past_queries_and_answers}

Document Context:
{chunk_texts}

Question: {user_question}
Answer:
```

---

## 4. 🖥️ User Interface

### 4.1 CLI (MVP)

* `upload <file>` – Parse and index document
* `ask <question>` – Query indexed documents
* `list` – Show indexed documents

### 4.2 Optional GUI (Phase 2)

* **Frontend**: Tauri + React or Svelte
* Features:

  * Document upload
  * Chat-style question interface
  * Show context used in response

---

## 5. 🛠️ Tools & Libraries

| Task              | Tool                                          |
| ----------------- | --------------------------------------------- |
| Language          | Nim                                           |
| PDF Parsing       | `pdftotext` CLI or C binding                  |
| HTTP Requests     | `httpclient` module                           |
| JSON Handling     | `json`, `jsony`, or `flatty`                  |
| SQLite            | `db_sqlite`                                   |
| Cosine similarity | Manual Nim implementation                     |
| Vector ops        | `seqmath` (or write custom dot/cos functions) |
| Local LLM         | [Ollama](https://ollama.com/)                 |
| UI (future)       | Tauri + React or GTK with Nim bindings        |

---

## 6. 🔒 Privacy & Offline Use

* No cloud calls; all data and models are local
* Embeddings and documents stored locally in `~/.nimnotebook`
* Ideal for journalists, researchers, students, and privacy-conscious users

---

## 7. 🚧 Future Improvements

* Metadata tagging, search filters
* Citing source positions in documents
* Summarization view per document
* Audio-to-text (e.g., Whisper integration)
* Sync between machines (via local network or file export)

---

## 8. 📝 Example CLI Session

```bash
$ nimnotebook upload article.pdf
[✓] Extracted 12 chunks from "article.pdf"

$ nimnotebook ask "What is the main argument of the author?"
[✓] Answer generated using 3 chunks:

🧠 Answer:
The author argues that decentralization improves resilience by...

📄 Source: article.pdf (pg. 3–4)
```

---

## 9. 📦 Directory Structure

```
nimnotebook/
├── src/
│   ├── main.nim
│   ├── chunker.nim
│   ├── embeddings.nim
│   ├── llm.nim
│   ├── vectorstore.nim
│   └── query.nim
├── tools/
│   └── pdf2text.sh
├── docs/
├── README.md
├── nimnotebook.db
└── config.yaml
```
