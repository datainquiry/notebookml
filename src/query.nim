import std/[json, httpclient]
import database, embeddings, config

type
  OllamaGenerateRequest = object
    model*: string
    prompt*: string
    stream*: bool
    system*: string
    thinking*: bool
    temperature*: float

  OllamaGenerateResponse = object
    response*: string

proc getRelevantChunks(query: string): seq[Chunk] =
  let queryVector = getEmbedding(query)
  let db = getDatabase()
  result = db.findSimilarChunks(queryVector, topK = 10)

proc constructPrompt(query: string, chunks: seq[Chunk]): string =
  var context = ""
  for chunk in chunks:
    context &= chunk.text & "\n\n"
  result = "Document Context:\n---\n" &
    context &
    "---\n\nQuestion: " &
    query

proc callLlm(prompt: string): string =
  let config = getConfig()
  let client = newHttpClient()
  defer: client.close()
  let requestBody = %*OllamaGenerateRequest(
    model: config.ollamaQueryModel,
    prompt: prompt,
    stream: false,
    system: config.systemPrompt,
    thinking: false,
    temperature: config.ollamaTemperature
  )
  try:
    let response = client.post(config.ollamaUrl & "/api/generate",
      body = $requestBody)
    if response.status != "200 OK":
      raise newException(Exception, "Error from LLM: " & response.body)
    let parsedResponse = to(parseJson(response.body), OllamaGenerateResponse)
    result = parsedResponse.response
  except HttpRequestError as e:
    raise newException(Exception,
      "Failed to connect to Ollama. Is it running? `Error: " &
      config.ollamaUrl &
      "/api/generate. Error: " &
      e.msg)
  except JsonParsingError as e:
    raise newException(Exception, "Failed to parse LLM response: " & e.msg)

proc answerQuery*(query: string): string =
  let db = getDatabase()
  let similarChunks = getRelevantChunks(query)
  if similarChunks.len == 0:
    return "I couldn't find relevant information for your query."
  let prompt = constructPrompt(query, similarChunks)
  let answer = callLlm(prompt)
  var loggedDocIds: seq[int]
  for chunk in similarChunks:
    if not (chunk.documentId in loggedDocIds):
      db.addNotebookEntry(chunk.documentId, query, answer)
      loggedDocIds.add(chunk.documentId)
  return answer
