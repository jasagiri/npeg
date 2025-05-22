#
# Example demonstrating how throttling improves UI responsiveness
#
# This example simulates a UI that updates a progress bar while parsing.
# It demonstrates how throttling can prevent UI thread overload while
# still providing responsive progress updates.
#

import npeg
import os, times, strutils, terminal, strformat

# Simulate a UI element that takes time to update
type
  ProgressUI = object
    updateCount: int
    lastRenderTime: float
    lastProgress: float

proc newProgressUI(): ProgressUI =
  result = ProgressUI(
    updateCount: 0,
    lastRenderTime: cpuTime(),
    lastProgress: 0.0
  )

proc updateProgressBar(ui: var ProgressUI, progress: float, stats: ProgressStats) =
  inc ui.updateCount
  
  # Get the current time
  let currentTime = cpuTime()
  
  # Calculate time since last render
  let timeSinceLastRender = (currentTime - ui.lastRenderTime) * 1000.0 # in ms
  
  # Simulate UI update overhead by sleeping
  # This simulates the time it takes to update a complex UI
  # More frequent updates can cause more overhead
  sleep(5) # sleep for 5ms to simulate UI update overhead
  
  # Generate status line
  let width = 50
  let filledWidth = int(float(width) * progress)
  let emptyWidth = width - filledWidth
  
  var statusLine = "["
  statusLine.add(repeat("#", filledWidth))
  statusLine.add(repeat(" ", emptyWidth))
  statusLine.add("] ")
  statusLine.add(fmt"{progress:.1%}")
  
  # Add stats
  statusLine.add(fmt" | Speed: {formatSpeed(stats.bytesPerSecond)}")
  statusLine.add(fmt" | ETA: {formatDuration(stats.estimatedTimeRemaining)}")
  statusLine.add(fmt" | Update #{ui.updateCount}")
  
  # If we're getting called too fast, indicate it
  if timeSinceLastRender < 16.7: # 60fps = 16.7ms per frame
    statusLine.add(" ⚠️ UI Overload")
  
  # Clear the line and write the status
  stdout.eraseLine()
  stdout.write(statusLine)
  stdout.flushFile()
  
  # Update UI state
  ui.lastRenderTime = currentTime
  ui.lastProgress = progress

proc runParsingDemo(throttlingMode: ThrottlingMode, modeDesc: string, throttleTimeMs: int = 0, progressDelta: float = 0.0) =
  echo "\n\n--- Testing UI responsiveness with ", modeDesc, " ---"
  echo "Press any key to start..."
  discard getch()
  
  # Create a large test string for parsing
  let testStrSize = 500_000
  let testStr = "a" & repeat("b", testStrSize) & "c"
  
  # Create our simulated UI
  var ui = newProgressUI()
  
  # Create a callback that updates the UI
  proc progressCallback(progress: float, stats: ProgressStats) =
    ui.updateProgressBar(progress, stats)
  
  # Create a parser
  let parser = peg "test":
    test <- "a" * +("b") * "c"
  
  # Create a progress tracker with the specified throttling mode
  let tracker = newProgressTracker(
    totalSize = testStr.len,
    callback = progressCallback,
    reportThreshold = 0.001,  # Very small threshold to generate lots of updates
    updateInterval = 10,      # Check frequently for progress
    throttlingMode = throttlingMode,
    throttleTimeMs = throttleTimeMs,
    minProgressDelta = progressDelta
  )
  
  # Parse with progress tracking and time it
  let startTime = cpuTime()
  let result = parser.match(testStr, tracker)
  let endTime = cpuTime()
  
  # Calculate parsing overhead
  let duration = endTime - startTime
  let bytesPerSec = float(testStr.len) / duration
  
  # Clear the status line
  stdout.eraseLine()
  
  # Print results
  echo "Parse completed successfully: ", result.ok
  echo "Total UI updates: ", ui.updateCount
  echo "Parse duration: ", formatDuration(duration)
  echo "Processing speed: ", formatSpeed(bytesPerSec)
  
  # Calculate theoretical values
  if throttlingMode == tmTime:
    echo "Maximum update rate with throttling: ", formatFloat(1000.0 / float(throttleTimeMs), ffDecimal, 1), " updates/sec"
    echo "Actual update rate: ", formatFloat(float(ui.updateCount) / duration, ffDecimal, 1), " updates/sec"
  elif throttlingMode == tmProgressDelta:
    let expectedUpdates = 1.0 / progressDelta
    echo "Expected number of updates with progress delta: ", formatFloat(expectedUpdates, ffDecimal, 1)
    echo "Actual number of updates: ", ui.updateCount
  
  echo "\nPress any key to continue..."
  discard getch()

proc main() =
  # Set up terminal
  if not isatty(stdout):
    echo "This example requires an interactive terminal"
    return
  
  echo "This example demonstrates how throttling improves UI responsiveness"
  echo "It simulates UI updates with different throttling settings to show the impact"
  
  # Test with no throttling - this will likely overload the UI
  runParsingDemo(tmNone, "No Throttling")
  
  # Test with time-based throttling - this limits updates to a reasonable rate
  # 60 FPS = 16.7ms, so 20ms gives a bit of headroom
  runParsingDemo(tmTime, "Time-based Throttling (20ms)", throttleTimeMs = 20)
  
  # Test with progress delta throttling - this updates at regular progress intervals
  runParsingDemo(tmProgressDelta, "Progress Delta Throttling (2%)", progressDelta = 0.02)
  
  # Final results
  echo "\n\nConclusions:"
  echo "1. Without throttling, the UI receives too many updates, causing lag"
  echo "2. Time-based throttling provides smooth updates at a controlled rate"
  echo "3. Progress delta throttling ensures updates are tied to meaningful progress"
  echo "4. Throttling reduces UI overhead without affecting parsing performance"
  echo "\nChoose the throttling mode based on your application needs:"
  echo "- Time-based: For consistent UI update rates (e.g., 30-60 FPS)"
  echo "- Progress delta: For updates based on meaningful progress changes"

when isMainModule:
  main()