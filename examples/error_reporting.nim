import npeg
import npeg/errors
import strutils

# Example demonstrating the improved error reporting

# Example 1: Basic syntax error in grammar
proc example1() =
  echo "\n--- Example 1: Basic syntax error ---"
  
  try:
    # Missing closing parenthesis
    let badGrammar = peg "doc":
      doc <- "hello" * (1 * 2
  except:
    echo "Caught compiler-time error (expected)"

# Example 2: Left recursion error
proc example2() =
  echo "\n--- Example 2: Left recursion error ---"
  
  try:
    # Define a parser with left recursion
    let parser = peg "expr":
      expr <- expr * "+" * term | term  # Left recursive!
      term <- +Digit
    
    let input = "1+2+3"
    discard parser.match(input)
  except NPegStackOverflowError as e:
    let errorInfo = extractErrorInfo(e, "1+2+3")
    echo $errorInfo

# Example 3: Parse error with context
proc example3() =
  echo "\n--- Example 3: Parse error with context ---"
  
  try:
    # Valid parser but with strict requirements
    let parser = peg "doc":
      doc <- "hello" * +Alpha * !1
    
    let input = "hello world123"  # Contains digits which don't match +Alpha
    discard parser.match(input)
  except NPegParseError as e:
    let errorInfo = extractErrorInfo(e, "hello world123")
    echo $errorInfo

# Example 4: Capture out of range error
proc example4() =
  echo "\n--- Example 4: Capture out of range error ---"
  
  try:
    # Trying to access a capture that doesn't exist
    var result: string
    let parser = peg "doc":
      doc <- "hello" * >+Alpha:
        result = $2  # Error: only $1 is available
    
    let input = "hello world"
    discard parser.match(input)
  except NPegCaptureOutOfRangeError as e:
    let errorInfo = extractErrorInfo(e, "hello world")
    echo $errorInfo

# Example 5: Using the match with better errors
proc example5() =
  echo "\n--- Example 5: Using matchWithBetterErrors ---"
  
  try:
    # Define a parser for a simple key-value format
    let parser = peg "document":
      document <- +line * !1
      line <- key * "=" * value * nl
      key <- +Alpha
      value <- +Digit
      nl <- '\n' | !1
    
    # Input with an error (letter in the value)
    let input = """
name=John
age=42x
city=New York
"""
    
    # Using our enhanced match function
    discard parser.matchWithBetterErrors(input, true)
  except:
    echo "Error caught and displayed"

# Run all examples
when isMainModule:
  example1()
  example2()
  example3()
  example4()
  example5()