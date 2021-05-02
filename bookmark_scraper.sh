#!/bin/bash
# Some functions will be in order at some point..

# A logger
function log(){

        # INFO
        if [[ $1 == 1  ]] && [[ $debug == 1 || $verbose == 1 ]]; then
        echo "INFO: $2\n"
        fi
        # DEBUG
        if [[ $1 == 2  ]] && [[ $debug == 1 ]]; then
        echo "DEBUG: $2\n"
        fi    
        # ERROR
        if [[ $1 == 3  ]]; then
        echo "WARNING: $2\n"
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

function get_bookmark_folder(){

    echo "Arg1 is: $1"

    # Check to see if there already is set bookmark_folder
    # (If there is a parent)
    if [[ $bookmark_folder ]]; then
    
        
    
        echo "The var bookmark_folder already exists"
        
        echo "Saving old bookmark_folder as: $bookmark_folder"
        old_bookmark_folder=$bookmark_folder
        
        echo "The "old" bookmark_folder is now: $old_bookmark_folder"
        
        # Get the id of the row where the title is",
        # the bookmarks folder I want to scrape.
        bookmark_folder=$(sqlite3 $bookmark_db "SELECT id FROM moz_bookmarks WHERE title='$1' AND parent='$old_bookmark_folder'")
        
    else
    
        echo "No older bookmark_folder"
        
        # Get the id of the entry where the title is $1,
        # the argument given to this funciton
        bookmark_folder=$(sqlite3 $bookmark_db "SELECT id FROM moz_bookmarks WHERE title='$1'")
        
    fi
    
    echo "bookmark_folder is now $bookmark_folder"
}

# Get subfolders of a bookmark folder. First arg is the DB
# the second arg is the name of the folder to get subfolders from
function get_subfolders() {

    get_bookmark_folder "$1"

    echo "Getting subfolders of: $1, with id $bookmark_folder"

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the folders, and not all the bookmarks, use type='2'.
    # Type 1 is bookmarks, 2 is folders
    subfolders_str=$(sqlite3 $bookmark_db "SELECT title FROM moz_bookmarks WHERE parent='$bookmark_folder' AND type='2'")
    
#     echo "Subfolders of $1 are $subfolders_str"
#     echo "Amount of subfolders of $1 are $subfolders_str"
    
    # "Return" in 1 line
    #subfolders="(string_to_array "$subfolders_str")"
    
    # Return in 2 lines
    string_to_array "$subfolders_str"
    subfolders=("${return_array[@]}")
    echo "Amount of subfolders of $1 are "${#subfolder[@]}""
    
}

# Get bookmarks of a bookmark folder. First arg is the DB
# the second arg is the name of the folder to get bookmarks from.
function get_bookmarks() {

    echo "Getting bookmarks of: $1, in $bookmark_folder"
    
    get_bookmark_folder "$1"
    
    echo "bookmark_folder is $bookmark_folder"

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the bookmarks, use type='1'.
    # Type 1 is bookmarks, 2 is folders
    bookmarks_str=$(sqlite3 $bookmark_db "SELECT title FROM moz_bookmarks WHERE parent='$bookmark_folder' AND type='1'")
    
    echo "bookmarks_str is $bookmarks_str"
    
    # Reutn in 1 line
#     booksmarks=$(string_to_array "$bookmarks_str")
    
    # Return in 2 lines
    string_to_array "$bookmarks_str"
    bookmarks=("${return_array[@]}")
    
}



function get_bookmark_url(){

    #echo "Getting url of: $1"

    # Getting the fk (Some kind of internal id for bookmarks across tables)
    local bookmark_id=$(sqlite3 $bookmark_db "SELECT fk FROM moz_bookmarks WHERE title='$1'")
    
    # Getting the url, based on th fk
    bookmark_url=$(sqlite3 $bookmark_db "SELECT url FROM moz_places WHERE id=${bookmark_id}")
    
}

function string_to_array() {

    # Setting delimiter to be a newline
    IFS=$'\n'
    # Reading each line from $subfolders into a the array "return_array"
    read -rd '' -a return_array <<< "$1"

}

# This function prints folders (and their subfolder (recursive) and bookmarks).
# When there are no more folders, it prints any bookmarks there is in the folder.

function entry_traverse(){

    log 1 "entry_traverse called with arg1 as $1:"
    echo "$1:\n"
    
    log 2 "Parent loop start"
    local entry
    for entry in "$@"; do
    
        # Code for subfolder traversion -- START
        get_subfolders "$entry"
        
        log 2 "Entry is $entry"
        log 2 "$entry have ${#subfolders[@]} subfolders"
        
        # If there are any subfolders
        if [[ ${#subfolders[@]} > 0 ]]; then
            log 2 "Subfolders will be printed now:"
            
            # Tarverse the subfolders
            echo "$(entry_traverse "${return_array[@]}")\n"
            
            log 2 "Subfolders done printing"
            
#         elif [[ ${#subfolders[@]} == 0 ]]; then
#             log 2 "Printing name of no subfolder folder:"
#             echo "$entry:\n"
        fi
        # Code for subfolder -- STOP
        
        # Code for bookmarks --START

        get_bookmarks "$entry"
        
        log 2 "Entry is $entry"
        log 2 "$entry have ${#bookmarks[@]} bookmarks"
        
        if [[ ${#bookmarks[@]} > 0 ]]; then

            log 2 "Bookmarks will be printed now:"
            
            for bookmark in "${bookmarks[@]}"; do
                echo "|--$bookmark\n"
            done
            # Code for bookmarks -- STOP
        
        fi
        

    done
    log 2 "Parent loop done\n"
    
## FUNCTION FINISHED
    
    # Leftovers:
    #         
#         for entry in "${return_array[@]}"; do
#             entry_traverse $entry
# 
#         done
    
}

# 
# # One for writing to the markdown(§future) file (and convert to pdf?)
# function write_to_file(){
#     
# }

# Setup nescessary properties
# (Reading the config file §future)

if [[ $1 == "-v" ]]; then
    verbose=1
elif [[ $1 == "-d" ]]; then
    debug=1
fi



# Get the bookmark db
get_bookmark_db

echo -e "Bookmark DB is: $bookmark_db\n"

#echo -e $(entry_traverse "Ønskeliste")

echo "running: get_subfolders "Ønskeliste":"
get_subfolders "Ønskeliste"

echo "running: get_subfolders "Musik":"
get_subfolders "Musik"
echo "running: get_bookmarks "Musik":"
get_bookmarks "Musik"



echo "${bookmarks[@]}"


# printf -- "%s\n" "$(entry_traverse "Ønskeliste")"

# echo -e "$(entry_traverse "Ønskeliste")"

# New line for clean terminal..
#printf "\n"

    
#"SELECT fk FROM moz_bookmarks WHERE title=\"${choice}\""

# 
# bookmark_id=$(sqlite3 ${BOOKMARKS_PATH} "SELECT fk FROM moz_bookmarks WHERE title=\"${choice}\"")
# 
# url=$(sqlite3 ${BOOKMARKS_PATH} "SELECT url FROM moz_places WHERE id=${bookmark_id}")
# # 
