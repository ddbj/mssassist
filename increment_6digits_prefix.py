##################################################
# Developed by Andrea Ghelfi 2023.12.19
# Part of ddbj_sakura2DB, implements 6 digits for WGS and TPA-WGS datatype
##################################################
#!/usr/bin/env python3

import string
import os
import sys

def get_version():
    while True:
        user_input = input('Default version 01. Confirm version (y/n)? ').strip().lower()
        if user_input == 'y':
            return '01'
        elif user_input == 'n':
            version = input('Enter version number (Example v.02, type: 02): ').strip()
            if version.isdigit() and len(version) == 2 and version != '00':
                return version
            else:
                print("Invalid input. Please enter a two-digit number other than 00 for the version number.")
        else:
            print("Invalid input. Please enter 'y' or 'n'.")

def get_last_prefix(start_letter):
    file_paths = [
        '~/temp_sakura2DB/last_prefix_actual_conv.txt',
        '~/temp_sakura2DB/last_prefix_actual_umss.txt',
        '~/temp_sakura2DB/last_prefix_test_conv.txt',
        '~/temp_sakura2DB/last_prefix_test_umss.txt'
    ]

    prefixes = []
    for file_path in file_paths:
        expanded_path = os.path.expanduser(file_path)
        if os.path.exists(expanded_path):
            with open(expanded_path, 'r') as file:
                for line in file:
                    # Only consider the first 6 characters
                    prefix = line.strip()[:6]
                    # Exclude prefixes that contain numbers
                    if prefix and prefix.startswith(start_letter) and not any(char.isdigit() for char in prefix):
                        prefixes.append(prefix)
    
    if prefixes:
        max_prefix = max(prefixes)
        # Print the last prefix to the console
        print("Last Prefix:", max_prefix)
        return max_prefix
    else:
        default_prefix = start_letter + "00000"
        print("No new prefixes found.")
        return default_prefix

def increment_prefix(prefix, times=1, start_letter='B'):
    if prefix ==  start_letter + "00000":
        current_prefix = start_letter + "AAAAA"
    else:
        # Increment the given prefix first, then continue
        current_prefix = increment_single_prefix(prefix, start_letter)

    new_prefixes = [current_prefix]

    for _ in range(times - 1):
        current_prefix = increment_single_prefix(current_prefix, start_letter)
        new_prefixes.append(current_prefix)
    print("Suggested prefix start from:", new_prefixes[0])
    return new_prefixes

def increment_single_prefix(prefix, start_letter):
    letters = list(prefix[1:])

    for i in range(len(letters)-1, -1, -1):
        if letters[i] != 'Z':
            pos = string.ascii_uppercase.index(letters[i])
            letters[i] = string.ascii_uppercase[pos + 1]
            break
        else:
            letters[i] = 'A'

    return start_letter + ''.join(letters)

def process_prefixes(start_letter):
    last_prefix = get_last_prefix(start_letter)

    try:
        with open(input_ids_path, 'r') as file:
            input_ids = file.read().splitlines()
            line_count = len(input_ids)
    except IOError as e:
        print(f"Error reading file: {e}")
        return

    new_prefixes = increment_prefix(last_prefix, times=line_count, start_letter=start_letter)
    version = get_version()    

    try:
        with open(next_file_path, 'w') as file:
            for prefix in new_prefixes:
                file.write(prefix + version + '\n')
    except IOError as e:
        print(f"Error writing file: {e}")
        return

    try:
        with open(prefix_input_ids_path, 'w') as outfile:
            for prefix, id_ in zip(new_prefixes, input_ids):
                outfile.write(f"{prefix}{version}\t{id_}\n")
    except IOError as e:
        print(f"Error writing file: {e}")

if __name__ == "__main__":
    # File paths initialization
    input_ids_path = os.path.expanduser('~/temp_sakura2DB/input_ids.txt')
    next_file_path = os.path.expanduser('~/temp_sakura2DB/next_prefix.txt')
    prefix_input_ids_path = os.path.expanduser('~/temp_sakura2DB/prefix_input_ids.txt')
    
    # Retrieve the prefix type from command line argument
    prefix_type = sys.argv[1] if len(sys.argv) > 1 else 'WGS'
    start_letter = 'B' if prefix_type == 'WGS' else 'E' 

    process_prefixes(start_letter)