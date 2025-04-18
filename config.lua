Config = {}

-- Basic Settings
Config.EnableAntiCheat = true           -- Master switch for the anti-cheat
Config.Debug = false                    -- Enable debug messages
Config.LogToConsole = true             -- Print detections to console
Config.LogToFile = true                -- Save detections to file
Config.LogFileName = "gods_eye_logs.txt"

-- Check Intervals (in milliseconds)
Config.WeaponCheckInterval = 5000       -- How often to check for blacklisted weapons
Config.HealthCheckInterval = 2000       -- How often to check player health
Config.PositionCheckInterval = 1000     -- How often to check for teleport

-- Detection Thresholds
Config.MaxHealth = 200                  -- Maximum allowed health
Config.MaxArmor = 100                  -- Maximum allowed armor
Config.TeleportThreshold = 100.0       -- Maximum allowed instant position change
Config.MaxSpeed = 100.0                -- Maximum allowed vehicle speed

-- Blacklisted Items
Config.BlacklistedWeapons = {
    "WEAPON_RAILGUN",
    "WEAPON_STUNGUN",
    "WEAPON_MINIGUN",
    "WEAPON_RPG",
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_GRENADELAUNCHER_SMOKE",
    "WEAPON_STINGER"
}

Config.BlacklistedVehicles = {
    "RHINO",
    "HYDRA",
    "LAZER",
    "HUNTER",
    "VIGILANTE"
}

-- Suspicious Events to Monitor
Config.SuspiciousEvents = {
    "esx:getSharedObject",
    "esx_ambulancejob:revive",
    "esx_policejob:handcuff",
    "esx_society:withdrawMoney",
    "esx_mafiajob:confiscatePlayerItem"
}

-- Punishment Settings
Config.Punishments = {
    enabled = true,
    kickPlayer = true,
    banPlayer = true,
    banDuration = 0,  -- 0 for permanent, otherwise hours
    warningMessage = "GOD'S EYE: Cheating detected!"
}

-- Exempt Players (add Steam IDs or identifiers)
Config.ExemptPlayers = {
    "steam:123456789",  -- Example admin
    "license:1234567"   -- Example staff
}

-- Discord Webhook Integration
Config.Discord = {
    enabled = false,
    webhook = "",  -- Your Discord webhook URL
    botName = "GOD'S EYE Anti-Cheat",
    color = 16711680  -- Red color in decimal
}

-- Anti-Explosion Settings
Config.ExplosionProtection = {
    enabled = true,
    blacklistedExplosions = {
        1,  -- GRENADE
        2,  -- GRENADELAUNCHER
        4,  -- STICKY_BOMB
        5,  -- MOLOTOV
        25, -- VEHICLE
        32, -- HI_OCTANE
        33, -- CAR
        35, -- PLANE
        36, -- PETROL_PUMP
        37, -- BIKE
        38  -- DIR_STEAM
    }
}

-- Resource Protection
Config.ResourceProtection = {
    enabled = true,
    protectedResources = {
        "es_extended",
        "esx_policejob",
        "esx_ambulancejob"
    }
}

-- Performance Settings
Config.Performance = {
    maxChecksPerTick = 10,     -- Maximum number of checks per server tick
    checkDelay = 100,          -- Delay between batch checks (ms)
    logCleanupInterval = 24,   -- Log cleanup interval (hours)
    maxLogSize = 10            -- Maximum log file size (MB)
}

return Config