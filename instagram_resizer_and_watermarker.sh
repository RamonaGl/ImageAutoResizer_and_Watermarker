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

# functions
function check_DIR {
  DIR=$1
  if [ ! -d "$DIR" ]; then
    echo "Error: Directory ${DIR} not found --> EXIT."
    exit 1
  fi
}

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

# check if all needed DIR exist
check_DIR "$DIR_SCRIPT"
check_DIR "$DIR_SRCIMG"
#check_DIR "$DIR_WATERMARK_IMAGES"
check_DIR "$DIR_BASE"

##DIR_BASE=`realpath $1`  # works
### SE
#WATERMARK_IMAGE="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1600px.png"
#echo "WATERMARK_IMAGE = $WATERMARK_IMAGE"

# Resolutions to generate

# Instagram Maße:
# quadratische Posts 1:1 = 1080 px x 1080 px
# Querformat 1,91:1 = 1200 px x 628 px
# Hochformat 4:5 = 1080 px x 1350 px
# Story 9:16 = 1080 px bis 1920 px

sizeSquare=1080
widthLandscape=1200
heightLandscape=628
widthPortrait=$sizeSquare
heightPortrait=1350
widthStory=$sizeSquare
heightStory=1920

# create subfolders for images
DIR_WATERMARK=$DIR_SRCIMG"/watermarked"

DIR_WATERMARK_ORIGINALS=$DIR_WATERMARK"-originals"
DIR_WATERMARK_SQUARE=$DIR_WATERMARK"-square-"$sizeSquare"px-"$sizeSquare"px"
DIR_WATERMARK_LANDSCAPE=$DIR_WATERMARK"-landscape-"$widthLandscape"px-"$heightLandscape"px"
DIR_WATERMARK_PORTRAIT=$DIR_WATERMARK"-portrait-"$widthPortrait"px-"$heightPortrait"px"
DIR_WATERMARK_STORY=$DIR_WATERMARK"-story-"$widthStory"px-"$heightStory"px"

check_and_create_DIR "$DIR_WATERMARK_ORIGINALS"
check_and_create_DIR "$DIR_WATERMARK_SQUARE"
check_and_create_DIR "$DIR_WATERMARK_LANDSCAPE"
check_and_create_DIR "$DIR_WATERMARK_PORTRAIT"
check_and_create_DIR "$DIR_WATERMARK_STORY"
#check_files_existance "$WATERMARK_IMAGE"

cd "$DIR_BASE" || exit 1

# Watermark images
before=$(date +%s) # get timing
COUNTER=1
cd "$DIR_SRCIMG" || exit 1
echo "DIR_SRCIMG $DIR_SRCIMG"
for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic *.png *.PNG *.tiff *.TIFF *.raw *.RAW *.RW2; do
  echo "$COUNTER PROCESSING: >$FN<"
  ((COUNTER++))

  FN_CUT="${FN%.*}"
  FQFN_ORIGINALS=$DIR_WATERMARK_ORIGINALS/$FN_CUT".jpg"
  FQFN_SQUARE=$DIR_WATERMARK_SQUARE/$FN_CUT"-"$sizeSquare"px-"$sizeSquare"px.jpg"
  FQFN_LANDSCAPE=$DIR_WATERMARK_LANDSCAPE/$FN_CUT"-"$widthLandscape"px-"$heightLandscape"px.jpg"
  FQFN_PORTRAIT=$DIR_WATERMARK_PORTRAIT/$FN_CUT"-"$widthPortrait"px-"$heightPortrait"px.jpg"
  FQFN_STORY=$DIR_WATERMARK_STORY/$FN_CUT"-"$widthStory"px-"$heightStory"px.jpg"

  WIDTH=$(identify -ping -format '%w' "$FN")
  HEIGHT=$(identify -ping -format '%h' "$FN")
  # LABELLING_SIZE=$(($WIDTH / 150)) # dynamic
  LABELLING_SIZE=48 # static
  # OFFSET_WATERMARK_X=$(($WIDTH / 70)) # dynamic
  OFFSET_WATERMARK_X=30 # static
  # OFFSET_WATERMARK_Y=0 + LABELLING_SIZE
  OFFSET_WATERMARK_Y=30 # static
  LABELLING_TEXT="Watermark Text"
  TEXTCOLOR="#FFFFFF"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize \"$WIDTH\"x\"$HEIGHT\"^ -strip -gravity center -extent \"$WIDTH\"x\"$HEIGHT\" -quality $QUALITYJPG  \"$FQFN_ORIGINALS\" "
  eval "$CMD"
  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $(($LABELLING_SIZE * 3)) -gravity SouthEast -annotate +"$(($OFFSET_WATERMARK_X * 3))"+$(($OFFSET_WATERMARK_Y * 3)) \"${LABELLING_TEXT}\" \"$FQFN_ORIGINALS\" \"$FQFN_ORIGINALS\" "
  eval "$CMD"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize \"$sizeSquare\"x\"$sizeSquare\"^ -strip -gravity center -extent \"$sizeSquare\"x\"$sizeSquare\" -quality $QUALITYJPG  \"$FQFN_SQUARE\" "
  eval "$CMD"
  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity SouthEast -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y)) \"${LABELLING_TEXT}\" \"$FQFN_SQUARE\" \"$FQFN_SQUARE\" "
  eval "$CMD"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize \"$widthLandscape\"x\"$heightLandscape\"^ -strip -gravity center -extent \"$widthLandscape\"x\"$heightLandscape\" -quality $QUALITYJPG  \"$FQFN_LANDSCAPE\" "
  eval "$CMD"
  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity SouthEast -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y)) \"${LABELLING_TEXT}\" \"$FQFN_LANDSCAPE\" \"$FQFN_LANDSCAPE\" "
  eval "$CMD"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize \"$widthPortrait\"x\"$heightPortrait\"^ -strip -gravity center -extent \"$widthPortrait\"x\"$heightPortrait\" -quality $QUALITYJPG  \"$FQFN_PORTRAIT\" "
  eval "$CMD"
  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity SouthEast -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y)) \"${LABELLING_TEXT}\" \"$FQFN_PORTRAIT\" \"$FQFN_PORTRAIT\" "
  eval "$CMD"

  CMD="$CONVERT \"$DIR_SRCIMG/$FN\" -resize \"$widthStory\"x\"$heightStory\"\> -strip -quality $QUALITYJPG  \"$FQFN_STORY\" "
  eval "$CMD"
  CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity SouthEast -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y)) \"${LABELLING_TEXT}\" \"$FQFN_STORY\" \"$FQFN_STORY\" "
  eval "$CMD"

  #CMD="$COMPOSITE -gravity SouthWest -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANSPARENZ \( \"$WATERMARK_IMAGE\"  \) \"$FQFN_SQUARE\" \"$FQFN_SQUARE\" "
  #eval "$CMD"

done

after=$(date +%s)
runtime=$((after - before))
RT="elapsed time: $runtime seconds"
echo "$RT"
echo "$RT" >script_execution_time.txt

exit
