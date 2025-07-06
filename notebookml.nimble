# Package

version       = "0.1.0"
author        = "Jaime Lopez"
description   = "A AI notebook for literature review"
license       = "MIT"
srcDir        = "src"
bin           = @["notebookml"]

task test, "Runs the tests":
  exec "nim c -r --path:src tests/test_database.nim"
  exec "nim c -r --path:src tests/test_chunker.nim"

# Dependencies

requires "nim >= 2.0.8"

requires "db_connector >= 0.1.0"