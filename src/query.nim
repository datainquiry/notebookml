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

proc answerQuery*(query: string): string =
  ## 1. Gets an embedding for the user's query.
  ## 2. Finds relevant chunks from the vector store.
  ## 3. Constructs a prompt and sends it to the LLM.
  ## 4. Returns the final answer.

  let config = getConfig()

  # 1. Get embedding for the query
  echo "Generating embedding for query..."
  let queryVector = getEmbedding(query)

  # 2. Find relevant chunks
  echo "Finding relevant chunks..."
  let db = getDatabase()
  let similarChunks = db.findSimilarChunks(queryVector, topK = 3)

  if similarChunks.len == 0:
    return "I couldn't find relevant information for your query."

  # 3. Construct a prompt
  echo "Found relevant context. Generating answer..."
  var context = ""
  for chunk in similarChunks:
    context &= chunk.text & "\n\n"
  
  let prompt = "Context:\n---\n" & context & "---\n\nQuestion: " & query & "\n\nAnswer:"

  # 4. Send to LLM and get answer
  let client = newHttpClient()
  defer: client.close()

  let systemPrompt = "You are a helpful assistant. Answer the question truthfully and concisely. If the answer is not in the provided context, respond with 'I couldn't find relevant information for your query.'"

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
      return "Error from LLM: " & response.body
    
    let parsedResponse = to(parseJson(response.body), OllamaGenerateResponse)
    result = parsedResponse.response

  except HttpRequestError as e:
    return "Failed to connect to Ollama. Is it running? Error: " & config.ollamaUrl & "/api/generate. Error: " & e.msg
  except JsonParsingError as e:
    return "Failed to parse LLM response: " & e.msg
