-- GOD'S EYE Anti-Cheat by Omiya
-- Advanced protection system against mod menu exploits in GTA RP servers
-- Version 1.0

local AntiCheat = {
    -- Configuration
    MAX_HEALTH = 200, -- Maximum allowed health
    MAX_ARMOR = 100,  -- Maximum allowed armor
    TELEPORT_THRESHOLD = 100.0, -- Maximum allowed instant position change
    WEAPON_CHECK_INTERVAL = 5000, -- How often to check for blacklisted weapons (ms)
    
    -- Blacklisted weapons commonly spawned by mod menus
    blacklistedWeapons = {
        "WEAPON_RAILGUN",
        "WEAPON_STUNGUN",
        "WEAPON_MINIGUN"
    },
    
    -- Known mod menu triggered events
    suspiciousEvents = {
        "esx:getSharedObject",
        "esx_ambulancejob:revive",
        "esx_policejob:handcuff"
    },
    
    -- Store last positions to check for teleporting
    playerLastPositions = {}
}

-- Initialize the anti-cheat system
function AntiCheat:Init()
    print([[
    =====================================
     GOD'S EYE Anti-Cheat System
     Created by Omiya
     Protecting your server against cheaters
    =====================================
    ]])
    
    -- Monitor for suspicious events
    for _, eventName in ipairs(self.suspiciousEvents) do
        AddEventHandler(eventName, function(source)
            self:CheckSuspiciousEvent(source, eventName)
        end)
    end
    
    -- Start periodic checks
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(self.WEAPON_CHECK_INTERVAL)
            self:CheckAllPlayers()
        end
    end)
end

-- Check a player for suspicious activity
function AntiCheat:CheckPlayer(playerId)
    local player = GetPlayerPed(playerId)
    
    -- Health check
    local health = GetEntityHealth(player)
    if health > self.MAX_HEALTH then
        self:DetectCheat(playerId, "Health hack detected")
    end
    
    -- Armor check
    local armor = GetPedArmour(player)
    if armor > self.MAX_ARMOR then
        self:DetectCheat(playerId, "Armor hack detected")
    end
    
    -- Weapon check
    local weapons = self:GetPlayerWeapons(playerId)
    for _, weapon in ipairs(weapons) do
        if self:IsWeaponBlacklisted(weapon) then
            self:DetectCheat(playerId, "Blacklisted weapon detected: " .. weapon)
        end
    end
    
    -- Position check for teleport detection
    local currentPos = GetEntityCoords(player)
    if self.playerLastPositions[playerId] then
        local lastPos = self.playerLastPositions[playerId]
        local distance = #(currentPos - lastPos)
        if distance > self.TELEPORT_THRESHOLD then
            self:DetectCheat(playerId, "Possible teleport detected")
        end
    end
    self.playerLastPositions[playerId] = currentPos
end

-- Check if a weapon is blacklisted
function AntiCheat:IsWeaponBlacklisted(weapon)
    for _, blacklisted in ipairs(self.blacklistedWeapons) do
        if weapon == blacklisted then
            return true
        end
    end
    return false
end

-- Get all weapons a player has
function AntiCheat:GetPlayerWeapons(playerId)
    local weapons = {}
    for _, weapon in ipairs(self.blacklistedWeapons) do
        if HasPedGotWeapon(GetPlayerPed(playerId), GetHashKey(weapon), false) then
            table.insert(weapons, weapon)
        end
    end
    return weapons
end

-- Handle suspicious events
function AntiCheat:CheckSuspiciousEvent(playerId, eventName)
    -- Log the suspicious event
    print(string.format("[GOD'S EYE] Suspicious event '%s' triggered by player %s", eventName, playerId))
    
    -- You can add additional checks here based on the event
    -- For example, checking if the player has permission to trigger this event
    
    -- Example: Block certain events completely
    if eventName == "esx:getSharedObject" then
        self:DetectCheat(playerId, "Attempted to trigger blocked event: " .. eventName)
        CancelEvent()
    end
end

-- Check all online players
function AntiCheat:CheckAllPlayers()
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        self:CheckPlayer(playerId)
    end
end

-- Handle detected cheats
function AntiCheat:DetectCheat(playerId, reason)
    -- Log the detection
    print(string.format("[GOD'S EYE] Detected possible cheat from player %s: %s", playerId, reason))
    
    -- Get player identifiers for logging
    local identifiers = GetPlayerIdentifiers(playerId)
    local steamId = "Unknown"
    local license = "Unknown"
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "steam:") then
            steamId = identifier
        elseif string.find(identifier, "license:") then
            license = identifier
        end
    end
    
    -- Log to database or file (implement your own logging system)
    self:LogCheat(playerId, steamId, license, reason)
    
    -- Take action (kick, ban, etc.)
    -- Uncomment the following lines to enable automatic actions
    -- DropPlayer(playerId, "GOD'S EYE: Cheating detected: " .. reason)
    -- self:BanPlayer(playerId, reason)
end

-- Log detected cheats
function AntiCheat:LogCheat(playerId, steamId, license, reason)
    -- Implement your own logging system here
    -- Example: Save to a file
    local logEntry = string.format(
        "[%s] Player: %s, Steam: %s, License: %s, Reason: %s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        playerId,
        steamId,
        license,
        reason
    )
    
    -- Save to file (you should implement proper file handling)
    local file = io.open("gods_eye_logs.txt", "a")
    if file then
        file:write(logEntry)
        file:close()
    end
end

-- Initialize the anti-cheat system
AntiCheat:Init()

-- Export the AntiCheat object if needed
_G.AntiCheat = AntiCheat
