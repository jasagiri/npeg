# NPeg Language Support for Visual Studio Code

This extension provides rich language support for NPeg grammar files in Visual Studio Code.

## Features

- Syntax highlighting for NPeg grammar files
- Error reporting and diagnostics
- Code completion for rules, built-in atoms, and operators
- Go to definition and find references
- Document outline
- Railroad diagram visualization
- Grammar validation
- Nim parser code generation

## Requirements

To enable all features, the NPeg language server should be installed. You can install it with:

```bash
nim c -r src/npeg/lsp/install.nim
```

Or manually build and install:

```bash
nim c -d:release -o:npeg-lsp src/npeg/lsp/server.nim
```

Then configure the path to the language server in the extension settings.

## Extension Settings

This extension contributes the following settings:

* `npeg.languageServer.enable`: Enable/disable the NPeg language server.
* `npeg.languageServer.path`: Path to the NPeg language server executable.
* `npeg.trace.server`: Trace the communication between VS Code and the NPeg language server for debugging.
* `npeg.visualization.railroadDiagramStyle`: Style of railroad diagrams for grammar visualization.

## Keyboard Shortcuts

* `Ctrl+Alt+V` / `Cmd+Alt+V` (macOS): Visualize Grammar
* `Ctrl+Alt+C` / `Cmd+Alt+C` (macOS): Validate Grammar

## Commands

* `NPeg: Visualize Grammar`: Generate and display a railroad diagram for the current grammar.
* `NPeg: Validate Grammar`: Validate the current grammar and show any errors.
* `NPeg: Generate Nim Parser Code`: Generate Nim code for the current grammar.

## Examples

Example NPeg grammar:

```
doc <- rule1 * rule2 * !1
rule1 <- "hello" | "hi"
rule2 <- +Alpha * *Space
```

## Known Issues

* Railroad diagram visualization requires the railroad-diagrams JavaScript library to be installed.
* The extension is still in early development and some features may not work correctly.

## Release Notes

### 0.1.0

Initial release of NPeg language support for VS Code.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This extension is released under the MIT License.