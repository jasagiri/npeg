#
# Example demonstrating progress tracking during parsing with NPeg
#

import ../src/npeg
import os, times, strutils, terminal

# Simple function to create a progress bar
proc drawProgressBar(progress: float, width: int = 50): string =
  let filledWidth = int(float(width) * progress)
  let emptyWidth = width - filledWidth
  
  result = "["
  result.add(repeat("#", filledWidth))
  result.add(repeat(" ", emptyWidth))
  result.add("] ")
  result.add($int(progress * 100) & "%")

# Create a callback function that will be called during parsing
proc progressCallback(progress: float, stats: ProgressStats) =
  # Clear the line and redraw the progress bar
  stdout.eraseLine()
  stdout.write(drawProgressBar(progress))
  if stats.bytesPerSecond > 0:
    stdout.write(" Speed: " & formatSize(int(stats.bytesPerSecond)) & "/s")
  if stats.estimatedTimeRemaining > 0:
    stdout.write(" ETA: " & formatDuration(stats.estimatedTimeRemaining))
  stdout.flushFile()

proc main() =
  # Path to a file to parse (for this example, we'll create a temporary file)
  let tempFilePath = getTempDir() / "npeg_progress_example.txt"
  
  # Create a large file to demonstrate progress tracking
  echo "Creating a large test file..."
  var largeContent = ""
  for i in 0..100_000:
    if i mod 10000 == 0:
      largeContent.add("marker_" & $i & "\n")
    else:
      largeContent.add("line " & $i & " with some text to parse\n")
  
  writeFile(tempFilePath, largeContent)
  echo "Created test file with ", largeContent.len, " characters"
  
  # Define a simple parser that counts lines with "marker" in them
  var count = 0
  let parser = peg "document":
    document <- +line
    line <- >*(1 - '\n') * ('\n' | !1):
      if "marker" in $1:
        inc count
  
  echo "Starting parse with progress tracking..."
  
  # Create a progress tracker
  # - First parameter is the total size of the input
  # - Second parameter is the callback function
  # - Third parameter is the threshold (report every 1% change)
  # - Fourth parameter is how often to check progress (in instructions)
  let tracker = newProgressTracker(largeContent.len, progressCallback, 0.01, 1000)
  
  # Record start time
  let startTime = cpuTime()
  
  # Parse the file with progress tracking
  let result = parser.matchFile(tempFilePath, tracker)
  
  # Record end time
  let endTime = cpuTime()
  
  # Clear the progress line and show results
  stdout.eraseLine()
  echo "Parse completed in ", formatFloat(endTime - startTime, ffDecimal, 3), " seconds"
  echo "Parsing successful: ", result.ok
  echo "Found ", count, " lines containing 'marker'"
  
  # Clean up
  removeFile(tempFilePath)
  echo "Temporary file removed"
  
  # Example of updating progress manually (not through parser)
  echo "\nManual progress tracking demonstration:"
  echo "Processing a hypothetical large dataset..."
  
  let manualTracker = newProgressTracker(100, progressCallback, 0.05)
  
  for i in 0..100:
    # Simulate processing work
    sleep(10)
    # Update progress manually
    let progress = float(i) / 100.0
    let stats = getStatistics(manualTracker, i, i * 10)
    manualTracker.lastUpdateTime = cpuTime() # Update the time to ensure accurate statistics
    progressCallback(progress, stats)
  
  stdout.eraseLine()
  echo "Manual processing complete!"

when isMainModule:
  main()