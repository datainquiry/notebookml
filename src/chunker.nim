# 
# @file chunker.nim
# @author Jaime Lopez
# @brief Splits text into manageable, context-aware chunks.
#

import strutils

proc chunkText*(text: string, chunkSize: int = 300): seq[string] =
  ## Splits a large string of text into a sequence of smaller strings (chunks).
  ## This implementation is simplified to be more robust.
  ##
  ## Args:
  ##   text: The input text to be chunked.
  ##   chunkSize: The target number of words per chunk.
  ##
  ## Returns:
  ##   A sequence of strings, where each string is a text chunk.

  if text.len == 0:
    return @[]

  let words = text.split()
  if words.len <= chunkSize:
    return @[text]

  result = newSeq[string]()
  var currentChunkStart = 0
  while currentChunkStart < words.len:
    let currentChunkEnd = min(currentChunkStart + chunkSize, words.len)
    result.add(words[currentChunkStart..<currentChunkEnd].join(" "))
    currentChunkStart = currentChunkEnd
  
  return result
