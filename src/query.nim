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
    temperature*: float

  OllamaGenerateResponse = object
    response*: string

proc getRelevantChunks(query: string): seq[Chunk] =
  ## Generates an embedding for the query and finds relevant chunks.
  echo "Generating embedding for query..."
  let queryVector = getEmbedding(query)

  echo "Finding relevant chunks..."
  let db = getDatabase()
  result = db.findSimilarChunks(queryVector, topK = 3)

proc constructPrompt(query: string, chunks: seq[Chunk], history: seq[NotebookEntry]): string =
  ## Constructs the prompt for the LLM based on the query, relevant chunks, and conversation history.
  var context = ""
  for chunk in chunks:
    context &= chunk.text & "\n\n"

  var historyText = ""
  if history.len > 0:
    historyText = "Conversation History:\n"
    for entry in history:
      historyText &= "- Q: " & entry.queryText & "\n"
      historyText &= "  A: " & entry.answerText & "\n"
    historyText &= "\n"
  
  result = historyText & "Document Context:\n---\n" & context & "---\n\nQuestion: " & query & "\n\nAnswer:"

proc callLlm(prompt: string): string =
  ## Calls the LLM (Ollama) with the constructed prompt and returns the answer.
  let config = getConfig()
  let client = newHttpClient()
  defer: client.close()

  let systemPrompt = "You are a helpful assistant. Answer the question truthfully and concisely. Format your response using Markdown. If the answer is not in the provided context, respond with 'I couldn't find relevant information for your query.'"

  let requestBody = %*OllamaGenerateRequest(
    model: config.ollamaQueryModel,
    prompt: prompt,
    stream: false,
    system: systemPrompt,
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
  echo "Found relevant context. Generating answer..."
  var history: seq[NotebookEntry]
  if similarChunks.len > 0:
    let primaryDocId = similarChunks[0].documentId
    history = db.listNotebookEntries(primaryDocId)

  let prompt = constructPrompt(query, similarChunks, history)

  # 3. Call LLM and get answer
  let answer = callLlm(prompt)

  # 4. Log the query and answer to the notebook
  var loggedDocIds: seq[int]
  for chunk in similarChunks:
    if not (chunk.documentId in loggedDocIds):
      db.addNotebookEntry(chunk.documentId, query, answer)
      loggedDocIds.add(chunk.documentId)

  return answer
