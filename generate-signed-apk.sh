#!/bin/bash
# vinigomescunha 
# File to sign apk unsigned based 
# set version of build tools, initially set as empty string
BUILDTOOLS_VERSION=""
# set apk file selected
APK_UNSIGNED=""
# set apk name generated/signed
APK_SIGNED=""
# set keystore file name generated
KEYSTORE_FILE=""
# define array of keystore data
KEYSTORE=();
#${KEYSTORE[0]} - keystore alias (* Required)
#${KEYSTORE[1]} - keystore pass (* Required)
#${KEYSTORE[2]} - First Name (Optional)
#${KEYSTORE[3]} - Last name (Optional)
#${KEYSTORE[4]} - Organization (Optional)
#${KEYSTORE[5]} - City (Optional)
#${KEYSTORE[6]} - State or Province (Optional)
#${KEYSTORE[7]} - two-letter country code (Optional)

function verifying_sdk_installed {
  echo "Verifying if ANDROID_HOME exist..."
  if [ -d "$ANDROID_HOME" ]; then
    echo "Android SDK exist"
  else
    zenity --error --text="Android SDK not found, verify Env Var ANDROID_HOME"
    exit 1
  fi
}
function set_build_version {
  # select build version directory
  FOLDER_SELECTED=$(zenity --file-selection --directory --title="Choose the version of the build you want to configure(Select the directory)" --filename=$ANDROID_HOME/build-tools/)
  # set build tools version based directory name
  BUILDTOOLS_VERSION="$(basename $FOLDER_SELECTED)"
}
function set_apk_data {
  # select apk unsigned
  FILE_SELECTED=$(zenity --file-selection --file-filter='APK Files (apk) | *.apk' --title="Select an APK")
  # set apk unsigned name depend of the selection
  APK_UNSIGNED="$FILE_SELECTED"
  # set apk signed name apk unsigned name based
  APK_SIGNED="$(dirname $FILE_SELECTED)/$(basename ${FILE_SELECTED%.*})-signed.apk"
}
function set_keystore_data {
  # set keystore file apk name based
  KEYSTORE_FILE="$(dirname $APK_UNSIGNED)/$(basename ${APK_UNSIGNED%.*}).keystore"
  # input select alias to keystore
  DIALOG=$(zenity --forms --title="Add Keystore Information" --text="Enter information about your .keystore." --separator=";" --add-entry="Keystore alias*"  --add-password="Password(min. 6)*" --add-entry="First Name" --add-entry="Last Name" --add-entry="Organization" --add-entry="City" --add-entry="State or Province" --add-entry="two-letter country code")
  KEYSTORE=(${DIALOG//;/ })
}
function generate_keystore {
  #generate keystore
  eval "keytool -genkey -noprompt -alias ${KEYSTORE[0]} -dname 'CN=${KEYSTORE[2]}, OU=${KEYSTORE[3]}, O=${KEYSTORE[4]}, L=${KEYSTORE[5]}, ST=${KEYSTORE[6]}, C=${KEYSTORE[7]}' -keystore $KEYSTORE_FILE -storepass ${KEYSTORE[1]} -keypass ${KEYSTORE[1]}  -keyalg RSA -keysize 2048 -validity 10000"
}
function align_apk {
  # align apk
  eval "$ANDROID_HOME/build-tools/$BUILDTOOLS_VERSION/zipalign -v 4 $APK_UNSIGNED $APK_SIGNED"
}
function sign_apk {
  # sign apk attach keystore file, apk signed and keystore alias and store keypass
  eval "jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_FILE $APK_SIGNED ${KEYSTORE[0]} -keypass ${KEYSTORE[1]} --storepass ${KEYSTORE[1]}"
}
function verify_apk {
  # verify if is signed
  if [[ $(eval "$ANDROID_HOME/build-tools/$BUILDTOOLS_VERSION/apksigner verify $APK_SIGNED 2>&1") ]]; then
    zenity --error --text="Signing failed apk failed: $APK_SIGNED"
  else
    zenity --info --text "Apk signed successfully: $APK_SIGNED" 2>/dev/null
  fi
}
function generate_info {
  echo " 
	******************************
	Data of Keystore Generated: 
	File: $KEYSTORE_FILE
	Alias: ${KEYSTORE[0]}
	Password: ${KEYSTORE[1]} 
	First Name: ${KEYSTORE[2]}
	Last Name: ${KEYSTORE[3]}
	Organization: ${KEYSTORE[4]}
	City: ${KEYSTORE[5]}
	State or Province: ${KEYSTORE[6]} 
	Country Code: ${KEYSTORE[7]}
	Apk Unsigned: $APK_UNSIGNED
	Apk Signed: $APK_SIGNED
	Build Tools version: $BUILDTOOLS_VERSION
	******************************
" >> "$APK_UNSIGNED.info.txt"
}
# verify if sdk is installed
verifying_sdk_installed
# select build tools version 
set_build_version
# select apk and set paths 
set_apk_data
# set alias to keystore
set_keystore_data
# generate keystore
generate_keystore
# align apk
align_apk
# sign apk
sign_apk
# verify apk is is signed
verify_apk
# generate information 
generate_info
