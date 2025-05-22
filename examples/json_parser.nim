import npeg

# A complete JSON parser that validates JSON documents
let jsonParser = peg "doc":
  S              <- *Space
  jtrue          <- "true"
  jfalse         <- "false"
  jnull          <- "null"

  unicodeEscape  <- 'u' * Xdigit[4]
  escape         <- '\\' * ({ '{', '"', '|', '\\', 'b', 'f', 'n', 'r', 't' } | unicodeEscape)
  stringBody     <- ?escape * *( +( {'\x20'..'\xff'} - {'"'} - {'\\'}) * *escape)
  jstring         <- ?S * '"' * stringBody * '"' * ?S

  minus          <- '-'
  intPart        <- '0' | (Digit-'0') * *Digit
  fractPart      <- "." * +Digit
  expPart        <- ( 'e' | 'E' ) * ?( '+' | '-' ) * +Digit
  jnumber         <- ?minus * intPart * ?fractPart * ?expPart

  doc            <- JSON * !1
  JSON           <- ?S * ( jnumber | jobject | jarray | jstring | jtrue | jfalse | jnull ) * ?S
  jobject        <- '{' * ( jstring * ":" * JSON * *( "," * jstring * ":" * JSON ) | ?S ) * "}"
  jarray         <- "[" * ( JSON * *( "," * JSON ) | ?S ) * "]"

# Test the parser
doAssert jsonParser.match("""{"name": "John", "age": 30, "city": "New York"}""").ok
doAssert jsonParser.match("""[1, 2, 3, "hello", true, null]""").ok
doAssert jsonParser.match("""{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}""").ok
doAssert jsonParser.match("""{"nested": {"array": [1, 2, {"deep": true}]}}""").ok

echo "All JSON tests passed!"