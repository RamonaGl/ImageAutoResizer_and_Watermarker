#! /bin/bash

# 2022-07 Code by Ramona and Hagen Glötter
# See www.gloetter.de

# Setup on Mac:
# brew install coreutils
# brew install imagemagick
# brew install guetzli

# Instagram Maße:
# quadratische Posts 1:1 = 1080 px x 1080 px
# Querformat 1,91:1 = 1200 px x 628 px
# Hochformat 4:5 = 1080 px x 1350 px
# Story 9:16 = 1080 px bis 1920 px

_self="${0##*/}"
echo "$_self is called"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [Picture-Foldername]"
  exit 1
fi

shopt -s nullglob
# use the nullglob option to simply ignore a failed match and not enter the body of the loop.
COMPOSITE=$(which composite) # path to imagemagick compose
CONVERT=$(which convert)
QUALITYJPG="85"
UBUNTU=$(grep -i "ubuntu" </etc/issue)
if [ $? -eq 0 ]; then
  echo "$UBUNTU detected"
  DIR_SCRIPT=$(dirname "$(readlink -f "$0")")
  DIR_SRCIMG=$(readlink -f "$1") # works on all *nix systems to make path absolute
else
  echo "MacOS detected"
  DIR_SCRIPT=$(dirname "$(greadlink -f "$0")")
  DIR_SRCIMG=$(greadlink -f "$1") # works on all *nix systems to make path absolute
fi
DIR_BASE=$(pwd) # does sometimes not work :-(
#DIR_WATERMARK_IMAGES="$DIR_SCRIPT/watermark-images"

echo "DIR_BASE:   $DIR_BASE"
echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_SCRIPT: $DIR_SCRIPT"
#echo "DIR_WATERMARK_IMAGES: $DIR_WATERMARK_IMAGES"

# Resolutions to generate
# IDEA Make this as an array and loop through the resolutions an generate all dirs on the fly
r6k=6000
r4k=4000
r2k=1680

function check_DIR {
  DIR=$1
  if [ ! -d "$DIR" ]; then
    echo "Error: Directory ${DIR} not found --> EXIT."
    exit 1
  fi
}

# functions
function check_and_create_DIR {
  DIR=$1
  #  [ -d "$DIR" ] && echo "Directory $DIR exists. -> OK" || mkdir $DIR # works but not so verbose
  if [ -d "$DIR" ]; then
    echo "${DIR} exists -> OK"
  else
    mkdir "$DIR"
    echo "Error: ${DIR} not found. Creating."
  fi
  # check if it worked
  if [ ! -d "$DIR" ]; then
    echo "Error: ${DIR} CAN NOT CREATE --> EXIT."
    exit 1
  fi
}

function check_files_existance {
  FN=$1
  if [ ! -f "$FN" ]; then
    echo "Error: $FN NOT FOUND --> EXIT."
    exit 1
  fi
}

function get_filename_without_extension {
  filename=$1
  FN_CUT="${filename%.*}"
  #  filename=$(basename -- "$1")
  #  extension="${filename##*.}"
  #  filename="${filename%.*}"
  return "$FN_CUT"
}

# check if all needed DIR exist
check_DIR "$DIR_SCRIPT"
check_DIR "$DIR_SRCIMG"
#check_DIR "$DIR_WATERMARK_IMAGES"
check_DIR "$DIR_BASE"

##DIR_BASE=`realpath $1`  # works
### SE
#WATERMARK_SE_L="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1600px.png"
#echo "WATERMARK_SE_L = $WATERMARK_SE_L"
#WATERMARK_SE_M="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png"
#echo "WATERMARK_SE_M = $WATERMARK_SE_M"
#WATERMARK_SE_S="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_500px.png"
#echo "WATERMARK_SE_S = $WATERMARK_SE_S"

# create subfolders for images
DIR_WATERMARK=$DIR_SRCIMG"/watermarked"
DIR_WATERMARK_2k=$DIR_WATERMARK"-"$r2k"px"
DIR_WATERMARK_4k=$DIR_WATERMARK"-"$r4k"px"
DIR_WATERMARK_6k=$DIR_WATERMARK"-"$r6k"px"
check_and_create_DIR "$DIR_WATERMARK_2k"
check_and_create_DIR "$DIR_WATERMARK_4k"
check_and_create_DIR "$DIR_WATERMARK_6k"
#check_files_existance "$WATERMARK_SE_S"
#check_files_existance "$WATERMARK_SE_M"
#check_files_existance "$WATERMARK_SE_L"

cd "$DIR_BASE" || exit 1

# Watermark images
before=$(date +%s) # get timing
COUNTER=1
cd "$DIR_SRCIMG" || exit 1
for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic *.png *.PNG; do
  echo "$COUNTER PROCESSING: >$FN<"
  ((COUNTER++))

  FN_CUT="${FN%.*}"
  FQFN_6k=$DIR_WATERMARK_6k/$FN_CUT"-"$r6k"px.jpg"
  FQFN_4k=$DIR_WATERMARK_4k/$FN_CUT"-"$r4k"px.jpg"
  FQFN_2k=$DIR_WATERMARK_2k/$FN_CUT"-"$r2k"px.jpg"
  
  echo "$FQFN_6k"
  echo "$FQFN_4k"
  echo "$FQFN_2k"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize $r6k -strip -quality $QUALITYJPG  \"$FQFN_6k\" "
  eval "$CMD"

  WIDTH=$(identify -ping -format '%w' "$FN")
  echo "WIDTH: $WIDTH"
  LABELLING_SIZE=$(($WIDTH / 60))
  OFFSET_WATERMARK_X=$(($WIDTH / 50))
  OFFSET_WATERMARK_Y=100
  LABELLING_TEXT="Watermark Text"
  TEXTCOLOR="#FFFFFF"

  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity NorthWest -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y + $(($LABELLING_SIZE * 2)))) \"${LABELLING_TEXT}\" \"$FQFN_6k\" \"$FQFN_6k\" "
  eval "$CMD"

  CMD="$CONVERT \"$FQFN_6k\" -resize $r4k -strip -quality $QUALITYJPG  \"$FQFN_4k\" "
  eval "$CMD &"
  CMD="$CONVERT \"$FQFN_6k\" -resize $r2k -strip -quality $QUALITYJPG  \"$FQFN_2k\" "
  eval "$CMD &"
done

after=$(date +%s)
runtime=$((after - before))
RT="elapsed time: $runtime seconds"
echo "$RT"
echo "$RT" >script_execution_time.txt

exit
