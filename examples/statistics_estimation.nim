#
# Example demonstrating progress statistics and ETA estimation
#

import npeg
import os, times, strutils, terminal, strformat

proc main() =
  # Create a large test file
  let tempFilePath = getTempDir() / "npeg_stats_example.txt"
  echo "Creating a large test file..."
  
  # Create a file with about 10MB of data
  let lineTemplate = "This is a line of text that will be repeated many times in our test file. " & 
                     "The goal is to create a file large enough that parsing it takes a measurable amount of time. " &
                     "The repetitive nature of this content is intentional.\n"
  let repeats = 100_000
  var fileContent = ""
  for i in 1..repeats:
    if i mod 10000 == 0:
      fileContent.add(fmt"MARKER_LINE_{i}: {lineTemplate}")
    else:
      fileContent.add(lineTemplate)
  
  writeFile(tempFilePath, fileContent)
  echo "Created test file with ", formatSize(fileContent.len), " of data"
  
  # Define a parser that counts markers
  var markerCount = 0
  let parser = peg "document":
    document <- +line
    line <- >*(1 - '\n') * ('\n' | !1):
      if $1.contains("MARKER_LINE"):
        inc markerCount
  
  # Setup progress callback that displays detailed stats
  var lastStatusLength = 0
  
  proc progressCallback(progress: float, stats: ProgressStats) =
    # Build a detailed status line
    let statusLine = formatStats(stats)
    
    # Clear the previous status line (if any)
    if lastStatusLength > 0:
      stdout.write("\r" & " ".repeat(lastStatusLength) & "\r")
    
    # Show the new status
    stdout.write(statusLine)
    stdout.flushFile()
    
    # Remember length for next update
    lastStatusLength = statusLine.len
  
  # Create a progress tracker with statistics
  let tracker = newProgressTracker(
    totalSize = fileContent.len,
    callback = progressCallback,
    reportThreshold = 0.01,  # Update every 1%
    updateInterval = 1000    # Check after every 1000 instructions
  )
  
  echo "Starting parse with detailed statistics..."
  echo ""  # Leave space for the progress bar
  
  # Record start time
  let startTime = cpuTime()
  
  # Parse the file with progress tracking
  let result = parser.matchFile(tempFilePath, tracker)
  
  # Calculate actual elapsed time
  let elapsedTime = cpuTime() - startTime
  
  # Clear the progress line
  if lastStatusLength > 0:
    stdout.write("\r" & " ".repeat(lastStatusLength) & "\r")
  
  # Show summary
  echo "Parse " & (if result.ok: "completed successfully" else: "failed") & " in ", formatDuration(elapsedTime)
  echo "File size: ", formatSize(fileContent.len)
  echo "Average speed: ", formatSpeed(float(fileContent.len) / elapsedTime)
  echo "Found ", markerCount, " marker lines"
  
  # Demonstrate getting final statistics
  let finalStats = tracker.getStatistics(fileContent.len, tracker.lastInstructionCount)
  echo "Final bytesPerSecond: ", formatSpeed(finalStats.bytesPerSecond)
  echo "Final instructionsPerSecond: ", formatFloat(finalStats.instructionsPerSecond, ffDecimal, 0), " instr/sec"
  echo "Instructions executed: ", formatFloat(float(finalStats.instructionsExecuted), ffDecimal, 0)
  
  # Clean up
  removeFile(tempFilePath)
  echo "Temporary file removed"
  
  # Comparative parse without progress tracking to measure overhead
  echo "\nRunning comparative test without progress tracking..."
  
  markerCount = 0
  fileContent = "" # Allow the previous content to be garbage collected
  
  # Write the same file again
  writeFile(tempFilePath, "This is just a small test file to measure overhead\n".repeat(100))
  echo "Small test file created"
  
  # Parse without tracker
  let startTime2 = cpuTime()
  let result2 = parser.matchFile(tempFilePath)
  let elapsedTime2 = cpuTime() - startTime2
  echo "Parse without progress tracking: ", formatDuration(elapsedTime2)
  
  # Parse with tracker
  let startTime3 = cpuTime()
  let result3 = parser.matchFile(tempFilePath, tracker)
  let elapsedTime3 = cpuTime() - startTime3
  echo "Parse with progress tracking: ", formatDuration(elapsedTime3)
  
  if elapsedTime3 > 0 and elapsedTime2 > 0:
    let overhead = (elapsedTime3 - elapsedTime2) / elapsedTime2 * 100.0
    echo "Progress tracking overhead: ", formatFloat(overhead, ffDecimal, 2), "%"
  
  # Clean up
  removeFile(tempFilePath)

when isMainModule:
  main()