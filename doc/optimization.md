# NPeg Optimization Guide

This guide explains the various optimization flags and techniques available in NPeg to improve parser performance.

## Compile-time Optimization Flags

NPeg provides several compile-time flags to control optimizations. These are controlled by the `-d:npegOptimize=N` flag, where N is a bitmask of optimization features.

### Available Optimizations

1. **Character Set Optimization** (`-d:npegOptimize=1`)
   - Combines adjacent character sets for efficiency
   - Optimizes character ranges
   - Default: Enabled

2. **Head Fail Optimization** (`-d:npegOptimize=2`)
   - Fails fast when patterns cannot possibly match
   - Reduces unnecessary backtracking
   - Default: Enabled

3. **Capture Shift Optimization** (`-d:npegOptimize=4`)
   - Optimizes capture stack operations
   - Reduces memory movement for captures
   - Default: Enabled

4. **Choice Commit Optimization** (`-d:npegOptimize=8`)
   - Optimizes ordered choice operations
   - Commits to choices earlier when possible
   - Default: Enabled

### Using Optimization Flags

To enable all optimizations (default):
```bash
nim c -d:npegOptimize=255 myparser.nim
```

To disable all optimizations (useful for debugging):
```bash
nim c -d:npegOptimize=0 myparser.nim
```

To enable only specific optimizations:
```bash
# Enable only character set and head fail optimizations
nim c -d:npegOptimize=3 myparser.nim
```

## Grammar Optimization Techniques

### 1. Rule Ordering

The order of rules affects inlining and performance:

```nim
# Good: Frequently used rules first, allows inlining
let parser = peg "doc":
  space <- ' ' | '\t'
  word <- +Alpha
  doc <- word * *(space * word)

# Less optimal: Complex rules first may prevent inlining
let parser = peg "doc":
  doc <- word * *(space * word)
  word <- +Alpha
  space <- ' ' | '\t'
```

### 2. Character Set Optimization

Combine character sets for better performance:

```nim
# Good: Single character set
identifier <- +{'a'..'z', 'A'..'Z', '0'..'9', '_'}

# Less optimal: Multiple checks
identifier <- +('a'..'z' | 'A'..'Z' | '0'..'9' | '_')
```

### 3. Avoiding Excessive Backtracking

Design grammars to fail fast:

```nim
# Good: Fails quickly on non-matches
number <- ?'-' * digit * *digit * ?('.' * +digit)
digit <- {'0'..'9'}

# Less optimal: More backtracking
number <- ?'-' * +{'0'..'9'} * ?('.' * +{'0'..'9'})
```

### 4. Using Lookahead Effectively

Use lookahead to avoid unnecessary parsing:

```nim
# Good: Check before parsing
statement <- &keyword * (ifStmt | whileStmt | assign)

# Less optimal: Parse then backtrack
statement <- ifStmt | whileStmt | assign
```

## Performance Tips

### 1. Inline Frequently Used Rules

Keep frequently used rules small for inlining:

```nim
# Will be inlined
ws <- *' '

# Too large for inlining
complexRule <- very * long * pattern * with * many * parts
```

### 2. Use Character Spans

Use span operator for repeated character matches:

```nim
# Good: Uses span optimization
identifier <- Alpha * *Alnum

# Less optimal: Individual character matching
identifier <- Alpha * *(Alpha | Digit)
```

### 3. Minimize Capture Overhead

Only capture what you need:

```nim
# Good: Capture only needed parts
keyValue <- >key * '=' * >value

# Less optimal: Capture everything
keyValue <- >(key * '=' * value)
```

## Debugging Performance

### Enable Tracing

Use `-d:npegTrace` to see parser execution:

```bash
nim c -d:npegTrace myparser.nim
```

### Generate Parser Graphs

Use `-d:npegDotDir=/tmp` to visualize grammar:

```bash
nim c -d:npegDotDir=/tmp myparser.nim
dot -Tpng /tmp/mygrammar.dot -o grammar.png
```

### Profile Your Parser

Use the benchmark suite to measure performance:

```nim
import times

let start = cpuTime()
for i in 0..1000:
  discard parser.match(input)
echo "Time: ", cpuTime() - start
```

## Common Pitfalls

1. **Over-inlining**: Very large grammars may hit the `npegPattMaxLen` limit
2. **Deep recursion**: May hit stack limits with complex grammars
3. **Excessive captures**: Can slow down parsing significantly
4. **Poor rule ordering**: Can prevent optimization opportunities

## Conclusion

NPeg provides powerful optimization capabilities, but the best performance comes from well-designed grammars. Profile your specific use case and apply optimizations where they provide measurable benefits.