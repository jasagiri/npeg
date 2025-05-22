import npeg
import npeg/capture2
import strutils, tables

# Example of using the improved capture API

type
  Config = object
    settings: Table[string, string]
    numbers: Table[string, int]
    flags: Table[string, bool]

# Traditional capture approach
proc parseConfigOld() =
  echo "=== Traditional Capture API ==="
  
  var config: Config
  config.settings = initTable[string, string]()
  config.numbers = initTable[string, int]()
  config.flags = initTable[string, bool]()
  
  let parser = peg("config", c: Config):
    config <- *line
    line <- >key * value * EOL
    key <- +(Alpha | '_') * '='
    value <- stringVal | numberVal | boolVal
    stringVal <- '"' * >*(1-'"') * '"':
      c.settings[$1] = $2
    numberVal <- >+Digit:
      try:
        c.numbers[$1] = parseInt($2)
      except ValueError:
        fail()
    boolVal <- >("true" | "false"):
      c.flags[$1] = ($2 == "true")
    EOL <- '\n' | !1
  
  let configText = """
name="My App"
version=42
debug=true
"""
  
  let result = parser.match(configText, config)
  echo "Parse result: ", result.ok
  echo "Settings: ", config.settings
  echo "Numbers: ", config.numbers
  echo "Flags: ", config.flags

# New capture API approach
proc parseConfigNew() =
  echo "\n=== Improved Capture API ==="
  
  var config: Config
  config.settings = initTable[string, string]()
  config.numbers = initTable[string, int]()
  config.flags = initTable[string, bool]()
  
  let parser = peg("config", c: Config):
    config <- *line
    line <- >key * value * EOL
    key <- +(Alpha | '_') * '='
    value <- stringVal | numberVal | boolVal
    stringVal <- '"' * >*(1-'"') * '"':
      withCapture:
        c.settings[ctx[0]] = ctx[1]
    numberVal <- >+Digit:
      withCapture:
        try:
          c.numbers[ctx[0]] = ctx.asInt(1)
        except:
          ctx.fail("Invalid number format: " & ctx[1])
    boolVal <- >("true" | "false"):
      withCapture:
        c.flags[ctx[0]] = (ctx[1] == "true")
        ctx.validate(ctx[1] in ["true", "false"], "Boolean must be 'true' or 'false'")
    EOL <- '\n' | !1
  
  let configText = """
name="My App"
version=42
debug=true
"""
  
  let result = parser.match(configText, config)
  echo "Parse result: ", result.ok
  echo "Settings: ", config.settings
  echo "Numbers: ", config.numbers
  echo "Flags: ", config.flags

# Example with typed captures and validation
proc parseTypedData() =
  echo "\n=== Typed Captures and Validation ==="
  
  type
    Person = object
      name: string
      age: int
      active: bool
  
  var person: Person
  
  let parser = peg("person", p: Person):
    person <- name * age * active * !1
    name <- "name=" * >+PrintableAscii * '\n':
      withCapture:
        p.name = ctx[0]
    age <- "age=" * >+Digit * '\n':
      withCapture:
        p.age = ctx.asInt(0)
        ctx.validate(p.age >= 0 and p.age <= 150, "Age must be between 0 and 150")
    active <- "active=" * >("true" | "false") * '\n':
      withCapture:
        p.active = (ctx[0] == "true")
  
  let personText = """
name=John Doe
age=35
active=true
"""
  
  let result = parser.match(personText, person)
  echo "Parse result: ", result.ok
  echo "Person: ", person

when isMainModule:
  parseConfigOld()
  parseConfigNew()
  parseTypedData()