#!/bin/bash
# Some functions will be in order at some point..

# A logger
function log(){

        # INFO
        if [[ $1 == 1  ]] && [[ $debug == 1 || $verbose == 1 ]]; then
        echo -e "INFO: $2\n"
        fi
        # DEBUG
        if [[ $1 == 2  ]] && [[ $debug == 1 ]]; then
        echo -e "DEBUG: $2\n"
        fi    
        # ERROR
        if [[ $1 == 3  ]]; then
        echo -e "WARNING: $2\n"
        fi
        # Print on scren instead of file
        if [[ $1 == 4  ]] &&  [[ $print == 1 ]]; then
        echo -e "PRINT: $2"
        fi
}

# # One for reading a config file (§future)?
# function get_config(){
#     
# }
# 
# One for reading the database
function get_bookmark_db(){

    # I know my firefox profile is named custom-profile, so finding it,
    # and its bookmark db with
    local db_path=$(find "$HOME/.mozilla/firefox/"*".default-release" | grep "places.sqlite$")
    db_copy="./db_copy.sqlite"

    # Firefox locks places DB when browser is running
    if [ ! "$(cmp $db_path $db_copy)" ]; then
        cp $db_path $db_copy
    fi

    bookmark_db="$db_copy"
    
}

# Get subfolders of a bookmark folder. First arg is the DB
# the second arg is the name of the folder to get subfolders from
function get_subfolders() {

    #get_bookmark_folder "$1"

    #echo "Getting subfolders of: $1"

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the folders, and not all the bookmarks, use type='2'.
    # Type 1 is bookmarks, 2 is folders
    subfolders_str=$(sqlite3 $bookmark_db "SELECT id FROM moz_bookmarks WHERE parent='$2' AND type='2'")
    
    #echo "Subfolders of $1 are $subfolders_str"
#     echo "Amount of subfolders of $1 are $subfolders_str"
    
    # "Return" in 1 line
    #subfolders="(string_to_array "$subfolders_str")"
    
    # Return in 2 lines
    string_to_array "$1" "$subfolders_str"
#     declare -a subfolders=("${return_array[@]}")
#     #echo "Amount of subfolders of $1 are "${#subfolder[@]}""
#     
#     echo ${subfolders[@]}
    
}

# Get bookmarks of a bookmark folder. First arg is the DB
# the second arg is the name of the folder to get bookmarks from.
function get_bookmarks() {

    #echo "Getting bookmarks of: $1, in $bookmark_folder"

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the bookmarks, use type='1'.
    # Type 1 is bookmarks, 2 is folders
    local bookmarks_str=$(sqlite3 $bookmark_db "SELECT id FROM moz_bookmarks WHERE parent='$2' AND type='1'")
    
    #echo "bookmarks_str is $bookmarks_str"
    
    # Reutn in 1 line
    # booksmarks=$(string_to_array "$bookmarks_str")
    
    # Return in 2 lines
    string_to_array "$1" "$bookmarks_str"
#     bookmarks=("${return_array[@]}")
#     
#     echo ${bookmarks[@]}
    
}

function get_bookmark_url(){

    #echo "Getting url of: $1"

    # Getting the fk (Some kind of internal id for bookmarks across tables)
    local bookmark_id=$(sqlite3 $bookmark_db "SELECT fk FROM moz_bookmarks WHERE id='$1'")
    
    # Getting the url, based on th fk
    bookmark_url=$(sqlite3 $bookmark_db "SELECT url FROM moz_places WHERE id=${bookmark_id}")
    
    echo $bookmark_url
    
}

function get_entry_name(){

    local entry_name=$(sqlite3 $bookmark_db "SELECT title FROM moz_bookmarks WHERE id=$1")
    
    echo $entry_name
    
}

function get_entry_type(){
    
    local entry_type=$(sqlite3 $bookmark_db "SELECT type FROM moz_bookmarks WHERE id=$1")
    
    echo $entry_type
    
}

function string_to_array() {

    # Setting delimiter to be a newline
    IFS=$'\n'
    # Reading each line from $subfolders into a the array "return_array"
    read -rd '' -a "$1" <<< "$2"

}

# Adds title (name of root folder) to the file
# in a title formatting
function add_title() {

    if [[ $print ]]; then
        log 4 "# $1"
    else
        echo -e "# $1\n" > $output_file
    fi
}
# Looks for header in given file.
# Adds a header if it is not there:
# 'header':
function add_header() {

    if [[ $print ]]; then
    
        log 4 "|$1"
    else

        while read y; do
            if [[ "$1" = $y ]]; then
                return 0
            fi
        done < $output_file
        
        echo -e "#$1\n" >> $output_file
    fi
    
}

# Adds an entry in form:
# - 'title'
#   - 'url'
function add_bulletpoint() {

    if [[ $print ]]; then
    
        log 4 "|$1\n           - $2"
    else

        while read y; do
            if [[ "$1" = $y ]]; then
                return 0
            fi
        done < $output_file
        
        echo -e "- $1\n       [ Link ]( "$2" )\n" >> $output_file
    fi
}

# Function that 
function add_to_file() {


    
    echo -e $2 > $1
}

# Echoes 0 if not empty
function empty_entry(){

    local entry_type=$(get_entry_type "$1")
    
    echo ${#subfolders[@]}
    echo ${#bookmarks[@]}
    
    if [[ ${#subfolders[@]} = 0 && ${#bookmarks[@]} = 0 ]]; then
    
        for folder in ${#subfolders[@]}; do
    
            if [[ $(empty_entry $folder) == 0 ]]; then
                echo "1"
                
                return
            fi
            
        done
            
    else
    
        echo "0"
    fi
}

# This function prints folders (and their subfolder (recursive) and bookmarks).
# When there are no more folders, it prints any bookmarks there is in the folder.
function entry_traverse(){
    local counter=0
    local entry
    
    for entry in "$@"; do
        counter=$((counter+1))
    
        local entry_name=$(get_entry_name "$entry")
        local entry_type=$(get_entry_type "$entry")
        
        get_subfolders "subfolder_array" "$entry"
        local subfolders=("${subfolder_array[@]}")
        
        get_bookmarks "bookmarks_array" "$entry"
        local bookmarks=("${bookmarks_array[@]}")            
        
#         log 1 "$counter. entry is $entry_name, with id: $entry of type: $entry_type\n      It have ${#subfolders[@]} subfolder(s), and ${#bookmarks[@]} bookmark(s)."       
        
        
        if [[ $entry_name = $title ]]; then
        
            add_title "$entry_name"
            
        elif [[ $entry_type = 1 ]]; then 
            
            log 1 "$counter. entry is $entry_name, a bookmark with id: $entry."
            
            if [[ deepness == 1 ]]; then
            
                add_header "Blandet"
            fi
            
            add_bulletpoint " $entry_name" $(get_bookmark_url $entry)
            
        elif [[ ( $entry_type = 2 ) &&  ( ( ${#subfolders[@]} > 0 ) || ${#bookmarks[@]} > 0) ]]; then
            
#             if [[ $(empty_entry $entry) == 0 ]]; then
#                 log 1 "$entry_name is empty, skipping."
#                 return
#             fi
        
            log 1 "$counter. entry is $entry_name, a folder with id: $entry.\n      It have ${#subfolders[@]} subfolder(s), and ${#bookmarks[@]} bookmark(s) in it."
            
            # Print deepness indicator
            indic=""
            __counter=1

            while [[ $__counter < $deepness ]]; do
                indic+="#"
                ((__counter++))
            done
            
            add_header "$indic $entry_name"
        
        fi
        
        if [[ ${#subfolders[@]} > 0 ]]; then
        
        # Code for subfolders --START
        
            log 1 "Traversing folders inside $entry_name"
            deepness=$((deepness+1))
            log 1 "Deepness is: $deepness (gone up)"
            
            entry_traverse ${subfolders[@]}
    
            deepness=$((deepness-1))
            log 1 "Deepness is: $deepness (gone down)"
    
        # Code for subfolders -- STOP
        
        fi

        if [[ ${#bookmarks[@]} > 0 ]]; then
        
        # Code for bookmarks --START
        
            log 1 "Traversing bookmarks inside $entry_name"
            entry_traverse ${bookmarks[@]}
            
        # Code for bookmarks -- STOP
            
        fi
        
#         log 1 "$counter. loop done."
                
    done
}

# Checking for log mode
if [[ $1 == "-v" ]]; then
    verbose=1
elif [[ $1 == "-d" ]]; then
    debug=1
elif [[ $1 == "-p" ]]; then
    print=1
fi

# Get the bookmark db
get_bookmark_db
log 2 "Bookmark DB is: $bookmark_db"

output_file="test-file.md"

# Testmappe is 792, øsnekliste 378
bookmark_folder=378
log 1 "Bookmark folder is: $bookmark_folder"
# echo "Choosen bookmark folder:"
title=$(get_entry_name "$bookmark_folder")

deepness=0
entry_traverse "$bookmark_folder"
