-- Create addon namespace
local addonName, Spud = ...
Spud = Spud or {}

-- Move all our variables into the namespace
Spud.playerKills = {}
Spud.totalKills = 0

-- Localization table
Spud.L = Spud.L or {}
local L = Spud.L

-- Default English strings
L["NO_KILLS"] = "No kills have been made yet."
L["RESET_MESSAGE"] = "Kill counts have been reset."
L["HELP_HEADER"] = "Spud Commands:"
L["USAGE_WHISPER"] = "Usage: /spudwhisper <player>"

-- define a function to reset the kill counts
local function resetKillCounts()
  for playerName in pairs(Spud.playerKills) do
    Spud.playerKills[playerName] = 0
  end
  Spud.totalKills = 0
end

-- define a function to generate a kill count message
local function generateKillCountMessage(playerName, killCount)
  if Spud.totalKills == 0 then
    return string.format("%s has killed %d enemies.", playerName, killCount)
  end
  local percentage = (killCount / Spud.totalKills) * 100
  return string.format("%s has killed %d enemies (%.2f%% of total).", playerName, killCount, percentage)
end

-- define our function that handles the event
local function eventHandler(self, event)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, subevent, _, srcGUID, _, _, _, _, _, dstFlags = CombatLogGetCurrentEventInfo()

    if subevent == "PARTY_KILL" then
      -- check if the killed unit is an NPC
      local isNPC = bit.band(dstFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0

      if isNPC and srcGUID then
        -- Get the player name from the GUID
        local playerName = select(6, GetPlayerInfoByGUID(srcGUID))

        -- increment the count for this player
        if playerName then
          if not Spud.playerKills[playerName] then
            Spud.playerKills[playerName] = 0
          end
          Spud.playerKills[playerName] = Spud.playerKills[playerName] + 1
          Spud.totalKills = Spud.totalKills + 1
        end
      end
    end
  end
end

-- define our slash commands
SLASH_SPUD1 = "/spud"
SlashCmdList["SPUD"] = function(msg)
  local hasKills = false
  for playerName, killCount in pairs(Spud.playerKills) do
    hasKills = true
    print(generateKillCountMessage(playerName, killCount))
  end
  if not hasKills then
    print(L["NO_KILLS"])
  end
end

SLASH_SPUDSHARE1 = "/spudshare"
SlashCmdList["SPUDSHARE"] = function(msg)
  local hasKills = false
  for playerName, killCount in pairs(Spud.playerKills) do
    hasKills = true
    SendChatMessage(generateKillCountMessage(playerName, killCount), "PARTY")
  end
  if not hasKills then
    SendChatMessage(L["NO_KILLS"], "PARTY")
  end
end

SLASH_SPUDRESET1 = "/spudreset"
SlashCmdList["SPUDRESET"] = function(msg)
  resetKillCounts()
  print(L["RESET_MESSAGE"])
end

SLASH_SPUDWHISPER1 = "/spudwhisper"
SlashCmdList["SPUDWHISPER"] = function(msg)
  -- Check if a player name was provided
  if msg and msg:trim() ~= "" then
    local targetPlayer = msg:trim()
    local hasKills = false
    
    -- Send kill counts via whisper
    for playerName, killCount in pairs(Spud.playerKills) do
      hasKills = true
      SendChatMessage(generateKillCountMessage(playerName, killCount), "WHISPER", nil, targetPlayer)
    end
    
    if not hasKills then
      SendChatMessage(L["NO_KILLS"], "WHISPER", nil, targetPlayer)
    end
  else
    print("Usage: /spudwhisper <player>")
  end
end

SLASH_SPUDHELP1 = "/spudhelp"
SlashCmdList["SPUDHELP"] = function(msg)
  print("Spud Commands:")
  print("  /spud - List current session's kill counts")
  print("  /spudshare - Share kill counts with party")
  print("  /spudwhisper <player> - Whisper kill counts to player")
  print("  /spudreset - Reset kill counts")
  print("  /spudresetall - Reset kill counts for all characters")
  print("  /spudhelp - Show this help message")
end

SLASH_SPUDRESETALL1 = "/spudresetall"
SlashCmdList["SPUDRESETALL"] = function(msg)
  -- Reset current session counts
  resetKillCounts()
  
  -- TODO: When persistent storage is implemented, this will also clear stored counts for all characters
  print(L["RESET_MESSAGE"])
end

-- create frame and register event
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", eventHandler)

-- initialize kill counts
resetKillCounts()
