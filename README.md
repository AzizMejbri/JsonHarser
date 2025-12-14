## JSON Parser in Haskell
A lightweight, educational JSON parser implemented in Haskell as a learning project. This parser demonstrates fundamental parsing techniques, recursive data structures, and functional programming patterns.

---
### 📋 Features
- Complete JSON Support: Parses all standard JSON data types (objects, arrays, strings, numbers, booleans, null)

- Multiple Number Formats: Supports decimal, hexadecimal (0x...), octal (0o...), and binary (0b...) integers

- Float Parsing: Handles decimal numbers with scientific notation (e.g., 1.23e10)

- Comment Support: Single-line // comments (non-standard but useful for configuration)

- Pretty Printing: Formats parsed JSON with proper indentation

- Error Handling: Provides descriptive error messages with context


---
### 🏗️ Architecture
#### Data Structure
The parser builds an Abstract Syntax Tree (AST) represented by the JsonValue algebraic data type:

```haskell
data JsonValue
  = JsonNull
  | JsonString String
  | JsonInt Int
  | JsonBool Bool
  | JsonFloat Double
  | JsonArray [JsonValue]
  | JsonObject (Map.Map String JsonValue)
Parser Combinators
```

The implementation uses a combinator-based approach:

- Primitive parsers for each JSON token type

- Recursive parsers for nested structures (objects/arrays)

- Whitespace and comment handling integrated at each parsing step

- Alternative (<|>) operator for trying parsers in sequence

---
### 📁 Project Structure
```text
json-parser/
├── Main.hs              # Main parser implementation
├── JsonUtils.hs         # Utility functions and operators
├── test.json           # Example JSON file
└── jsonparser.cabal    # Build configuration
```

### 🚀 Getting Started
#### Prerequisites
- GHC (Glasgow Haskell Compiler) ≥ 9.6

- Cabal (Haskell build tool)

#### Building
```bash
# Clone or create the project directory
mkdir json-parser && cd json-parser

# Place the source files in the directory

# Build with Cabal
cabal build

# Run the parser
cabal run
```

#### Compilation Options
```bash
# Simple compilation with GHC
ghc -o jsonparser Main.hs JsonUtils.hs

# With optimizations
ghc -O3 -o jsonparser Main.hs
```

---

### 📖 Usage Examples
Basic Parsing
```haskell
-- Parse a JSON string
parseJson "{\"name\": \"Alice\", \"age\": 30}"

-- Result: JsonObject (fromList [("name", "Alice"), ("age", 30)])
```
Number Formats
```json
{
  "decimal": 42,
  "hex": 0x2A,
  "octal": 0o52,
  "binary": 0b101010,
  "float": 3.14159,
  "scientific": 6.022e23
}
```
Nested Structures
```json
{
  "users": [
    {
      "id": 1,
      "name": "Alice",
      "active": true
    },
    {
      "id": 2,
      "name": "Bob",
      "active": false
    }
  ],
  "metadata": {
    "count": 2,
    "timestamp": "2024-01-01"
  }
}
```
With Comments
```json
{
  // This is a single-line comment
  "api_key": "secret123",  // API authentication
  "timeout": 5000,  // milliseconds
  "retry": true
}
```

---
### 🔧 API Reference
Main Functions
```haskell
-- Parse a JSON string into a JsonValue
parseJson :: String -> Either String JsonValue

-- Pretty print a JsonValue with indentation
prettyPrint :: JsonValue -> Int -> String

-- Core parser type
type JsonParser = String -> Maybe (JsonValue, String)
```

#### 📊 Parser Functions Overview

| Parser Functions | Category | Description |
|------------------|----------|-------------|
| `parseNull`, `parseBool`, `parseStringValue` | **Primitive Parsers** | Parses basic JSON data types (null, booleans, and strings) |
| `parseInt`, `parseFloat` | **Number Parsers** | Parses numeric values including integers (decimal, hex, octal, binary) and floating-point numbers |
| `parseArray`, `parseObject` | **Collection Parsers** | Parses JSON arrays and objects with support for nesting |
| `parseJsonValue` | **Top-level Parser** | Main entry point that dispatches to appropriate parser based on input |

#### 🔧 Detailed Function Descriptions

##### Primitive Parsers
| Function | Signature | Description |
|----------|-----------|-------------|
| `parseNull` | `String -> Maybe (JsonValue, String)` | Parses JSON `null` value |
| `parseBool` | `String -> Maybe (JsonValue, String)` | Parses JSON boolean values (`true`/`false`) |
| `parseStringValue` | `String -> Maybe (String, String)` | Parses JSON string values (returns raw `String` for internal use) |

##### Number Parsers
| Function | Signature | Description | Example Inputs |
|----------|-----------|-------------|----------------|
| `parseInt` | `String -> Maybe (JsonValue, String)` | Parses integers in decimal, hex (`0x`), octal (`0o`), and binary (`0b`) formats | `42`, `0x2A`, `0o52`, `0b101010` |
| `parseFloat` | `String -> Maybe (JsonValue, String)` | Parses floating-point numbers with optional scientific notation | `3.14`, `1.23e10`, `-0.5E-3` |

##### Collection Parsers
| Function | Signature | Description |
|----------|-----------|-------------|
| `parseArray` | `String -> Maybe (JsonValue, String)` | Parses JSON arrays (e.g., `[1, 2, 3]`) |
| `parseObject` | `String -> Maybe (JsonValue, String)` | Parses JSON objects (e.g., `{"key": "value"}`) |

##### High-level Functions
| Function | Signature | Description |
|----------|-----------|-------------|
| `parseJson` | `String -> Either String JsonValue` | Main parsing function, returns either parsed JSON or error message |
| `prettyPrint` | `JsonValue -> Int -> String` | Formats JSON with specified indentation level |

#### 🔄 Parser Combinators

| Combinator | Signature | Description |
|------------|-----------|-------------|
| `<|>` | `Maybe a -> Maybe a -> Maybe a` | Alternative combinator (tries left parser, falls back to right) |
| `parseWS` | `(String -> Maybe a) -> String -> Maybe a` | Wrapper that adds whitespace and comment skipping |

#### 📝 Utility Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `skipComments` | `String -> String` | Removes single-line comments (`// ...`) |
| `skipWhitespaceAndComments` | `String -> String` | Removes both whitespace and comments |
| `startsWith` | `String -> String -> (Bool, String)` | Checks if string starts with pattern, returns remaining |
| `skipSpaces` | `String -> String` | Removes leading whitespace characters |

#### 🔍 Internal Helper Functions

| Function | Description | Used By |
|----------|-------------|---------|
| `parseList` | Parses comma-separated lists of values | `parseArray` |
| `parseKeyValue` | Parses `"key": value` pairs | `parseObject` |
| `parseObjectItems` | Parses multiple key-value pairs | `parseObject` |

#### 📊 Data Type

| Type | Definition | Purpose |
|------|------------|---------|
| `JsonValue` | Algebraic data type with 7 constructors | Represents parsed JSON structure |
| `JsonParser` | `type JsonParser = String -> Maybe (JsonValue, String)` | Parser function type alias |

#### ⚠️ Error Handling

| Function | Returns | Description |
|----------|---------|-------------|
| `parseJson` | `Either String JsonValue` | `Left "error message"` on failure, `Right jsonValue` on success |
| Individual parsers | `Maybe (JsonValue, String)` | `Nothing` on parse failure, `Just (value, remaining)` on success |
----
### 🚫 Limitations
This is an educational project with the following limitations:

- Performance: No benchmarking or performance optimization performed

- Standards Compliance: Single-line comments (//) are non-standard in JSON

- Error Recovery: No sophisticated error recovery or line/column tracking

- Memory Usage: Not optimized for large JSON files

- Unicode Support: Basic string handling without full Unicode normalization

### 📚 Learning Objectives
This project demonstrates:

- Parser combinator design in functional programming

- Recursive algebraic data types for AST representation

- Monadic error handling with Maybe and Either

- Pattern matching and case expressions in Haskell

- Module organization and code structure

### 🔍 Implementation Details
Key Techniques
- Recursive Descent Parsing: Each parser function handles one syntactic construct

- Lookahead via Pattern Matching: Uses Haskell's pattern matching for token recognition

- Combinator Pattern: Small parsers combined to build complex parsers

- Whitespace Skipping: Integrated at each parsing step for robustness

Interesting Code Snippets
```haskell
-- Parser combinator for alternatives
infixl 3 <|>
(<|>) :: Maybe a -> Maybe a -> Maybe a 
(Just x) <|> _ = Just x 
Nothing <|> y = y

-- Recursive object parsing
parseObject :: JsonParser
parseObject = parseWS $ \case
  '{' : rest -> 
      case parseObjectItems rest of
          Just (items, '}' : remaining) -> Just (JsonObject (Map.fromList items), remaining)
          _ -> Nothing
  _ -> Nothing
```

----
### 📄 License
```text
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 🎯 Project Status
Status: Complete (Educational Project)

This project was developed for learning purposes and is considered feature-complete for its educational goals. No further development or maintenance is planned unless for academic purposes.

### 📚 Related Resources
- JSON Specification (RFC 8259)

- Haskell Programming from First Principles

- Parser Combinators in Haskell

### 🙏 Acknowledgments
Inspired by various parser combinator tutorials and educational materials

Thanks to the Haskell community for excellent learning resources

Built as part of a functional programming learning journey

