-- Caps Lock (F18) toggles kitty with opencode (quake-style)

local kittyBundleID = "net.kovidgoyal.kitty"
local opencodePath = "/opt/homebrew/bin/opencode"
local log = hs.logger.new("quake-kitty", "info")

local managedWindow = nil

local function toggleQuakeKitty()
    local app = hs.application.get(kittyBundleID)
    local focusedWin = hs.window.focusedWindow()
    local kittyFrontmost = focusedWin and focusedWin:application():bundleID() == kittyBundleID

    if app == nil then
        log.i("Launching kitty with opencode")
        hs.application.launchOrFocus("kitty")
        hs.timer.doAfter(0.5, function()
            local kitty = hs.application.get(kittyBundleID)
            if kitty then
                local win = kitty:mainWindow()
                if win then
                    managedWindow = win
                    hs.eventtap.keyStrokes(opencodePath .. "\n")
                    log.i("Sent opencode launch command")
                end
            end
        end)
    elseif kittyFrontmost then
        log.i("Hiding kitty")
        app:hide()
    else
        log.i("Bringing kitty to front")
        app:activate()
    end
end

hs.hotkey.bind({}, "f18", toggleQuakeKitty)

log.i("Loaded: Caps Lock (F18) -> quake kitty toggle")
