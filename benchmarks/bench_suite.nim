import std/[times, strutils, tables, json, os]
import npeg

type
  BenchmarkResult = object
    name: string
    iterations: int
    totalTime: float
    averageTime: float
    minTime: float
    maxTime: float

proc runBenchmark(name: string, iterations: int, body: proc()): BenchmarkResult =
  result.name = name
  result.iterations = iterations
  result.minTime = float.high
  result.maxTime = 0.0
  
  for i in 0..<iterations:
    let start = cpuTime()
    body()
    let elapsed = cpuTime() - start
    result.totalTime += elapsed
    result.minTime = min(result.minTime, elapsed)
    result.maxTime = max(result.maxTime, elapsed)
  
  result.averageTime = result.totalTime / float(iterations)

proc formatTime(t: float): string =
  if t < 0.001:
    formatFloat(t * 1_000_000, ffDecimal, 2) & " μs"
  elif t < 1.0:
    formatFloat(t * 1_000, ffDecimal, 2) & " ms"
  else:
    formatFloat(t, ffDecimal, 2) & " s"

proc printResults(results: seq[BenchmarkResult]) =
  echo "\nBenchmark Results:"
  echo "=================="
  for r in results:
    echo "\n", r.name
    echo "  Iterations: ", r.iterations
    echo "  Average:    ", formatTime(r.averageTime)
    echo "  Min:        ", formatTime(r.minTime)
    echo "  Max:        ", formatTime(r.maxTime)
    echo "  Total:      ", formatTime(r.totalTime)

# Benchmark 1: Simple string matching
proc benchSimpleMatch() =
  let parser = patt("hello")
  for i in 0..1000:
    discard parser.match("hello world")

# Benchmark 2: Complex grammar
proc benchComplexGrammar() =
  let parser = peg "doc":
    doc <- expr * !1
    expr <- term * *(('+' | '-') * term)
    term <- factor * *(('*' | '/') * factor)
    factor <- +Digit | ('(' * expr * ')')
  
  for i in 0..100:
    discard parser.match("1+2*3+(4/5)*6")

# Benchmark 3: JSON parsing
proc benchJsonParsing() =
  let jsonParser = peg "json":
    json <- value * !1
    value <- object | array | string | number | boolean | null
    object <- '{' * ?(pair * *(',' * pair)) * '}'
    pair <- string * ':' * value
    array <- '[' * ?(value * *(',' * value)) * ']'
    string <- '"' * *(!'"' * 1) * '"'
    number <- ?'-' * +Digit * ?('.' * +Digit)
    boolean <- "true" | "false"
    null <- "null"
  
  let testJson = """{"name": "test", "value": 42, "items": [1, 2, 3]}"""
  for i in 0..100:
    discard jsonParser.match(testJson)

# Benchmark 4: Character set performance
proc benchCharSets() =
  let parser = patt(+{'a'..'z', 'A'..'Z', '0'..'9', '_'})
  let testString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" & " invalid"
  
  for i in 0..1000:
    discard parser.match(testString)

# Benchmark 5: Backreference performance
proc benchBackreferences() =
  let parser = peg "tags":
    tags <- tag * !1
    tag <- '<' * R("name", ident) * '>' * content * "</" * R("name") * '>'
    content <- *(1 - '<')
    ident <- +Alpha
  
  for i in 0..100:
    discard parser.match("<div>Hello World</div>")

# Main benchmark runner
when isMainModule:
  var results: seq[BenchmarkResult]
  
  echo "Running NPeg Benchmark Suite..."
  
  results.add runBenchmark("Simple Match", 10000) do:
    benchSimpleMatch()
  
  results.add runBenchmark("Complex Grammar", 1000) do:
    benchComplexGrammar()
  
  results.add runBenchmark("JSON Parsing", 1000) do:
    benchJsonParsing()
  
  results.add runBenchmark("Character Sets", 10000) do:
    benchCharSets()
  
  results.add runBenchmark("Backreferences", 1000) do:
    benchBackreferences()
  
  printResults(results)
  
  # Save results to JSON
  var jsonResults = newJObject()
  jsonResults["timestamp"] = %($now())
  jsonResults["hostname"] = %(getEnv("HOSTNAME", "unknown"))
  var benchmarks = newJArray()
  
  for r in results:
    var bench = newJObject()
    bench["name"] = %r.name
    bench["iterations"] = %r.iterations
    bench["average_ms"] = %(r.averageTime * 1000)
    bench["min_ms"] = %(r.minTime * 1000)
    bench["max_ms"] = %(r.maxTime * 1000)
    benchmarks.add(bench)
  
  jsonResults["benchmarks"] = benchmarks
  
  let outputFile = "benchmark_results.json"
  writeFile(outputFile, $jsonResults)
  echo "\nResults saved to ", outputFile