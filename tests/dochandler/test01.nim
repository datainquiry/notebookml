import unittest
import os
import ../../src/dochandler
import osproc
import strutils

suite "dochandler tests":
  test "extractText from .txt file":
    let content = extractText("tests/dochandler/test.txt")
    check(content == "This is a test text file.")

  test "extractText from .md file":
    let content = extractText("tests/dochandler/test.md")
    check(content == "# This is a test markdown file.")

  test "extractText from non-existent file":
    expect IOError:
      discard extractText("tests/dochandler/nonexistent.txt")

  test "extractText from unsupported file type":
    expect ValueError:
      discard extractText("tests/dochandler/test.unsupported")

  test "extractText from .pdf file":
    if findExe("pdftotext") != "":
      let content = extractText("tests/dochandler/test.pdf")
      check(content.contains("Nim Destructors and Move Semantics"))
    else:
      skip()
