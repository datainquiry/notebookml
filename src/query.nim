#
# @file query.nim
# @author Jaime Lopez
# @brief Orchestrates turning a user query into a context-aware AI-generated answer.

import json
import httpclient

import database
import embeddings
import config

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
  ## Generates an embedding for the query and finds relevant chunks.
  echo "Generating embedding for query..."
  let queryVector = getEmbedding(query)

  echo "Finding relevant chunks..."
  let db = getDatabase()
  result = db.findSimilarChunks(queryVector, topK = 10)

proc constructPrompt(query: string, chunks: seq[Chunk]): string =
  ## Constructs the prompt for the LLM based on the query, relevant chunks, and conversation history.
  var context = ""
  for chunk in chunks:
    context &= chunk.text & "\n\n"

  result = "Document Context:\n---\n" & context & "---\n\nQuestion: " & query & "\n\nAnswer:"

proc callLlm(prompt: string): string =
  ## Calls the LLM (Ollama) with the constructed prompt and returns the answer.
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
    let response = client.post(config.ollamaUrl & "/api/generate", body = $requestBody)
    if response.status != "200 OK":
      raise newException(Exception, "Error from LLM: " & response.body)
    
    let parsedResponse = to(parseJson(response.body), OllamaGenerateResponse)
    result = parsedResponse.response

  except HttpRequestError as e:
    raise newException(Exception, "Failed to connect to Ollama. Is it running? Error: " & config.ollamaUrl & "/api/generate. Error: " & e.msg)
  except JsonParsingError as e:
    raise newException(Exception, "Failed to parse LLM response: " & e.msg)

proc answerQuery*(query: string): string =
  ## Orchestrates the process of getting an AI-generated answer.

  let db = getDatabase()

  # 1. Get relevant chunks
  let similarChunks = getRelevantChunks(query)

  if similarChunks.len == 0:
    return "I couldn't find relevant information for your query."

  # 2. Construct prompt
  let prompt = constructPrompt(query, similarChunks)

  # 3. Call LLM and get answer
  let answer = callLlm(prompt)

  # 4. Log the query and answer to the notebook
  var loggedDocIds: seq[int]
  for chunk in similarChunks:
    if not (chunk.documentId in loggedDocIds):
      db.addNotebookEntry(chunk.documentId, query, answer)
      loggedDocIds.add(chunk.documentId)

  return answer
