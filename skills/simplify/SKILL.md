---
name: simplify
description: Use when a file or module has grown too complex — removes unnecessary abstractions, dead code, and over-engineering without changing behavior. Invoke after implementing a feature when the code feels over-engineered.
allowed-tools: Read, Grep, Glob, Bash
---

# Simplify

Simplify the code in `$ARGUMENTS` (file or module path).
If no argument — simplify the most recently edited file.

## Guiding principle
> The best code is code that doesn't exist. The second best is code that's obvious.

## Step 1: Read the full file
Understand what it does before suggesting changes.

## Step 2: Identify complexity sources

### Unnecessary abstractions
- Classes that wrap a single function
- Interfaces with only one implementation
- Generic types that add no type safety benefit
- Factories or registries for things that don't need dynamic registration

### Dead code
- Unused functions, variables, imports, types
- Commented-out code blocks
- Feature flags that are always true or always false
- Exports that are never imported anywhere

### Over-engineering
- Flag parameters that switch behavior (split into two functions)
- Functions doing more than one thing
- Deeply nested conditionals that could be early-returned
- Premature optimization without evidence of a bottleneck

### Readability issues
- Variable names that don't communicate intent
- Long functions that should be extracted
- Inconsistent patterns vs the rest of the codebase

## Step 3: Propose changes
For each identified issue:
- Show the current code
- Show the simplified version
- Explain what was removed/changed and why it's better

## Step 4: Confirm before applying
List all proposed changes and ask:
"Should I apply all of these, or would you like to review each one?"

## Rules
- Never change behavior — only structure
- Run tests after each change to confirm nothing broke
- If a simplification requires a refactor across multiple files, note it but don't do it automatically — scope it separately
