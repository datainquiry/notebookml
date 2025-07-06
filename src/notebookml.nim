#
# @file notebookml.nim
# @author Jaime Lopez
# @brief Exports the modules for the notebookml CLI.
#

import strutils
import parseopt
import clihandler
import config
import os
import times
import std/osproc

proc showHelp(): string =
  result = "**NotebookML CLI** - A command line interface for NotebookML\n" &
           "Usage:\n" &
           "  notebookml --help                                 Show this help message\n" &
           "  notebookml --init                                 Initialize the database\n" &
           "  notebookml --upload:<file_path>                   Upload a document\n" &
           "  notebookml --list:tag                             List all uploaded documents\n" &
           "  notebookml --ask:<query_text>                     Ask a question\n" &
           "  notebookml --notebook:<doc_id>                    View Q&A history for a document\n" &
           "  notebookml --delete:<doc_id>                      Delete a document and its data\n" &
           "  notebookml --tag:<doc_id>:<add|remove>:<tag_name> Add or remove a tag from a document\n" &
           "  notebookml --rename:<doc_id>:<new_name>           Rename a document\n" &
           "  notebookml --tags                                 List all available tags\n" &
           "  notebookml --db:<database_path>                   Specify a custom database file (overrides config)"

proc displayOutput(output: string) =
  let config = getConfig()
  if config.outputViewer.len > 0:
    # Write output to a temporary file and then use the viewer
    let timestamp = format(now(), "yyyyMMddHHmmss")
    let tempFile = getTempDir() / ("notebookml_output_" & timestamp & ".txt")
    writeFile(tempFile, output)
    let exitCode = execCmd(config.outputViewer & " " & tempFile)
    if exitCode != 0:
      echo "Warning: Output viewer command '" & config.outputViewer & "' exited with code ", exitCode
    removeFile(tempFile)
  else:
    echo output

proc runCli*() =

  loadConfig()
  var p = initOptParser()
  var filePath: string
  var query: string
  var commandProvided = false

  for kind, key, val in p.getopt():
    commandProvided = true
    case kind
    of cmdLongOption:
      case key.toLower
      of "init":
        displayOutput(handleInit())
      of "upload":
        filePath = val
        displayOutput(handleUpload(filePath))
      of "list":
        let tag = val.toLower
        displayOutput(handleList(tag))
      of "ask":
        query = val
        displayOutput(handleAsk(query))
      of "notebook":
        let docId = parseInt(val)
        displayOutput(handleNotebook(docId))
      of "delete":
        let docId = parseInt(val)
        displayOutput(handleDelete(docId))
      of "tag":
        let parts = val.split(':')
        if parts.len == 3:
          let docId = parseInt(parts[0])
          let action = parts[1]
          let tag = parts[2]
          displayOutput(handleTag(docId, tag, action))
        else:
          displayOutput("Invalid tag command. Usage: --tag:<doc_id>:<action>:<tag_name>")
      of "rename":
        let parts = val.split(':')
        if parts.len == 2:
          let docId = parseInt(parts[0])
          let newName = parts[1]
          displayOutput(handleRename(docId, newName))
        else:
          displayOutput("Invalid rename command. Usage: --rename:<doc_id>:<new_name>")
      of "tags":
        displayOutput(handleTags())
      of "help":
        displayOutput(showHelp())
      else:
        displayOutput("Unknown command or missing value for option: " & key)
    of cmdArgument:
      displayOutput("Unknown argument: " & key)
    else:
      discard

  if not commandProvided:
    displayOutput(showHelp())

when isMainModule:
  runCli()
