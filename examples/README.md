# NPeg Examples

This directory contains various examples demonstrating how to use NPeg for different parsing tasks.

## Examples

1. **quickstart.nim** - The basic example from the README showing key-value pair parsing
2. **arithmetic.nim** - Parser for arithmetic expressions with operator precedence
3. **json_parser.nim** - Complete JSON parser that validates JSON documents
4. **http_response.nim** - HTTP response parser with capture of headers and status

## Running the Examples

To run any example:

```bash
nim c -r examples/quickstart.nim
nim c -r examples/arithmetic.nim
nim c -r examples/json_parser.nim
nim c -r examples/http_response.nim
```

## More Examples

You can find more examples in the `tests/` directory, particularly:
- `tests/examples.nim` - Additional parsing examples
- `tests/captures.nim` - Examples of different capture techniques
- `tests/precedence.nim` - Advanced operator precedence examples

## Contributing

Feel free to contribute more examples that demonstrate NPeg features or solve real-world parsing problems!