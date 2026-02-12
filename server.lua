-- GOD'S EYE Anti-Cheat by Omiya
-- Advanced protection system against mod menu exploits in GTA RP servers
-- Version 1.0

local AntiCheat = {
    lastPositions = {},
    lastChecks = {},
    blacklistWeapons = {},
    blacklistWeaponsList = {},
    blacklistVehicles = {},
    blacklistVehiclesList = {},
    blacklistExplosions = {},
    bans = { list = {}, byIdentifier = {} },
    lastLogCleanup = 0
}

local function safeNumber(value, fallback)
    if type(value) == "number" then
        return value
    end
    return fallback
end

function AntiCheat:Init()
    if Config and Config.EnableAntiCheat == false then
        print("[GOD'S EYE] Anti-cheat disabled in config.")
        return
    end

    print([[ 
    =====================================
     GOD'S EYE Anti-Cheat System
     Created by Omiya
     Protecting your server against cheaters
    =====================================
    ]])

    self.blacklistWeapons, self.blacklistWeaponsList = self:BuildHashSet(Config.BlacklistedWeapons)
    self.blacklistVehicles, self.blacklistVehiclesList = self:BuildHashSet(Config.BlacklistedVehicles)
    self.blacklistExplosions = self:BuildSimpleSet((Config.ExplosionProtection or {}).blacklistedExplosions)
    self.bans = self:LoadBans()

    for _, eventName in ipairs(Config.SuspiciousEvents or {}) do
        AddEventHandler(eventName, function(source)
            self:CheckSuspiciousEvent(source, eventName)
        end)
    end

    AddEventHandler("explosionEvent", function(sender, event)
        self:CheckExplosion(sender, event)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        self:CheckResourceStop(resourceName)
    end)

    AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
        self:CheckPlayerConnecting(source, playerName, setKickReason, deferrals)
    end)

    AddEventHandler("playerDropped", function()
        self:CleanupPlayer(source)
    end)

    Citizen.CreateThread(function()
        while true do
            self:CheckAllPlayers()
            Citizen.Wait(250)
        end
    end)
end

function AntiCheat:BuildHashSet(list)
    local set = {}
    local hashList = {}
    if type(list) ~= "table" then
        return set, hashList
    end
    for _, name in ipairs(list) do
        local hash = GetHashKey(name)
        set[hash] = name
        table.insert(hashList, hash)
    end
    return set, hashList
end

function AntiCheat:BuildSimpleSet(list)
    local set = {}
    if type(list) ~= "table" then
        return set
    end
    for _, value in ipairs(list) do
        set[value] = true
    end
    return set
end

function AntiCheat:ShouldRunCheck(playerId, key, interval)
    local checkInterval = safeNumber(interval, 0)
    if checkInterval <= 0 then
        return true
    end
    if not self.lastChecks[key] then
        self.lastChecks[key] = {}
    end
    local now = GetGameTimer()
    local last = self.lastChecks[key][playerId] or 0
    if now - last >= checkInterval then
        self.lastChecks[key][playerId] = now
        return true
    end
    return false
end

function AntiCheat:IsExempt(playerId)
    if not playerId then
        return false
    end
    if IsPlayerAceAllowed and IsPlayerAceAllowed(playerId, "gods_eye.exempt") then
        return true
    end
    local exemptList = Config.ExemptPlayers or {}
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, identifier in ipairs(identifiers) do
        for _, exempt in ipairs(exemptList) do
            if identifier == exempt then
                return true
            end
        end
    end
    return false
end

function AntiCheat:GetPrimaryIdentifier(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local license = nil
    local steam = nil
    local fivem = nil
    local discord = nil

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "license:") then
            license = identifier
        elseif string.find(identifier, "steam:") then
            steam = identifier
        elseif string.find(identifier, "fivem:") then
            fivem = identifier
        elseif string.find(identifier, "discord:") then
            discord = identifier
        end
    end

    return license or steam or fivem or discord or identifiers[1] or tostring(playerId)
end

function AntiCheat:CheckPlayer(playerId)
    if self:IsExempt(playerId) then
        return
    end

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then
        return
    end

    if self:ShouldRunCheck(playerId, "health", Config.HealthCheckInterval) then
        local health = GetEntityHealth(ped)
        if health > safeNumber(Config.MaxHealth, 200) then
            self:DetectCheat(playerId, "Health hack detected")
        end

        local armor = GetPedArmour(ped)
        if armor > safeNumber(Config.MaxArmor, 100) then
            self:DetectCheat(playerId, "Armor hack detected")
        end
    end

    if self:ShouldRunCheck(playerId, "weapons", Config.WeaponCheckInterval) then
        for _, hash in ipairs(self.blacklistWeaponsList) do
            if HasPedGotWeapon(ped, hash, false) then
                local weaponName = self.blacklistWeapons[hash] or tostring(hash)
                self:DetectCheat(playerId, "Blacklisted weapon detected: " .. weaponName)
            end
        end
    end

    if self:ShouldRunCheck(playerId, "position", Config.PositionCheckInterval) then
        local currentPos = GetEntityCoords(ped)
        local lastPos = self.lastPositions[playerId]
        if lastPos then
            local distance = #(currentPos - lastPos)
            if distance > safeNumber(Config.TeleportThreshold, 100.0) then
                self:DetectCheat(playerId, "Possible teleport detected")
            end
        end
        self.lastPositions[playerId] = currentPos
    end

    if self:ShouldRunCheck(playerId, "vehicle", Config.PositionCheckInterval) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle ~= 0 then
            local model = GetEntityModel(vehicle)
            if self.blacklistVehicles[model] then
                local vehicleName = self.blacklistVehicles[model] or tostring(model)
                self:DetectCheat(playerId, "Blacklisted vehicle detected: " .. vehicleName)
            end

            local maxSpeed = safeNumber(Config.MaxSpeed, 0)
            if maxSpeed > 0 then
                local speed = GetEntitySpeed(vehicle)
                if speed > maxSpeed then
                    self:DetectCheat(playerId, "Abnormal vehicle speed detected")
                end
            end
        end
    end
end

function AntiCheat:CheckAllPlayers()
    if Config and Config.EnableAntiCheat == false then
        return
    end

    local players = GetPlayers()
    local processed = 0
    local maxChecksPerTick = safeNumber((Config.Performance or {}).maxChecksPerTick, 10)
    local checkDelay = safeNumber((Config.Performance or {}).checkDelay, 100)

    for _, playerId in ipairs(players) do
        self:CheckPlayer(playerId)
        processed = processed + 1
        if processed >= maxChecksPerTick then
            processed = 0
            Citizen.Wait(checkDelay)
        end
    end
end

function AntiCheat:CheckSuspiciousEvent(playerId, eventName)
    if self:IsExempt(playerId) then
        return
    end

    self:Log(string.format("Suspicious event '%s' triggered by player %s", eventName, playerId))
    self:DetectCheat(playerId, "Suspicious event triggered: " .. eventName)
    CancelEvent()
end

function AntiCheat:CheckExplosion(playerId, event)
    if not (Config.ExplosionProtection and Config.ExplosionProtection.enabled) then
        return
    end
    if self:IsExempt(playerId) then
        return
    end

    if event and self.blacklistExplosions[event.explosionType] then
        self:DetectCheat(playerId, "Blacklisted explosion detected")
        CancelEvent()
    end
end

function AntiCheat:CheckResourceStop(resourceName)
    if not (Config.ResourceProtection and Config.ResourceProtection.enabled) then
        return
    end
    local protected = (Config.ResourceProtection.protectedResources or {})
    for _, name in ipairs(protected) do
        if resourceName == name then
            self:Log("Protected resource stopped: " .. resourceName)
            if resourceName ~= GetCurrentResourceName() then
                StartResource(resourceName)
            end
            break
        end
    end
end

function AntiCheat:DetectCheat(playerId, reason)
    if self:IsExempt(playerId) then
        return
    end

    local playerName = GetPlayerName(playerId) or "Unknown"
    self:Log(string.format("Detected possible cheat from %s (%s): %s", playerName, playerId, reason))
    self:LogCheat(playerId, reason)
    self:SendDiscordLog(playerId, reason)

    if Config.Punishments and Config.Punishments.enabled then
        if Config.Punishments.banPlayer then
            self:BanPlayer(playerId, reason)
        end
        if Config.Punishments.kickPlayer then
            local message = (Config.Punishments.warningMessage or "GOD'S EYE: Cheating detected!") .. " " .. reason
            DropPlayer(playerId, message)
        end
    end
end

function AntiCheat:LogCheat(playerId, reason)
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

    local logEntry = string.format(
        "[%s] Player: %s, Steam: %s, License: %s, Reason: %s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        playerId,
        steamId,
        license,
        reason
    )

    self:WriteLog(logEntry)
end

function AntiCheat:WriteLog(entry)
    if Config.LogToConsole then
        print("[GOD'S EYE] " .. entry:gsub("\n", ""))
    end
    if not Config.LogToFile then
        return
    end

    local fileName = Config.LogFileName or "gods_eye_logs.txt"
    local resourceName = GetCurrentResourceName()
    local existing = LoadResourceFile(resourceName, fileName) or ""

    local cleanupHours = safeNumber((Config.Performance or {}).logCleanupInterval, 0)
    if cleanupHours > 0 then
        local now = os.time()
        if self.lastLogCleanup == 0 then
            self.lastLogCleanup = now
        elseif now - self.lastLogCleanup >= cleanupHours * 3600 then
            existing = ""
            self.lastLogCleanup = now
        end
    end

    local maxSizeMb = safeNumber((Config.Performance or {}).maxLogSize, 10)
    local maxBytes = math.max(0, math.floor(maxSizeMb * 1024 * 1024))
    local newContent = existing .. entry
    if maxBytes > 0 and #newContent > maxBytes then
        newContent = string.sub(newContent, #newContent - maxBytes + 1)
    end

    SaveResourceFile(resourceName, fileName, newContent, -1)
end

function AntiCheat:SendDiscordLog(playerId, reason)
    if not (Config.Discord and Config.Discord.enabled) then
        return
    end
    -- Placeholder: implement HTTP POST to Discord webhook here if desired.
    self:Log("Discord logging enabled but not implemented. Reason: " .. reason)
end

function AntiCheat:LoadBans()
    local fileName = Config.BanFileName or "gods_eye_bans.json"
    local resourceName = GetCurrentResourceName()
    local raw = LoadResourceFile(resourceName, fileName)
    if not raw or raw == "" then
        return { list = {}, byIdentifier = {} }
    end
    local decoded = json.decode(raw)
    if type(decoded) ~= "table" then
        return { list = {}, byIdentifier = {} }
    end

    local bans = { list = decoded, byIdentifier = {} }
    for _, ban in ipairs(bans.list) do
        if ban.identifiers then
            for _, identifier in ipairs(ban.identifiers) do
                bans.byIdentifier[identifier] = ban
            end
        end
    end
    return bans
end

function AntiCheat:SaveBans()
    local fileName = Config.BanFileName or "gods_eye_bans.json"
    local resourceName = GetCurrentResourceName()
    SaveResourceFile(resourceName, fileName, json.encode(self.bans.list), -1)
end

function AntiCheat:PurgeExpiredBans()
    local now = os.time()
    local newList = {}
    local newMap = {}
    for _, ban in ipairs(self.bans.list) do
        if not ban.expiresAt or ban.expiresAt == 0 or ban.expiresAt > now then
            table.insert(newList, ban)
            if ban.identifiers then
                for _, identifier in ipairs(ban.identifiers) do
                    newMap[identifier] = ban
                end
            end
        end
    end
    self.bans.list = newList
    self.bans.byIdentifier = newMap
end

function AntiCheat:BanPlayer(playerId, reason)
    self:PurgeExpiredBans()

    local identifiers = GetPlayerIdentifiers(playerId)
    local banDuration = safeNumber(Config.Punishments and Config.Punishments.banDuration, 0)
    local expiresAt = 0
    if banDuration > 0 then
        expiresAt = os.time() + (banDuration * 3600)
    end

    local banEntry = {
        identifiers = identifiers,
        primary = self:GetPrimaryIdentifier(playerId),
        name = GetPlayerName(playerId) or "Unknown",
        reason = reason,
        createdAt = os.time(),
        expiresAt = expiresAt
    }

    table.insert(self.bans.list, banEntry)
    for _, identifier in ipairs(identifiers) do
        self.bans.byIdentifier[identifier] = banEntry
    end
    self:SaveBans()
end

function AntiCheat:CheckPlayerConnecting(playerId, playerName, setKickReason, deferrals)
    self:PurgeExpiredBans()
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, identifier in ipairs(identifiers) do
        local ban = self.bans.byIdentifier[identifier]
        if ban then
            if deferrals then
                deferrals.defer()
                Citizen.Wait(0)
                deferrals.done("GOD'S EYE: You are banned. Reason: " .. (ban.reason or "Unknown"))
            else
                setKickReason("GOD'S EYE: You are banned. Reason: " .. (ban.reason or "Unknown"))
            end
            return
        end
    end
end

function AntiCheat:CleanupPlayer(playerId)
    self.lastPositions[playerId] = nil
    for _, bucket in pairs(self.lastChecks) do
        if type(bucket) == "table" then
            bucket[playerId] = nil
        end
    end
end

function AntiCheat:Log(message)
    if Config.LogToConsole then
        print("[GOD'S EYE] " .. message)
    end
end

AntiCheat:Init()
_G.AntiCheat = AntiCheat
