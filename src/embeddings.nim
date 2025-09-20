import std/[httpclient, json]
import config

type
  OllamaEmbeddingRequest = object
    model*: string
    prompt*: string
  
  OllamaEmbeddingResponse = object
    embedding*: seq[float]

proc getEmbedding*(text: string): seq[float] =
  let client = newHttpClient()
  defer: client.close()
  let config = getConfig()
  let requestBody = %*OllamaEmbeddingRequest(model: config.ollamaEmbeddingModel,
    prompt: text)
  try:
    let response = client.post(config.ollamaUrl & "/api/embeddings",
      body = $requestBody)
    if response.status != "200 OK":
      raise newException(Exception,
        "Failed to get embedding from Ollama. Status: " &
        response.status &
        " Body: " &
        response.body)
    let parsedResponse = to(parseJson(response.body), OllamaEmbeddingResponse)
    return parsedResponse.embedding
  except HttpRequestError as e:
    raise newException(Exception,
      "Failed to connect to Ollama at " &
      config.ollamaUrl &
      "/api/embeddings. Is Ollama running? Error: "
      & e.msg)
  except JsonParsingError as e:
    raise newException(Exception, "Failed to parse Ollama response: " & e.msg)
