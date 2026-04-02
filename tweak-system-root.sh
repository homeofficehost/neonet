#!/bin/bash
# https://vilimpoc.org/blog/2014/01/15/provisioning-os-x-and-disabling-unnecessary-services/
# https://github.com/JayBrown/Disable-and-toggle-WebRTC-in-macOS-Safari

# Ask for the administrator password upfront
sudo -v

function ok() {
    echo -e "[OK] "$1
}

function bot() {
    echo -e "\[._.]/ - "$1
}

function running() {
    echo -en " → "$1": "
}

bot "This script will disable some agents and daemon. What would you like to do?"
read -r -p "(E)xecute your Disable script, (R)estore default or (Q)uit  [default=E] " response
response=${response:-E}
if [[ $response =~ (e|E) ]];then
    # Execute disable
    CMD_TO_RUN="load"
elif [[ $response =~ (r|R) ]];then
    # Restore backup
    CMD_TO_RUN="unload"
elif [[ $response =~ (q|Q) ]];then
    echo "Quitting.." >&2
    exit 0
fi

#---------------------------------------------------------------------
# Agents
#---------------------------------------------------------------------
# [Sure Keep] Enable - keeping the default, dont disable
# AGENTS=('com.apple.security.keychainsyncingoveridsproxy')
# AGENTS+=('com.apple.DictationIM')
# AGENTS+=('com.apple.icloud.findmydeviced.findmydevice-user-agent')
# # dictation
# AGENTS+=('com.apple.DictationIM')
# calendar agent... calendar still seems to work fine with this off (EXPERIMENTAL)
# AGENTS+=('com.apple.CalendarAgent')
# telephony.... this may cause 100% cpu issues if SIP is not disabled (reboot into safe mode, csrutil disable)
# used for facetime and handover with calls/sms. garbage.
# AGENTS+=('com.apple.telephonyutilities.callservicesd')
# airplay - you can always load it if you end up needing it
# AGENTS+=('com.apple.AirPlayUIAgent')
# airport basestation client - you don't need it if you don't run an airport base station.
# AGENTS+=('com.apple.AirPortBaseStationAgent')
# this appears to be for talking to airport basestations... could also include other stuff? experiment.
# sudo launchctl disable system/airportd
# Speech & Voice
# sudo rm -rf /System/Library/Speech/Voices/
# AGENTS+=('com.apple.VoiceOver')
# AGENTS+=('com.apple.speech.voiceinstallerd')
# AGENTS+=('com.apple.speech.synthesisserver')
# AGENTS+=('com.apple.speech.recognitionserver')
# AGENTS+=('com.apple.speech.feedbackservicesserver')
# AGENTS+=('com.apple.speech.speechsynthesisd')
# AGENTS+=('com.apple.speech.speechdatainstallerd')
# Disable SWAP
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
# sudo rm /private/var/vm/swapfile*

# [Sure Remove] Disabled - not keeping the default, disable
# Photos.app
# the devil itself. image recognition that slowly eats away at your cpu and your soul.
AGENTS+=('com.apple.photoanalysisd')
# background uploading of photos.
AGENTS+=('com.apple.cloudphotosd')
# game Center
AGENTS+=('com.apple.gamed')
# find my friends daemon
AGENTS+=('com.apple.icloud.fmfd')
# siri.
AGENTS+=('com.apple.assistant_service')
# AOSPushRelay BAD for your privacy.
AGENTS+=('com.apple.AOSPushRelay')
# seedusage daemon - used by feedback assistant.
AGENTS+=('com.apple.appleseed.seedusaged')
# parental controls (see the prefs page, it's shit)
AGENTS+=('com.apple.parentalcontrols.check')
# same
AGENTS+=('com.apple.familycontrols.useragent')
# cloudkit. not needed for syncing.
AGENTS+=('com.apple.cloudd')
AGENTS+=('com.apple.assistantd')
# location suggestions for siri, spotlight + messages suggestions, safari lookup
AGENTS+=('com.apple.parsecd')
AGENTS+=('com.apple.identityservicesd')
# iChat / messages.app stuff... if you don't use it, disable it... surprisingly the app still works but you won't get updates if it's closed.
AGENTS+=('com.apple.soagent')
# iCloud Notifications
AGENTS+=('com.apple.librariand')
AGENTS+=('com.apple.icloud.AOSNotificationAgent')
AGENTS+=('com.apple.icloud.AOSNotificationLoginAgent')
# itunes home sharing and other junk.
sudo launchctl disable system/rtcreportingd
AGENTS+=('com.apple.Maps.mapspushd')
AGENTS+=('com.apple.Maps.pushdaemon')

# [EXPERIMENTAL] Enable - keeping the default, dont disable TODO: Try do disable this
# AGENTS+=('com.apple.security.cloudkeychainproxy3')
# AGENTS+=('com.apple.security.idskeychainsyncingproxy')
# AGENTS+=('com.apple.security.keychain-circle-notification')
# AGENTS+=('com.apple.iCloudUserNotifications')
# AGENTS+=('com.apple.familycircled')
# AGENTS+=('com.apple.familynotificationd')
# AGENTS+=('com.apple.cloudfamilyrestrictionsd-mac')
# AGENTS+=('com.apple.syncdefaultsd')
# AGENTS+=('com.apple.personad')
# AGENTS+=('com.apple.passd')
# AGENTS+=('com.apple.screensharing.MessagesAgent')
# AGENTS+=('com.apple.CommCenter-osx')
# AGENTS+=('com.apple.imagent')
# AGENTS+=('com.apple.cloudpaird')
# AGENTS+=('com.apple.CallHistorySyncHelper')
# AGENTS+=('com.apple.CallHistoryPluginHelper')
# AGENTS+=('com.apple.IMLoggingAgent')
# AGENTS+=('com.apple.geodMachServiceBridge')
# AGENTS+=('com.apple.sharingd')


#---------------------------------------------------------------------
# Daemons
#---------------------------------------------------------------------
# [Sure Keep] Enable - keeping the default, dont disable
# get rid of some garbage unwanted network services:
# you'll need this if you want to snoop on network shares though.
# DAEMONS=('com.apple.netbiosd')
# Notifications
# DAEMONS+=('com.apple.AOSNotificationOSX')

# [Sure Remove] Disabled - not keeping the default, disable
# Diagnostics
DAEMONS+=('com.apple.SubmitDiagInfo')
# Location
DAEMONS+=('com.apple.locationd')
# same
DAEMONS+=('com.apple.locationmenu')

# [EXPERIMENTAL] Enable - keeping the default, dont disable TODO: Try do disable this
# DAEMONS+=('com.apple.familycontrols')
# DAEMONS+=('com.apple.findmymac')
# DAEMONS+=('com.apple.icloud.findmydeviced')
# DAEMONS+=('com.apple.iCloudStats')
# DAEMONS+=('com.apple.mbicloudsetupd')
# DAEMONS+=('com.apple.preferences.timezone.admintool')
# DAEMONS+=('com.apple.preferences.timezone.auto')
# DAEMONS+=('com.apple.remotepairtool')
# DAEMONS+=('com.apple.rpmuxd')
# DAEMONS+=('com.apple.security.FDERecoveryAgent')
# DAEMONS+=('com.apple.findmymacmessenger')
# DAEMONS+=('com.apple.screensharing')
# DAEMONS+=('com.apple.appleseed.fbahelperd')
# DAEMONS+=('com.apple.apsd')
# DAEMONS+=('com.apple.FileSyncAgent.sshd')
# DAEMONS+=('com.apple.ManagedClient.cloudconfigurationd')
# DAEMONS+=('com.apple.ManagedClient.enroll')
# DAEMONS+=('com.apple.ManagedClient')
# DAEMONS+=('com.apple.ManagedClient.startup')
# DAEMONS+=('com.apple.laterscheduler')
# DAEMONS+=('com.apple.awacsd')
# DAEMONS+=('com.apple.eapolcfg_auth')

# TODO: Fix Calendar
# com.apple.cloudd
# com.apple.assistantd
# sudo mv -vn /System/Library/LaunchAgents/com.apple.cloudd.plist.bkp /System/Library/LaunchAgents/com.apple.cloudd.plist
# sudo launchctl load -w /System/Library/LaunchAgents/com.apple.cloudd.plist

bot "Agents"
for agent in "${AGENTS[@]}"; do
    running "disabling agent/${agent}"
    {
        sudo launchctl $CMD_TO_RUN -w /System/Library/LaunchAgents/${agent}.plist
        launchctl $CMD_TO_RUN -w /System/Library/LaunchAgents/${agent}.plist
    } &> /dev/null
    ok
    # moves only if dest file does not exist.
    sudo mv -vn /System/Library/LaunchAgents/${agent}.plist /System/Library/LaunchAgents/${agent}.plist.bkp
    ok
done

bot "Daemons"
for daemon in "${DAEMONS[@]}"; do
    running "disabling daemons/${daemon}"
    {
        sudo launchctl $CMD_TO_RUN -w /System/Library/LaunchDaemons/${daemon}.plist;ok
        launchctl $CMD_TO_RUN -w /System/Library/LaunchDaemons/${daemon}.plist
    } &> /dev/null
    ok
    # moves only if dest file does not exist.
    sudo mv -vn /System/Library/LaunchDaemons/${daemon}.plist /System/Library/LaunchDaemons/${daemon}.plist.bkp
    ok
done

bot "Backups saved on /System/Library/LaunchAgents/\*.plist.bkp"

running "Deleting useless apps"
#---------------------------------------------------------------------
# Delete Automator
#---------------------------------------------------------------------

#sudo rm -rf /Applications/Automator.app/
#sudo rm -rf /System/Library/Automator/
#sudo rm -rf /System/Library/CoreServices/Automator\ Launcher.app
#sudo rm -rf /System/Library/CoreServices/System\ Image\ Utility.app/Contents/Library/Automator/
#sudo rm -rf /System/Library/Frameworks/Automator.framework/

#---------------------------------------------------------------------
# I dont use these Applications anyway.
#---------------------------------------------------------------------

# sudo rm -rf /Applications/FaceTime.app/
# sudo rm -rf /Applications/Notes.app/
# sudo rm -rf /Applications/Calculator.app/
# sudo rm -rf /Applications/Automator.app/
# sudo rm -rf /System/Library/Frameworks/Automator.framework/
# sudo rm -rf /System/Library/CoreServices/System\ Image\ Utility.app/Contents/Library/Automator
# sudo rm -rf /System/Library/CoreServices/Automator\ Runner.app
# sudo rm -rf /System/Library/CoreServices/Automator\ Launcher.app/
# sudo rm -rf /Applications/Calendar.app/
# sudo rm -rf /System/Library/Screen\ Savers
sudo rm -rf /Applications/TextEdit.app/
sudo rm -rf /Applications/iBooks.app/
sudo rm -rf /Applications/Reminders.app/
sudo rm -rf /Applications/Stickies.app/
sudo rm -rf /Applications/Photo\ Booth.app/
sudo rm -rf /Applications/DVD\ Player.app/
sudo rm -rf /Applications/Mission\ Control.app/
sudo rm -rf /Applications/Dashboard.app/
sudo rm -rf /Applications/Dictionary.app/
sudo rm -rf /Applications/Game\ Center.app/
sudo rm -rf /Applications/Chess.app/
sudo rm -rf /Applications/Mail.app/
sudo rm -rf /Applications/Messages.app/
sudo rm -rf /Applications/Maps.app/

ok

exit 0