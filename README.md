# mac_installer
A sample macOS installer that installs a service - the example code installs a system
service.

System services (daemons) are started when the OS starts, and are running independently of
whether a user is logged in to the computer or not. They can run with elevated (root)
privileges, and do not have access to a window manager or UI (i.e., no desktop and no
windows). They are usually installed into /Library/LaunchDaemons, but the example code
installs the service into /Library/PrivilegedHelperTools just to show that it can be done.

In order to customize this project for your own needs, the installer app itself needs to
be built with your own bundle ID and the system service it uses during installation also
needs to have its bundle ID changed to one that you own. That's what AdjustProjectSettings.zsh
does - it will update the Xcode project and the source tree with the new bundle IDs.
Once you run AdjustProjectSettings.zsh, you should check in the updated sources.

All of the files in Payload/ are meant to be replaced.

The installer needs to have everything it installs under the 'Payload' folder. The metadata
describing the files to install is in Payload/PayloadMetedata.plist, and SetupPayloadMetadata.zsh
will fill Payload/PayloadMetedata.plist with the needed information.
You should only need to run this whenever the files to install change.

The example payload is a small system service that writes out the date and name of the
currently logged-in user to /var/log/product.log.
If you build the installer and run it, then log out (but not shut down), when you log back in
/var/log/product.log will have been updated to show that no-one was logged in. This
demonstrates that the service was still running even when the login window was being shown
and no one was logged in.

# Implementation

User services (agents) can be launched when a user is logged in, and have access to the
UI that each specific user sees. If multiple users are logged in at the same time,
there each user can run their own separate copy of the user service if it is installed
into ~/Library/LaunchAgents, or they can share a single copy if it is installed into
/Library/LaunchAgents.

The installer uses a system 'helper' daemon at run time to perform actions which
require elevated privileges. The helper daemon is embedded within the installer app,
and macOS takes care of prompting the user for admin credentials before allowing the
helper daemon to be run and invoked.

[Installer UI] (runs as user)
(handles user interaction)
invokes
[helper service] (runs as root)
(handles actions requiring root access)
  
An installer needs to do several things in order to be able to handle installing
a system-level service. All actions involving daemons require root access.
- detect whether a service is running
- start and stop a service
- copy the service executables to the appropriate destination directory
- copy configuration files for any installed services to the
appropriate system-level or user-level directories.

