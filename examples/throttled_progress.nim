#
# Example demonstrating throttled progress tracking
#

import ../src/npeg
import os, times, strutils, terminal, strformat

proc drawProgressBar(progress: float, width: int = 50): string =
  let filledWidth = int(float(width) * progress)
  let emptyWidth = width - filledWidth
  
  result = "["
  result.add(repeat("#", filledWidth))
  result.add(repeat(" ", emptyWidth))
  result.add("] ")
  result.add($int(progress * 100) & "%")

proc measureCallbackRate(mode: ThrottlingMode, modeDesc: string, throttleTimeMs: int = 50, progressDelta: float = 0.1) =
  echo "\n--- Testing ", modeDesc, " ---"
  
  # Create a large test string for parsing
  let testStr = "a" & repeat("b", 100_000) & "c"
  
  # Track callback invocations
  var callbackCount = 0
  var startTime = 0.0
  var endTime = 0.0
  var lastStats: ProgressStats
  
  # Create a callback that just counts invocations
  proc progressCallback(progress: float, stats: ProgressStats) =
    if callbackCount == 0:
      startTime = cpuTime()
    
    inc callbackCount
    lastStats = stats
    
    # Print callback info
    stdout.eraseLine()
    let statusLine = fmt"Callback #{callbackCount}: {formatStats(stats)}"
    stdout.write(statusLine)
    stdout.flushFile()
  
  # Create a parser
  let parser = peg "test":
    test <- "a" * +("b") * "c"
  
  # Create a progress tracker with specified throttling
  let tracker = newProgressTracker(
    totalSize = testStr.len,
    callback = progressCallback,
    reportThreshold = 0.001,  # Very low threshold to generate lots of potential updates
    updateInterval = 100,     # Check frequently for progress
    throttlingMode = mode,
    throttleTimeMs = throttleTimeMs,
    minProgressDelta = progressDelta
  )
  
  # Parse with progress tracking
  echo "Parsing ", formatSize(testStr.len), " of data with throttling..."
  let result = parser.match(testStr, tracker)
  endTime = cpuTime()
  
  # Clear status line
  stdout.eraseLine()
  
  # Calculate callback rate
  let duration = endTime - startTime
  let callbackRate = if duration > 0: float(callbackCount) / duration else: 0.0
  
  # Print results
  echo "Parse completed successfully: ", result.ok
  echo "Total callbacks: ", callbackCount
  echo "Parse duration: ", formatDuration(duration)
  echo "Callback rate: ", formatFloat(callbackRate, ffDecimal, 1), " callbacks/sec"
  if mode == tmTime:
    echo "Theoretical maximum rate: ", formatFloat(1000.0 / float(throttleTimeMs), ffDecimal, 1), " callbacks/sec"
  elif mode == tmProgressDelta:
    echo "Expected number of callbacks: ", formatFloat(1.0 / progressDelta, ffDecimal, 1)
  echo "Final progress stats: ", formatStats(lastStats)

proc main() =
  echo "Demonstrating different throttling modes for progress tracking"
  
  # Test with no throttling
  measureCallbackRate(tmNone, "No Throttling")
  
  # Test with time-based throttling
  measureCallbackRate(tmTime, "Time-based Throttling (50ms)", throttleTimeMs = 50)
  
  # Test with more aggressive time-based throttling
  measureCallbackRate(tmTime, "Time-based Throttling (200ms)", throttleTimeMs = 200)
  
  # Test with progress delta throttling
  measureCallbackRate(tmProgressDelta, "Progress Delta Throttling (10%)", progressDelta = 0.1)
  
  # Test with finer progress delta throttling
  measureCallbackRate(tmProgressDelta, "Progress Delta Throttling (5%)", progressDelta = 0.05)
  
  # Demo of dynamic throttling configuration
  echo "\n--- Demonstrating dynamic throttling configuration ---"
  
  # Create a large test string for parsing
  let testStr = "a" & repeat("b", 100_000) & "c"
  
  # Track callback invocations
  var callbackCount = 0
  var lastStats: ProgressStats
  
  # Create a callback that just counts invocations
  proc progressCallback(progress: float, stats: ProgressStats) =
    inc callbackCount
    lastStats = stats
    
    # Print callback info
    stdout.eraseLine()
    let statusLine = fmt"Callback #{callbackCount}: {formatStats(stats)}"
    stdout.write(statusLine)
    stdout.flushFile()
  
  # Create a parser
  let parser = peg "test":
    test <- "a" * +("b") * "c"
  
  # Create a progress tracker with no throttling initially
  let tracker = newProgressTracker(
    totalSize = testStr.len,
    callback = progressCallback,
    reportThreshold = 0.001
  )
  
  # Reconfigure throttling dynamically
  echo "Starting with no throttling..."
  sleep(1000)
  
  echo "\nSwitching to time-based throttling (100ms)..."
  tracker.configureThrottling(tmTime, 100)
  sleep(1000)
  
  echo "\nSwitching to progress delta throttling (5%)..."
  tracker.configureThrottling(tmProgressDelta, progressDelta = 0.05)
  sleep(1000)
  
  echo "\nDisabling throttling again..."
  tracker.configureThrottling(tmNone)
  sleep(1000)

when isMainModule:
  main()