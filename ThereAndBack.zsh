#!/bin/zsh

# there...
SIGNINGCERT="Developer ID Application: Paulo Raffaelli (2XEVFK8ZST)" CLIENTNAME="com.greenkitty.macinstaller" HELPERNAME="com.greenkitty.macinstallerhelper" ./AdjustProjectSettings.zsh

# ..and back
SIGNINGCERT="Developer ID Application: Paulo Raffaelli (2XEVFK8ZST)" CLIENTNAME="com.greenkitty.macinstaller" HELPERNAME="com.greenkitty.macinstallerhelper" ./RestoreProjectSettings.zsh

