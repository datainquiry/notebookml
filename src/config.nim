#
# @file config.nim
# @author Jaime Lopez
# @brief Handles loading and managing application configuration.
#

import json
import os

type
  Config* = object
    ollamaUrl*: string
    ollamaEmbeddingModel*: string
    ollamaQueryModel*: string
    ollamaTemperature*: float
    databasePath*: string

var globalConfig*: Config

proc loadConfig*(filePath: string = "config.json") =
  ## Loads configuration from a JSON file.
  try:
    let content = readFile(filePath)
    let json = parseJson(content)

    globalConfig.ollamaUrl = json["ollamaUrl"].getStr()
    globalConfig.ollamaEmbeddingModel = json["ollamaEmbeddingModel"].getStr()
    globalConfig.ollamaQueryModel = json["ollamaQueryModel"].getStr()
    globalConfig.ollamaTemperature = json["ollamaTemperature"].getFloat()
    globalConfig.databasePath = json["databasePath"].getStr()

  except Exception as e:
    echo "Error loading configuration from ", filePath, ": ", e.msg
    echo "Please ensure config.json exists and is correctly formatted."
    quit(1)

proc getConfig*(): Config =
  ## Returns the loaded global configuration.
  return globalConfig
