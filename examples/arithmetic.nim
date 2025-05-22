import npeg

# Simple arithmetic expression parser
let parser = peg "line":
  exp      <- term   * *( ('+'|'-') * term)
  term     <- factor * *( ('*'|'/') * factor)
  factor   <- +{'0'..'9'} | ('(' * exp * ')')
  line     <- exp * !1

doAssert parser.match("3*(4+15)+2").ok
doAssert parser.match("42").ok
doAssert parser.match("(10+5)*3").ok

# Example with captures
var operations: seq[(string, string, string)] = @[]

let calcParser = peg "line":
  exp      <- term * *(>{'+'|'-'} * term):
    operations.add(($1, $0, $2))
  term     <- factor * *(>{'*'|'/'} * factor):
    operations.add(($1, $0, $2))
  factor   <- +{'0'..'9'} | ('(' * exp * ')')
  line     <- exp * !1

discard calcParser.match("3*(4+15)+2")
echo operations  # Shows the order of operations captured