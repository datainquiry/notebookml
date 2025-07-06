#
# @file config.nim
# @author Jaime Lopez
# @brief Handles loading and managing application configuration.
#

import json
import std/appdirs
import std/paths
import std/files

type
  Config* = object
    ollamaUrl*: string
    ollamaEmbeddingModel*: string
    ollamaQueryModel*: string
    ollamaTemperature*: float
    databasePath*: string
    outputViewer*: string
    systemPrompt*: string

var globalConfig*: Config

proc loadConfig*(filePath: string = "config.json") =
  ## Loads configuration from a JSON file.
  var configLoaded = false
  var triedPaths: seq[string] = @[]

  # Try loading from the specified filePath first (or default config.json in CWD)
  try:
    let content = readFile(filePath)
    let json = parseJson(content)

    globalConfig.ollamaUrl = json["ollamaUrl"].getStr()
    globalConfig.ollamaEmbeddingModel = json["ollamaEmbeddingModel"].getStr()
    globalConfig.ollamaQueryModel = json["ollamaQueryModel"].getStr()
    globalConfig.ollamaTemperature = json["ollamaTemperature"].getFloat()
    globalConfig.databasePath = json["databasePath"].getStr()
    globalConfig.outputViewer = json["outputViewer"].getStr()
    globalConfig.systemPrompt = json["systemPrompt"].getStr()
    configLoaded = true
  except Exception as e:
    triedPaths.add(filePath & " (Error: " & e.msg & ")")

  # If not loaded and using default filePath, try user config directory
  if not configLoaded and filePath == "config.json":
    let userConfigDir = getConfigDir() / Path("notebookml")
    let userConfigPath = userConfigDir / Path("notebookml.json")
    try:
      # Ensure the directory exists before trying to read
      if fileExists(userConfigPath):
        let content = readFile(userConfigPath.string)
        let json = parseJson(content)

        globalConfig.ollamaUrl = json["ollamaUrl"].getStr()
        globalConfig.ollamaEmbeddingModel = json["ollamaEmbeddingModel"].getStr()
        globalConfig.ollamaQueryModel = json["ollamaQueryModel"].getStr()
        globalConfig.ollamaTemperature = json["ollamaTemperature"].getFloat()
        globalConfig.databasePath = json["databasePath"].getStr()
        globalConfig.outputViewer = json["outputViewer"].getStr()
        configLoaded = true
      else:
        triedPaths.add(userConfigPath.string & " (File not found)")
    except Exception as e:
      triedPaths.add(userConfigPath.string & " (Error: " & e.msg & ")")

  if not configLoaded:
    echo "Error loading configuration. Tried the following paths:"
    for p in triedPaths:
      echo "- ", p
    echo "Please ensure a valid config.json exists in the current directory or notebookml.json in your user config directory." 
    quit(1)

proc getConfig*(): Config =
  ## Returns the loaded global configuration.
  return globalConfig
