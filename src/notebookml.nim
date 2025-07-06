#
# @file notebookml.nim
# @author Jaime Lopez
# @brief Exports the modules for the notebookml CLI.
#

import strutils
import parseopt
import clihandler
import config

proc showHelp() =
  echo "NotebookML CLI - A command line interface for NotebookML"
  echo "Usage:"
  echo "  notebookml --help                Show this help message"
  echo "  notebookml --init                Initialize the database"
  echo "  notebookml --upload:<file_path>  Upload a document"
  echo "  notebookml --list                List all uploaded documents"
  echo "  notebookml --ask:<query_text>    Ask a question"

when isMainModule:
  loadConfig()
  var p = initOptParser()
  var filePath: string
  var query: string
  for kind, key, val in p.getopt():
    case kind
    of cmdLongOption:
      case key.toLower
      of "init":
        handleInit()
      of "upload":
        filePath = val
        handleUpload(filePath)
      of "list":
        handleList()
      of "ask":
        query = val
        handleAsk(query)
      of "help":
        showHelp()
      else:
        echo "Unknown command or missing value for option: ", key
    of cmdArgument:
      echo "Unknown argument: ", key
    else:
      discard
