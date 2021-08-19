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

# Looks for header in given file.
# Adds a header if it is not there:
# 'header':
function add_header() {

    while read y; do
        if [[ "$1" = $y ]]; then
            return 0
        fi
    done < $2
    
    echo -e $1 >> $2
    
}

# Adds an entry in form:
# - 'title'
#   - 'url'
function add_bulletpoint() {

    
    echo "- $1\n  - $2"
}

function add_to_file() {
    echo "oo"
}

# This function prints folders (and their subfolder (recursive) and bookmarks).
# When there are no more folders, it prints any bookmarks there is in the folder.

function entry_traverse(){
    local counter=0

    for entry in "$@"; do
        counter=$((counter+1))
    
        local entry_name=$(get_entry_name "$entry")
        local entry_type=$(get_entry_type "$entry")
        
        get_subfolders "subfolder_array" "$entry"
        local subfolders=("${subfolder_array[@]}")
        
        get_bookmarks "bookmarks_array" "$entry"
        local bookmarks=("${bookmarks_array[@]}")            
        
        log 1 "$counter. entry is $entry_name, with id: $entry of type: $entry_type\n      It have ${#subfolders[@]} subfolder(s), and ${#bookmarks[@]} bookmark(s)."
        
            
            if [[ $entry_type = 1 ]]; then 
            
            echo "| |- $entry_name"
            echo "|"
            elif [[ $entry_type = 2 ]]; then

            echo "|-$entry_name"
            
            fi

        if [[ ${#bookmarks[@]} > 0 ]]; then
        
        # Code for bookmarks --START
        
            log 1 "Traversing bookmarks inside $entry_name"
            entry_traverse ${bookmarks[@]}
            
        # Code for bookmarks -- STOP
            
        fi
        
        if [[ ${#subfolders[@]} > 0 ]]; then
        
        # Code for subfolders --START
        
            log 1 "Traversing folders inside $entry_name"
            entry_traverse ${subfolders[@]}
    
        # Code for subfolders -- STOP
        
        fi
        
        log 1 "$counter. loop done."
                
    done  
}

#  ${#bookmarks[@]} ${#subfolders[@]}

# Setup nescessary properties
# (Reading the config file §future)

if [[ $1 == "-v" ]]; then
    verbose=1
elif [[ $1 == "-d" ]]; then
    debug=1
fi

# Get the bookmark db
get_bookmark_db

log 2 "Bookmark DB is: $bookmark_db"

# Testmappe is 792, øsnekliste 126
bookmark_folder=792
log 1 "Bookmark folder is: $bookmark_folder"
echo "Choosen bookmark folder:"
entry_traverse "$bookmark_folder"
