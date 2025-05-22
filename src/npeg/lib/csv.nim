## CSV parser library for NPeg
## 
## This module provides a CSV (Comma-Separated Values) parser that handles
## quoted fields, escaped quotes, and various delimiters.

import ../../npeg
import strutils

# Generic CSV parser with configurable delimiter
template csvParser*(delimiter: char = ','): untyped =
  peg "csv":
    csv <- record * *(lineEnd * record) * ?lineEnd * !1
    record <- field * *(delimiter * field)
    field <- quotedField | unquotedField
    
    quotedField <- '"' * >(*(escape | (!'"' * 1))) * '"':
      push($1.replace("\"\"", "\""))
    
    unquotedField <- >*(!{delimiter, '\r', '\n'} * 1):
      push($1)
    
    escape <- "\"\"" # Escaped quote
    lineEnd <- '\r' * ?'\n' | '\n'

# Standard CSV parser
let csvStandard* = csvParser(',')

# Tab-separated values parser
let tsvParser* = csvParser('\t')

# Custom parser example for ';' delimiter (common in Europe)
let csvSemicolon* = csvParser(';')

# Parser that collects records as sequences
proc csvWithCapture*(): auto =
  result = peg("csv", rows: seq[seq[string]]):
    csv <- record * *(lineEnd * record) * ?lineEnd * !1
    record <- field * *(',' * field):
      var row: seq[string]
      for i in 1..capture.len-1:
        row.add(capture[i].s)
      rows.add(row)
    field <- quotedField | unquotedField
    
    quotedField <- '"' * >(*(escape | (!'"' * 1))) * '"':
      push($1.replace("\"\"", "\""))
    
    unquotedField <- >*(!{',' , '\r', '\n'} * 1):
      push($1)
    
    escape <- "\"\""
    lineEnd <- '\r' * ?'\n' | '\n'

# Helper proc to parse CSV to seq[seq[string]]
proc parseCSV*(input: string, delimiter: char = ','): seq[seq[string]] =
  let parser = csvWithCapture()
  let res = parser.match(input, result)
  if not res.ok:
    raise newException(NPegParseError, "Invalid CSV format")
  
# RFC 4180 compliant CSV parser
let csvRFC4180* = peg "csv":
  file <- (record * *(CRLF * record)) * ?CRLF * !1
  record <- field * *(COMMA * field)
  field <- (escaped | nonEscaped)
  escaped <- DQUOTE * *(TEXTDATA | COMMA | CR | LF | DDQUOTE) * DQUOTE
  nonEscaped <- *TEXTDATA
  COMMA <- ','
  CR <- '\r'
  DQUOTE <- '"'
  LF <- '\n'
  CRLF <- CR * LF
  TEXTDATA <- {'\x20'..'\x21', '\x23'..'\x2B', '\x2D'..'\x7E'}
  DDQUOTE <- DQUOTE * DQUOTE  # Escaped double quote