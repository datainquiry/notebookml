import std/strutils

proc chunkText*(text: string, chunkSize: int = 300): seq[string] =
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
