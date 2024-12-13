-- Create addon namespace
local addonName, Spud = ...
Spud = Spud or {}

-- Move all our variables into the namespace
Spud.playerKills = {}
Spud.totalKills = 0
Spud.currentCombatDamage = {}
Spud.currentTarget = nil
Spud.playerLoot = {}
Spud.totalLoot = 0

-- Localization table
Spud.L = Spud.L or {}
local L = Spud.L

-- Default English strings
L["NO_KILLS"] = "No kills have been made yet."
L["NO_LOOT"] = "No loot has been collected yet."
L["RESET_MESSAGE"] = "Statistics have been reset."
L["HELP_HEADER"] = "Spud Commands:"
L["USAGE_WHISPER"] = "Usage: /spudwhisper <player>"
L["VERSION"] = "Spud Version %s"

-- define a function to reset the kill counts
local function resetCounts()
  -- Reset kill counts
  for playerName in pairs(Spud.playerKills) do
    Spud.playerKills[playerName] = 0
  end
  Spud.totalKills = 0
  
  -- Reset loot counts
  for playerName in pairs(Spud.playerLoot) do
    Spud.playerLoot[playerName] = 0
  end
  Spud.totalLoot = 0
  
  print(L["RESET_MESSAGE"])
end

-- define a function to generate a kill count message
local function generateKillCountMessage(playerName, killCount)
  if Spud.totalKills == 0 then
    return string.format("%s has killed %d enemies.", playerName, killCount)
  end
  local percentage = (killCount / Spud.totalKills) * 100
  return string.format("%s has killed %d enemies (%.2f%% of total).", playerName, killCount, percentage)
end

-- define a function to generate loot message
local function generateLootMessage(playerName, lootAmount)
  if Spud.totalLoot == 0 then
    return string.format("%s has looted %d copper.", playerName, lootAmount)
  end
  local percentage = (lootAmount / Spud.totalLoot) * 100
  return string.format("%s has looted %d copper (%.2f%% of total).", playerName, lootAmount, percentage)
end

-- define our function that handles the event
local function eventHandler(self, event)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, subevent, _, srcGUID, _, _, _, destGUID, destName, dstFlags = CombatLogGetCurrentEventInfo()

    -- Track damage events
    if subevent == "DAMAGE_SHIELD" or subevent == "DAMAGE_SPLIT" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "SWING_DAMAGE" then
      local amount = select(subevent == "SWING_DAMAGE" and 12 or 15, CombatLogGetCurrentEventInfo())
      
      -- Initialize damage tracking for this target
      if not Spud.currentCombatDamage[destGUID] then
        Spud.currentCombatDamage[destGUID] = {}
      end
      
      -- Add damage to player's total
      if srcGUID then
        local playerName = select(6, GetPlayerInfoByGUID(srcGUID))
        if playerName then
          Spud.currentCombatDamage[destGUID][playerName] = (Spud.currentCombatDamage[destGUID][playerName] or 0) + amount
        end
      end
    end

    -- Handle kills
    if subevent == "PARTY_KILL" then
      local isNPC = bit.band(dstFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0
      if isNPC and destGUID and Spud.currentCombatDamage[destGUID] then
        -- Calculate damage percentages and update kill counts
        local totalDamage = 0
        for _, damage in pairs(Spud.currentCombatDamage[destGUID]) do
          totalDamage = totalDamage + damage
        end

        -- Update kill counts based on damage contribution
        for playerName, damage in pairs(Spud.currentCombatDamage[destGUID]) do
          local contribution = damage / totalDamage
          if not Spud.playerKills[playerName] then
            Spud.playerKills[playerName] = 0
          end
          Spud.playerKills[playerName] = Spud.playerKills[playerName] + contribution
          Spud.totalKills = Spud.totalKills + contribution
        end

        -- Clear damage tracking for this target
        Spud.currentCombatDamage[destGUID] = nil
      end
    end

    -- Handle loot events
    if subevent == "LOOT_MONEY" then
      if srcGUID then
        local playerName = select(6, GetPlayerInfoByGUID(srcGUID))
        if playerName then
          local amount = select(13, CombatLogGetCurrentEventInfo())
          if not Spud.playerLoot[playerName] then
            Spud.playerLoot[playerName] = 0
          end
          Spud.playerLoot[playerName] = Spud.playerLoot[playerName] + amount
          Spud.totalLoot = Spud.totalLoot + amount
        end
      end
    end

    if SpudStatsFrame and SpudStatsFrame:IsShown() then
        UpdateStats(SpudStatsFrame)
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
SlashCmdList["SPUDRESET"] = resetCounts

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
  print(string.format(L["VERSION"], GetAddOnMetadata("Spud", "Version")))
  print(L["HELP_HEADER"])
  print("  /spud - List current session's kill counts")
  print("  /spudshare - Share kill counts with party")
  print("  /spudwhisper <player> - Whisper kill counts to player")
  print("  /spudreset - Reset all statistics")
  print("  /spudloot - List current session's loot statistics")
  print("  /spudlootshare - Share loot statistics with party")
  print("  /spudlootwhisper <player> - Whisper loot statistics to player")
  print("  /spudhelp - Show this help message")
  print("  /spudwindow - Toggle stats window display")
end

SLASH_SPUDRESETALL1 = "/spudresetall"
SlashCmdList["SPUDRESETALL"] = function(msg)
  -- Reset current session counts
  resetCounts()
  
  -- TODO: When persistent storage is implemented, this will also clear stored counts for all characters
  print(L["RESET_MESSAGE"])
end

SLASH_SPUDLOOT1 = "/spudloot"
SlashCmdList["SPUDLOOT"] = function(msg)
  local hasLoot = false
  for playerName, lootAmount in pairs(Spud.playerLoot) do
    hasLoot = true
    print(generateLootMessage(playerName, lootAmount))
  end
  if not hasLoot then
    print("No loot has been collected yet.")
  end
end

SLASH_SPUDLOOTSHARE1 = "/spudlootshare"
SlashCmdList["SPUDLOOTSHARE"] = function(msg)
  local hasLoot = false
  for playerName, lootAmount in pairs(Spud.playerLoot) do
    hasLoot = true
    SendChatMessage(generateLootMessage(playerName, lootAmount), "PARTY")
  end
  if not hasLoot then
    SendChatMessage(L["NO_LOOT"], "PARTY")
  end
end

SLASH_SPUDLOOTWHISPER1 = "/spudlootwhisper"
SlashCmdList["SPUDLOOTWHISPER"] = function(msg)
  if msg and msg:trim() ~= "" then
    local targetPlayer = msg:trim()
    local hasLoot = false
    
    for playerName, lootAmount in pairs(Spud.playerLoot) do
      hasLoot = true
      SendChatMessage(generateLootMessage(playerName, lootAmount), "WHISPER", nil, targetPlayer)
    end
    
    if not hasLoot then
      SendChatMessage(L["NO_LOOT"], "WHISPER", nil, targetPlayer)
    end
  else
    print(L["USAGE_WHISPER"])
  end
end

-- Add to the existing slash commands section
SLASH_UNTAMEDBEASTMODE1 = "/untamedbeastmode"
SlashCmdList["UNTAMEDBEASTMODE"] = function(msg)
    -- Override the kill count message generator temporarily
    local originalGenerator = generateKillCountMessage
    generateKillCountMessage = function(playerName, killCount)
        if Spud.totalKills == 0 then
            return string.format("%s *RAWRS* %d *GROWLS*", playerName, killCount)
        end
        local percentage = (killCount / Spud.totalKills) * 100
        return string.format("%s has *SAVAGELY MAULED* %d prey (*FEROCIOUSLY* %d%% of the hunt)", 
            playerName, killCount, percentage)
    end
    
    -- Reset after 30 seconds
    C_Timer.After(30, function()
        generateKillCountMessage = originalGenerator
        print("The beast has been tamed... for now...")
    end)
    
    print("*UNLEASHING PRIMAL FURY* - Messages are now more... bestial... for 30 seconds")
end

-- create frame and register event
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", eventHandler)

-- initialize kill counts
resetCounts()

-- Create the main frame
local function CreateStatsFrame()
    local frame = CreateFrame("Frame", "SpudStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Add title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("Spud Stats")
    
    -- Add scrolling content frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetSize())
    scrollFrame:SetScrollChild(content)
    
    frame.content = content
    frame:Hide()
    
    return frame
end

-- Update the stats display
local function UpdateStats(frame)
    local content = frame.content
    local yOffset = 0
    
    -- Clear existing fontstrings
    for _, child in pairs({content:GetChildren()}) do
        child:Hide()
    end
    
    -- Add kill stats
    for playerName, killCount in pairs(Spud.playerKills) do
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 10, -yOffset)
        text:SetText(generateKillCountMessage(playerName, killCount))
        yOffset = yOffset + 20
    end
    
    -- Add spacing
    yOffset = yOffset + 20
    
    -- Add loot stats
    for playerName, lootAmount in pairs(Spud.playerLoot) do
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 10, -yOffset)
        text:SetText(generateLootMessage(playerName, lootAmount))
        yOffset = yOffset + 20
    end
    
    content:SetHeight(yOffset)
end
