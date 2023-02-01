#!/usr/bin/env bash

# does an api call to my api

source autocommit-env

function get_hidden_key {
        # hash our key and the current 10 second interal in the epoch
        # creates a new key that the server will know, and expires in 10 seconds
        # we use the part before the : as the identifier, and the part after as the hashed part
        local identifier=$(echo $AUTOCOMMIT_KEY | cut -f 1 -d :)
        local ten_second_interval=$(ruby -e 'puts (Time.now.to_f/10).truncate()')
        local hidden_key=$(echo $(echo $AUTOCOMMIT_KEY | cut -f 2 -d :)$ten_second_interval | md5)
        echo $identifier:$hidden_key # return the hidden key
        # should be secure enough, since we already have ssl
        # md5 isn't secure because hash collisions can be found.
        # since ours changes every 10 seconds, it is essentially secure
        # also, md5 has a simple plain js implementation, and is "generally faster than sha256"
}

diff=$(mktemp /tmp/diff.XXXXXX)
git diff $(git log -n 1 | grep "^commit" | cut -f 2 -d " ") > $diff
# makes the diff between HEAD and the staged working tree

commit_message=$(mktemp /tmp/commit-message.XXXXXX)
# where to store the autocommit message
# gpt could return something that needs to be escaped
# shove it into a file to simplify things

curl -s \
	"https://u1319464.wixsite.com/git-autocommit--chan/_functions-dev/autocommit?key=$(get_hidden_key)" \
	-H 'Content-Type: application/json' \
	--data @$diff \
	> $commit_message
# gets the autocommit message from my api
# currently outputs nothing if key is wrong

git commit -eF $commit_message
# sets the commit message to our autocommit message, and then opens it for editing in git's default editor

rm $commit_message
rm $diff
