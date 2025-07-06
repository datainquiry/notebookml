#
# @file test_chunker.nim
# @author Jaime Lopez
# @brief Unit tests for the chunker module.
#

import unittest
import strutils
import ../../src/chunker

suite "Text Chunking Tests (Simplified)":
  
  test "Chunking empty text":
    check chunkText("").len == 0

  test "Text shorter than chunk size returns a single chunk":
    let shortText = "This is a short sentence."
    let chunks = chunkText(shortText, chunkSize = 50)
    check chunks.len == 1
    check chunks[0] == shortText

  test "Basic chunking with small chunk size":
    let text = "One two three four five six seven eight nine."
    let chunks = chunkText(text, chunkSize = 3)
    check chunks.len == 3
    check chunks[0] == "One two three"
    check chunks[1] == "four five six"
    check chunks[2] == "seven eight nine."

  test "Chunking a long text with default chunk size":
    let singleBlock = "This is a sentence to be repeated for testing purposes." # No trailing space
    let longText = singleBlock.repeat(20) 
    let chunks = chunkText(longText, chunkSize = 100)
    check chunks.len == 2

    var totalWords = 0
    for chunk in chunks:
      totalWords += chunk.split().len
    
    check totalWords == longText.split().len
