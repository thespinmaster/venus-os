# Bash Config Library — v1.0

A dependency-free Bash library for safely reading, validating, and managing
configuration files. It is designed to replace fragile `source`-based configs with
a robust, linted, schema-aware system.

---

## Features

- Safe config loading without `source` or `eval`
- Multiline quoted strings and heredocs
- Escaped double quote handling (`\"`)
- Schema support with default values, types, and required fields
- Configuration linting with optional auto-fix
- Style enforcement (uppercase public variables)
- JSON output for linting
- Deterministic parsing suitable for CI pipelines

---

## Files

```
conf-lib              # Main library (source this)
example.conf          # Example configuration file
example.conf.schema   # Example schema file
example.sh            # Example consumer script
```

---

## Installation

Just copy `conf_lib` into your project and source it in your scripts:

```bash
source ./conf_lib
```

---

## Usage

### Load configuration safely

```bash
conf_lib_load_vars path/to/config.conf
```

- Loads variables into the current shell
- Supports multiline quoted strings and heredocs
- Handles escaped quotes
- Fails on invalid syntax

### Load configuration with schema validation

```bash
conf_lib_load_with_schema path/to/config.conf
```

- Automatically loads `path/to/config.conf.schema` if it exists
- Applies default values
- Enforces required variables
- Validates value types
- Runs strict linting with style checks

---

## Linting

Use `conf_lib_lint` to validate configuration files without loading them:

```bash
conf_lib_lint path/to/config.conf [options]
```

### Options

| Option      | Description |
|------------|-------------|
| `--strict` | Enforce strict parsing rules (invalid escapes, trailing garbage) |
| `--style`  | Enforce style rules (uppercase public variables) |
| `--fix`    | Auto-fix trivial issues (trailing whitespace) |
| `--json`   | Output lint results in JSON format |

### Exit Codes

| Code | Meaning |
|-----:|--------|
| 0    | No issues |
| 1    | Warnings only |
| 2    | Errors found |

---

## Configuration file format (`*.conf`)

- Data-only: no shell code execution
- Variable names must be valid Bash identifiers
- Public variables should be uppercase
- Supports quoted values, multiline strings, and heredocs
- Supports escaped double quotes (`\"`)
- Comments and blank lines are allowed

### Example (`example.conf`)

```bash
PORT="8080"
HOST="localhost"

MESSAGE="He said \"hello\"
and this is line two"

BANNER<<EOF
Welcome to the system
This is a banner
EOF
```

Rules:

- Variable names must be valid Bash identifiers
- Public variables should be UPPERCASE
- No command substitution
- No arithmetic expansion
- No unquoted values

---

## Schema files (`*.conf.schema`)

Schema files define allowed variables, types, default values, and required flags.

- Must use the naming convention: `<config>.conf.schema`
- Format:

```
KEY | TYPE | DEFAULT | FLAGS
```

### Example (`example.conf.schema`)

```text
PORT     | int           | 8080       | required
HOST     | string        | localhost  | required
DEBUG    | bool          | false      |
MODE     | enum:dev,prod | dev        |
MESSAGE  | string        |            |
```

Supported types:

- `string`
- `int`
- `bool`
- `enum:a,b,c`

Schema flags:

- `required`

---

## Public Functions

### `conf_lib_lint <file> [options]`

Lint a configuration file. Options: `--strict`, `--style`, `--fix`, `--json`.

- Returns 0 on success, 1 on warnings, 2 on errors

### `conf_lib_load <file>`

Safely load a `.conf` file into the current shell.

- Supports multiline values and heredocs
- Escapes quotes correctly
- Returns non-zero on failure

### `conf_lib_load_with_schema <file>`

Load a `.conf` file with schema validation.

- Loads `<file>.conf.schema` if available
- Applies defaults, enforces required variables
- Validates values against types
- Returns non-zero on failure

### `conf_lib_load_schema <schema_file>`

Load a schema file into internal associative arrays.

- Populates `CONF_SCHEMA_TYPE`, `CONF_SCHEMA_DEFAULT`, `CONF_SCHEMA_REQUIRED`
- Returns non-zero on invalid schema

### `conf_lib_schema_validate_value <value> <type>`

Validate a value against a schema type.

- Returns 0 if valid, 1 if invalid

---

## Design Guarantees

- No code execution from config files
- Deterministic parsing
- Fail-fast on invalid configuration
- Safe for CI pipelines and production scripts

---

## Versioning

- **v1.0**: API frozen, fully documented, ready for production

---

## License

MIT (or your preferred license)

