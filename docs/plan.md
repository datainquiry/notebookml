# 📆 Development Plan – NimNotebookAI (Spiral Model)

### 👷 Project Manager: Jaime Lopez

### 🧱 Methodology: **Spiral Model** (Risk-driven, iterative)

### 📍 Duration: \~6–8 weeks (adjustable per availability)

---

## 🔁 Spiral Model Overview

Each **spiral loop** includes:

1. **Planning**: Define objectives, constraints, and deliverables
2. **Risk Analysis**: Identify risks, evaluate alternatives
3. **Development/Prototyping**: Build and test incrementally
4. **Evaluation**: User/tester feedback → iterate

---

## 🔄 Phase Overview

| Phase    | Name                           | Focus                                |
| -------- | ------------------------------ | ------------------------------------ |
| Spiral 1 | CLI MVP Core                   | Foundation: Document parsing + query |
| Spiral 2 | LLM + Vector Search            | Query engine and AI answering        |
| Spiral 3 | Robust Storage + Notebook Mode | Indexing and document history        |
| Spiral 4 | Optional GUI                   | Interactive UI (Tauri or GTK)        |
| Spiral 5 | Extensions + Optimization      | Summarization, tagging, citations    |

---

## 📅 Detailed Schedule

---

### 🔁 **Spiral 1: CLI MVP – Core Engine**

🗓️ **Week 1 – 1.5**

#### ✅ Goals:

* Basic CLI with commands: `upload`, `ask`, `list`
* Text extraction from `.txt`, `.md`, `.pdf`
* Chunking logic with metadata storage

#### 🛠️ Tasks:

* `main.nim`: CLI routing
* `chunker.nim`: Paragraph/sentence chunker
* Shell wrapper for `pdftotext`
* `documents/` folder for raw files
* Basic SQLite storage: file info + chunks

#### 🎯 Deliverable:

> `nimnotebook upload file.pdf` and `ask "..."` returns matching chunk (no AI yet)

#### 🔍 Risks:

* PDF extraction inconsistencies
* CLI parsing (arg parse) bugs

---

### 🔁 **Spiral 2: Embeddings + AI Querying**

🗓️ **Week 2 – 3**

#### ✅ Goals:

* Integrate local LLM (Ollama) for embeddings + answers
* Vector search with cosine similarity
* Embed chunks and store them in SQLite

#### 🛠️ Tasks:

* `embeddings.nim`: Call Ollama embeddings
* `vectorstore.nim`: Store + retrieve chunk vectors
* `query.nim`: Search and rank by cosine distance
* Prompt template to call LLM for contextual answers

#### 🎯 Deliverable:

> `ask "What’s the main idea?"` returns LLM-generated answer with cited chunk

#### 🔍 Risks:

* Ollama model compatibility
* Performance on large text sets

---

### 🔁 **Spiral 3: Storage, Indexing & Notebook Mode**

🗓️ **Week 3.5 – 4.5**

#### ✅ Goals:

* Improved metadata: tags, source, positions
* Store full user queries + answers in a notebook log
* Add `notebook` command to view past interactions

#### 🛠️ Tasks:

* Extend database schema: `notebook` table
* `history.nim`: Load and replay Q\&A per document
* Implement `delete`, `tag`, `rename` commands

#### 🎯 Deliverable:

> Ability to explore document-specific notebooks, track what you asked

#### 🔍 Risks:

* Schema changes may break older indexes
* Managing DB consistency across commands

---

### 🔁 **Spiral 4: Optional GUI (Tauri or GTK)**

🗓️ **Week 5 – 6**

#### ✅ Goals:

* Create local UI with drag-and-drop file upload, chat input
* View document chunks and answers with highlights
* Package app for Linux/macOS/Windows

#### 🛠️ Tasks:

* UI built in Tauri (recommended) or Nim GTK
* Backend → expose REST or IPC endpoints
* Frontend: Document viewer, input form, answer display

#### 🎯 Deliverable:

> Local app resembling NotebookLM: ask + see cited content

#### 🔍 Risks:

* IPC between Nim and Tauri (can use subprocess fallback)
* Layout polish and error handling

---

### 🔁 **Spiral 5: Advanced Features**

🗓️ **Week 6.5 – 8**

#### ✅ Goals:

* Summarization per document
* Auto-tagging with LLM
* Inline citation linking (chunk → original page)

#### 🛠️ Tasks:

* Add `summarize` command per document
* Use LLM to suggest tags per doc
* UI/CLI improvements for source tracing

#### 🎯 Deliverable:

> Highly usable personal AI research assistant with smart tools

#### 🔍 Risks:

* Prompt engineering for summarization
* Token limits for large doc summaries

---

## ✅ Milestone Summary

| Week | Deliverable                                  |
| ---- | -------------------------------------------- |
| 1    | CLI MVP: Upload + chunking                   |
| 3    | Ask questions with context-aware LLM answers |
| 4.5  | Document notebooks + query history           |
| 6    | GUI (Tauri app)                              |
| 8    | Summarization + citations + tag system       |

---

## 📦 Project Management Suggestions

* Use Git and semantic commits (`feat:`, `fix:`, etc.)
* Organize tasks via GitHub Projects or Trello board
* Write unit tests for chunking, vector math, and DB logic
* Document API calls and CLI usage early
