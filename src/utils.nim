import os

proc captureOutput*(procToRun: proc()) : string =
  let tempFile = getTempDir() / "caputure_" & $getCurrentProcessId() & ".txt"
  let file = open(tempFile, fmWrite)
  let oldStdout = stdout
  stdout = file
  try:
    procToRun()
  finally:
    stdout = oldStdout
    close(file)


