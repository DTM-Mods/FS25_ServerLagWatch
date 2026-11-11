-- NoProfanityFilter: turns off the game's profanity filter everywhere it is used from Lua
-- (chat, text input boxes such as vehicle/farm names, license plates).
-- The game filters through the engine global filterText(text, ...); we replace it with
-- a pass-through so text always shows exactly as typed.
-- Mod scripts run in their own environment, so a bare "filterText = ..." would only change
-- this mod's copy. The game's real globals sit behind the environment's metatable __index.
-- Author: PropaineX

local mt = getmetatable(_G)
local gameEnv = (mt ~= nil and type(mt.__index) == "table") and mt.__index or _G

if gameEnv.filterText ~= nil and gameEnv.NoProfanityFilter_originalFilterText == nil then
    gameEnv.NoProfanityFilter_originalFilterText = gameEnv.filterText

    gameEnv.filterText = function(text, ...)
        return text
    end

    if gameEnv.filterText("fuck", true, true) == "fuck" then
        print("ServerLagWatch: profanity filter disabled (game global replaced)")
    else
        print("ServerLagWatch: WARNING profanity filter still active")
    end
else
    print("ServerLagWatch: WARNING could not disable profanity filter (filterText not found)")
end
