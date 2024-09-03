#!/bin/zsh

#  SetupPayloadMetadata.zsh
#  macInstaller
#
#  Created by Paulo Raffaelli on 8/19/24.
#

# Write out macInstaller/Resources/PayloadMetadata.plist, which contains
# the information the installer uses to copy the installed files
# to their destinations and set their owner and permissions.

# There are three options:
# 1. Install as system service running as root ('System')
# - The plist will be installed into '/Library/LaunchDaemons/'
# - The executable itself will be in a subdirectory of '/Library'
# 2. Install as user service for all users ('AllUsers')
# - The plist will be installed into '/Library/LaunchAgents/'
# - The executable itself will be in a subdirectory of '/Library'
# 3. Install as user service only for the currently logged-in user ('User')
# - The plist will be installed into '/Users/<username>/Library/LaunchAgents/'
# - The executable itself will be in a subdirectory of '/Users/<username>/Library/'
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

# Payloads (dictionary)
# The only recognized keys are 'System', 'AllUsers' and 'User'
plutil -insert "Payloads" -dictionary "$PAYLOAD_PLIST"

########## If Payloads.System is included, then the UI will allow the user to install the service as a system service #####
plutil -insert "Payloads.System" -dictionary "$PAYLOAD_PLIST"

plutil -insert "Payloads.System.Files" -array "$PAYLOAD_PLIST"
plutil -insert "Payloads.System.Files.0" -dictionary "$PAYLOAD_PLIST"
# system-level plists must be owned by root:wheel
plutil -insert "Payloads.System.Files.0.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# every system-level plist seems to have these permissions
plutil -insert "Payloads.System.Files.0.Permissions" -string "-rw-r--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.System.Files.0.Destination" -string "$PLIST_DIR" "$PAYLOAD_PLIST"
plutil -insert "Payloads.System.Files.0.Filename" -string "$INSTALLED_SYSTEM_SERVICE_PLIST" "$PAYLOAD_PLIST"

plutil -insert "Payloads.System.Files.1" -dictionary "$PAYLOAD_PLIST"
# system-level services must be owned by root:wheel
plutil -insert "Payloads.System.Files.1.OwnerGroup" -string "root:wheel" "$PAYLOAD_PLIST"
# system-level services must have these p
plutil -insert "Payloads.System.Files.1.Permissions" -string "-r-xr--r--" "$PAYLOAD_PLIST"
plutil -insert "Payloads.System.Files.1.Destination" -string "$INSTALL_DIR_SYSTEM_SERVICE" "$PAYLOAD_PLIST"
plutil -insert "Payloads.System.Files.1.Filename" -string "$INSTALLED_SYSTEM_SERVICE" "$PAYLOAD_PLIST"

########## If Payloads.AllUsers is included, then the UI will allow the user to install the service as a user service for all users #####
# plutil -insert "Payloads.AllUsers" -dictionary "$PAYLOAD_PLIST"

########## If Payloads.AllUsers is included, then the UI will allow the user to install the service as a user service for the
########## user that ran the installer
# plutil -insert "Payloads.User" -dictionary "$PAYLOAD_PLIST"

# PayloadMetadata.plist is checked whenever it is opened by the background service.
# It must have the structure
# BundleID -> String of the form ([a-zA-Z]+.)+[a-zA-Z]+
# Files -> nonempty array of Dictionary
# Each Dictionary must have these four keys:
# OwnerGroup -> "root:wheel"
# Permissions -> "-(r|w|x){9}"
# Destination -> /Library/...
# Filename -> a filename for a file in the 'Payload' subdirectory

