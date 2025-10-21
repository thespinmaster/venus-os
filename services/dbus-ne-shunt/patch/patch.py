#!/usr/bin/python3 -u

import os
import time
import sys

class patch_helper:
    
    start_comment_string = None
    end_comment_string = None
    patch_separator = None

    def __init__(patch_separator = "====", start_comment_string = "/*", end_comment_string = "*/") :
        patch_separator = patch_separator
        start_comment_string = start_comment_string
        end_comment_string = end_comment_string

    def _find(self, dest_lines, find_lines):
 
        found = False
        in_comment = False
        iline = -1
        iline_comment = -1
        dest_range = range(len(dest_lines))
        find_range = range(len(find_lines))
        
        for i in dest_range:
            ln = dest_lines[i].strip()

            if ((not in_comment and ln == start_comment_string) or (in_comment and ln == end_comment_string)):
                in_comment = not in_comment
                if (not in_comment and found):
                    break
                iline_comment = i if in_comment else -1
            elif in_comment and found:
                    continue # continue until end comment is reached
            
            for x in find_range:
                xln = find_lines[x].strip()
                if (ln == xln):
                    if iline == -1:
                        iline = i if not in_comment else iline_comment
                    if (x == find_range.stop - 1):
                        found = True
                        break 
                    i += 1
                    if (i == dest_range.stop - 1):
                        break
                    ln = dest_lines[i].strip()
                else:
                    iline = -1
                    break
            if (found and not in_comment):
                break

        if (found):
            return (iline, i)
        
        return -1
    
    def _loadPatch(self, patch_file):
        with open(patch_file, 'r') as file:
            patch_items = file.read().split(patch_separator + "\n")
            if (len(patch_items) == 0):
                print("Invalid patch file")
                return 1
            return patch_items
    
    def _writePatch(self, patch_file, lines):
        with open(patch_file, "w") as file:
            file.writelines(lines)

    def apply(self, file_to_patch, file_with_patch):
        
        patch_items = self._loadPatch(file_with_patch)
        if patch_items == 1:
            return 1

        with open(file_to_patch, 'r') as file:
            dest_lines = file.readlines()
        
        result = None
        command = None
        last_result = None
        last_command = None

        for i in range(len(patch_items)):
            
            lines = patch_items[i].splitlines()
            command = lines.pop(0)

            match command:
                case "@find":     
                    result = self._find(dest_lines, lines)
                    # if result is -1 could not find text
                
                case "@insertafter" | "@insertbefore":
                    if (last_command == "@find" and last_result != -1):
                        result = self._find(dest_lines, lines)
                        if (result == -1): # if -1 then insert has not been added
                            index = last_result[0] if command == "@insertbefore" else last_result[1] + 1

                            for i in range(len(lines)-1, -1, -1):
                                dest_lines.insert(index, lines[i] + "\n")

                    command = None
                    result = None

                case "@remove":
                    # When removing we only comment out the text. 
                    # This is so we can find it easily when reversing
                    result = self._find(dest_lines, lines)
                    if (result != -1):
                        dest_lines.insert(result[1] + 1, end_comment_string + "\n")
                        dest_lines.insert(result[0], start_comment_string + "\n")

                    command = None
                    result = None

            last_command = command
            last_result = result

        self._writePatch(file_to_patch, dest_lines)


    def revert(self, file_to_patch, file_with_patch):
        
        patch_items = self._loadPatch(file_with_patch)

        with open(file_to_patch, 'r') as file:
            dest_lines = file.readlines()
        
        result = None
        command = None
        last_result = None
        last_command = None

        for i in range(0, len(patch_items), 1):
            
            lines = patch_items[i].splitlines()
            command = lines.pop(0)

            match patch_items[i]:
                case "@find":     
                    #result = self._find(dest_lines, lines)
                    # if result is -1 could not find text
                    pass
                case "@insertafter" | "@insertbefore":
 
                    result = self._find(dest_lines, lines)
                    if (result != -1): # if -1 then insert has not been added
                        for i in range(len(lines)):
                            dest_lines.pop(result[0])

                    command = None
                    result = None

                case "@remove":
                    # When removing we only comment out the text. 
                    # This is so we can find it easily when reverting
                    result = self._find(dest_lines, lines)
                    if (result != -1):
                        if result[1] > 0:
                            if dest_lines[result[1]] == end_comment_string + "\n":
                                dest_lines.pop(result[1])

                        if result[0] > 0:
                            if dest_lines[result[0]] == start_comment_string + "\n":
                                dest_lines.pop(result[0])

                    command = None
                    result = None

            last_command = command
            last_result = result
  
        self._writePatch(file_to_patch, dest_lines)

if __name__ == "__main__":

    orig_patch_file = "/home/admin/dev/projects/venus-os/services/dbus-ne-shunt/patch/test.orig"
    working_patch_file = "/home/admin/dev/projects/venus-os/services/dbus-ne-shunt/patch/test.working"
    patchFile = "/home/admin/dev/projects/venus-os/services/dbus-ne-shunt/patch/test.patch"
 
    with open(orig_patch_file, 'r') as file:
        contents = file.read()
    with open(working_patch_file, 'w') as file:
        file.write(contents)
    contents = None

    ph = patch_helper()
    ph.apply(working_patch_file, patchFile)

    #ph.revert(working_patch_file, patchFile)
