local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local enemiesFolder = workspace:WaitForChild("Enemies")

local CONFIG = {
    ATTACK_RANGE = 650,
    SEARCH_RADIUS = 2500,
    MAX_HIT_TARGETS = 20,
    PLAYER_AUTO_ATTACK_DISTANCE = 9999,
    MOB_AUTO_ATTACK_DISTANCE = 200,
    AIM_PREDICTION_FACTOR = 0.12,
    DEBUG = true,
}  

local Net, registerHit, registerAttack
pcall(function()
    Net = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
    registerHit    = Net:RemoteEvent("RegisterHit")
    registerAttack = Net:RemoteEvent("RegisterAttack")
end)

local function dbg(...)
    if CONFIG.DEBUG then print("[AutoAtk]", ...) end
end

local function getRoot(model)
    return model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso"))
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function hrp()
    return getRoot(plr.Character)
end

local function aliveModel(model)
    local hum  = getHumanoid(model)
    local root = getRoot(model)
    return hum and root and hum.Health > 0
end

local prevPositions = {}

local function getPredictedPosition(targetRoot)
    local now = tick()
    local cur = targetRoot.Position
    local prev = prevPositions[targetRoot]
    prevPositions[targetRoot] = { pos = cur, t = now }

    -- Cleanup old entries to prevent memory leak
    for key, val in pairs(prevPositions) do
        if now - val.t > 5 then
            prevPositions[key] = nil
        end
    end

    if prev and (now - prev.t) > 0 and (now - prev.t) < 0.5 then
        local vel = (cur - prev.pos) / (now - prev.t)
        return cur + vel * CONFIG.AIM_PREDICTION_FACTOR
    end

    local ok, vel = pcall(function() return targetRoot.AssemblyLinearVelocity end)
    if ok and vel and vel.Magnitude > 0 then
        -- Scale prediction by velocity magnitude
        local scaleFactor = math.min(vel.Magnitude / 100, 1) * CONFIG.AIM_PREDICTION_FACTOR
        return cur + vel * scaleFactor
    end

    return cur
end

local function dir(origin, targetPos)
    local v = targetPos - origin
    if v.Magnitude == 0 then return nil end
    return v.Magnitude > CONFIG.ATTACK_RANGE and (v.Unit * CONFIG.ATTACK_RANGE) or v
end

local function getRemote()
    local char = plr.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                local r = v:FindFirstChild("LeftClickRemote", true)
                if r then return r, v end
            end
        end
    end
    for _, v in ipairs(plr.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            local r = v:FindFirstChild("LeftClickRemote", true)
            if r then return r, v end
        end
    end
end

local function getEnv()
    if typeof(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
end

local function getTeamName(player)
    local team = player and player.Team
    return team and tostring(team.Name) or nil
end

local function isPvPEnabled(player)
    if not player then return false end
    local ok, val = pcall(function() return player:GetAttribute("PvpDisabled") end)
    if not ok then return true end  
    return val ~= true
end

local function isEnemyPlayer(other)
    if not other or other == plr then return false end

    local char = other.Character
    if not char then return false end
    if not aliveModel(char) then return false end

    local selfTeam  = getTeamName(plr)
    local otherTeam = getTeamName(other)

    local canAttack

    if selfTeam == "Marines" then
        canAttack = otherTeam == "Pirates"
    elseif selfTeam == "Pirates" then
        canAttack = otherTeam == "Marines" or otherTeam == "Pirates"
    elseif selfTeam ~= nil and otherTeam ~= nil then
        canAttack = selfTeam ~= otherTeam
    else
        canAttack = true
    end

    if not canAttack then return false end
    if not isPvPEnabled(other) then return false end
    return true
end

local function getBountyTarget()
    local env = getEnv()
    local tp  = env and env.targ
    if typeof(tp) == "Instance" and tp:IsA("Player") and isEnemyPlayer(tp) then
        local char = tp.Character
        return char, getRoot(char), "player"
    end
end

local function isValidTargetEntry(entry)
    return entry
        and entry.model
        and entry.root
        and entry.root.Parent
        and aliveModel(entry.model)
end

local function getTargetDistance(root, targetRoot)
    if not root or not targetRoot then return math.huge end
    return (targetRoot.Position - root.Position).Magnitude
end

local function gatherTargets(root)
    local targets     = {}
    local forcedModel, forcedRoot, forcedKind = getBountyTarget()

    local function push(model, targetRoot, kind, priority)
        if not model or not targetRoot then return end
        local distance = (targetRoot.Position - root.Position).Magnitude
        if distance > CONFIG.SEARCH_RADIUS then return end
        if kind == "mob" and distance > CONFIG.MOB_AUTO_ATTACK_DISTANCE then return end

        table.insert(targets, {
            model    = model,
            root     = targetRoot,
            kind     = kind,
            priority = priority,
            distance = distance,
        })
    end

    if forcedModel and forcedRoot then
        push(forcedModel, forcedRoot, forcedKind, -99)
    end

    for _, other in ipairs(Players:GetPlayers()) do
        if isEnemyPlayer(other) and other.Character ~= forcedModel then
            push(other.Character, getRoot(other.Character), "player", -10)
        end
    end

    local hasPlayer = false
    for _, t in ipairs(targets) do
        if t.kind == "player" then hasPlayer = true; break end
    end

    if not hasPlayer then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            if aliveModel(mob) then
                push(mob, getRoot(mob), "mob", 10)
            end
        end
    end

    table.sort(targets, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.distance < b.distance
    end)

    return targets
end

local currentTargetModel = nil

local function getPrimaryPlayerTarget(targets)
    for i = 1, #targets do
        local e = targets[i]
        if isValidTargetEntry(e) and e.kind == "player" then return e end
    end
end

local function getPrimaryTarget(targets)
    for i = 1, #targets do
        if isValidTargetEntry(targets[i]) then return targets[i] end
    end
end

local function canKeepCurrentTarget(root, entry)
    if not root or not isValidTargetEntry(entry) then return false end

    if entry.kind == "player" then
        return getTargetDistance(root, entry.root) <= CONFIG.SEARCH_RADIUS
    end
    return getTargetDistance(root, entry.root) <= CONFIG.MOB_AUTO_ATTACK_DISTANCE
end

local function getLockedTarget(root, targets)
    local playerTarget = getPrimaryPlayerTarget(targets)
    if playerTarget then
        currentTargetModel = playerTarget.model
        return playerTarget
    end

    if currentTargetModel then
        for i = 1, #targets do
            local e = targets[i]
            if e.model == currentTargetModel and canKeepCurrentTarget(root, e) then
                return e
            end
        end
    end

    local primary = getPrimaryTarget(targets)
    currentTargetModel = primary and primary.model or nil
    return primary
end

local function shouldAttackNow(root, entry)
    if not entry then return false end
    if entry.kind == "player" then return true end
    return getTargetDistance(root, entry.root) <= CONFIG.MOB_AUTO_ATTACK_DISTANCE
end

local function buildHitList(targets, primaryEntry)
    local hitData = {}
    local seen    = {}

    if primaryEntry and isValidTargetEntry(primaryEntry) then
        hitData[1]                    = { primaryEntry.model, primaryEntry.root }
        seen[primaryEntry.model]      = true
    end

    for i = 1, #targets do
        if #hitData >= CONFIG.MAX_HIT_TARGETS then break end
        local e = targets[i]
        if not seen[e.model] and isValidTargetEntry(e) and e.kind == "player" then
            hitData[#hitData + 1] = { e.model, e.root }
            seen[e.model] = true
        end
    end

    for i = 1, #targets do
        if #hitData >= CONFIG.MAX_HIT_TARGETS then break end
        local e = targets[i]
        if not seen[e.model] and isValidTargetEntry(e)
            and e.kind == "mob" and e.distance <= CONFIG.MOB_AUTO_ATTACK_DISTANCE
        then
            hitData[#hitData + 1] = { e.model, e.root }
            seen[e.model] = true
        end
    end

    return hitData
end

local function fireAt(remote, origin, targetRoot, isPlayer)
    if not remote or not origin or not targetRoot then return end
    local aimPos  = isPlayer and getPredictedPosition(targetRoot) or targetRoot.Position
    local fireVec = dir(origin, aimPos)
    if fireVec then
        remote:FireServer(fireVec, 1, true)
    end
end

local sharedTargets  = {}
local sharedPrimary  = nil
local _lastDebugTick = 0
local lastAttackTime = 0
local ATTACK_COOLDOWN = 0.1  -- 100ms

task.spawn(function()
    while task.wait(0.03) do
        pcall(function()
            local now = tick()
            if now - lastAttackTime < ATTACK_COOLDOWN then return end

            local root   = hrp()
            local remote = getRemote()

            if not root or not remote then
                if tick() - _lastDebugTick > 3 then
                    _lastDebugTick = tick()
                    dbg("WARN root=" .. tostring(root ~= nil) .. " remote=" .. tostring(remote ~= nil))
                end
                return
            end

            sharedTargets = gatherTargets(root)
            sharedPrimary = getLockedTarget(root, sharedTargets)

            if tick() - _lastDebugTick > 3 then
                _lastDebugTick = tick()
                local pc, mc = 0, 0
                for _, t in ipairs(sharedTargets) do
                    if t.kind == "player" then pc += 1 else mc += 1 end
                end
                dbg(("targets=%dp+%dm | primary=%s(%s)"):format(
                    pc, mc,
                    sharedPrimary and sharedPrimary.model.Name or "nil",
                    sharedPrimary and sharedPrimary.kind or "-"
                ))
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= plr then
                        dbg(("  %s alive=%s pvp=%s team=%s→%s enemy=%s"):format(
                            other.Name,
                            tostring(other.Character and aliveModel(other.Character)),
                            tostring(isPvPEnabled(other)),
                            tostring(getTeamName(plr)),
                            tostring(getTeamName(other)),
                            tostring(isEnemyPlayer(other))
                        ))
                    end
                end
            end

            if not sharedPrimary then currentTargetModel = nil; return end

            if shouldAttackNow(root, sharedPrimary) then
                fireAt(remote, root.Position, sharedPrimary.root, sharedPrimary.kind == "player")
                lastAttackTime = now
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.08) do
        pcall(function()
            local root   = hrp()
            local remote = getRemote()
            if not root or not remote then return end

            local primary = sharedPrimary
            if not primary or not shouldAttackNow(root, primary) then return end

            local hitData = buildHitList(sharedTargets, primary)
            if #hitData == 0 then return end

            if registerHit then
                if registerAttack then registerAttack:FireServer() end
                registerHit:FireServer(
                    primary.root, hitData, nil, nil,
                    tostring(math.random(100000, 999999))
                )
            else
                for i = 2, #hitData do
                    local extraRoot = hitData[i][2]
                    if extraRoot then
                        local isP = Players:GetPlayerFromCharacter(hitData[i][1]) ~= nil
                        fireAt(remote, root.Position, extraRoot, isP)
                    end
                end
            end
        end)
    end
end)

-- Periodic target validation to prevent locking on distant targets
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local root = hrp()
            if root and currentTargetModel and sharedPrimary and not canKeepCurrentTarget(root, sharedPrimary) then
                currentTargetModel = nil
                sharedPrimary = nil
            end
        end)
    end
end)

local combatY = nil
pcall(function()
    local scripts = plr:FindFirstChild("PlayerScripts")
    if scripts then
        local ok, result = pcall(function()
            return require(scripts:FindFirstChild("CombatFramework"))
        end)
        if ok and result then
            combatY = debug.getupvalues(result)[2]
        end
    end
end)

local _isSwinging    = false
local _swingCooldown = 0

task.spawn(function()
    game:GetService("RunService").RenderStepped:Connect(function(dt)
        if not (combatY and typeof(combatY) == "table") then return end
        pcall(function()
            local ctrl = combatY.activeController
            if not ctrl then return end

            ctrl.hitboxMagnitude = 60
            ctrl.timeToNextBlock = 0
            ctrl.focusStart      = 1655503339.0980349
            ctrl.increment       = 1
            ctrl.blocking        = false
            if ctrl.humanoid then
                ctrl.humanoid.AutoRotate = true
            end

            local root = hrp()
            local hasPrimary = sharedPrimary and isValidTargetEntry(sharedPrimary) and root
                and (sharedPrimary.root.Position - root.Position).Magnitude <= CONFIG.SEARCH_RADIUS

            if not hasPrimary then
                ctrl.active    = false
                ctrl.attacking = false
                _isSwinging    = false
            else
                ctrl.active = false
            end
        end)
    end)
end)
