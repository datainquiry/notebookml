import unittest
import ../../src/embeddings
import ../../src/config
import httpclient

proc isOllamaRunning(): bool =
  loadConfig()
  let config = getConfig()
  try:
    let client = newHttpClient()
    defer: client.close()
    let response = client.get(config.ollamaUrl)
    return response.status == "200 OK"
  except HttpRequestError:
    echo "Ollama is not running."
    return false

suite "Embeddings Module Tests":
  test "Get embedding from Ollama":
    if not isOllamaRunning():
      skip()

    let text = "This is a test sentence."
    let embedding = getEmbedding(text)

    check embedding.len > 0
    # The embedding for mxbai-embed-large should have a dimension of 1024
    check embedding.len == 1024
