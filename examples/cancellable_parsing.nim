#
# Example demonstrating cancellable parsing with NPeg
#

import ../src/npeg
import os, times, strutils, terminal

# For simulating user input in a non-blocking way
when defined(windows):
  import winlean
else:
  from posix import STDIN_FILENO, Timeval, Fdset, FDSET, select

# Function to create a progress bar
proc drawProgressBar(progress: float, width: int = 50): string =
  let filledWidth = int(float(width) * progress)
  let emptyWidth = width - filledWidth
  
  result = "["
  result.add(repeat("#", filledWidth))
  result.add(repeat(" ", emptyWidth))
  result.add("] ")
  result.add($int(progress * 100) & "%")

# Simplified function for demonstration purposes
proc kbhit(): bool =
  # Always return false in this example to focus on the timeout-based cancellation
  return false

proc progressCallback(progress: float, stats: ProgressStats) =
  # Clear the line and redraw the progress bar
  stdout.eraseLine()
  stdout.write(drawProgressBar(progress) & " - Press 'q' to cancel")
  stdout.flushFile()

# Cancellation callback - check if user pressed 'q'
var cancelRequested = false
proc cancellationCallback(): bool =
  # Check for key press without blocking
  # For demonstration purposes, always return false
  # In a real application, this would check for user input
  return cancelRequested

proc main() =
  # Path to a file to parse (for this example, we'll create a temporary file)
  let tempFilePath = getTempDir() / "npeg_cancellable_example.txt"
  
  # Create a large file to demonstrate cancellable parsing
  echo "Creating a large test file..."
  var largeContent = ""
  for i in 0..1_000_000: # Deliberately large to make parsing slow
    if i mod 10000 == 0:
      largeContent.add("marker_" & $i & "\n")
    else:
      largeContent.add("line " & $i & " with some text to parse\n")
  
  writeFile(tempFilePath, largeContent)
  echo "Created test file with ", largeContent.len, " characters"
  
  # Define a parser that counts lines with "marker" in them
  var count = 0
  let parser = peg "document":
    document <- +line
    line <- >*(1 - '\n') * ('\n' | !1):
      if "marker" in $1:
        inc count
  
  echo "Starting parse with cancellation support..."
  echo "Press 'q' at any time to cancel parsing"
  
  # Create a progress tracker with cancellation support
  let tracker = newProgressTracker(
    totalSize = largeContent.len,
    callback = progressCallback,
    reportThreshold = 0.01, 
    updateInterval = 1000,
    cancellationToken = cancellationCallback
  )
  
  # Record start time
  let startTime = cpuTime()
  
  # Parse the file with progress tracking and cancellation
  let result = parser.matchFile(tempFilePath, tracker)
  
  # Record end time
  let endTime = cpuTime()
  
  # Clear the progress line
  stdout.eraseLine()
  
  # Report results based on whether parsing was cancelled or completed
  if tracker.isCancelled():
    echo "Parsing was cancelled after ", formatFloat(endTime - startTime, ffDecimal, 3), " seconds"
    echo "Parsed ", result.matchLen, " of ", largeContent.len, " characters (", 
         formatFloat(float(result.matchLen) / float(largeContent.len) * 100.0, ffDecimal, 1), "% complete)"
    echo "Found ", count, " marker lines before cancellation"
  else:
    echo "Parse completed successfully in ", formatFloat(endTime - startTime, ffDecimal, 3), " seconds"
    echo "Found ", count, " marker lines in total"
  
  # Clean up
  removeFile(tempFilePath)
  echo "Temporary file removed"

  # Timeout-based cancellation demo
  echo "\nDemonstrating timeout-based cancellation:"
  
  # Generate another large test string
  let largeString = "a" & repeat("b", 1_000_000) & "c"
  
  # Reset cancellation flag
  cancelRequested = false
  
  # Create a timeout-based cancellation callback
  let timeoutSeconds = 3.0
  let startTimeTimeout = cpuTime()
  proc timeoutCancellationCallback(): bool =
    let elapsed = cpuTime() - startTimeTimeout
    if elapsed > timeoutSeconds:
      stdout.write("\nTimeout reached! Cancelling parse...\n")
      stdout.flushFile()
      return true
    return false
  
  # Create a progress tracker with timeout cancellation
  let timeoutTracker = newProgressTracker(
    totalSize = largeString.len,
    callback = progressCallback,
    reportThreshold = 0.01, 
    updateInterval = 1000,
    cancellationToken = timeoutCancellationCallback
  )
  
  echo "Starting parse with a ", timeoutSeconds, "-second timeout..."
  
  # Parse with timeout cancellation
  let timeoutResult = parser.match(largeString, timeoutTracker)
  
  stdout.eraseLine()
  if timeoutTracker.isCancelled():
    echo "Parsing was cancelled due to timeout"
    echo "Parsed ", timeoutResult.matchLen, " of ", largeString.len, " characters"
  else:
    echo "Parse completed before timeout (unexpected)"

when isMainModule:
  main()