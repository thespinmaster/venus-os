
#!/bin/bash

# --------------------------------------------------------
# Function Definition
# Removes a multiline string from another string.
# The strings can contain any special characters.
# The match must be an exact match
# Arguments: 
# $1 = the pattern to remove (passed via -v)
# $2 = the source is passed via STDIN (e.g., using <<< or a file name)
# Returns: The modified content is passed to stdout
# --------------------------------------------------------
awk_remove_multiline_string() {
    local pattern="$1"
    shift
  
    # We use "-" as the filename argument to awk, which tells awk to read from STDIN
    awk -v pattern="$pattern" '
        BEGIN {RS = ""; ORS = ""} # Slurp entire file/input, keep output separator empty

        {
            content = $0;
            # Find the first match using literal index search
            match_pos = index(content, pattern);
            
            if (match_pos > 0) {
                # Rebuild the string: part before the match + part after the match
                len_pattern = length(pattern);
                new_content = substr(content, 1, match_pos - 1);
                new_content = new_content substr(content, match_pos + len_pattern);
                print new_content;
            } else {
              print content; # No match, return original content
            }
        }
    ' "$@"
}

# --------------------------------------------------------
# Checks if a multiline string exists in another string.
# The check is for an exact match
# Function Definition
# Arguments: 
# $1 = the pattern to remove (passed via -v)
# $2 = the source is passed via STDIN (e.g., using <<< or a file name)
# Returns: 1 if there is at least 1 match else; nothing
# --------------------------------------------------------
awk_contains_multiline_string() {
    local pattern="$1"
  
    awk -v pattern="$pattern" '
        BEGIN {RS = ""; ORS = ""} # Slurp entire file/input, keep output separator empty
        {
            # Find the first match using literal index search
            content = $0
            match_pos = index(content, pattern);
            if (match_pos > 0) {
 		print 1
                exit 0   
            }
        }
    ' "${@:2}"
}
