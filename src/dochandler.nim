#
# @file dochandler.nim
# @author Jaime Lopez
# @brief Manages file-specific operations like text extraction.
#

import os
import strutils
import osproc

proc extractText*(filePath: string): string =
  ## Extracts the full text content from a given file.
  ## It dispatches to the correct parser based on the file extension (`.txt`, `.md`, `.pdf`).
  ## Throws an exception if the file format is not supported or if `pdftotext` fails.

  if not fileExists(filePath):
    raise newException(IOError, "File not found: " & filePath)

  let extension = filePath.splitFile.ext.toLower
  case extension
  of ".txt", ".md":
    try:
      result = readFile(filePath)
    except IOError as e:
      raise newException(IOError, "Failed to read file: " & e.msg)
  of ".pdf":
    let (output, exitCode) = execCmdEx("pdftotext " & filePath.quoteShell & " -")
    if exitCode != 0:
      raise newException(Exception, "Failed to execute pdftotext. Make sure it's installed and in your PATH. Error: " & output)
    result = output
  else:
    raise newException(ValueError, "Unsupported file format: " & extension)
