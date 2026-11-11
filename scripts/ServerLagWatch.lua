--- Server Lag Watch
--
-- Finds which mod freezes a dedicated server and tells every player when it happens.
--
-- How it works:
--  * Every vehicle/placeable script call (SpecializationUtil.raiseEvent) and every mod's update()
--    is timed. Lua runs its garbage cleanup inside whichever script is allocating at that moment,
--    so the script that builds a huge amount of data is also the one that "pays" for the freeze.
--  * When a whole server frame takes longer than FREEZE_MS, the server writes a line to its log
--    and sends a notification to every connected player, naming the slowest script of that moment.
--  * If the game allows collectgarbage, the Lua memory each slow call added is reported too, and
--    the server logs its Lua memory once a minute.
--  * Every time the server saves the game, every player sees big red "SERVER SAVE" letters in the
--    middle of the screen until the save is done (see "Server save message" below).
--  * The server sends every player a small heartbeat each second. When a player's game hears nothing
--    for HEARTBEAT_TIMEOUT_MS, big red "SERVER LAG WATCH" letters show until the server answers again.

ServerLagWatch = {}
ServerLagWatch.modName = g_currentModName

ServerLagWatch.FREEZE_MS = 250          -- a server frame longer than this counts as a freeze
ServerLagWatch.SLOW_CALL_MS = 40        -- single script calls slower than this are remembered
ServerLagWatch.BIG_ALLOC_KB = 100000    -- single script calls adding more than ~100 MB are logged
ServerLagWatch.NOTIFY_COOLDOWN_MS = 10000
ServerLagWatch.MEMORY_LOG_MS = 60000

ServerLagWatch.SAVE_TEXT = "SERVER SAVE"
ServerLagWatch.SAVE_TEXT_SIZE = 0.1         -- share of the screen height; capitals ~1 inch tall on a 27" 1440p screen
ServerLagWatch.SAVE_QUIET_MS = 2000         -- a save is done once no save step ran for this long
ServerLagWatch.SAVE_MAX_MS = 300000         -- the server ends the message after this, whatever happens
ServerLagWatch.SAVE_BLOCKING_MS = 250       -- a save call that takes longer than this froze the server
ServerLagWatch.SAVE_DELAY_MS = 500          -- blocking saves start this much later so the message reaches players first
ServerLagWatch.SAVE_MIN_SHOW_MS = 2000      -- players see the message at least this long
ServerLagWatch.SAVE_SCREEN_TIMEOUT_MS = 600000 -- players drop the message if the "done" never arrives
ServerLagWatch.SAVE_STEP_CLASSES = {"ItemSystem", "VehicleSystem", "PlaceableSystem", "HandToolSystem", "AISystem"}
ServerLagWatch.SAVE_FILE_LOG_MS = 5         -- file writes during a save slower than this are logged by name

ServerLagWatch.LAG_TEXT = "SERVER LAG WATCH"
ServerLagWatch.HEARTBEAT_MS = 1000          -- server sends a heartbeat this often
ServerLagWatch.HEARTBEAT_TIMEOUT_MS = 3000  -- players show the lag message after this long without one

local gc = collectgarbage
local clock = getTimeSec

ServerLagWatch.worst = nil              -- slowest call since the last report {name, ms, kb}
ServerLagWatch.lastNotify = -math.huge
ServerLagWatch.memoryTimer = 0
ServerLagWatch.installed = false

ServerLagWatch.saveState = nil          -- server: the save running now {startedAt, lastStepAt, returned}
ServerLagWatch.pendingSave = nil        -- server: a save waiting for SAVE_DELAY_MS {mission, args, n, runAt}
ServerLagWatch.inSave = false           -- server: inside the game's own saveSavegame
ServerLagWatch.saveBlocks = false       -- server: true once a save was seen freezing the server in one go
ServerLagWatch.saveShownAt = nil        -- player: when the message went up (nil = not shown)
ServerLagWatch.saveHideRequested = false
ServerLagWatch.xmlNames = {}            -- server: xml file id -> file name, so save writes can be named
ServerLagWatch.lastUpdateClock = nil    -- server: real time of the last update (dt is capped by the game)
ServerLagWatch.lastHeartbeatSent = 0    -- server
ServerLagWatch.lastHeartbeat = nil      -- player: real time the last heartbeat arrived (nil = none yet)
ServerLagWatch.lagShownAt = nil         -- player: real time the lag message went up (nil = not shown)

local function luaMemoryKb()
    if gc ~= nil then
        local ok, kb = pcall(gc, "count")
        if ok then
            return kb
        end
    end
    return nil
end

--- Remembers a slow or memory-hungry script call.
function ServerLagWatch.record(name, ms, kb)
    if kb ~= nil and kb >= ServerLagWatch.BIG_ALLOC_KB then
        Logging.info("[ServerLagWatch] %s added %d MB of Lua memory in one call (%d ms)", name, math.floor(kb / 1024), math.floor(ms))
    end

    if ms >= ServerLagWatch.SLOW_CALL_MS then
        local worst = ServerLagWatch.worst
        if worst == nil or ms > worst.ms then
            ServerLagWatch.worst = {name = name, ms = ms, kb = kb}
        end
    end
end

--- Times one function call and records it.
local function timed(name, func, ...)
    local m0 = luaMemoryKb()
    local t0 = clock()
    func(...)
    local ms = (clock() - t0) * 1000
    local kb = nil
    if m0 ~= nil then
        local m1 = luaMemoryKb()
        if m1 ~= nil then
            kb = m1 - m0
        end
    end
    if ms >= ServerLagWatch.SLOW_CALL_MS or (kb ~= nil and kb >= ServerLagWatch.BIG_ALLOC_KB) then
        ServerLagWatch.record(name, ms, kb)
    end
end

--- Who is responsible for a vehicle or placeable, and where it is: "Farm 2 / JohnDoe - Field 14".
-- Only called for slow calls, so the lookups cost nothing in normal frames.
local function describeOwner(object)
    local parts = {}

    if object.getOwnerFarmId ~= nil then
        local farmId = object:getOwnerFarmId()
        local farm = g_farmManager ~= nil and g_farmManager:getFarmById(farmId) or nil
        if farm ~= nil and farm.name ~= nil and farm.name ~= "" then
            table.insert(parts, farm.name)
        elseif farmId ~= nil then
            table.insert(parts, "Farm " .. tostring(farmId))
        end
    end

    -- an implement's driver sits in the tractor it hangs on
    local root = object.rootVehicle or object
    local who = nil
    if root.getIsAIActive ~= nil and root:getIsAIActive() then
        who = "AI helper"
    end
    if root.getIsControlled ~= nil and root:getIsControlled() and root.getControllerName ~= nil then
        local name = root:getControllerName()
        if name ~= nil and name ~= "" then
            who = who ~= nil and (name .. " + AI helper") or name
        end
    end
    if who == nil and root.getIsControlled ~= nil then
        who = "no driver"
    end
    if who ~= nil then
        if #parts > 0 then
            parts[#parts] = parts[#parts] .. " / " .. who
        else
            table.insert(parts, who)
        end
    end

    local node = object.rootNode
    if node ~= nil and node ~= 0 and g_farmlandManager ~= nil then
        local x, _, z = getWorldTranslation(node)
        local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
        if farmland ~= nil and farmland.field ~= nil then
            table.insert(parts, "Field " .. tostring(farmland.field.name or farmland.id))
        elseif farmland ~= nil then
            table.insert(parts, "farmland " .. tostring(farmland.id))
        else
            table.insert(parts, "off-field")
        end
    end

    return table.concat(parts, " - ")
end

--- Times every vehicle and placeable specialization call.
function ServerLagWatch.installSpecializationHook()
    local originalRaiseEvent = SpecializationUtil.raiseEvent

    SpecializationUtil.raiseEvent = function(object, eventName, ...)
        local listeners = object.eventListeners ~= nil and object.eventListeners[eventName] or nil
        if listeners == nil then
            return originalRaiseEvent(object, eventName, ...)
        end

        for _, spec in ipairs(listeners) do
            local t0 = clock()
            local m0 = luaMemoryKb()
            spec[eventName](object, ...)
            local ms = (clock() - t0) * 1000
            local kb = nil
            if m0 ~= nil then
                local m1 = luaMemoryKb()
                if m1 ~= nil then
                    kb = m1 - m0
                end
            end
            if ms >= ServerLagWatch.SLOW_CALL_MS or (kb ~= nil and kb >= ServerLagWatch.BIG_ALLOC_KB) then
                local owner = object.configFileNameClean or (object.getName ~= nil and object:getName()) or "?"
                local ok, who = pcall(describeOwner, object)
                local name = string.format("%s:%s (%s)", tostring(spec.className), eventName, tostring(owner))
                if ok and who ~= nil and who ~= "" then
                    name = name .. " - " .. who
                end
                ServerLagWatch.record(name, ms, kb)
            end
        end
    end
end

--- Times every mod's own update() (mod event listeners found in each mod's globals).
function ServerLagWatch.installModListenerHooks()
    local wrapped = {}
    local count = 0

    for modName, _ in pairs(g_modIsLoaded) do
        local env = _G[modName]
        if type(env) == "table" and modName ~= ServerLagWatch.modName then
            for key, value in pairs(env) do
                if type(value) == "table" and not wrapped[value] then
                    local update = rawget(value, "update")
                    if type(update) == "function" and (rawget(value, "loadMap") ~= nil or rawget(value, "deleteMap") ~= nil) then
                        wrapped[value] = true
                        local name = modName .. "." .. tostring(key) .. ":update"
                        value.update = function(...)
                            timed(name, update, ...)
                        end
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

---------------------------------------------------------------------------------------------
-- Server save message
--
-- The game's save code is not in the published Lua source, so it is watched from the outside:
--  * FSBaseMission.saveSavegame starting = the save starts.
--  * The save is done once saveSavegame has returned and none of the game's save steps
--    (ItemSystem/VehicleSystem/... :save) has run for SAVE_QUIET_MS. That covers both a save that
--    runs in one go and one that is spread over several frames.
--  * A save that runs in one go freezes the server, so "save started" could not reach the players
--    before it ends. Once the server has seen that happen, later saves on a dedicated server wait
--    SAVE_DELAY_MS after the message is sent. A waiting save is run at once if the game is closed.
--  * Every step is logged with its time, so the server log shows how the game really saves.
---------------------------------------------------------------------------------------------

local function pack(...)
    return {n = select("#", ...), ...}
end

function ServerLagWatch.beginSave()
    local now = clock()
    ServerLagWatch.saveState = {startedAt = now, lastStepAt = now, returned = false, stepMs = 0, fileMs = 0, fileCount = 0}
    Logging.info("[ServerLagWatch] Server save started")
    g_server:broadcastEvent(ServerSaveEvent.new(true))
    if g_dedicatedServer == nil then
        ServerLagWatch.setSaveShown(true)
    end
end

function ServerLagWatch.endSave(reason)
    local state = ServerLagWatch.saveState
    if state == nil then
        return
    end
    ServerLagWatch.saveState = nil
    Logging.info("[ServerLagWatch] Server save finished after %.1f s (%s)", clock() - state.startedAt, reason)
    if g_server ~= nil then
        g_server:broadcastEvent(ServerSaveEvent.new(false))
    end
    if g_dedicatedServer == nil then
        ServerLagWatch.setSaveShown(false)
    end
end

--- Runs the game's own save and notes how long the call blocked.
function ServerLagWatch.runSave(originalSave, mission, ...)
    local state = ServerLagWatch.saveState
    local m0 = luaMemoryKb()
    local t0 = clock()
    ServerLagWatch.inSave = true
    local results = pack(pcall(originalSave, mission, ...))
    ServerLagWatch.inSave = false
    local ms = (clock() - t0) * 1000
    local m1 = luaMemoryKb()

    if not results[1] then
        Logging.error("[ServerLagWatch] Game save failed: %s", tostring(results[2]))
    end
    if state ~= nil then
        state.returned = true
        state.lastStepAt = clock()
        state.callMs = ms
    end
    Logging.info("[ServerLagWatch] saveSavegame call took %d ms", math.floor(ms))
    if state ~= nil then
        Logging.info("[ServerLagWatch] Save breakdown: system saves %d ms, file writes %d ms in %d calls, everything else %d ms%s",
            math.floor(state.stepMs), math.floor(state.fileMs), state.fileCount,
            math.floor(math.max(ms - state.stepMs - state.fileMs, 0)),
            (m0 ~= nil and m1 ~= nil) and string.format(", Lua memory %+d MB", math.floor((m1 - m0) / 1024)) or "")
    end
    ServerLagWatch.record("game save (saveSavegame)", ms, nil) -- so a freeze report names the save
    if ms >= ServerLagWatch.SAVE_BLOCKING_MS and not ServerLagWatch.saveBlocks then
        ServerLagWatch.saveBlocks = true
        Logging.info("[ServerLagWatch] Saving froze the server in one go: next saves start %d ms after the message", ServerLagWatch.SAVE_DELAY_MS)
    end
    return unpack(results, 2, results.n)
end

function ServerLagWatch.runPendingSave(reason)
    local pending = ServerLagWatch.pendingSave
    if pending == nil then
        return
    end
    ServerLagWatch.pendingSave = nil
    Logging.info("[ServerLagWatch] Running the waiting save (%s)", reason)
    ServerLagWatch.runSave(pending.originalSave, pending.mission, unpack(pending.args, 1, pending.args.n))
end

function ServerLagWatch.installSaveHooks()
    if FSBaseMission == nil or FSBaseMission.saveSavegame == nil then
        Logging.warning("[ServerLagWatch] FSBaseMission.saveSavegame not found, no server save message")
        return
    end
    -- game classes outlive a savegame; the hooks look ServerLagWatch up by name, so once is enough
    if FSBaseMission.slwSaveHooksInstalled then
        return
    end
    FSBaseMission.slwSaveHooksInstalled = true

    local originalSave = FSBaseMission.saveSavegame
    FSBaseMission.saveSavegame = function(mission, ...)
        local watch = ServerLagWatch
        if not watch.installed or watch.inSave then
            return originalSave(mission, ...)
        end
        if watch.pendingSave ~= nil then
            return -- the same save is already waiting to run
        end
        if watch.saveState == nil then
            watch.beginSave()
        end
        if watch.saveBlocks and g_dedicatedServer ~= nil then
            watch.pendingSave = {originalSave = originalSave, mission = mission, args = pack(...),
                runAt = clock() + watch.SAVE_DELAY_MS / 1000}
            return
        end
        return watch.runSave(originalSave, mission, ...)
    end

    -- a save still waiting when the game closes runs right away, before anything is torn down
    FSBaseMission.delete = Utils.prependedFunction(FSBaseMission.delete, function()
        if ServerLagWatch.installed then
            ServerLagWatch.runPendingSave("game closing")
            ServerLagWatch.endSave("game closing")
        end
    end)

    for _, className in ipairs(ServerLagWatch.SAVE_STEP_CLASSES) do
        local class = _G[className]
        if type(class) == "table" and type(class.save) == "function" then
            local originalStep = class.save
            class.save = function(...)
                local state = ServerLagWatch.installed and ServerLagWatch.saveState or nil
                if state == nil then
                    return originalStep(...)
                end
                local t0 = clock()
                state.inStep = true -- file writes inside a step count toward the step, not twice
                local results = pack(originalStep(...))
                state.inStep = false
                state.lastStepAt = clock()
                state.stepMs = state.stepMs + (state.lastStepAt - t0) * 1000
                Logging.info("[ServerLagWatch] Save step %s.save at +%d ms took %d ms%s", className,
                    math.floor((t0 - state.startedAt) * 1000), math.floor((state.lastStepAt - t0) * 1000),
                    state.returned and " (after saveSavegame returned)" or "")
                return unpack(results, 1, results.n)
            end
        end
    end

    ServerLagWatch.installFileWriteHooks()
end

--- Names a file write from its arguments: an xml id, a file name, or an object with .filename.
local function describeWrite(funcName, ...)
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "number" and ServerLagWatch.xmlNames[arg] ~= nil then
            return string.format("%s(%s)", funcName, ServerLagWatch.xmlNames[arg])
        elseif type(arg) == "string" and (arg:find("/", 1, true) or arg:find("%.%a+$")) then
            return string.format("%s(%s)", funcName, arg)
        elseif type(arg) == "table" and type(rawget(arg, "filename")) == "string" then
            return string.format("%s(%s)", funcName, arg.filename)
        end
    end
    return funcName
end

--- Times every global save* function (engine file writers such as saveXMLFile, saveBitVectorMapToFile)
--- while a save runs, and remembers xml file names so the log can say which file was slow.
function ServerLagWatch.installFileWriteHooks()
    local names = {}
    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "function" and name:match("^save") then
            table.insert(names, name)
        end
    end

    for _, name in ipairs(names) do
        local original = _G[name]
        _G[name] = function(...)
            local state = ServerLagWatch.installed and ServerLagWatch.saveState or nil
            if state == nil then
                return original(...)
            end
            local t0 = clock()
            local results = pack(original(...))
            local t1 = clock()
            local ms = (t1 - t0) * 1000
            if not state.inStep then
                state.fileMs = state.fileMs + ms
                state.fileCount = state.fileCount + 1
            end
            state.lastStepAt = t1
            if ms >= ServerLagWatch.SAVE_FILE_LOG_MS then
                Logging.info("[ServerLagWatch] Save write %s at +%d ms took %d ms", describeWrite(name, ...),
                    math.floor((t0 - state.startedAt) * 1000), math.floor(ms))
            end
            return unpack(results, 1, results.n)
        end
    end

    for _, name in ipairs({"createXMLFile", "loadXMLFile"}) do
        local original = _G[name]
        if type(original) == "function" then
            _G[name] = function(objectName, filename, ...)
                local id = original(objectName, filename, ...)
                if type(id) == "number" and id ~= 0 and type(filename) == "string" then
                    ServerLagWatch.xmlNames[id] = filename
                end
                return id
            end
        end
    end

    Logging.info("[ServerLagWatch] Timing %d save* file functions during saves", #names)
end

--- Server, every frame: starts a waiting save and decides when the running one is done.
function ServerLagWatch.updateSave()
    local now = clock()
    local pending = ServerLagWatch.pendingSave
    if pending ~= nil and now >= pending.runAt then
        ServerLagWatch.runPendingSave("message sent")
    end

    local state = ServerLagWatch.saveState
    if state == nil or ServerLagWatch.pendingSave ~= nil then
        return
    end
    if (now - state.startedAt) * 1000 >= ServerLagWatch.SAVE_MAX_MS then
        ServerLagWatch.endSave("time limit")
    elseif state.returned and (now - state.lastStepAt) * 1000 >= ServerLagWatch.SAVE_QUIET_MS then
        ServerLagWatch.endSave("done")
    end
end

--- Player: puts the message up or asks for it to come down (after SAVE_MIN_SHOW_MS).
function ServerLagWatch.setSaveShown(isSaving)
    if isSaving then
        ServerLagWatch.saveShownAt = g_time or 0
        ServerLagWatch.saveHideRequested = false
    elseif ServerLagWatch.saveShownAt ~= nil then
        ServerLagWatch.saveHideRequested = true
    end
end

function ServerLagWatch.updateSaveMessage()
    local shownAt = ServerLagWatch.saveShownAt
    if shownAt == nil then
        return
    end
    local shownFor = (g_time or 0) - shownAt
    if (ServerLagWatch.saveHideRequested and shownFor >= ServerLagWatch.SAVE_MIN_SHOW_MS)
        or shownFor >= ServerLagWatch.SAVE_SCREEN_TIMEOUT_MS then
        ServerLagWatch.saveShownAt = nil
        ServerLagWatch.saveHideRequested = false
    end
end

--- Server, every frame: sends the heartbeat players use to notice a frozen server.
function ServerLagWatch.updateHeartbeat(now)
    if now - ServerLagWatch.lastHeartbeatSent >= ServerLagWatch.HEARTBEAT_MS / 1000 then
        ServerLagWatch.lastHeartbeatSent = now
        g_server:broadcastEvent(ServerHeartbeatEvent.new())
    end
end

--- Player: shows "SERVER LAG WATCH" while no heartbeat arrives, hides it once they come back.
function ServerLagWatch.updateLagMessage()
    local last = ServerLagWatch.lastHeartbeat
    if last == nil or g_server ~= nil then
        return -- no heartbeat seen yet, or this game is the server itself
    end
    local now = clock()
    local silentMs = (now - last) * 1000
    if silentMs >= ServerLagWatch.HEARTBEAT_TIMEOUT_MS then
        if ServerLagWatch.lagShownAt == nil then
            ServerLagWatch.lagShownAt = now
            Logging.info("[ServerLagWatch] No word from the server for %.1f s", silentMs / 1000)
        end
    elseif ServerLagWatch.lagShownAt ~= nil
        and (now - ServerLagWatch.lagShownAt) * 1000 >= ServerLagWatch.SAVE_MIN_SHOW_MS then
        Logging.info("[ServerLagWatch] Server answering again after %.1f s", now - ServerLagWatch.lagShownAt + ServerLagWatch.HEARTBEAT_TIMEOUT_MS / 1000)
        ServerLagWatch.lagShownAt = nil
    end
end

local function drawBigText(text, size)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    setTextColor(0, 0, 0, 0.8)
    renderText(0.5 + size * 0.03, 0.5 - size * 0.04, size, text)
    setTextColor(1, 0, 0, 1)
    renderText(0.5, 0.5, size, text)
    setTextColor(1, 1, 1, 1)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
end

function ServerLagWatch:draw()
    -- a save freezes the server too, so the save message wins
    if self.saveShownAt ~= nil then
        drawBigText(self.SAVE_TEXT, self.SAVE_TEXT_SIZE)
    elseif self.lagShownAt ~= nil then
        drawBigText(self.LAG_TEXT, self.SAVE_TEXT_SIZE)
    end
end

---------------------------------------------------------------------------------------------

function ServerLagWatch:loadMap(filename)
    if g_server == nil then
        return
    end

    self:installSpecializationHook()
    local count = self:installModListenerHooks()
    self.installSaveHooks()
    self.installed = true

    local kb = luaMemoryKb()
    Logging.info("[ServerLagWatch] Watching %d mod update scripts and all vehicle/placeable scripts. Freeze threshold %d ms. Lua memory readout %s.",
        count, self.FREEZE_MS, kb ~= nil and string.format("available (%d MB now)", math.floor(kb / 1024)) or "not available")
end

function ServerLagWatch:deleteMap()
    self.installed = false
    self.saveState = nil
    self.pendingSave = nil
    self.saveShownAt = nil
    self.lastHeartbeat = nil
    self.lagShownAt = nil
end

function ServerLagWatch:update(dt)
    self.updateSaveMessage()
    self.updateLagMessage()
    if not self.installed then
        return
    end
    self.updateSave()

    -- the game caps dt, so a long freeze only shows in real time
    local now = clock()
    if self.lastUpdateClock ~= nil then
        dt = math.max(dt, (now - self.lastUpdateClock) * 1000)
    end
    self.lastUpdateClock = now
    self.updateHeartbeat(now)

    if dt >= self.FREEZE_MS then
        local worst = self.worst
        local culprit = "unknown"
        if worst ~= nil then
            culprit = string.format("%s, %d ms", worst.name, math.floor(worst.ms))
            if worst.kb ~= nil then
                culprit = culprit .. string.format(", +%d MB", math.floor(worst.kb / 1024))
            end
        end

        Logging.info("[ServerLagWatch] SERVER FROZE for %d ms. Slowest script: %s", math.floor(dt), culprit)

        local now = g_time or 0
        if now - self.lastNotify >= self.NOTIFY_COOLDOWN_MS then
            self.lastNotify = now
            g_server:broadcastEvent(ServerLagEvent.new(math.floor(dt), culprit))
            if g_dedicatedServer == nil then
                -- self-hosted game: the host plays on this machine and should see it too
                ServerLagWatch.showWarning(math.floor(dt), culprit)
            end
        end

        self.worst = nil
    end

    self.memoryTimer = self.memoryTimer + dt
    if self.memoryTimer >= self.MEMORY_LOG_MS then
        self.memoryTimer = 0
        local kb = luaMemoryKb()
        if kb ~= nil then
            Logging.info("[ServerLagWatch] Lua memory %d MB", math.floor(kb / 1024))
        end
        -- slow calls that did not cause a freeze are forgotten after a minute
        self.worst = nil
    end
end

--- Shown on every player's screen.
function ServerLagWatch.showWarning(ms, culprit)
    local text = string.format("Server froze %.1f s - %s", ms / 1000, culprit)
    Logging.info("[ServerLagWatch] %s", text)
    if g_currentMission ~= nil and g_currentMission.addIngameNotification ~= nil then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
    end
end


ServerLagEvent = {}
local ServerLagEvent_mt = Class(ServerLagEvent, Event)
InitEventClass(ServerLagEvent, "ServerLagEvent")

function ServerLagEvent.emptyNew()
    return Event.new(ServerLagEvent_mt)
end

function ServerLagEvent.new(ms, culprit)
    local self = ServerLagEvent.emptyNew()
    self.ms = ms
    self.culprit = culprit
    return self
end

function ServerLagEvent:readStream(streamId, connection)
    self.ms = streamReadInt32(streamId)
    self.culprit = streamReadString(streamId)
    self:run(connection)
end

function ServerLagEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.ms)
    streamWriteString(streamId, self.culprit)
end

function ServerLagEvent:run(connection)
    if connection:getIsServer() then
        ServerLagWatch.showWarning(self.ms, self.culprit)
    end
end


ServerSaveEvent = {}
local ServerSaveEvent_mt = Class(ServerSaveEvent, Event)
InitEventClass(ServerSaveEvent, "ServerSaveEvent")

function ServerSaveEvent.emptyNew()
    return Event.new(ServerSaveEvent_mt)
end

function ServerSaveEvent.new(isSaving)
    local self = ServerSaveEvent.emptyNew()
    self.isSaving = isSaving
    return self
end

function ServerSaveEvent:readStream(streamId, connection)
    self.isSaving = streamReadBool(streamId)
    self:run(connection)
end

function ServerSaveEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isSaving)
end

function ServerSaveEvent:run(connection)
    if connection:getIsServer() then
        ServerLagWatch.setSaveShown(self.isSaving)
    end
end


ServerHeartbeatEvent = {}
local ServerHeartbeatEvent_mt = Class(ServerHeartbeatEvent, Event)
InitEventClass(ServerHeartbeatEvent, "ServerHeartbeatEvent")

function ServerHeartbeatEvent.emptyNew()
    return Event.new(ServerHeartbeatEvent_mt)
end

function ServerHeartbeatEvent.new()
    return ServerHeartbeatEvent.emptyNew()
end

function ServerHeartbeatEvent:readStream(streamId, connection)
    self:run(connection)
end

function ServerHeartbeatEvent:writeStream(streamId, connection)
end

function ServerHeartbeatEvent:run(connection)
    if connection:getIsServer() then
        ServerLagWatch.lastHeartbeat = clock()
    end
end


addModEventListener(ServerLagWatch)
