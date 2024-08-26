#!/bin/zsh

#  SetupPayloadMetadata.zsh
#  macInstaller
#
#  Created by Paulo Raffaelli on 8/19/24.
#

# Write out macInstaller/Resources/PayloadMetadata.plist, which contains
# the information the installer uses to copy the installed files
# to their destinations and set their owner and permissions.

# The plist telling the OS where to find the executable for the installed service
INSTALLED_SYSTEM_SERVICE='com.greenkitty.product'
INSTALLED_SYSTEM_SERVICE_PLIST="$INSTALLED_SYSTEM_SERVICE.plist"
PLIST_DIR='/Library/LaunchDaemons/'

# The location and name of the installed service's executable.
INSTALL_DIR_SYSTEM_SERVICE='/Library/PrivilegedHelperTools/'
PATH_TO_INSTALLED_SYSTEM_SERVICE="$INSTALL_DIR_SYSTEM_SERVICE/$INSTALLED_SYSTEM_SERVICE"

# --------------- customize with your own files to be installed ------
# /Library/LaunchDaemons/INSTALLED_SYSTEM_SERVICE.plist
# owner is root:wheel
# permissions are -rw-r--r--
#
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#     <key>Label</key>
#     <string>INSTALLED_SYSTEM_SERVICE</string>
#     <key>Program</key>
#     <string>PATH_TO_INSTALLED_SYSTEM_SERVICE</string>
#     <key>RunAtLoad</key>
#     <true/>
#     <key>KeepAlive</key>
#     <true/>
# </dict>
# </plist>


# Create PayloadMetadata
PAYLOAD_PLIST='macInstaller/Payload/PayloadMetadata.plist'
plutil -create xml1 "$PAYLOAD_PLIST"

# Bundle identifier="$INSTALLED_SYSTEM_SERVICE"
plutil -insert "BundleID" -string "$INSTALLED_SYSTEM_SERVICE" "$PAYLOAD_PLIST"
# Files: array of dictionary
PAYLOAD_PLIST='macInstaller/Payload/PayloadMetadata.plist'
plutil -insert "Files" -array "$PAYLOAD_PLIST"
#   [ OwnerGroup: "root:wheel" Permissions: "-rw-r--r--" Destination: "$PLIST_DIR" Filename: "$INSTALLED_SYSTEM_SERVICE_PLIST" ]
plutil -insert "Files.0" -dictionary "$PAYLOAD_PLIST"
plutil -insert "Files.0.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
plutil -insert "Files.0.Permissions" -string "-rw-r--r--" "$PAYLOAD_PLIST"
plutil -insert "Files.0.Destination" -string "$PLIST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Files.0.Filename" -string "$INSTALLED_SYSTEM_SERVICE_PLIST" "$PAYLOAD_PLIST"

#   [ OwnerGroup: "root:wheel" Permissions: "-r-xr--r--" Destination: "$INSTALL_DIR_SYSTEM_SERVICE" Filename: "$INSTALLED_SYSTEM_SERVICE" ]
plutil -insert "Files.1" -dictionary "$PAYLOAD_PLIST"
plutil -insert "Files.1.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
plutil -insert "Files.1.Permissions" -string "-r-xr--r--" "$PAYLOAD_PLIST"
plutil -insert "Files.1.Destination" -string "$INSTALL_DIR_SYSTEM_SERVICE" "$PAYLOAD_PLIST"
plutil -insert "Files.1.Filename" -string "$INSTALLED_SYSTEM_SERVICE" "$PAYLOAD_PLIST"

# PayloadMetadata.plist is checked whenever it is opened by the background service.
# It must have the structure
# BundleID -> String of the form ([a-zA-Z]+.)+[a-zA-Z]+
# Files -> nonempty array of Dictionary
# Each Dictionary must have these four keys:
# OwnerGroup -> "root:wheel"
# Permissions -> "-(r|w|x){9}"
# Destination -> /Library/...
# Filename -> a filename for a file in the 'Payload' subdirectory

