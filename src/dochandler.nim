import os
import strutils
import osproc

proc extractText*(filePath: string): string =
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
    let (output, exitCode) = execCmdEx("pdftotext " & filePath.quoteShell &
      " -")
    if exitCode != 0:
      raise newException(Exception,
        "Failed to execute pdftotext. Error: " &
        output)
    result = output
  else:
    raise newException(ValueError, "Unsupported file format: " & extension)
