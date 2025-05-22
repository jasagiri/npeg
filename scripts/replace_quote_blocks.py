#!/usr/bin/env python3
"""
Script to systematically replace quote do: blocks in codegen.nim with newStmtList() placeholders.
This helps isolate the issue with variable scoping by testing different combinations.
"""

import re
import os
import sys
from pathlib import Path

def find_quote_blocks(content):
    """Find all quote do: blocks and their positions"""
    pattern = r'(code = )(quote do:.*?)(\n\s*(?:of |else|#|result))'
    matches = []
    
    for match in re.finditer(pattern, content, re.DOTALL):
        start_pos = match.start(2)
        end_pos = match.end(2)
        quote_content = match.group(2)
        
        # Find the actual end of the quote block by counting indentation
        lines = content[start_pos:].split('\n')
        quote_lines = []
        base_indent = None
        
        for i, line in enumerate(lines):
            if i == 0:  # First line is "quote do:"
                quote_lines.append(line)
                continue
                
            if line.strip() == '':
                quote_lines.append(line)
                continue
                
            # Determine base indentation from first non-empty line after "quote do:"
            if base_indent is None and line.strip():
                base_indent = len(line) - len(line.lstrip())
                quote_lines.append(line)
                continue
            
            # Check if we're still inside the quote block
            current_indent = len(line) - len(line.lstrip()) if line.strip() else 0
            if line.strip() and current_indent <= base_indent and not line.strip().startswith('#'):
                # We've reached the end of the quote block
                break
            
            quote_lines.append(line)
        
        actual_quote = '\n'.join(quote_lines)
        actual_end = start_pos + len(actual_quote)
        
        matches.append({
            'start': start_pos,
            'end': actual_end,
            'content': actual_quote,
            'op_context': content[max(0, start_pos-100):start_pos]
        })
    
    return matches

def replace_quote_blocks(content, block_indices_to_replace):
    """Replace specified quote blocks with newStmtList()"""
    quote_blocks = find_quote_blocks(content)
    
    # Sort by position in reverse order to maintain correct indices
    quote_blocks.sort(key=lambda x: x['start'], reverse=True)
    
    result = content
    
    for i, block in enumerate(quote_blocks):
        # Convert to 0-based index from end
        block_index = len(quote_blocks) - 1 - i
        
        if block_index in block_indices_to_replace:
            # Replace with newStmtList()
            result = result[:block['start']] + 'newStmtList()' + result[block['end']:]
    
    return result

def analyze_quote_blocks(content):
    """Analyze and list all quote blocks for reference"""
    quote_blocks = find_quote_blocks(content)
    
    print(f"Found {len(quote_blocks)} quote blocks:")
    print("-" * 60)
    
    for i, block in enumerate(quote_blocks):
        # Extract operation context
        op_match = re.search(r'of (op\w+):', block['op_context'])
        op_name = op_match.group(1) if op_match else "unknown"
        
        print(f"Block {i}: {op_name}")
        print(f"  Position: {block['start']}-{block['end']}")
        print(f"  Preview: {block['content'][:100].replace(chr(10), ' ')}...")
        print()
    
    return quote_blocks

def create_test_combinations(num_blocks):
    """Create different test combinations for systematic testing"""
    combinations = [
        [],  # No replacements (original)
        list(range(num_blocks)),  # All replacements
    ]
    
    # Individual replacements
    for i in range(num_blocks):
        combinations.append([i])
    
    # Half and half
    mid = num_blocks // 2
    combinations.append(list(range(mid)))
    combinations.append(list(range(mid, num_blocks)))
    
    return combinations

def main():
    codegen_path = Path("/Users/jasagiri/_temp/_fix_progress/npeg/src/npeg/codegen.nim")
    
    if not codegen_path.exists():
        print(f"Error: {codegen_path} not found")
        return 1
    
    # Read the original file
    with open(codegen_path, 'r') as f:
        original_content = f.read()
    
    # Analyze quote blocks
    quote_blocks = analyze_quote_blocks(original_content)
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "analyze":
            return 0
        elif sys.argv[1] == "test":
            # Create test files for systematic testing
            combinations = create_test_combinations(len(quote_blocks))
            
            for i, combo in enumerate(combinations):
                test_content = replace_quote_blocks(original_content, combo)
                test_file = codegen_path.parent / f"codegen_test_{i}.nim"
                
                with open(test_file, 'w') as f:
                    f.write(test_content)
                
                combo_desc = f"blocks {combo}" if combo else "original"
                print(f"Created {test_file.name} - replacing {combo_desc}")
            
            return 0
        elif sys.argv[1].startswith("replace"):
            # Parse block indices to replace
            if "=" in sys.argv[1]:
                indices_str = sys.argv[1].split("=")[1]
                indices = [int(x.strip()) for x in indices_str.split(",") if x.strip()]
            else:
                indices = []
            
            # Create backup
            backup_path = codegen_path.with_suffix(".nim.backup")
            with open(backup_path, 'w') as f:
                f.write(original_content)
            print(f"Backup created: {backup_path}")
            
            # Replace specified blocks
            modified_content = replace_quote_blocks(original_content, indices)
            
            with open(codegen_path, 'w') as f:
                f.write(modified_content)
            
            replaced_desc = f"blocks {indices}" if indices else "no blocks"
            print(f"Replaced {replaced_desc} in {codegen_path}")
            return 0
        elif sys.argv[1] == "restore":
            backup_path = codegen_path.with_suffix(".nim.backup")
            if backup_path.exists():
                with open(backup_path, 'r') as f:
                    backup_content = f.read()
                with open(codegen_path, 'w') as f:
                    f.write(backup_content)
                print(f"Restored {codegen_path} from backup")
            else:
                print("No backup file found")
            return 0
    
    # Default: show usage
    print("Usage:")
    print("  python replace_quote_blocks.py analyze        - Analyze quote blocks")
    print("  python replace_quote_blocks.py test           - Create test files")
    print("  python replace_quote_blocks.py replace=1,2,3  - Replace specific blocks")
    print("  python replace_quote_blocks.py replace=       - Replace no blocks (test)")
    print("  python replace_quote_blocks.py restore        - Restore from backup")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())