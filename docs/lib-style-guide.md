# Bash Library coding style guide

## Bash Library Naming Convention

This document provides a recommended naming convention for functions, variables, and library files in Bash. Following these guidelines will help avoid naming collisions, improve readability, and maintain consistency across projects.

---

### 1. Library File Naming

* Use `snake_case` for filenames.
* Library files **must end with `_lib.sh`** to indicate they are intended to be sourced and are not standalone scripts.
* Name the file according to the library's purpose.

**Example:**

```
conf_lib.sh        # Configuration library
network_lib.sh     # Networking utilities library
strings_lib.sh     # String manipulation library
```

**Non-library scripts:**

```
install_helpers.sh # May contain helpers but is executable
run_backup.sh      # Script intended to be executed
```

---

### 2. Function Naming

* Prefix all **public functions** with the library name (matching the file prefix).
* Use `snake_case` for function names.
* Distinguish private/internal functions using a double underscore `__` prefix or suffix.

**Format:**

```
<library_prefix>_<function_name>         # Public function
<library_prefix>__<function_name>        # Private/internal function
```

**Example:**

```bash
# File: conf_lib.sh

# Public functions
conf_lib_load_vars() {
    # implementation
}

conf_lib_save_vars() {
    # implementation
}

# Private/internal function
conf_lib__parse_internal() {
    # implementation
}
```

The two exceptions to this rule are the following,
which drop 'lib' from the method name:
file name  | method name   
log-lib  -> log, log_push_indent... etc
test-lib -> test_file_exists... etc

---

### 3. Variable Naming

* Prefix global variables with the library name.
* Use `UPPERCASE` for constants and environment-like variables.
* Use lowercase for internal variables within functions.

**Format:**

```
<LIBRARY_PREFIX>_<VARIABLE_NAME>       # Global variable
<LIBRARY_PREFIX>__<VARIABLE_NAME>      # Internal/private variable
```

**Example:**

```bash
# Global configuration variables
CONF_LIB_DEFAULT_PATH="/etc/myapp"
CONF_LIB_MAX_RETRIES=5

# Internal variable
local __count=0
```

---

### 4. Sourcing Libraries

* Always use `source` or `.` to load libraries.
* Avoid executing library files directly.
* Wrap your library code in a check to prevent double sourcing:

```bash
# conf_lib.sh

if [[ -n "${_CONF_LIB_SH_INCLUDED:-}" ]]; then
    return
fi
_CONF_LIB_SH_INCLUDED=1
```

---

### 5. Example Library Structure

```
conf_lib.sh
  ├─ conf_lib_load_vars()
  ├─ conf_lib_save_vars()
  └─ conf_lib__parse_internal()
```

Usage in a script:

```bash
#!/bin/bash
source conf_lib.sh

conf_lib_load_vars
```

---

### 6. Summary

* **Library file names:** snake_case ending with `_lib.sh`
* **Function names:** `<library_prefix>_<function_name>` (public), `<library_prefix>__<function_name>` (private)
* **Variable names:** `<LIBRARY_PREFIX>_<VARIABLE>` (global), `<LIBRARY_PREFIX>__<VARIABLE>` (private)
* **Consistency** is key for readability and avoiding collisions.

Following this methodology will keep your Bash libraries organized, maintainable, and scalable.

## Bash Line Wrapping and Continuation Cheat Sheet

This cheat sheet provides recommended practices for line length, continuation, and formatting in Bash scripts to improve readability and maintainability.

---

### 1. Recommended Line Length

* **80–100 characters per line** is ideal.
* Maximum **120 characters** if needed, but avoid when possible.
* Shorter lines improve readability in terminals and version control diffs.

---

### 2. Line Continuation Using `\`

Use `\` at the **end of a line** to continue a command on the next line.

* No trailing spaces after `\`
* Indent continuation lines 2–4 spaces for readability

**Examples:**

**Chaining commands:**

```bash
if [[ -f "$file" ]] && \
   [[ -r "$file" ]]; then
    echo "File exists and is readable"
fi
```

**Long command:**

```bash
rsync -avz --progress /source/path/ \
          /destination/path/
```

**Pipeline:**

```bash
grep "error" logfile.txt | \
awk '{print $2, $3}' | \
sort | uniq -c
```

---

### 3. Multi-line Constructs Without `\`

Some Bash constructs allow natural line breaks:

**Arrays:**

```bash
my_array=(
    "apple"
    "banana"
    "cherry"
)
```

**Subshell or grouping:**

```bash
(
    cd /tmp || exit
    tar -czf backup.tar.gz folder/
)
```

**Functions:**

```bash
my_function() {
    echo "This is a multi-line function"
    echo "Another line"
}
```

---

### 4. Breaking Lines at Logical Points

* Break after `|`, `&&`, `||`, `,` or `\` for clarity
* Avoid breaking in the middle of arguments or quoted strings

**Example:**

```bash
command1 arg1 arg2 && \
command2 argA argB || \
command3 argX argY
```

---

### 5. Indentation Guidelines

* Indent **continuation lines** 2–4 spaces
* Keep **nested structures** (loops, conditionals) consistently indented

**Example:**

```bash
for file in *.txt; do
    if [[ -s "$file" ]] && \
       [[ -r "$file" ]]; then
        echo "$file is non-empty and readable"
    fi
done
```

---

### 6. Summary

| Aspect            | Recommendation                             |                       |   |               |
| ----------------- | ------------------------------------------ | --------------------- | - | ------------- |
| Max line length   | 80–100 chars (120 max if necessary)        |                       |   |               |
| Line continuation | Use `\` at end, no trailing spaces         |                       |   |               |
| Break points      | After pipes `                              | `, logical ops `&&`/` |   | `, commas `,` |
| Alternatives      | Arrays `()`, grouping `()`, functions `{}` |                       |   |               |
| Indentation       | 2–4 spaces for continuation lines          |                       |   |               |

Following these guidelines will make Bash scripts **readable, maintainable, and easier to debug**.


