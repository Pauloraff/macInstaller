#!/bin/zsh

#  AdjustProjectSettings.zsh
#  macInstaller
#
#  Created by Paulo Raffaelli on 7/14/24.
#

# CLIENTNAME name of main (client) program: com.greenkitty.macinstaller
# HELPERNAME name of helper service: com.greenkitty.macinstallerhelper
# SIGNINGCERT Name of signing cert is 'Developer ID Application: Paulo Raffaelli (2XEVFK8ZST)'
# COMPANYNAME Name for folder created in /Library/Application Support for the installed software.

echo "Client app bundle identifier is $CLIENTNAME"
echo "Background service bundle identifier is $HELPERNAME"
echo "Signing cert for both app and service is $SIGNINGCERT"
echo "Company name for installed software is $COMPANYNAME"

# sample invocation
# SIGNINGCERT="Developer ID Application: Paulo Raffaelli (2XEVFK8ZST)" CLIENTNAME="com.greenkitty.macinstaller" HELPERNAME="com.greenkitty.macinstallerhelper" COMPANYMAME="Green Kitty" ./AdjustProjectSettings.zsh
# Note that if CLIENTNAME is a prefix of HELPERNAME, this script works.
# If HELPERNAME is a prefix of CLIENTNAME, then this script will fail.

# SIGNINGTEAM is '2XEVFK8ZST'
SIGNINGTEAM=`[[ "$SIGNINGCERT" =~ '\([A-Z0-9]*\)' ]] && echo $MATCH | tr -d '()'`
echo "Team identifier for both app and service is $SIGNINGTEAM"

# ESCAPEDHELPER is needed because '.' is the separator for property paths in plutil,
# and we want to insert keys with embedded periods.
ESCAPEDHELPER=`echo "$HELPERNAME" | sed 's/\./\\\./g'`

CLIENTNAMETESTS="${CLIENTNAME}Tests"
echo "Client app test target name is $CLIENTNAMETESTS"

CLIENTNAMEUITESTS="${CLIENTNAME}UITests"
echo "Client app UI test target name is $CLIENTNAMEUITESTS"

# target name is 'HELPERNAME'
# HELPERNAME target Bundle identifier 'HELPERNAME'
# HELPERNAME target Build setting Objective-C Bridging Header = 'HELPERNAME/HELPERNAME-Bridging-Header.h'
sed "s/HELPERNAME/$HELPERNAME/g" macInstaller/macInstaller.xcodeproj/project.pbxproj > temp.out

# macInstaller target Bundle identifier 'CLIENTNAME'
sed "s/CLIENTNAMETESTS/$CLIENTNAMETESTS/g" temp.out > temp2.out
rm temp.out
sed "s/CLIENTNAMEUITESTS/$CLIENTNAMEUITESTS/g" temp2.out > temp3.out
rm temp2.out
sed "s/CLIENTNAME/$CLIENTNAME/g" temp3.out > temp4.out
rm temp3.out

# cert used to sign executables
sed "s/SIGNINGCERT/$SIGNINGCERT/g" temp4.out > temp5.out
rm temp4.out

# dev team
sed "s/SIGNINGTEAM/$SIGNINGTEAM/g" temp5.out > temp6.out
rm temp5.out

# copy modified .pbxproj file over
rm macInstaller/macInstaller.xcodeproj/project.pbxproj
mv temp6.out macInstaller/macInstaller.xcodeproj/project.pbxproj

# macInstaller/Resources/PayloadMetadata.plist
sed "s/HELPERNAME/$HELPERNAME/g" macInstaller/Resources/PayloadMetadata.plist > temp.out
mv temp.out macInstaller/Resources/PayloadMetadata.plist
sed "s/COMPANYNAME/$COMPANYNAME/g" macInstaller/Resources/PayloadMetadata.plist > temp.out
mv temp.out macInstaller/Resources/PayloadMetadata.plist

# macInstaller/macInstaller/Info.plist:
# key 'HELPERNAME'
# value 'identifier "CLIENTNAME" and anchor apple generic and certificate leaf[subject.CN] = "SIGNINGIDENT"'

echo "SMPrivilegedExecutables in macInstaller/macInstaller/Info.plist"
plutil -remove "SMPrivilegedExecutables" macInstaller/macInstaller/Info.plist
plutil -insert "SMPrivilegedExecutables" -dictionary macInstaller/macInstaller/Info.plist
plutil -insert "SMPrivilegedExecutables.$ESCAPEDHELPER" -string "identifier \"$HELPERNAME\" and anchor apple generic and certificate leaf[subject.CN] = \"$SIGNINGCERT\"" macInstaller/macInstaller/Info.plist

# macInstaller/HELPERNAME/Info.plist
# CFBundleIdentifier: HELPERNAME
# CFBundleInfoDictionaryVersion: 6.0
# SMAuthorizedClients: array
# - identifier "CLIENTNAME" and anchor apple generic and certificate leaf[subject.CN] = "SIGNINGIDENT"
echo "CFBundleIdentifier in macInstaller/$HELPERNAME/Info.plist"
plutil -remove "CFBundleIdentifier" macInstaller/HELPERNAME/Info.plist
plutil -insert "CFBundleIdentifier" -string "$HELPERNAME" macInstaller/HELPERNAME/Info.plist

# key Clients allowed to add and remove tool
# item 0: ''
#    identifier "HELPERNAME" and anchor apple generic and certificate leaf[subject.CN] = "SIGNINGCERT"
echo "SMAuthorizedClients in macInstaller/$HELPERNAME/Info.plist"
plutil -remove "SMAuthorizedClients" macInstaller/HELPERNAME/Info.plist
plutil -insert "SMAuthorizedClients" -array macInstaller/HELPERNAME/Info.plist
plutil -insert "SMAuthorizedClients.0" -string "identifier \"$CLIENTNAME\" and anchor apple generic and certificate leaf[subject.CN] = \"$SIGNINGCERT\"" macInstaller/HELPERNAME/Info.plist

# macInstaller/HELPERNAME/launchd.plist
# key Label
# value 'HELPERNAME'
echo "Label in macInstaller/$HELPERNAME/launchd.plist"
plutil -remove "Label" macInstaller/HELPERNAME/launchd.plist
plutil -insert "Label" -string "$HELPERNAME" macInstaller/HELPERNAME/launchd.plist

# key MachServices (array)
# - key 'HELPERNAME' value YES
echo "MachServices in macInstaller/$HELPERNAME/launchd.plist"
plutil -remove "MachServices" macInstaller/HELPERNAME/launchd.plist
plutil -insert "MachServices" -dictionary macInstaller/HELPERNAME/launchd.plist
plutil -insert "MachServices.$ESCAPEDHELPER" -bool true macInstaller/HELPERNAME/launchd.plist

# macInstaller/HELPERNAME/XPCServer.swift
#         let entitlements = "identifier \"CLIENTNAME\" and anchor apple generic and certificate leaf[subject.CN] = \"SIGNINGCERT\""
echo "Updating XPCServer.swift with $CLIENTNAME and $SIGNINGCERT"
sed "s/CLIENTNAME/$CLIENTNAME/g" macInstaller/HELPERNAME/XPCServer.swift > temp.out
sed "s/SIGNINGCERT/$SIGNINGCERT/g" temp.out > temp2.out
rm temp.out
rm macInstaller/HELPERNAME/XPCServer.swift
mv temp2.out macInstaller/HELPERNAME/XPCServer.swift

# macInstaller/Shared/Constants.swift
echo "Updating Constants.swift with $HELPERNAME"
sed "s/HELPERNAME/$HELPERNAME/g" macInstaller/Shared/Constants.swift > temp.out
rm macInstaller/Shared/Constants.swift
mv temp.out macInstaller/Shared/Constants.swift

mv "macInstaller/HELPERNAME/HELPERNAME-Bridging-Header.h" "macInstaller/HELPERNAME/$HELPERNAME-Bridging-Header.h" 

# subfolder named HELPERNAME/
echo "Copying macInstaller/HELPERNAME directory to macInstaller/$HELPERNAME"
mv "macInstaller/HELPERNAME/" "macInstaller/$HELPERNAME/" 

