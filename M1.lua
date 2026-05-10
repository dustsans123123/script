local Players           = game:GetService("Players")
local TeleportService   = game:GetService("TeleportService")
local player            = Players.LocalPlayer
local CONFIG = {
    TeleportDistance      = 2,
    SilentTeleport        = true,
    CheckSafeZone         = true,
    GhostResetInterval    = 0.5,
    RecentlyKilledTimeout = 9999,
    NoHitTimeout          = 5,
    BlacklistTimeout      = 60,
    AttackInterval        = 0.03,
    SweepSpeed            = 0.04,
    HopDelay              = 3,
    AutoRejoin            = true,
    AutoJoinTeam          = true,
    Team                  = "Marines",
    PreferredRegion       = "sing",
    SpawnAltitude         = 2000,
}
local STATS_FILE            = "Zeroxhub.json"
local totalBountyGlobal     = 0
local totalTimeGlobal       = 0
local sessionBounty         = 0

local function autoJoinTeam()
    if not CONFIG.AutoJoinTeam then return end
    local teamStr = CONFIG.Team or "Marines"
    pcall(function()
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
        if remote then remote:InvokeServer("SetTeam", teamStr) end
    end)
end
task.spawn(autoJoinTeam)
local recentlyKilled    = {}
local hitTracker        = {}
local isRunning         = false
local currentTarget     = nil
local cachedRemote      = nil
local cachedTool        = nil
local cachedM1Active    = nil
local lastTargetPos     = nil
local lastTargetDir     = Vector3.new(0, 0, -1)
local sessionStartTime  = os.time()
local targetStartTime   = nil
local targetStartHealth = nil
local noTargetSince     = nil
local isHopping         = false
local PLACE_ID = game.PlaceId
local JOB_ID   = game.JobId

local function getRandomOffset()
    return Vector3.new(
        (math.random()-0.5)*0.5,
        (math.random()-0.5)*0.5,
        (math.random()-0.5)*0.5
    )
end

local function formatTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d",h,m,s)
    else return string.format("%02d:%02d",m,s) end
end

local HttpService = game:GetService("HttpService")
local function saveStats()
    local data = {
        TotalBounty = totalBountyGlobal,
        TotalTime   = totalTimeGlobal + (os.time() - sessionStartTime)
    }
    pcall(function() writefile(STATS_FILE, HttpService:JSONEncode(data)) end)
end

local function loadStats()
    pcall(function()
        if isfile(STATS_FILE) then
            local content = readfile(STATS_FILE)
            local data = HttpService:JSONDecode(content)
            totalBountyGlobal = data.TotalBounty or 0
            totalTimeGlobal   = data.TotalTime or 0
        end
    end)
end
loadStats()

local function isInSafeZone(targetChar)
    if not targetChar then return false end
    if targetChar == player.Character then
        local pg = player:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        local bhl = main and main:FindFirstChild("BottomHUDList")
        local szUI = bhl and bhl:FindFirstChild("SafeZone")
        if szUI and szUI.Visible then return true end
    end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local folder = workspace:FindFirstChild("_WorldOrigin")
        and workspace._WorldOrigin:FindFirstChild("SafeZones")
    if not folder then return false end
    local pos = root.Position
    for _, zone in pairs(folder:GetChildren()) do
        if zone:IsA("BasePart") then
            local lp   = zone.CFrame:PointToObjectSpace(pos)
            local half = zone.Size / 2
            if math.abs(lp.X)<=half.X and math.abs(lp.Y)<=half.Y and math.abs(lp.Z)<=half.Z then
                return true
            end
        end
    end
    return false
end

local function physicalEscape()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    pcall(function()
        for i = 1, 3 do
            root.CFrame = root.CFrame * CFrame.new(0, 0, -50)
            task.wait(0.05)
        end
        root.CFrame = root.CFrame * CFrame.new(0, 500, 0)
    end)
end

local function shouldIgnore(targetPlayer, targetChar)
    if not targetPlayer or not targetChar then return true end
    if player.Team and player.Team.Name == "Marines" and targetPlayer.Team and targetPlayer.Team.Name == "Marines" then
        return true
    end
    if CONFIG.CheckSafeZone and isInSafeZone(targetChar) then return true end
    if targetChar:FindFirstChildOfClass("ForceField") then return true end
    local killTime = recentlyKilled[targetPlayer.Name]
    if killTime and os.time()-killTime < CONFIG.RecentlyKilledTimeout then
        return true
    elseif killTime then
        recentlyKilled[targetPlayer.Name] = nil
    end
    local tracker = hitTracker[targetPlayer.Name]
    if tracker and tracker.blacklistedUntil then
        if os.time() < tracker.blacklistedUntil then return true
        else hitTracker[targetPlayer.Name] = nil end
    end
    return false
end

local function getPlayerLevel(p)
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs({"Level","Lv","level","LVL","EXP","Rank"}) do
            local v = ls:FindFirstChild(n)
            if v then return tostring(v.Value) end
        end
    end
    for _, child in pairs(p:GetChildren()) do
        local lv = child:FindFirstChild("Level") or child:FindFirstChild("Lv")
        if lv then return tostring(lv.Value) end
    end
    return "?"
end

local function scanRemoteInTool(tool)
    if not tool then return nil, nil end
    local r = tool:FindFirstChild("LeftClickRemote")
    local m = tool:FindFirstChild("M1Active")
    if r then return r, m end
    for _, child in pairs(tool:GetChildren()) do
        if child:IsA("Model") then
            r = child:FindFirstChild("LeftClickRemote")
            if r then return r, child:FindFirstChild("M1Active") end
        end
    end
    return nil, nil
end

local FRUIT_NAMES = {
    "t-rex", "trex", "dragon", "kitsune", "empyrean", "pain", "control",
    "mammoth", "leopard", "yeti", "gas", "lightning", "magma", "quake",
    "buddha", "shadow", "venom", "soul", "dough", "string", "spider",
    "phoenix", "rubber", "gravity", "bomb", "spike", "flame", "ice",
    "sand", "dark", "light", "love", "door", "smoke", "barrier",
}

local function isFruitTool(tool)
    if not tool then return false end
    local name = tool.Name:lower()
    for _, fn in ipairs(FRUIT_NAMES) do
        if name:find(fn, 1, true) then return true end
    end
    local r = tool:FindFirstChild("LeftClickRemote")
    if r then return true end
    for _, child in pairs(tool:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("LeftClickRemote") then
            return true
        end
    end
    return false
end

local function equipAndCache()
    local char = player.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local r, m = scanRemoteInTool(tool)
        if r then
            cachedTool = tool
            cachedRemote = r
            cachedM1Active = m
            return true
        end
    end
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and isFruitTool(item) then
            local hum = char:FindFirstChild("Humanoid")
            if hum then pcall(function() hum:EquipTool(item) end) end
            return false
        end
    end
    return false
end

local function ghostReset()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    if not currentTarget then return end
    hum.Health = 0
    if currentTarget then
        local targetChar = currentTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            lastTargetPos = targetRoot.Position
            pcall(function()
                myRoot.CFrame = CFrame.new(
                    targetRoot.Position + Vector3.new(0, 0, CONFIG.TeleportDistance),
                    targetRoot.Position
                )
            end)
            lastTargetDir = (targetRoot.Position - myRoot.Position).Unit
            if cachedRemote then
                pcall(function() cachedRemote:FireServer(lastTargetDir, 1) end)
            end
        end
    end
    pcall(function() hum:BreakJoints() end)
end

local function fireRemote(dir)
    local remote = cachedRemote
    if not remote or not remote.Parent then cachedRemote = nil; return false end
    if cachedM1Active then pcall(function() cachedM1Active.Value = true end) end
    local ok = pcall(function() remote:FireServer(dir, 1) end)
    if cachedM1Active then pcall(function() cachedM1Active.Value = false end) end
    return ok
end

local function normalAttack(targetChar)
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not cachedRemote then return false end
    lastTargetPos = targetRoot.Position
    local myChar  = player.Character
    local myRoot  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot then
        pcall(function()
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, CONFIG.TeleportDistance)
        end)
    end
    local dir = Vector3.new(0,0,-1)
    if myRoot and myRoot.Parent then
        local d = (targetRoot.Position + getRandomOffset() - myRoot.Position).Unit
        if d.Magnitude > 0.001 then dir = d end
    end
    lastTargetDir = dir
    local ok = fireRemote(dir)
    return ok
end

local function onKill(killedPlayer)
    recentlyKilled[killedPlayer.Name] = os.time()
    if currentTarget == killedPlayer then
        sessionBounty     = sessionBounty + 1
        totalBountyGlobal = totalBountyGlobal + 1
        saveStats()
        currentTarget     = nil
        targetStartTime   = nil
        targetStartHealth = nil
        noTargetSince     = nil
    end
end

local function setupKillDetector(p)
    if p == player then return end
    local function hook(char)
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
        if hum then hum.Died:Connect(function() onKill(p) end) end
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(function(c) task.wait(0.5); hook(c) end)
end

for _, p in pairs(Players:GetPlayers()) do setupKillDetector(p) end
Players.PlayerAdded:Connect(setupKillDetector)

local function fetchServerList()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(PLACE_ID)
    local body = nil
    local methods = {
        function() return game:HttpGet(url, true) end,
        function()
            local req = (syn and syn.request) or request or (http and http.request)
            if req then
                local res = req({ Url = url, Method = "GET" })
                return res and res.Body
            end
        end,
    }
    for _, fn in ipairs(methods) do
        local ok, result = pcall(fn)
        if ok and result and #result > 10 then body = result; break end
    end
    if not body then return nil end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    if ok2 and decoded and decoded.data then return decoded.data end
    return nil
end

local function hopServer()
    if isHopping then return end
    isHopping = true
    saveStats()
    task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")
        local HS = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100&_rnd=" .. math.random(1, 9999)
        local ok, result = pcall(function()
            return HS:JSONDecode(game:HttpGet(url))
        end)
        if ok and result and result.data then
            for _, s in pairs(result.data) do
                if s.playing < s.maxPlayers and s.id ~= JOB_ID then
                    pcall(function()
                        RS.__ServerBrowser:InvokeServer("teleport", s.id)
                    end)
                    task.wait(5)
                    break
                end
            end
        end
        isHopping = false
    end)
end

if CONFIG.AutoRejoin then
    local GuiService = game:GetService("GuiService")
    GuiService.ErrorMessageChanged:Connect(function(msg)
        task.wait(2)
        pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID) end)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent and not isHopping then
            task.wait(2)
            pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, JOB_ID) end)
        end
    end)
end

local function startHunter()
    if isRunning then return end
    isRunning        = true
    sessionStartTime = os.time()
    local sweepHitTracker = {}
    task.spawn(function()
        while isRunning do pcall(equipAndCache); task.wait(0.3) end
    end)
    task.spawn(function()
        while isRunning do pcall(ghostReset); task.wait(CONFIG.GhostResetInterval) end
    end)
    task.spawn(function()
        while isRunning do
            local validTargets = {}
            for _, other in pairs(Players:GetPlayers()) do
                if other ~= player then
                    local char = other.Character
                    local hum  = char and char:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and not shouldIgnore(other, char) then
                        table.insert(validTargets, other)
                    end
                end
            end
            if #validTargets > 0 then
                noTargetSince = nil
                for _, target in ipairs(validTargets) do
                    if not isRunning then break end
                    currentTarget = target
                    local tc = target.Character
                    local hum = tc and tc:FindFirstChild("Humanoid")
                    if hum and cachedRemote then
                        local tName = target.Name
                        local curHP = hum.Health
                        local data  = sweepHitTracker[tName]
                        if not data then
                            sweepHitTracker[tName] = { lastHealth = curHP, lastDamageTime = tick() }
                        else
                            if curHP < data.lastHealth then
                                sweepHitTracker[tName].lastHealth = curHP
                                sweepHitTracker[tName].lastDamageTime = tick()
                            else
                                if tick() - sweepHitTracker[tName].lastDamageTime > 15 then
                                    hitTracker[tName] = hitTracker[tName] or {}
                                    hitTracker[tName].blacklistedUntil = os.time() + CONFIG.BlacklistTimeout
                                    sweepHitTracker[tName] = nil
                                    continue
                                end
                            end
                        end
                        pcall(function()
                            local pct = math.clamp(curHP/hum.MaxHealth,0,1)
                            local lv  = getPlayerLevel(target)
                            TargetNameL.Text = target.Name .. "  [Lv." .. lv .. "]"
                            TargetInfoL.Text = math.floor(curHP) .. " / " .. math.floor(hum.MaxHealth) .. " HP"
                            HPBar.Size       = UDim2.new(pct, 0, 1, 0)
                            HPBar.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(200*pct+55), 50)
                            HPText.Text = math.floor(pct*100) .. "%"
                            TargetStroke.Color = Color3.fromRGB(255,80,80)
                        end)
                        normalAttack(tc)
                    end
                    task.wait(CONFIG.SweepSpeed)
                end
                for name, _ in pairs(sweepHitTracker) do
                    local found = false
                    for _, v in ipairs(validTargets) do if v.Name == name then found = true; break end end
                    if not found then sweepHitTracker[name] = nil end
                end
            else
                currentTarget = nil
                if not noTargetSince then noTargetSince = os.time()
                elseif os.time()-noTargetSince >= CONFIG.HopDelay then
                    noTargetSince = nil; hopServer()
                end
                task.wait(CONFIG.SweepSpeed)
            end
        end
    end)
end

local function stopHunter()
    isRunning = false; currentTarget = nil
    targetStartTime = nil; targetStartHealth = nil; noTargetSince = nil
end
local _ok, _cg = pcall(function() return game:GetService("CoreGui") end)
local guiParent = (_ok and _cg) or player:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("TRexHunterUI") then guiParent.TRexHunterUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TRexHunterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local C = {
    BG       = Color3.fromRGB(10, 10, 14),
    Panel    = Color3.fromRGB(17, 17, 24),
    Card     = Color3.fromRGB(22, 22, 32),
    AccentG  = Color3.fromRGB(46, 213, 115),
    AccentR  = Color3.fromRGB(235, 59, 90),
    AccentB  = Color3.fromRGB(72, 126, 255),
    Text     = Color3.fromRGB(230, 230, 240),
    Muted    = Color3.fromRGB(110, 110, 140),
    Line     = Color3.fromRGB(30, 30, 44),
}

local W, H = 300, 420
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "Main"
MainFrame.Size             = UDim2.new(0, W, 0, H)
MainFrame.Position         = UDim2.new(0.5, -W/2, 0.5, -H/2)
MainFrame.BackgroundColor3 = C.BG
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local OuterStroke = Instance.new("UIStroke")
OuterStroke.Color     = C.AccentG
OuterStroke.Thickness = 1.5
OuterStroke.Transparency = 0.4
OuterStroke.Parent    = MainFrame

local function corner(parent, r)
    Instance.new("UICorner", parent).CornerRadius = UDim.new(0, r or 10)
end
local function stroke(parent, col, thick)
    local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = thick or 1; s.Parent = parent; return s
end
local function label(parent, txt, size, col, font, ax)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = txt; l.TextSize = size
    l.TextColor3 = col or C.Text
    l.Font = font or Enum.Font.GothamSemibold
    l.TextXAlignment = ax or Enum.TextXAlignment.Left
    l.Parent = parent; return l
end

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = C.Panel
Header.BorderSizePixel = 0
Header.Parent = MainFrame
corner(Header, 16)
local HeaderFill = Instance.new("Frame")
HeaderFill.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFill.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFill.BackgroundColor3 = C.Panel
HeaderFill.BorderSizePixel = 0
HeaderFill.Parent = Header

local TitleL = label(Header, "ZEROX", 16, C.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
TitleL.Size = UDim2.new(0, 100, 1, 0)
TitleL.Position = UDim2.new(0, 16, 0, 0)

local SubL = label(Header, "T-Rex Hunter  v5", 10, C.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Left)
SubL.Size = UDim2.new(0, 160, 0, 14)
SubL.Position = UDim2.new(0, 16, 1, -18)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -20, 0.5, -4)
StatusDot.BackgroundColor3 = C.AccentR
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Header
corner(StatusDot, 4)

-- Stat row
local StatRow = Instance.new("Frame")
StatRow.Size = UDim2.new(1, -24, 0, 36)
StatRow.Position = UDim2.new(0, 12, 0, 60)
StatRow.BackgroundColor3 = C.Panel
StatRow.BorderSizePixel = 0
StatRow.Parent = MainFrame
corner(StatRow, 10)

local function statCell(txt, col, posX)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.33, 0, 1, 0)
    f.Position = UDim2.new(posX, 0, 0, 0)
    f.BackgroundTransparency = 1
    f.Parent = StatRow
    local l = label(f, txt, 12, col, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    l.Size = UDim2.new(1, 0, 1, 0)
    return l
end

local TimeLabel   = statCell("00:00",  C.AccentB,  0)
local BountyLabel = statCell("0 Kill", Color3.fromRGB(255, 200, 60), 0.33)
local ModeStat    = statCell("Sep",    C.AccentG,  0.66)

-- Divider
local function divider(y)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -24, 0, 1)
    d.Position = UDim2.new(0, 12, 0, y)
    d.BackgroundColor3 = C.Line
    d.BorderSizePixel = 0
    d.Parent = MainFrame
end
divider(104)

-- Target Card
local TargetBox = Instance.new("Frame")
TargetBox.Size = UDim2.new(1, -24, 0, 64)
TargetBox.Position = UDim2.new(0, 12, 0, 112)
TargetBox.BackgroundColor3 = C.Card
TargetBox.BorderSizePixel = 0
TargetBox.Parent = MainFrame
corner(TargetBox, 10)

local TargetStroke = stroke(TargetBox, C.Muted, 1)

local DotIcon = Instance.new("Frame")
DotIcon.Size = UDim2.new(0, 6, 0, 6)
DotIcon.Position = UDim2.new(0, 10, 0, 13)
DotIcon.BackgroundColor3 = C.Muted
DotIcon.BorderSizePixel = 0
DotIcon.Parent = TargetBox
corner(DotIcon, 3)

local TargetNameL = label(TargetBox, "Scanning...", 12, C.Text, Enum.Font.GothamSemibold, Enum.TextXAlignment.Left)
TargetNameL.Size = UDim2.new(1, -32, 0, 22)
TargetNameL.Position = UDim2.new(0, 22, 0, 6)

local TargetInfoL = label(TargetBox, "", 10, C.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Left)
TargetInfoL.Size = UDim2.new(1, -22, 0, 14)
TargetInfoL.Position = UDim2.new(0, 22, 0, 28)

local HPBG = Instance.new("Frame")
HPBG.Size = UDim2.new(1, -20, 0, 6)
HPBG.Position = UDim2.new(0, 10, 0, 50)
HPBG.BackgroundColor3 = C.Line
HPBG.BorderSizePixel = 0
HPBG.Parent = TargetBox
corner(HPBG, 3)

local HPBar = Instance.new("Frame")
HPBar.Size = UDim2.new(0, 0, 1, 0)
HPBar.BackgroundColor3 = C.AccentG
HPBar.BorderSizePixel = 0
HPBar.Parent = HPBG
corner(HPBar, 3)

local HPText = label(HPBG, "", 7, C.Text, Enum.Font.Gotham, Enum.TextXAlignment.Center)
HPText.Size = UDim2.new(1, 0, 1, 0)

divider(184)

-- Player list title
local ListTitle = label(MainFrame, "Targets: 0", 11, C.Muted, Enum.Font.GothamSemibold, Enum.TextXAlignment.Left)
ListTitle.Size = UDim2.new(1, -24, 0, 18)
ListTitle.Position = UDim2.new(0, 12, 0, 192)

-- Scroll
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -24, 0, 136)
ScrollFrame.Position = UDim2.new(0, 12, 0, 214)
ScrollFrame.BackgroundColor3 = C.Panel
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 2
ScrollFrame.ScrollBarImageColor3 = C.AccentG
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame
corner(ScrollFrame, 10)

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingLeft = UDim.new(0, 4)
ScrollPad.PaddingTop  = UDim.new(0, 3)
ScrollPad.PaddingRight = UDim.new(0, 4)
ScrollPad.Parent = ScrollFrame

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.SortOrder = Enum.SortOrder.Name
ScrollLayout.Padding = UDim.new(0, 3)
ScrollLayout.Parent = ScrollFrame

divider(358)

-- Buttons
local function makeBtn(txt, col, x, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 36)
    b.Position = UDim2.new(0, x, 0, 366)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = C.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.Parent = MainFrame
    corner(b, 9)
    return b
end

local ToggleBtn = makeBtn("START", C.AccentG, 12, 136)
local ModeBtn   = makeBtn("SEP", C.AccentB, 156, 64)
local HopBtn    = makeBtn("HOP", Color3.fromRGB(90, 30, 140), 228, 64)

-- Toggle logic
ToggleBtn.MouseButton1Click:Connect(function()
    if isRunning then
        stopHunter()
        ToggleBtn.Text = "START"
        ToggleBtn.BackgroundColor3 = C.AccentR
        OuterStroke.Color = C.AccentR
        StatusDot.BackgroundColor3 = C.AccentR
        DotIcon.BackgroundColor3 = C.AccentR
    else
        startHunter()
        ToggleBtn.Text = "RUNNING"
        ToggleBtn.BackgroundColor3 = C.AccentG
        OuterStroke.Color = C.AccentG
        StatusDot.BackgroundColor3 = C.AccentG
        DotIcon.BackgroundColor3 = C.AccentG
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    CONFIG.SeparatorMode = not CONFIG.SeparatorMode
    if CONFIG.SeparatorMode then
        ModeBtn.Text = "SEP"; ModeBtn.BackgroundColor3 = C.AccentB; ModeStat.Text = "Sep"
    else
        ModeBtn.Text = "TEL"; ModeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 130); ModeStat.Text = "Tele"
    end
end)

HopBtn.MouseButton1Click:Connect(function() hopServer() end)

-- Player rows
local playerRows = {}
Players.PlayerRemoving:Connect(function(p)
    if playerRows[p.Name] then
        playerRows[p.Name]:Destroy(); playerRows[p.Name] = nil
    end
end)

local function getOrCreateRow(name)
    if playerRows[name] and playerRows[name].Parent then return playerRows[name] end
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, -6, 0, 32)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel = 0
    row.Parent = ScrollFrame
    corner(row, 7)

    local nl = label(row, name, 11, C.Text, Enum.Font.GothamSemibold, Enum.TextXAlignment.Left)
    nl.Name = "Name"; nl.Size = UDim2.new(0.55, 0, 0, 18); nl.Position = UDim2.new(0, 7, 0, 2)

    local ll = label(row, "Lv.?", 10, Color3.fromRGB(255, 210, 60), Enum.Font.Gotham, Enum.TextXAlignment.Left)
    ll.Name = "Lv"; ll.Size = UDim2.new(0.22, 0, 0, 18); ll.Position = UDim2.new(0.55, 0, 0, 2)

    local hl = label(row, "?HP", 9, C.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Right)
    hl.Name = "HP"; hl.Size = UDim2.new(0.22, 0, 0, 18); hl.Position = UDim2.new(0.77, 0, 0, 2)

    local bg = Instance.new("Frame"); bg.Name = "BarBG"
    bg.Size = UDim2.new(1, -14, 0, 5); bg.Position = UDim2.new(0, 7, 0, 24)
    bg.BackgroundColor3 = C.Line; bg.BorderSizePixel = 0; bg.Parent = row
    corner(bg, 3)

    local bar = Instance.new("Frame"); bar.Name = "Bar"
    bar.Size = UDim2.new(1, 0, 1, 0); bar.BackgroundColor3 = C.AccentG
    bar.BorderSizePixel = 0; bar.Parent = bg
    corner(bar, 3)

    playerRows[name] = row; return row
end

-- Update loop
task.spawn(function()
    while task.wait(0.5) do
        if isRunning then
            TimeLabel.Text = formatTime(totalTimeGlobal + (os.time()-sessionStartTime))
        end
        BountyLabel.Text = totalBountyGlobal .. " Kill"
        if currentTarget and currentTarget.Character then
        else
            if noTargetSince and isRunning then
                local rem = math.max(0, CONFIG.HopDelay-(os.time()-noTargetSince))
                TargetNameL.Text = "No targets → Hop in " .. math.floor(rem) .. "s"
                DotIcon.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
            else
                TargetNameL.Text = "Scanning..."
                DotIcon.BackgroundColor3 = C.Muted
            end
            TargetInfoL.Text = ""; HPBar.Size = UDim2.new(0,0,1,0); HPText.Text = ""
            TargetStroke.Color = C.Line
        end

        local validNames = {}
        for _, other in pairs(Players:GetPlayers()) do
            if other ~= player then
                local char = other.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 and not shouldIgnore(other, char) then
                    table.insert(validNames, other.Name)
                    local row   = getOrCreateRow(other.Name)
                    local lv    = getPlayerLevel(other)
                    local pct   = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    local isCur = (currentTarget == other)
                    row.BackgroundColor3 = isCur and Color3.fromRGB(18, 40, 22) or C.Card
                    row:FindFirstChild("Name").Text = other.Name
                    row:FindFirstChild("Lv").Text   = "Lv." .. lv
                    row:FindFirstChild("HP").Text   = math.floor(hum.Health).."HP"
                    local bar = row:FindFirstChild("BarBG"):FindFirstChild("Bar")
                    bar.Size = UDim2.new(pct, 0, 1, 0)
                    bar.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(200*pct+55), 50)
                end
            end
        end
        for name, row in pairs(playerRows) do
            local found = false
            for _, n in ipairs(validNames) do if n==name then found=true; break end end
            if not found then row:Destroy(); playerRows[name] = nil end
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 4)
        ListTitle.Text = "Targets: " .. #validNames
    end
end)

-- Status dot pulse
task.spawn(function()
    local t = 0
    while task.wait(0.05) do
        t = t + 0.05
        if isRunning then
            local a = (math.sin(t*4)+1)/2
            StatusDot.BackgroundColor3 = Color3.new(a*0.1, 0.8+a*0.2, a*0.3)
        end
    end
end)

startHunter()
