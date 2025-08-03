#!/bin/zsh

#  SetupPayloadMetadata.zsh
#  macInstaller
#
#  Created by Paulo Raffaelli on 8/19/24.
#

# Write out macInstaller/Resources/PayloadMetadata.plist, which contains
# the information the installer uses to copy the installed files
# to their destinations and set their owner and permissions.

# There are two options:
# 1. Install as system service running as root ('AllUsers')
# - The plist will be installed into '/Library/LaunchDaemons/'
# - The executable itself will be in a subdirectory of '/Library'
# 2. Install as user service only for the currently logged-in user ('User')
# - The plist will be installed into '/Users/<username>/Library/LaunchAgents/'
# - The executable itself will be in a subdirectory of '/Users/<username>/Library/'
# The plist telling the OS where to find the executable for the installed service

#### system service: Payload/AllUsers/com.greenkitty.product.plist -> /Library/LaunchDaemons
SOURCE_ALLUSER_SERVICE='com.greenkitty.product'
ALLUSER_SERVICE_EXEC="$SOURCE_ALLUSER_SERVICE"
ALLUSER_SERVICE_PLIST="$SOURCE_ALLUSER_SERVICE.plist"
ALLUSER_SERVICE_PLIST_DEST_DIR='/Library/LaunchDaemons/'

# The location and name of the installed system service's executable.
ALLUSER_SERVICE_DEST_DIR='/Library/PrivilegedHelperTools/'
ALLUSER_SERVICE_FULL_PATH="$ALLUSER_SERVICE_DEST_DIR/$SOURCE_ALLUSER_SERVICE"

#### user service: Payload/User/com.greenkitty.product.plist -> /Library/LaunchAgents
SOURCE_USER_SERVICE='com.greenkitty.product'
USER_SERVICE_EXEC="$SOURCE_USER_SERVICE"
USER_SERVICE_PLIST="$SOURCE_USER_SERVICE.plist"
USER_SERVICE_PLIST_DEST_DIR='/Library/LaunchAgents/'

# The location and name of the installed system service's executable.
### the actual destination directory is /Users/<current logged-in-user>/Library/LaunchAgents
#
USER_SERVICE_DEST_DIR="/Library/Application Support/$SOURCE_USER_SERVICE/"
USER_SERVICE_FULL_PATH="$USER_SERVICE_DEST_DIR/$SOURCE_USER_SERVICE"


# --------------- customize with your own files to be installed ------
# /Library/LaunchDaemons/SOURCE_ALLUSER_SERVICE.plist
# owner is root:wheel
# permissions are -rw-r--r--
#
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#     <key>Label</key>
#     <string>SOURCE_ALLUSER_SERVICE</string>
#     <key>Program</key>
#     <string>SYSTEM_SERVICE_FULL_PATH</string>
#     <key>RunAtLoad</key>
#     <true/>
#     <key>KeepAlive</key>
#     <true/>
# </dict>
# </plist>

# ----- 'AllUsers' services install to /Library/LaunchDaemons or /Library/LaunchAgents

# Create PayloadMetadata
PAYLOAD_PLIST='macInstaller/Payload/PayloadMetadata.plist'
plutil -create xml1 "$PAYLOAD_PLIST"

# Bundle identifier="$SOURCE_ALLUSER_SERVICE"
plutil -insert "BundleID" -string "$SOURCE_ALLUSER_SERVICE" "$PAYLOAD_PLIST"
# Files: array of dictionary

# Payloads (dictionary)
# The only recognized keys are 'AllUsers' and 'User'
plutil -insert "Payloads" -dictionary "$PAYLOAD_PLIST"

########## If Payloads.AllUsers is included, then the UI will allow the user to install the service as a system service #####
plutil -insert "Payloads.AllUsers" -dictionary "$PAYLOAD_PLIST"

plutil -insert "Payloads.AllUsers.Files" -array "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.0" -dictionary "$PAYLOAD_PLIST"
# system-level plists must be owned by root:wheel
plutil -insert "Payloads.AllUsers.Files.0.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# every system-level plist seems to have these permissions
plutil -insert "Payloads.AllUsers.Files.0.Permissions" -string "-rw-r--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.0.Destination" -string "$ALLUSER_SERVICE_PLIST_DEST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.0.Filename" -string "$ALLUSER_SERVICE_PLIST" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.0.SHA256" -string "`shasum -a 256 "macInstaller/Payload/AllUsers/$ALLUSER_SERVICE_PLIST" | cut -d " " -f 1`" "$PAYLOAD_PLIST"

plutil -insert "Payloads.AllUsers.Files.1" -dictionary "$PAYLOAD_PLIST"
# system-level services must be owned by root:wheel
plutil -insert "Payloads.AllUsers.Files.1.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# system-level services must have these p
plutil -insert "Payloads.AllUsers.Files.1.Permissions" -string "-r-xr--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.1.Destination" -string "$ALLUSER_SERVICE_DEST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.1.Filename" -string "$ALLUSER_SERVICE_EXEC" "$PAYLOAD_PLIST"
plutil -insert "Payloads.AllUsers.Files.1.SHA256" -string "`shasum -a 256 "macInstaller/Payload/AllUsers/$ALLUSER_SERVICE_EXEC" | cut -d " " -f 1`" "$PAYLOAD_PLIST"

########## If Payloads.User is included, then the UI will allow the user to install the service for a single user ###
plutil -insert "Payloads.User" -dictionary "$PAYLOAD_PLIST"

plutil -insert "Payloads.User.Files" -array "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.0" -dictionary "$PAYLOAD_PLIST"
# system-level plists must be owned by root:wheel
plutil -insert "Payloads.User.Files.0.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# every system-level plist seems to have these permissions
plutil -insert "Payloads.User.Files.0.Permissions" -string "-rw-r--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.0.Destination" -string "$USER_SERVICE_PLIST_DEST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.0.Filename" -string "$USER_SERVICE_PLIST" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.0.SHA256" -string "`shasum -a 256 "macInstaller/Payload/User/$USER_SERVICE_PLIST" | cut -d " " -f 1`" "$PAYLOAD_PLIST"

plutil -insert "Payloads.User.Files.1" -dictionary "$PAYLOAD_PLIST"
# system-level services must be owned by root:wheel
plutil -insert "Payloads.User.Files.1.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# system-level services must have these p
plutil -insert "Payloads.User.Files.1.Permissions" -string "-r-xr--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.1.Destination" -string "$USER_SERVICE_DEST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.1.Filename" -string "$USER_SERVICE_EXEC" "$PAYLOAD_PLIST"
plutil -insert "Payloads.User.Files.1.SHA256" -string "`shasum -a 256 "macInstaller/Payload/User/$USER_SERVICE_EXEC" | cut -d " " -f 1`" "$PAYLOAD_PLIST"

# PayloadMetadata.plist is checked whenever it is opened by the background service.
# It must have the structure
# BundleID -> String of the form ([a-zA-Z]+.)+[a-zA-Z]+
# Files -> nonempty array of Dictionary
# Each Dictionary must have these five keys:
# OwnerGroup -> "root:wheel"
# Permissions -> "-(r|w|x){9}"
# Destination -> /Library/...
# Filename -> a filename for a file in the 'Payload' subdirectory
# SHA256 -> the SHA 256 hash of the file being installed.
