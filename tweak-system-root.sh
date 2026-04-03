#!/bin/bash
# =============================================================================
# macOS Service Disabler — macOS 26+ (Apple Silicon, SIP Enabled)
# =============================================================================
#
# Uses modern `launchctl disable`/`enable` + `bootout`/`bootstrap` instead of
# the deprecated `load`/`unload` approach. Works with SIP enabled because
# `launchctl disable` persists state in /private/var/db/com.apple.xpc.launchd/
# (not SIP-protected), rather than modifying /System/Library/ plists.
#
# To revert ALL disables: sudo rm -r /private/var/db/com.apple.xpc.launchd/*
# Then reboot.
#
# NOTE: Some of these overlap with Ansible privacy.yml (defaults-level settings).
# This script handles launchctl-level disabling; Ansible handles defaults writes.
# They can coexist — both layers of hardening apply independently.
#
# References:
#   - https://gist.github.com/b0gdanw/0c20c2fd5d0a7e6cff01849b57108967 (Tahoe)
#   - https://gist.github.com/b0gdanw/b349f5f72097955cf18d6e7d8035c665 (Sequoia)
#   - https://ernw.de/en/blog/ernw-hardening-guide-apple-macos-14-sonoma
#   - https://vilimpoc.org/blog/2014/01/15/provisioning-os-x-and-disabling-unnecessary-services/
#
# =============================================================================

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


bot "This script will disable some agents and daemons. What would you like to do?"
read -r -p "(E)xecute your Disable script, (R)estore default or (Q)uit  [default=E] " response
response=${response:-E}
if [[ $response =~ (e|E) ]];then
    ACTION="disable"
elif [[ $response =~ (r|R) ]];then
    ACTION="enable"
elif [[ $response =~ (q|Q) ]];then
    echo "Quitting.." >&2
    exit 0
fi

UID=$(id -u)

# =========================================================================
# USER AGENTS — Active (exist on macOS 26.4, safe to disable)
# =========================================================================
# Photos.app — the devil itself. image recognition that slowly eats away at your cpu and your soul.
AGENTS=('com.apple.photoanalysisd')
# Game Center
AGENTS+=('com.apple.gamed')
# Siri
AGENTS+=('com.apple.assistant_service')
# AOSPushRelay — BAD for your privacy.
AGENTS+=('com.apple.AOSPushRelay')
# seedusage daemon — used by feedback assistant.
AGENTS+=('com.apple.appleseed.seedusaged')
# parental controls
AGENTS+=('com.apple.parentalcontrols.check')
AGENTS+=('com.apple.familycontrols.useragent')
# Siri backend
AGENTS+=('com.apple.assistantd')
# location suggestions for siri, spotlight + messages suggestions, safari lookup
AGENTS+=('com.apple.parsecd')
AGENTS+=('com.apple.identityservicesd')
# Maps
AGENTS+=('com.apple.Maps.pushdaemon')

# =========================================================================
# USER AGENTS — Experimental (keep for reference, untested on macOS 26.4)
# =========================================================================
# AGENTS+=('com.apple.security.cloudkeychainproxy3')
# AGENTS+=('com.apple.security.keychain-circle-notification')
# AGENTS+=('com.apple.iCloudUserNotifications')
# AGENTS+=('com.apple.familycircled')
# AGENTS+=('com.apple.familynotificationd')
# AGENTS+=('com.apple.syncdefaultsd')
# AGENTS+=('com.apple.passd')
# AGENTS+=('com.apple.screensharing.MessagesAgent')
# AGENTS+=('com.apple.CommCenter-osx')
# AGENTS+=('com.apple.imagent')
# AGENTS+=('com.apple.cloudpaird')
# AGENTS+=('com.apple.CallHistorySyncHelper')
# AGENTS+=('com.apple.CallHistoryPluginHelper')
# AGENTS+=('com.apple.geodMachServiceBridge')
# AGENTS+=('com.apple.sharingd')

# =========================================================================
# USER AGENTS — [EXPERIMENTAL] Community recommended (b0gdanw Tahoe gist)
# =========================================================================
# AGENTS+=('com.apple.ScreenTimeAgent')
# AGENTS+=('com.apple.siriactionsd')
# AGENTS+=('com.apple.siriinferenced')
# AGENTS+=('com.apple.generativeexperiencesd')    # Apple Intelligence
# AGENTS+=('com.apple.intelligenceflowd')          # Apple Intelligence
# AGENTS+=('com.apple.intelligencecontextd')        # Apple Intelligence
# AGENTS+=('com.apple.intelligenceplatformd')       # Apple Intelligence
# AGENTS+=('com.apple.UsageTrackingAgent')
# AGENTS+=('com.apple.followupd')
# AGENTS+=('com.apple.chronod')
# AGENTS+=('com.apple.routined')
# AGENTS+=('com.apple.triald')
# AGENTS+=('com.apple.inputanalyticsd')
# AGENTS+=('com.apple.biomesyncd')
# AGENTS+=('com.apple.BiomeAgent')
# AGENTS+=('com.apple.corespeechd')
# AGENTS+=('com.apple.mediaanalysisd')

# =========================================================================
# SYSTEM DAEMONS — Active (exist on macOS 26.4)
# =========================================================================
# Diagnostics telemetry
DAEMONS=('com.apple.SubmitDiagInfo')
# CloudKit daemon (was misclassified as agent in old script)
DAEMONS+=('com.apple.cloudd')
# RTC reporting telemetry
DAEMONS+=('com.apple.rtcreportingd')
# Location services daemon
DAEMONS+=('com.apple.locationd')

# =========================================================================
# SYSTEM DAEMONS — Experimental (keep for reference, untested on macOS 26.4)
# =========================================================================
# DAEMONS+=('com.apple.familycontrols')
# DAEMONS+=('com.apple.findmymac')
# DAEMONS+=('com.apple.icloud.findmydeviced')
# DAEMONS+=('com.apple.preferences.timezone.admintool')
# DAEMONS+=('com.apple.remotepairtool')
# DAEMONS+=('com.apple.security.FDERecoveryAgent')
# DAEMONS+=('com.apple.findmymacmessenger')
# DAEMONS+=('com.apple.screensharing')
# DAEMONS+=('com.apple.appleseed.fbahelperd')
# DAEMONS+=('com.apple.apsd')
# DAEMONS+=('com.apple.ManagedClient.enroll')
# DAEMONS+=('com.apple.ManagedClient')
# DAEMONS+=('com.apple.ManagedClient.startup')
# DAEMONS+=('com.apple.eapolcfg_auth')
# DAEMONS+=('com.apple.netbiosd')

COUNT=0
bot "User Agents (${ACTION})"
for agent in "${AGENTS[@]}"; do
    running "${ACTION} gui/${UID}/${agent}"
    if [[ $ACTION == "disable" ]]; then
        launchctl bootout gui/${UID}/${agent} 2>/dev/null
        launchctl disable gui/${UID}/${agent}
    else
        launchctl enable gui/${UID}/${agent}
        launchctl bootstrap gui/${UID} /System/Library/LaunchAgents/${agent}.plist 2>/dev/null
    fi
    ok
    ((COUNT++))
done

DCOUNT=0
bot "System Daemons (${ACTION})"
for daemon in "${DAEMONS[@]}"; do
    running "${ACTION} system/${daemon}"
    if [[ $ACTION == "disable" ]]; then
        sudo launchctl bootout system/${daemon} 2>/dev/null
        sudo launchctl disable system/${daemon}
    else
        sudo launchctl enable system/${daemon}
        sudo launchctl bootstrap system /System/Library/LaunchDaemons/${daemon}.plist 2>/dev/null
    fi
    ok
    ((DCOUNT++))
done

echo ""
bot "Done. ${ACTION}d ${COUNT} user agents and ${DCOUNT} system daemons."
if [[ $ACTION == "disable" ]]; then
    echo ""
    bot "To revert ALL disables: sudo rm -r /private/var/db/com.apple.xpc.launchd/* && sudo reboot"
fi

exit 0
