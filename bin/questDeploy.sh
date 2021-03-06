#!/bin/bash                                                                                                                                                                                                 

# I put a variable in my scripts named PROGNAME which
# holds the name of the program being run.  You can get this
# value from the first item on the command line ($0).
PROGNAME=$(basename $0)

# Assign the current work directory to the bash script variable 'CWD'.
CWD=$(pwd)
trap "git checkout --quiet master && cd $CWD" EXIT

function error_exit
{

#   ----------------------------------------------------------------
#   Function for exit due to fatal program error
#               Accepts 1 argument:
#                       string containing descriptive error message
#   ----------------------------------------------------------------
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

cd ~/quest
git fetch --quiet
git fetch --tags --quiet

# Get latest tag name
LATESTTAG=$(git describe --tags $(git rev-list --tags="v$1*" --max-count=1)) || error_exit "$LINENO: could find tags in $1"

# Checkout latest tag
git checkout --quiet $LATESTTAG || error_exit "$LINENO: could not checkout $LATESTTAG."

# Get version
SUBVERSION="$(node -pe 'JSON.parse(process.argv[1]).version' "$(cat ~/quest/package.json)")"
echo -e "\e[36m \nExporting $SUBVERSION... \e[0m"

# deploy directory
DIR="$HOME/commonjs/quest/$SUBVERSION"

# make sure directory doesn't exist
if [ -d $DIR ]; then
    echo "Directory already exists: removing..."
    rm -rf $DIR;
fi

echo "Creating directory: $DIR"
mkdir -p $DIR || "$LINENO: could not create directory $DIR"

echo "Copying files to $SUBVERSION"
cp -r ~/quest/{dist,bower_components,package.json} $DIR


# extended globbing on
shopt -s extglob

# if the parameter is of the form 0.0 create a minor directory
if [[ $1 == *([0-9]).*([0-9]) ]]; then
    LATESTDIR= echo "$DIR" | sed 's/.[0-9]*$//'
    echo -e "\e[36m \nExporting latest: $1... \e[0m"
    rm -rf $HOME/commonjs/quest/$1
    mkdir -p $HOME/commonjs/quest/$1
    echo "Copying files to $HOME/commonjs/quest/$1"
    cp -r ~/quest/{dist,bower_components,package.json} $HOME/commonjs/quest/$1
fi

#################################
# master
#################################

git checkout --quiet master

echo -e "\e[36m \nExporting master... \e[0m"

# deploy directory
DIR="$HOME/commonjs/quest/master"

# make sure directory doesn't exist
rm -rf $DIR;

echo "Creating directory: $DIR"
mkdir -p $DIR || "$LINENO: could not create directory $DIR"

echo "Copying files to master"
cp -r ~/quest/{dist,bower_components,package.json} $DIR

# extended globbing off
shopt -u extglob
