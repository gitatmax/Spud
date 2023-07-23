-- store kill counts
local playerKills = {}
local totalKills = 0

-- define a function to reset the kill counts
local function resetKillCounts()
  for playerName in pairs(playerKills) do
    playerKills[playerName] = 0
  end
  totalKills = 0
end

-- define a function to generate a kill count message
local function generateKillCountMessage(playerName, killCount)
  local percentage = (killCount / totalKills) * 100
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
          if not playerKills[playerName] then
            playerKills[playerName] = 0
          end
          playerKills[playerName] = playerKills[playerName] + 1
          totalKills = totalKills + 1
        end
      end
    end
  end
end

-- define our slash commands
SLASH_KILLCOUNT1 = "/killcount"
SlashCmdList["KILLCOUNT"] = function(msg)
  local hasKills = false
  for playerName, killCount in pairs(playerKills) do
    hasKills = true
    print(generateKillCountMessage(playerName, killCount))
  end
  if not hasKills then
    print("No kills have been made yet.")
  end
end

SLASH_KILLCOUNTSHARE1 = "/killcountshare"
SlashCmdList["KILLCOUNTSHARE"] = function(msg)
  local hasKills = false
  for playerName, killCount in pairs(playerKills) do
    hasKills = true
    SendChatMessage(generateKillCountMessage(playerName, killCount), "PARTY")
  end
  if not hasKills then
    SendChatMessage("No kills have been made yet.", "PARTY")
  end
end

SLASH_KILLCOUNTRESET1 = "/killcountreset"
SlashCmdList["KILLCOUNTRESET"] = function(msg)
  resetKillCounts()
  print("Kill counts have been reset.")
end

-- create frame and register event
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", eventHandler)

-- initialize kill counts
resetKillCounts()
