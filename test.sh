#!/bin/bash

# function get_bookmark_url(){
# 
#     echo "Bookmark is: $1"
# 
#     str_test="$1"
# 
#     local bookmark_id=$(sqlite3 ./db_copy.sqlite "SELECT fk FROM moz_bookmarks WHERE title='$1'")
#     
#     
#     bookmark_url=$(sqlite3 ./db_copy.sqlite "SELECT url FROM moz_places WHERE id=${bookmark_id}")
#     
# }
# 
# # Test string to search for (Exactly as it is in db):
# # "A Fresh Start" Print – Poorly Drawn Store
# 
# str_title='"A Fresh Start" Print – Poorly Drawn Store'
# 
# echo "str_title is: $str_title"
# 
# get_bookmark_url "$str_title"
# 
# echo "Bookmark url is: $bookmark_url"

bookmarks_str=$(sqlite3 ./db_copy.sqlite "SELECT title FROM moz_bookmarks WHERE parent='119' AND type='1'")
    
    
        # Setting delimiter to be a newline
    IFS=$'\n'
    # Reading each line from $subfolders into a the array "return_array"
    read -rd '' -a return_array <<< "$bookmarks_str"
    
    echo -e "${return_array[@]}"
    
