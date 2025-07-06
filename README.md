# NotebookML

## Overview

NotebookML is a command-line interface (CLI) tool designed to help you interact
with your documents and notes using a local Large Language Model (LLM) via
Ollama. It allows you to upload documents, ask questions based on their
content, manage tags, view conversation history, and more.

## Features

- **Document Upload:** Upload text documents, PDFs, and Markdown files. The
  content is chunked and embedded for efficient retrieval.
- **Contextual Q&A:** Ask questions about your uploaded documents, and
  NotebookML will provide AI-generated answers based on the most relevant
  information.
- **Document Management:**
    - List all uploaded documents.
    - View Q&A history for specific documents.
    - Delete documents and their associated data.
    - Add and remove tags from documents.
    - Rename documents.
- **Tag Management:** List all available tags.
- **Custom Database:** Specify a custom SQLite database file for your data.
- **Configurable Output Viewer:** Use your preferred command-line tool (e.g.,
  `cat`, `glow`) to display output.

## Installation

### Prerequisites

- **Nim:** Ensure you have Nim installed. You can follow the official
  installation guide:
  [https://nim-lang.org/install.html](https://nim-lang.org/install.html)
- **Ollama:** Download and install Ollama from
  [https://ollama.ai/](https://ollama.ai/). Make sure you have at least one
  model downloaded (e.g., `ollama pull llama2`).
- **`db_connector` Nimble Package:** ```bash nimble install db_connector ```

### Building NotebookML

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/notebookml.git
   cd notebookml
   ```
   
3. Compile the project:

   ```bash
   nim c -o:notebookml src/notebookml.nim
   ```
   
   This will create an executable named `notebookml` in your project directory.

## Configuration

NotebookML uses a `config.json` file for its settings. You can place this file
in the current working directory or in your user's configuration directory
(`~/.config/notebookml/notebookml.json` on Linux).

Here's an example `config-example.json`:

```json
{
  "ollamaUrl": "http://localhost:11434",
  "ollamaEmbeddingModel": "nomic-embed-text",
  "ollamaQueryModel": "llama2",
  "ollamaTemperature": 0.2,
  "databasePath": "notebookml.db",
  "outputViewer": "glow -s dark"
}
```

- `ollamaUrl`: The URL where your Ollama instance is running.
- `ollamaEmbeddingModel`: The Ollama model to use for generating embeddings
  (e.g., `nomic-embed-text`).
- `ollamaQueryModel`: The Ollama model to use for answering queries (e.g.,
  `llama2`).
- `ollamaTemperature`: The temperature setting for the LLM (0.0 to 1.0).
- `databasePath`: The path to your SQLite database file.
- `outputViewer`: (Optional) A command-line tool to use for displaying output.
  For example, `glow -s dark` for Markdown rendering, or `cat` for plain text.
  If not specified, output will be printed directly to the console.

## Usage

All commands are executed via the `notebookml` executable.

```bash
./notebookml --help
```

### Commands:

-   **Show Help:**

    ```bash
    ./notebookml --help
    ```

-   **Initialize Database:**

    Initializes the SQLite database, creating necessary tables. This is
    required before uploading documents.

    ```bash
    ./notebookml --init
    ```

-   **Upload a Document:**

    Uploads a document (text, PDF, Markdown) to the database.

    ```bash
    ./notebookml --upload:/path/to/your/document.txt
    ./notebookml --upload:/path/to/your/document.pdf
    ./notebookml --upload:/path/to/your/document.md
    ```

-   **List Documents:**

    Lists all uploaded documents. Optionally filter by tag.

    ```bash
    ./notebookml --list
    ./notebookml --list:mytag
    ```

-   **Ask a Question:**

    Asks a question based on the content of your uploaded documents.

    ```bash
    ./notebookml --ask:"What is the main topic of the uploaded documents?"
    ```

-   **View Notebook History:**

    Displays the Q&A history for a specific document.

    ```bash
    ./notebookml --notebook:<document_id>
    ```
  
    (You can find `document_id` using the `--list` command.)

-   **Delete a Document:**

    Deletes a document and all its associated chunks and notebook entries.

    ```bash
    ./notebookml --delete:<document_id>
    ```

-   **Add/Remove Tag:**

    Adds or removes a tag from a document.

    ```bash
    ./notebookml --tag:<document_id>:add:my_new_tag
    ./notebookml --tag:<document_id>:remove:my_old_tag
    ```

-   **Rename a Document:**

    Renames an uploaded document.

    ```bash
    ./notebookml --rename:<document_id>:new_document_name.txt
    ```

-   **List All Tags:**

    Displays all unique tags currently in the database.

    ```bash
    ./notebookml --tags
    ```

## Testing

NotebookML uses `testament` for running tests.

1.  Ensure `testament` is installed:

    ```bash
    nimble install testament
    ```
3.  Run all tests:

    ```bash
    testament all
    ```
