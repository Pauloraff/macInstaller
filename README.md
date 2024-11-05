# mac_installer

What this project is
--------------------

This project is an installer for macOS X. It can be customized to install a software
payload containing your software (app, system service, configuration files, etc.).

The installer, once built, does not need to be distributed via Apple's App Store, but
can be downloaded and run by the end user from a web site (for instance).

Adapting the installer for your own use
---------------------------------------

In order to customize this project for your own needs, the installer app itself needs to
be built with your own bundle ID and the system service it uses during installation also
needs to have its bundle ID changed to one that you own. 
The installer needs to be notarized using your developer credentials so that it can
be distributed outside the App Store.
AdjustProjectSettings.zsh updates the Xcode project and the source tree with the new
bundle IDs and adds your developer credentials to the notarization step.
Once you run AdjustProjectSettings.zsh, you should check in the updated sources.
You only need to perform this step once.

In order to support notarization, you will need to use your Apple ID to create an 'app-specific
password' that is stored in the keychain of your build machine and used to perform the notarization
step. If you have already done this for some other project, you do not need to repeat this step.

The next step is to replace the sample software payload with the software you want installed.
The installer will only install files if they are in the Payload/ directory, and you should completely replace
everything in Payload/ with your own software.

A special file used by the installer to tell it what the files in Payload/ are is Payload/PayloadMetadata.plist.
PayloadMetadata.plist can be created by hand, but there is a script which will generate it from scratch which you
can customize to describe your specific payload: SetupPayloadMetadata.zsh.

The example payload is a small system service that writes out the date and name of the
currently logged-in user to /var/log/product.log.
If you build the installer and run it, then log out (but not shut down), when you log back in
/var/log/product.log will have been updated to show that no-one was logged in. This
demonstrates that the service was still running even when the login window was being shown
and no one was logged in.

# What can the installer install?

- System services
- Per-user services
- Applications
- Configuration/support files

Every file installed by the installer has an intended owner:group and set of permissions specified
in the payload metadata. The installer ensures that the file is copied to its intended
destination with the correct permissions and that its owner and group match.

Depending on what is being installed, the owner:group and permissions may need to be exactly what the
OS expects. Services will not launch if they have the wrong owner/permission settings, for instance.
 
System services (daemons) are started when the OS starts, and are running independently of
whether a user is logged in to the computer or not. They can run with elevated (root)
privileges, and do not have access to a window manager or UI (i.e., no desktop and no
windows). They are usually installed into /Library/LaunchDaemons, but the example code
installs the service into /Library/PrivilegedHelperTools just to show that it can be done.

User services (agents) can be launched when a user is logged in, and have access to the
UI that each specific user sees. If multiple users are logged in at the same time,
there each user can run their own separate copy of the user service if it is installed
into ~/Library/LaunchAgents, or they can share a single copy if it is installed into
/Library/LaunchAgents.

Applications (.app) files are folders with a well-defined structure. To include an app
folder in the installer's payload, copy the app to the Payload/ directory.

The .app folder can also be archived and the installer will unarchive it during installation.
This is to reduce the size of the final installer.

Configuration/support files are simply copied to their destination folder when the installer is run.

# Implementation


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

