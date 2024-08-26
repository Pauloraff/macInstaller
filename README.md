# mac_installer
A sample macOS installer that can install a system service along with its
configuration files.

System services (daemons) are started when the OS starts, and are running independently of
whether a user is logged in to the computer or not. They can run with elevated (root)
privileges, and do not have access to a window manager or UI (i.e., no desktop and no
windows). They are configured with plists in /Library/LaunchDaemons, but the daemon
executable itself is usually placed in a subfolder of /Library.

Future versions of the installer will be able to install user services, as well.

User services (agents) can be launched when a user is logged in, and have access to the
UI that each specific user sees. If multiple users are logged in at the same time,
there each user can run their own separate copy of the user service if it is installed
into ~/Library/LaunchAgents, or they can share a single copy if it is installed into
/Library/LaunchAgents.

Implementation details
----------------------
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

