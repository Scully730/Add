#!/usr/bin/bash

search_files() {
    local pattern="$1"
    local search_path=$2
    grep -rlE "$pattern" $search_path
}

process_files() {
    local regex_filter="$1"
    shift  # Remove the first two arguments (the script file and regex filter) from the arguments list
    local files=("$@")  # Use the rest of the arguments as the list of files
    # Initialize a variable to store the result

    # Iterate over the list of files and process their contents, excluding the script file
    for file in "${files[@]}"; do
        if [ "$file" != "$script_file" ]; then
            # Process the file contents and add matching lines to the result variable
            while IFS= read -r line; do
                if [[ "$line" =~ $regex_filter ]]; then
                    echo $line >> $output_file
                fi
            done < "$file"
        fi
    done

}





# Default values for options
regex=$1
search_dir=$2
output_file=$3


# Shift the parsed options so that the remaining arguments (if any) are accessible as positional parameters
files=$(search_files "$regex" $search_dir)  # Capture the result returned by the function

positiveFiles=$(echo $files | wc -w)
echo "Found $positiveFiles files with lines matching your regex"
if [ $positiveFiles -eq 0 ]
then
    echo note: if you are having trouble constucting a regex pattern, see this https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions >&2
    echo SCRIPT DONE >&2
    exit 0
fi
echo If there are a lot of lines matching your regex, this will take a while >&2

echo Processing the files
#echo lines will be instantly written to the output file, so you may quit early
echo > $output_file
process_files "$regex" $files

echo -e Done, wrote $(cat $output_file | wc -l) lines to $output_file
echo SCRIPT DONE

