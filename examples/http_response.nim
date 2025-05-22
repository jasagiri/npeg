import npeg, strutils, tables

type
  Request = object
    proto: string
    version: string
    code: int
    message: string
    headers: Table[string, string]

# HTTP grammar (simplified)

let parser = peg("http", userdata: Request):
  space       <- ' '
  crlf        <- '\n' * ?'\r'
  url         <- +(Alpha | Digit | '/' | '_' | '.')
  eof         <- !1
  header_name <- +(Alpha | '-')
  header_val  <- +(1-{'\n'}-{'\r'})
  proto       <- >+Alpha:
    userdata.proto = $1
  version     <- >(+Digit * '.' * +Digit):
    userdata.version = $1
  code        <- >+Digit:
    userdata.code = parseInt($1)
  msg         <- >(+(1 - '\r' - '\n')):
    userdata.message = $1
  header      <- >header_name * ": " * >header_val:
    userdata.headers[$1] = $2
  response    <- proto * '/' * version * space * code * space * msg
  headers     <- *(header * crlf)
  http        <- response * crlf * headers * eof


# Parse the data and print the resulting table

const data = """
HTTP/1.1 301 Moved Permanently
Content-Length: 162
Content-Type: text/html
Location: https://nim.org/
"""

var request: Request
let res = parser.match(data, request)
echo request

# Output:
# (
#   proto: "HTTP",
#   version: "1.1",
#   code: 301,
#   message: "Moved Permanently",
#   headers: {
#     "Content-Length": "162",
#     "Content-Type": "text/html",
#     "Location": "https://nim.org/"
#   }
# )