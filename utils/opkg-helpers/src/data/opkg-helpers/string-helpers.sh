
#!/bin/bash

# --------------------------------------------------------
# Finds and replaces multiline text in the string contents privided
# in STDIN. The search string can contain any characters.
# Arguments
# $1 (required): The multi-line string to find/replace
#  --break-on-first | -b : Exists when the first item is found or removed. 
#  --opt_find_only  | -f : Find the text only. Returns the number of occurances. if break-on-first will return 1
#                          otherwise the source string is returned with the multiline strings removed. 
#  --opt_trim_lines | -t : Trims line feeds around the removed strings. (tries to leave one space)
#  
#  Input: Content via STDIN '< [filename]' or '<<< [string]' to supply the contents
#  Returns: The modified string or the number of matches depending on the options above
# --------------------------------------------------------
multiline_string_match() {
  
  if [[ -z "$1" ]]; then
    echo "no search string provided"
    exit 1
  fi

  IFS=$'\n' read -d '' -r -a pat_lines <<< "$1"
  shift

  declare -i pat_len=${#pat_lines[@]}; declare -i idx_pat=0
  declare -i match_start=-1;  declare -i found=0
  declare -i opt_break_on_first=0; declare -i opt_find_only=0
  declare -i opt_trim_lines=0
  newline=$'\n'
  output=

# process args
while [ $# -gt 0 ]; do
  case "$1" in
    --break-on-first*|-b*)
      opt_break_on_first=1
      ;;
    --find-only*|-f*)
      opt_find_only=1
      ;;
    --trim-lines*|-t*)
      opt_trim_lines=1
      ;;
    --help|-h)
      HELP="Searches for a multiline string in the stdin.
  
  Version 1.1
  
  Arguments:  
  \$1 : the multiline string to find/replace 
  --break-on-first | -b : Exists when the first item is found or removed. 
  --opt_find_only  | -f : Find the text only. Returns the number of occurances. if break-on-first will return 1
                          otherwise the source string is returned with the multiline strings removed. 
  --opt_trim_lines | -t : Trims line feeds around the removed strings. (tries to leave one space)
  
  Input: Content via STDIN '< [filename]' or '<<< [string]' to supply the contents
  Returns: The modified string or the number of matches depending on the options above  
"
      echo "${HELP}"
      exit 0
      ;;
    *)
      >&2 printf "string-helpers.sh :Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done
########################################################
  
  # for debugging
  #for pline in "${pat_lines[@]}"; do echo "$idx_pat:$pline"; idx_pat+=1; done
  # idx_pat=0

  while IFS= read -r line; do
 
    if [[ "${pat_lines[$idx_pat]}" == "$line" ]] && \
      [[ $found -eq 0 || $opt_break_on_first -ne 1 ]]; then

      if [[ $idx_pat -eq 0 ]]; then match_start=${#output}; fi 
      
      idx_pat+=1
      if [[ $idx_pat -eq $pat_len ]]; then
        idx_pat=0
        found+=1
        if [[ $opt_find_only -eq 0 ]]; then 
          if [[ $opt_trim_lines -eq 0 ]]; then
            output="${output:0:match_start}"
          else
            if [[ "${output:(match_start-2):1}" == "$newline" ]]; then
              match_start=$((match_start-1))
            fi
 
            output="${output:0:match_start}"
            IFS= read -r line
            if [[ -n "$line" ]]; then
              output+="${newline}$line"
            fi
          fi
        elif [[ $opt_break_on_first -eq 1 ]]; then
          break
        fi
        continue
      fi
    else
      idx_pat=0
    fi      
    if [[ $opt_find_only -eq 0 ]]; then output+="${newline}$line"; fi
  done
  
  if [[ $opt_find_only -eq 0 ]] ; then
    echo "${output}"
  elif [[ $found -gt 0 ]]; then
    echo $found
  fi

}
