#! /bin/sh

sudo launchctl unload /Library/LaunchDaemons/me.sunsol.OpenDirectoryServer.PrivilegedHelperTool.plist
sudo rm /Library/LaunchDaemons/me.sunsol.OpenDirectoryServer.PrivilegedHelperTool.plist
sudo rm /Library/PrivilegedHelperTools/me.sunsol.OpenDirectoryServer.PrivilegedHelperTool

sudo security -q authorizationdb remove me.sunsol.OpenDirectoryServer.createMaster
sudo security -q authorizationdb remove me.sunsol.OpenDirectoryServer.createReplica
sudo security -q authorizationdb remove me.sunsol.OpenDirectoryServer.createBackup
sudo security -q authorizationdb remove me.sunsol.OpenDirectoryServer.restoreBackup
