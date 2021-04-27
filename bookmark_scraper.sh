#!/bin/bash
# Some functions will be in order at some point..

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

    #printf "In get_subfolders()\nArg1 is $1\nArg2 is $2\n"

    # Get the id of the row where the title is "Ønskeliste",
    # the bookmarks folder I want to scrape.
    local bookmark_folder=$(sqlite3 $db_copy "SELECT id FROM moz_bookmarks WHERE title='$1'")

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the folders, and not all the bookmarks, use type='2'.
    # Type 1 is bookmarks, 2 is folders
    subfolders=$(sqlite3 $db_copy "SELECT title FROM moz_bookmarks WHERE parent='$bookmark_folder' AND type='2'")
    
}

# Get bookmarks of a bookmark folder. First arg is the DB
# the second arg is the name of the folder to get bookmarks from.
function get_bookmarks() {

    #printf "In get_subfolders()\nArg1 is $1\nArg2 is $2\n"

    # Get the id of the row where the title is "Ønskeliste",
    # the bookmarks folder I want to scrape.
    local bookmark_folder=$(sqlite3 $db_copy "SELECT id FROM moz_bookmarks WHERE title='$1'")

    # Get the titles of the subfolders from that folder
    # Firefox uses the parameter "parent" to determin "parent folders".
    # Parents are identified by their id, so parent='$bookmark_folder'
    # To only get the bookmarks, use type='1'.
    # Type 1 is bookmarks, 2 is folders
    bookmarks=$(sqlite3 $db_copy "SELECT title FROM moz_bookmarks WHERE parent='$bookmark_folder' AND type='1'")
    
}



function get_bookmark_url(){

    echo "$1"

    local bookmark_id=$(sqlite3 $db_copy "SELECT fk FROM moz_bookmarks WHERE title=\'\"Toxic Thinking\" Print – the Awkward Store\'")
    bookmark_url=$(sqlite3 $db_copy "SELECT url FROM moz_places WHERE id=${bookmark_id}")
    
}

function string_to_array() {

    # Setting delimiter to be a newline
    IFS=$'\n'
    # Reading each line from $subfolders into a the array "return_array"
    read -rd '' -a return_array <<< "$1"

}

# The core logic is a for loop that traverses each folder (entry in the
# return_array) and reading its entries.
# If it is a folder (type=2), print the name of the folder
# as a heading in a markdown file, read that folders entries
# (and run this loop inside that second folder) to print those entries under
# the second folders heading.
# If it is a bookmark (type=1), get the title and url, and print them
# in the markdown file under a "Andet" (Danish for other) heading.

function entry_traverse(){

    for entry in "$@"; do
        printf "$entry:\n"
        
        # Check to see if there are any subfolders
        get_subfolders $entry
        
        # If not; get the bookmarks
        if [[ ! "$subfolders" ]]; then
            get_bookmarks $entry
            string_to_array "$bookmarks"
            for bookmark in "${return_array[@]}"; do
                get_bookmark_url "${bookmark}"
                #printf -- "|-- %s\n|   -%s\n" "$bookmark" "$bookmark_url"
                printf ""
            done
        else
            #folder_traverse $entry
            #echo "Not empty"
            string_to_array "$subfolders"
            printf -- "|-- %s\n" "${return_array[@]}"
        fi
        printf "|\n"
    done
}

# 
# # One for writing to the markdown(§future) file (and convert to pdf?)
# function write_to_file(){
#     
# }

# Setup nescessary properties
# (Reading the config file §future)

# Get the bookmark db
get_bookmark_db

get_subfolders "Ønskeliste"
#echo $subfolders

string_to_array "$subfolders"

#printf -- "|-- %s\n" "${return_array[@]}"

entry_traverse "${return_array[@]}"

    
#"SELECT fk FROM moz_bookmarks WHERE title=\"${choice}\""

# 
# bookmark_id=$(sqlite3 ${BOOKMARKS_PATH} "SELECT fk FROM moz_bookmarks WHERE title=\"${choice}\"")
# 
# url=$(sqlite3 ${BOOKMARKS_PATH} "SELECT url FROM moz_places WHERE id=${bookmark_id}")
# # 
