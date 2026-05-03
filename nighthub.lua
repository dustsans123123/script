-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    NATURE UI  v6.0  —  Deep Purple & Toggles     ║
-- ║        TopBar kéo dài • Logo FYNIX • Grid Stats • Toggles        ║
-- ╚══════════════════════════════════════════════════════════════════╝

local CONFIG = {
    Title    = "Fynix Hub Auto Bounty",
    Version  = "v6.0",
    Subtitle = "fynix hub best auto bounty m1",

    Width  = 680,
    Height = 520,
    SidebarWidth = 190,

    StartX = 0.5,
    StartY = 0.5,

    Accent  = Color3.fromRGB(155, 43, 199),   
    Accent2 = Color3.fromRGB(190, 90, 230),   
    AccentBlue = Color3.fromRGB(80, 150, 230), 
    Danger  = Color3.fromRGB(205,  75,  75),   

    BgPanel = Color3.fromRGB(16, 12, 20),
    BgBar   = Color3.fromRGB(12, 8, 16),
    BgRow   = Color3.fromRGB(24, 18, 30),
    BgTop   = Color3.fromRGB(14, 10, 18),

    AlphaPanel  = 0.55, 
    AlphaRow    = 0.50,
    AlphaButton = 0.50,

    Bold = Enum.Font.GothamBold,
    Norm = Enum.Font.Gotham,

    RPanel  = 22,
    RRow    = 14,
    RButton = 12,
    RPill   = 99,

    TweenFast   = 0.18,
    TweenMed    = 0.32,
    TweenSlow   = 0.55,
}

local STATUS_PRESETS = {
    live    = { text = "● live",   color = Color3.fromRGB(155, 43, 199) },
    hunting = { text = "⚔ hunt",  color = Color3.fromRGB(190, 90, 230) },
    idle    = { text = "◌ idle",  color = Color3.fromRGB(140, 115, 165) },
    waiting = { text = "⏳ wait", color = Color3.fromRGB(188, 152,  18) },
    dead    = { text = "✕ dead",  color = Color3.fromRGB(205,  75,  75) },
}

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local _alive, _pulseList, _statReg = true, {}, {}

local C = {
    PURPLE = CONFIG.Accent, 
    LIGHT_PURPLE = CONFIG.Accent2, 
    BLUE   = CONFIG.AccentBlue, 
    RED    = CONFIG.Danger,
    DIM    = Color3.fromRGB(140, 115, 165), 
    WHITE  = Color3.fromRGB(235, 225, 245), 
    LINE   = Color3.fromRGB(105, 60, 155), 
    
    HP_G   = Color3.fromRGB(65,  195, 120), 
    HP_Y   = Color3.fromRGB(188, 152,  18), 
    HP_R   = Color3.fromRGB(188,  48,  48),
}

local function _tw(obj, t, props)
    if obj and obj.Parent then TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end
end
local function _twSine(obj, t, props)
    if obj and obj.Parent then TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props):Play() end
end

local function _corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or CONFIG.RPanel); c.Parent = p; return c
end
local function _stroke(p, col, thick, alpha)
    local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = thick or 1; s.Transparency = alpha or 0.70; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function _pulse(obj, prop, lo, hi) table.insert(_pulseList, {obj=obj, prop=prop, lo=lo, hi=hi}) end
local function _removePulse(obj)
    for i = #_pulseList, 1, -1 do if _pulseList[i].obj == obj then table.remove(_pulseList, i) end end
end

local function _hover(btn, base)
    local hi1, hi2 = math.max(0, base - 0.28), math.max(0, base - 0.45)
    btn.MouseEnter:Connect(function() _tw(btn, 0.14, {BackgroundTransparency = hi1}) end)
    btn.MouseLeave:Connect(function() _tw(btn, 0.18, {BackgroundTransparency = base}) end)
    btn.MouseButton1Down:Connect(function() _tw(btn, 0.07, {BackgroundTransparency = hi2}) end)
    btn.MouseButton1Up:Connect(function() _tw(btn, 0.14, {BackgroundTransparency = hi1}) end)
end

local function _drag(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, target.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = i.Position - dragStart
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
end

local function _lbl(parent, t, s, text, col, pos, sz, align, z)
    local L = Instance.new("TextLabel"); L.BackgroundTransparency, L.BorderSizePixel = 1, 0
    L.Font, L.TextSize, L.Text, L.TextColor3, L.TextXAlignment, L.TextTruncate = t, s, text, col, align or Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
    L.Position, L.Size, L.ZIndex, L.Parent = pos, sz, z or 1, parent; return L
end

local function _hpCol(p) return p > 65 and C.HP_G or p > 30 and C.HP_Y or C.HP_R end
local function _hpGrad(p)
    if p > 65 then return Color3.fromRGB(22,148,78), Color3.fromRGB(72,222,150)
    elseif p > 30 then return Color3.fromRGB(158,108, 6), Color3.fromRGB(222,178,44)
    else return Color3.fromRGB(158, 32,32), Color3.fromRGB(218, 72,72) end
end

-- ══════════════════════════════════════════════════════════════════
--  GUI SETUP
-- ══════════════════════════════════════════════════════════════════
local _gui = (gethui and gethui()) or (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or Players.LocalPlayer:WaitForChild("PlayerGui")
local Screen = Instance.new("ScreenGui")
Screen.Name, Screen.IgnoreGuiInset, Screen.ResetOnSpawn, Screen.Parent = "NatureUI_Tabs", true, false, _gui
Screen.Destroying:Connect(function() _alive = false end)

local Panel = Instance.new("Frame")
Panel.Name, Panel.Parent = "MainPanel", Screen
Panel.BackgroundColor3, Panel.BackgroundTransparency = CONFIG.BgPanel, 1
Panel.Position, Panel.Size = UDim2.new(CONFIG.StartX, -CONFIG.Width/2, CONFIG.StartY, -CONFIG.Height/2), UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
Panel.ClipsDescendants = true
_corner(Panel, CONFIG.RPanel)
local _panelStroke = _stroke(Panel, C.PURPLE, 1, 0.3)

local _pg = Instance.new("UIGradient")
_pg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(35, 15, 45)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 10, 25)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 6, 18)),
}
_pg.Rotation, _pg.Parent = 140, Panel

task.defer(function() _tw(Panel, 0.45, {BackgroundTransparency = CONFIG.AlphaPanel}) end)

local Toggle = Instance.new("TextButton")
Toggle.Parent, Toggle.BackgroundColor3, Toggle.BackgroundTransparency = Screen, CONFIG.BgTop, 0.25
Toggle.Position, Toggle.Size, Toggle.Font, Toggle.Text, Toggle.TextSize, Toggle.ZIndex = UDim2.new(0, 14, 0.5, -22), UDim2.new(0, 44, 0, 44), CONFIG.Bold, "🔮", 20, 10
_corner(Toggle, 14); _stroke(Toggle, C.PURPLE, 1.5, 0.3); _hover(Toggle, 0.25); _drag(Toggle, Toggle)
local _vis = true
Toggle.MouseButton1Click:Connect(function()
    _vis = not _vis
    if _vis then Panel.Visible = true; _tw(Panel, 0.32, {BackgroundTransparency = CONFIG.AlphaPanel})
    else _tw(Panel, 0.25, {BackgroundTransparency = 1}); task.delay(0.27, function() if not _vis then Panel.Visible = false end end) end
end)

-- ══════════════════════════════════════════════════════════════════
--  TOPBAR & SIDEBAR VỚI LOGO
-- ══════════════════════════════════════════════════════════════════
local TopBar = Instance.new("Frame")
TopBar.Parent, TopBar.BackgroundColor3, TopBar.BackgroundTransparency, TopBar.BorderSizePixel = Panel, CONFIG.BgTop, 0.38, 0
TopBar.Position, TopBar.Size = UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 54)
_corner(TopBar, CONFIG.RPanel) 

local DragZone = Instance.new("TextButton")
DragZone.Parent, DragZone.BackgroundTransparency, DragZone.Text, DragZone.ZIndex, DragZone.Size = TopBar, 1, "", 5, UDim2.new(1, -100, 1, 0)
_drag(DragZone, Panel) 

local _titleLbl = _lbl(TopBar, CONFIG.Bold, 16, CONFIG.Title, C.WHITE, UDim2.new(0, 25, 0, 5), UDim2.new(0, 200, 0, 26), nil, 6)
local _subLbl = _lbl(TopBar, CONFIG.Norm, 10, CONFIG.Subtitle, C.DIM, UDim2.new(0, 25, 0, 32), UDim2.new(0, 200, 0, 15), nil, 6)

local Sidebar = Instance.new("Frame")
Sidebar.Parent, Sidebar.BackgroundTransparency, Sidebar.Size, Sidebar.Position = Panel, 1, UDim2.new(0, CONFIG.SidebarWidth, 1, 0), UDim2.new(0,0,0,0)

local VDivider = Instance.new("Frame")
VDivider.Parent, VDivider.BackgroundColor3, VDivider.BackgroundTransparency, VDivider.BorderSizePixel = Panel, C.LINE, 0.2, 0 
VDivider.Position, VDivider.Size = UDim2.new(0, CONFIG.SidebarWidth, 0, 54), UDim2.new(0, 1, 1, -54)

-- LOGO FYNIX HUB
local LogoImg = Instance.new("ImageLabel")
LogoImg.Parent = Sidebar
LogoImg.BackgroundTransparency = 1
LogoImg.Position = UDim2.new(0.5, -80, 0, 65) 
LogoImg.Size = UDim2.new(0, 160, 0, 90)       
LogoImg.Image = "rbxthumb://type=Asset&id=128680826808255&w=420&h=420"        
LogoImg.ScaleType = Enum.ScaleType.Fit
_corner(LogoImg, 8)

-- TAB BUTTONS
local TabButtons = {}
local function CreateTabBtn(name, icon, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent, btn.BackgroundColor3, btn.BackgroundTransparency, btn.BorderSizePixel = Sidebar, CONFIG.BgRow, 0.8, 0
    btn.Position, btn.Size = UDim2.new(0.08, 0, 0, yPos), UDim2.new(0.84, 0, 0, 36)
    btn.Font, btn.Text, btn.TextColor3, btn.TextSize = CONFIG.Bold, "  " .. icon .. "  " .. name, C.DIM, 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    _corner(btn, 8)
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"; indicator.Parent = btn
    indicator.BackgroundColor3, indicator.BorderSizePixel = C.PURPLE, 0
    indicator.Position, indicator.Size = UDim2.new(0, 0, 0.2, 0), UDim2.new(0, 3, 0.6, 0)
    indicator.BackgroundTransparency = 1 
    _corner(indicator, 4)

    TabButtons[name] = {Btn = btn, Indicator = indicator}
    return btn
end

local btnHome    = CreateTabBtn("Home", "🏠", 170)
local btnPlayers = CreateTabBtn("Players", "👥", 215)
local btnSetting = CreateTabBtn("Settings", "⚙️", 260)

-- ══════════════════════════════════════════════════════════════════
--  RIGHT CONTENT AREA
-- ══════════════════════════════════════════════════════════════════
local RightArea = Instance.new("Frame")
RightArea.Parent, RightArea.BackgroundTransparency = Panel, 1
RightArea.Position, RightArea.Size = UDim2.new(0, CONFIG.SidebarWidth, 0, 54), UDim2.new(1, -CONFIG.SidebarWidth, 1, -54)

local Tabs = {}
local function CreateTabFrame(name)
    local f = Instance.new("Frame")
    f.Name = name; f.Parent = RightArea; f.BackgroundTransparency = 1
    f.Size, f.Position = UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0); f.Visible = false
    Tabs[name] = f; return f
end
local TabHome    = CreateTabFrame("Home")
local TabPlayers = CreateTabFrame("Players")
local TabSetting = CreateTabFrame("Settings")

local CurrentTab = "Home"
local function SwitchTab(tabName)
    CurrentTab = tabName
    for name, f in pairs(Tabs) do f.Visible = (name == tabName) end
    for name, tbl in pairs(TabButtons) do
        local isActive = (name == tabName)
        _tw(tbl.Btn, 0.2, {BackgroundTransparency = isActive and 0.4 or 0.8, TextColor3 = isActive and C.PURPLE or C.DIM})
        _tw(tbl.Indicator, 0.2, {BackgroundTransparency = isActive and 0 or 1})
    end
end
btnHome.MouseButton1Click:Connect(function() SwitchTab("Home") end)
btnPlayers.MouseButton1Click:Connect(function() SwitchTab("Players") end)
btnSetting.MouseButton1Click:Connect(function() SwitchTab("Settings") end)
SwitchTab("Home")

-- ══════════════════════════════════════════════════════════════════
--  NỘI DUNG TAB HOME
-- ══════════════════════════════════════════════════════════════════
local StatsContainer = Instance.new("ScrollingFrame")
StatsContainer.Parent = TabHome
StatsContainer.BackgroundTransparency = 1
StatsContainer.BorderSizePixel = 0
StatsContainer.Position = UDim2.new(0, 16, 0, 12)
StatsContainer.Size = UDim2.new(1, -32, 0, 120) 
StatsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
StatsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
StatsContainer.ScrollBarThickness = 0 

local gridLayout = Instance.new("UIGridLayout")
gridLayout.Parent = StatsContainer
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.CellSize = UDim2.new(0, 108, 0, 52) 
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)

local function _contentDiv(parent, posY)
    local d = Instance.new("Frame"); d.Parent, d.BackgroundColor3, d.BackgroundTransparency, d.BorderSizePixel = parent, C.LINE, 0.3, 0
    d.Position, d.Size = UDim2.new(0.04, 0, 0, posY), UDim2.new(0.92, 0, 0, 1)
end
_contentDiv(TabHome, 140)

local Hdr = Instance.new("Frame")
Hdr.Parent, Hdr.BackgroundTransparency, Hdr.Position, Hdr.Size = TabHome, 1, UDim2.new(0, 20, 0, 145), UDim2.new(1, -40, 0, 20)
local function _hdrCol(text, xs) _lbl(Hdr, CONFIG.Norm, 11, text, C.LINE, UDim2.new(xs, 0, 0, 0), UDim2.new(0.3, 0, 1, 0)) end
_hdrCol("🎯 TARGET", 0.00); _hdrCol("HP", 0.40); _hdrCol("STATUS", 0.80)
for _, child in ipairs(Hdr:GetChildren()) do if child:IsA("TextLabel") then child.TextColor3 = C.DIM end end

local TargetScroll = Instance.new("ScrollingFrame")
TargetScroll.Parent, TargetScroll.BackgroundTransparency, TargetScroll.BorderSizePixel = TabHome, 1, 0
TargetScroll.Position, TargetScroll.Size = UDim2.new(0, 12, 0, 165), UDim2.new(1, -24, 0, 235)
TargetScroll.ScrollBarThickness, TargetScroll.ScrollBarImageColor3, TargetScroll.ScrollBarImageTransparency = 3, C.PURPLE, 0.55
TargetScroll.CanvasSize, TargetScroll.AutomaticCanvasSize = UDim2.new(0,0,0,0), Enum.AutomaticSize.Y
local _tLayout = Instance.new("UIListLayout"); _tLayout.Parent, _tLayout.Padding = TargetScroll, UDim.new(0, 7)
local _tPad = Instance.new("UIPadding"); _tPad.Parent, _tPad.PaddingTop, _tPad.PaddingBottom = TargetScroll, UDim.new(0, 4), UDim.new(0, 4)

_contentDiv(TabHome, 405)
local BtnArea = Instance.new("Frame")
BtnArea.Parent, BtnArea.BackgroundTransparency, BtnArea.Position, BtnArea.Size = TabHome, 1, UDim2.new(0, 14, 0, 412), UDim2.new(1, -28, 0, 44)
local _btnLayout = Instance.new("UIListLayout")
_btnLayout.Parent, _btnLayout.FillDirection, _btnLayout.Padding = BtnArea, Enum.FillDirection.Horizontal, UDim.new(0, 8)
_btnLayout.HorizontalAlignment, _btnLayout.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
local _btnCount = 0

-- ══════════════════════════════════════════════════════════════════
--  NỘI DUNG TAB PLAYERS
-- ══════════════════════════════════════════════════════════════════
local PHdr = Instance.new("Frame")
PHdr.Parent, PHdr.BackgroundTransparency, PHdr.Position, PHdr.Size = TabPlayers, 1, UDim2.new(0, 20, 0, 10), UDim2.new(1, -40, 0, 23)
_lbl(PHdr, CONFIG.Norm, 11, "👥 PLAYER", C.DIM, UDim2.new(0, 0, 0, 0), UDim2.new(0.3, 0, 1, 0))
_lbl(PHdr, CONFIG.Norm, 11, "LEVEL", C.DIM, UDim2.new(0.45, 0, 0, 0), UDim2.new(0.3, 0, 1, 0))
_lbl(PHdr, CONFIG.Norm, 11, "HP", C.DIM, UDim2.new(0.75, 0, 0, 0), UDim2.new(0.3, 0, 1, 0))

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Parent, PlayerScroll.BackgroundTransparency, PlayerScroll.BorderSizePixel = TabPlayers, 1, 0
PlayerScroll.Position, PlayerScroll.Size = UDim2.new(0, 12, 0, 35), UDim2.new(1, -24, 1, -45)
PlayerScroll.ScrollBarThickness, PlayerScroll.ScrollBarImageColor3, PlayerScroll.ScrollBarImageTransparency = 3, C.PURPLE, 0.55
PlayerScroll.CanvasSize, PlayerScroll.AutomaticCanvasSize = UDim2.new(0,0,0,0), Enum.AutomaticSize.Y
local _pLayout = Instance.new("UIListLayout"); _pLayout.Parent, _pLayout.Padding = PlayerScroll, UDim.new(0, 6)

-- ══════════════════════════════════════════════════════════════════
--  NỘI DUNG TAB SETTINGS (MỚI THÊM)
-- ══════════════════════════════════════════════════════════════════
local SettingScroll = Instance.new("ScrollingFrame")
SettingScroll.Parent = TabSetting
SettingScroll.BackgroundTransparency = 1
SettingScroll.BorderSizePixel = 0
SettingScroll.Position = UDim2.new(0, 16, 0, 15)
SettingScroll.Size = UDim2.new(1, -32, 1, -30)
SettingScroll.ScrollBarThickness = 3
SettingScroll.ScrollBarImageColor3 = C.PURPLE
SettingScroll.CanvasSize = UDim2.new(0,0,0,0)
SettingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local _sLayout = Instance.new("UIListLayout")
_sLayout.Parent = SettingScroll
_sLayout.Padding = UDim.new(0, 8)

-- Pulse Loop
task.defer(function()
    local t = 0
    while _alive do
        task.wait(0.05); t = t + 0.05
        local v = (math.sin(t * math.pi / 1.4) + 1) / 2
        local snapshot = table.clone(_pulseList)
        for _, e in ipairs(snapshot) do
            if e.obj and e.obj.Parent then e.obj[e.prop] = e.lo + (e.hi - e.lo) * v end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  API CÔNG KHAI VÀ CÁC HÀM TÙY CHỈNH DỄ DÀNG
-- ══════════════════════════════════════════════════════════════════
local NatureUI = { C = C }

NatureUI.Stats = setmetatable({}, {
    __newindex = function(_, k, v) if _statReg[k] then _statReg[k]._valLbl.Text = tostring(v) end end,
    __index = function(_, k) return _statReg[k] and _statReg[k]._valLbl.Text or nil end,
})

-- Tạo ô Grid (Home)
function NatureUI.AddStat(key, label, value, color)
    local f = Instance.new("Frame")
    f.Parent = StatsContainer
    f.BackgroundColor3 = CONFIG.BgRow
    f.BackgroundTransparency = 0.5
    f.BorderSizePixel = 0
    _corner(f, 6)
    _stroke(f, C.LINE, 1, 0.2)

    _lbl(f, CONFIG.Norm, 10, label or "", C.DIM, UDim2.new(0,8,0,6), UDim2.new(1,-16,0,14))
    
    local valLbl = _lbl(f, CONFIG.Bold, 14, tostring(value or "0"), color or C.PURPLE, UDim2.new(0,8,0,22), UDim2.new(1,-16,0,24))
    valLbl.TextScaled = false
    valLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    local cell = { _frame = f, _valLbl = valLbl }
    if key and key ~= "" then _statReg[key] = cell end
    return cell
end

-- ====================================================================
-- HÀM MỚI: TẠO CÔNG TẮC BẬT/TẮT (TOGGLE) TRONG TAB SETTINGS
-- ====================================================================
function NatureUI.AddToggle(label, defaultState, callback)
    local state = defaultState or false
    
    local Row = Instance.new("TextButton")
    Row.Parent = SettingScroll
    Row.BackgroundColor3 = CONFIG.BgRow
    Row.BackgroundTransparency = CONFIG.AlphaRow
    Row.BorderSizePixel = 0
    Row.Size = UDim2.new(1, -4, 0, 42)
    Row.Text = ""
    Row.AutoButtonColor = false
    _corner(Row, 8)
    _stroke(Row, C.LINE, 1, 0.3)

    local Title = _lbl(Row, CONFIG.Bold, 13, label, C.WHITE, UDim2.new(0, 16, 0, 0), UDim2.new(0.7, 0, 1, 0))

    -- Khung nền công tắc
    local ToggleBg = Instance.new("Frame")
    ToggleBg.Parent = Row
    ToggleBg.BackgroundColor3 = state and C.PURPLE or CONFIG.BgBar
    ToggleBg.BorderSizePixel = 0
    ToggleBg.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleBg.Size = UDim2.new(0, 36, 0, 20)
    _corner(ToggleBg, 99)
    local TgStroke = _stroke(ToggleBg, C.LINE, 1, 0.5)

    -- Cục tròn trượt qua lại
    local Knob = Instance.new("Frame")
    Knob.Parent = ToggleBg
    Knob.BackgroundColor3 = C.WHITE
    Knob.BorderSizePixel = 0
    Knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.Size = UDim2.new(0, 16, 0, 16)
    _corner(Knob, 99)

    -- Hàm cập nhật hiệu ứng trượt
    local function UpdateVisuals()
        if state then
            _tw(ToggleBg, 0.25, {BackgroundColor3 = C.PURPLE})
            _tw(Knob, 0.25, {Position = UDim2.new(1, -18, 0.5, -8)})
        else
            _tw(ToggleBg, 0.25, {BackgroundColor3 = CONFIG.BgBar})
            _tw(Knob, 0.25, {Position = UDim2.new(0, 2, 0.5, -8)})
        end
    end

    -- Sự kiện click
    Row.MouseButton1Click:Connect(function()
        state = not state
        UpdateVisuals()
        if callback then task.spawn(callback, state) end
    end)

    -- Trả về Object để bạn có thể truy xuất hoặc set từ xa
    local togObj = {}
    function togObj:Set(newState)
        state = newState
        UpdateVisuals()
        if callback then task.spawn(callback, state) end
    end
    function togObj:GetValue()
        return state
    end
    
    -- Khởi tạo lần đầu
    if state and callback then task.spawn(callback, state) end

    return togObj
end
-- ====================================================================

-- Các hàm thay đổi nhanh thông số
function NatureUI.ThayDoiStatus(text)     NatureUI.Stats.status = text     end
function NatureUI.ThayDoiTarget(name)     NatureUI.Stats.target = name     end
function NatureUI.ThayDoiBountyGain(val)  NatureUI.Stats.bountyGain = val  end
function NatureUI.ThayDoiTotalGain(val)   NatureUI.Stats.totalGain = val   end

function NatureUI.AutoUpdateBountyCurrent()
    local plr = Players.LocalPlayer
    task.spawn(function()
        local stats = plr:WaitForChild("leaderstats", 10)
        if stats then
            local bountyVal = stats:WaitForChild("Bounty/Honor", 10)
            if bountyVal then
                local function formatBounty(val)
                    local num = tonumber(val) or 0
                    if num >= 1000000 then return string.format("%.2fM", num / 1000000)
                    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
                    else return tostring(num) end
                end
                NatureUI.Stats.bountyCur = formatBounty(bountyVal.Value)
                bountyVal.Changed:Connect(function(newVal)
                    NatureUI.Stats.bountyCur = formatBounty(newVal)
                end)
            end
        end
    end)
end

function NatureUI.ClearAllTargets()
    for _, child in ipairs(TargetScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end
function NatureUI.ClearAllPlayers()
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

function NatureUI.AddTargetRow(name, level, hp)
    local rowObj, _data = {}, { hp=hp or 100, status="live" }
    local Row = Instance.new("Frame")
    Row.Parent, Row.BackgroundColor3, Row.BackgroundTransparency, Row.BorderSizePixel, Row.Size = TargetScroll, CONFIG.BgRow, CONFIG.AlphaRow, 0, UDim2.new(1, -4, 0, 52)
    _corner(Row, 10); local _rowStroke = _stroke(Row, C.PURPLE, 1, 0.3)

    local Accent = Instance.new("Frame")
    Accent.Parent, Accent.BackgroundColor3, Accent.Position, Accent.Size, Accent.BorderSizePixel = Row, _hpCol(_data.hp), UDim2.new(0, 0, 0.15, 0), UDim2.new(0, 3, 0.7, 0), 0; _corner(Accent, 4)

    local NameLbl = _lbl(Row, CONFIG.Bold, 14, name, C.WHITE, UDim2.new(0,16,0, 6), UDim2.new(0.35,0,0,20))
    local LvLbl = _lbl(Row, CONFIG.Norm, 11, "Lv. "..tostring(level), C.DIM, UDim2.new(0,16,0,26), UDim2.new(0.35,0,0,17))

    local HpBg = Instance.new("Frame")
    HpBg.Parent, HpBg.BackgroundColor3, HpBg.BackgroundTransparency, HpBg.Position, HpBg.Size = Row, CONFIG.BgBar, 0.42, UDim2.new(0.40, 0, 0.5, -7), UDim2.new(0.32, 0, 0, 14); _corner(HpBg, 5); _stroke(HpBg, C.PURPLE, 1, 0.82)
    
    local HpFill = Instance.new("Frame")
    HpFill.Parent, HpFill.Size, HpFill.BorderSizePixel = HpBg, UDim2.new(_data.hp/100, 0, 1, 0), 0; _corner(HpFill, 5)
    local _hg = Instance.new("UIGradient"); local gs, ge = _hpGrad(_data.hp); _hg.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, gs), ColorSequenceKeypoint.new(1, ge)}; _hg.Parent = HpFill

    local Badge = Instance.new("TextLabel")
    Badge.Parent, Badge.BackgroundColor3, Badge.BackgroundTransparency, Badge.Position, Badge.Size = Row, CONFIG.BgRow, 0.50, UDim2.new(0.78, 0, 0.5, -12), UDim2.new(0.20, 0, 0, 24)
    Badge.Font, Badge.Text, Badge.TextColor3, Badge.TextSize = CONFIG.Bold, "● live", C.PURPLE, 11
    _corner(Badge, 99); local BadgeStroke = _stroke(Badge, C.PURPLE, 1, 0.60)

    function rowObj:SetHP(newHp)
        newHp = math.clamp(newHp, 0, 100); _data.hp = newHp
        _tw(HpFill, 0.4, {Size = UDim2.new(newHp/100, 0, 1, 0)}); _tw(Accent, 0.4, {BackgroundColor3 = _hpCol(newHp)})
        local ns, ne = _hpGrad(newHp); _hg.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ns), ColorSequenceKeypoint.new(1, ne)}
    end
    function rowObj:SetStatus(statusKey)
        local preset = STATUS_PRESETS[statusKey]
        if preset then
            _tw(Badge, 0.2, {TextColor3 = preset.color}); BadgeStroke.Color = preset.color; Badge.Text = preset.text
        else
            Badge.Text = tostring(statusKey)
        end
    end
    setmetatable(rowObj, { __newindex = function(t,k,v) if k=="HP" then rowObj:SetHP(v) elseif k=="Status" then rowObj:SetStatus(v) end end })
    return rowObj
end

function NatureUI.AddPlayerRow(name, level, hp)
    local rowObj, _data = {}, { hp=hp or 100 }
    local Row = Instance.new("Frame")
    Row.Parent, Row.BackgroundColor3, Row.BackgroundTransparency, Row.BorderSizePixel, Row.Size = PlayerScroll, CONFIG.BgRow, CONFIG.AlphaRow, 0, UDim2.new(1, -4, 0, 40)
    _corner(Row, 8); _stroke(Row, C.LINE, 1, 0.3)

    local Av = Instance.new("TextLabel")
    Av.Parent, Av.BackgroundColor3, Av.BackgroundTransparency, Av.Position, Av.Size = Row, CONFIG.BgRow, 0.45, UDim2.new(0, 10, 0.5, -14), UDim2.new(0, 28, 0, 28)
    Av.Font, Av.Text, Av.TextColor3, Av.TextSize = CONFIG.Bold, string.upper(string.sub(name, 1, 1)), C.WHITE, 14
    _corner(Av, 6)

    _lbl(Row, CONFIG.Bold, 13, name, C.WHITE, UDim2.new(0, 48, 0, 0), UDim2.new(0.3, 0, 1, 0))
    _lbl(Row, CONFIG.Norm, 12, "Lv."..tostring(level), C.DIM, UDim2.new(0.45, 0, 0, 0), UDim2.new(0.2, 0, 1, 0))

    local HpBg = Instance.new("Frame")
    HpBg.Parent, HpBg.BackgroundColor3, HpBg.BackgroundTransparency, HpBg.Position, HpBg.Size = Row, CONFIG.BgBar, 0.42, UDim2.new(0.70, 0, 0.5, -6), UDim2.new(0.25, 0, 0, 12); _corner(HpBg, 4); _stroke(HpBg, C.DIM, 1, 0.8)
    
    local HpFill = Instance.new("Frame")
    HpFill.Parent, HpFill.Size, HpFill.BorderSizePixel, HpFill.BackgroundColor3 = HpBg, UDim2.new(_data.hp/100, 0, 1, 0), 0, _hpCol(_data.hp); _corner(HpFill, 4)

    function rowObj:SetHP(newHp)
        newHp = math.clamp(newHp, 0, 100); _data.hp = newHp
        _tw(HpFill, 0.4, {Size = UDim2.new(newHp/100, 0, 1, 0), BackgroundColor3 = _hpCol(newHp)})
    end
    setmetatable(rowObj, { __newindex = function(t,k,v) if k=="HP" then rowObj:SetHP(v) end end })
    return rowObj
end

function NatureUI.AddButton(label, callback, style)
    _btnCount = _btnCount + 1
    local btnStyles = { purple = C.PURPLE, blue = C.BLUE, red = C.RED }
    local st = btnStyles[style or "purple"] or C.PURPLE
    local bw = math.floor((RightArea.AbsoluteSize.X - 28 - (_btnCount-1)*8) / _btnCount)
    if bw < 50 then bw = 120 end 
    
    for _, c in ipairs(BtnArea:GetChildren()) do 
        if c:IsA("TextButton") then c.Size = UDim2.new(0, bw, 1, 0) end 
    end

    local btn = Instance.new("TextButton")
    btn.Parent, btn.BackgroundColor3, btn.BackgroundTransparency, btn.BorderSizePixel, btn.Size = BtnArea, Color3.fromRGB(20,15,30), CONFIG.AlphaButton, 0, UDim2.new(0, bw, 1, 0)
    btn.Font, btn.Text, btn.TextColor3, btn.TextSize = CONFIG.Bold, label, st, 13
    _corner(btn, CONFIG.RButton); _stroke(btn, st, 1, 0.58); _hover(btn, CONFIG.AlphaButton)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

-- ══════════════════════════════════════════════════════════════════
--  HỆ THỐNG LƯU TRỮ VÀ KHỞI TẠO DỮ LIỆU
-- ══════════════════════════════════════════════════════════════════

local UptimeFile = "FynixHub_Uptime.json"
local HttpService = game:GetService("HttpService")

local function FormatTime(seconds)
    local h, m, s = math.floor(seconds / 3600), math.floor((seconds % 3600) / 60), seconds % 60
    if h > 0 then return string.format("%02dh %02dm", h, m)
    elseif m > 0 then return string.format("%02dm %02ds", m, s)
    else return string.format("%02ds", s) end
end

local function LoadTotalUptime()
    if isfile and isfile(UptimeFile) and readfile then
        local s, d = pcall(function() return HttpService:JSONDecode(readfile(UptimeFile)) end)
        if s and type(d) == "table" and d.totalSeconds then return tonumber(d.totalSeconds) or 0 end
    end
    return 0 
end

local function SaveTotalUptime(seconds)
    if writefile then pcall(function() writefile(UptimeFile, HttpService:JSONEncode({ totalSeconds = seconds })) end) end
end

-- KHỞI TẠO 7 Ô STATS
NatureUI.AddStat("status",       "⚡ STATUS",        "Idle",     NatureUI.C.LIGHT_PURPLE)
NatureUI.AddStat("target",       "🎯 TARGET",        "None",     NatureUI.C.RED)
NatureUI.AddStat("bountyCur",    "🪙 CURRENT",       "...",      NatureUI.C.PURPLE)
NatureUI.AddStat("bountyGain",   "📈 GAIN",          "0",        NatureUI.C.BLUE)
NatureUI.AddStat("uptime",       "⏱ UP TIME",       "0s",       NatureUI.C.WHITE)
NatureUI.AddStat("totalGain",    "📊 TOT GAIN",      "0",        NatureUI.C.BLUE)
NatureUI.AddStat("totalUptime",  "⏳ TOT UPTIME",    "0s",       NatureUI.C.DIM)

-- VÒNG LẶP ĐẾM GIỜ
local SessionStartTime = os.clock()
local SavedTotalSeconds = LoadTotalUptime()

task.spawn(function()
    while _alive do
        task.wait()
        local cur = math.floor(os.clock() - SessionStartTime)
        NatureUI.Stats.uptime = FormatTime(cur)
        
        local tot = SavedTotalSeconds + cur
        NatureUI.Stats.totalUptime = FormatTime(tot)
        SaveTotalUptime(tot)
    end
end)

-- GỌI HÀM AUTO UPDATE BOUNTY
NatureUI.AutoUpdateBountyCurrent()

-- CÁC NÚT BẤM (TAB HOME)
NatureUI.AddButton("🗡 HUNTING", nil, "purple")
NatureUI.AddButton("🌐 HOP SV", nil, "blue")
NatureUI.AddButton("🗑️ RESET STATS", function()
    SavedTotalSeconds = 0
    SessionStartTime = os.clock() 
    SaveTotalUptime(0)            
    NatureUI.Stats.uptime = "00s"
    NatureUI.Stats.totalUptime = "00s"
    NatureUI.ThayDoiBountyGain("0")
    NatureUI.ThayDoiTotalGain("0")
end, "red")

-- ══════════════════════════════════════════════════════════════════
--  VÍ DỤ TÍCH HỢP TẤT CẢ VÀO LOGIC CỦA BẠN
-- ══════════════════════════════════════════════════════════════════

-- 1. TAB SETTINGS: Cách thêm các công tắc gạt (Toggles)
_G.AutoBounty = false
_G.BypassSafeZone = false
_G.HopIfTargetDead = true

NatureUI.AddToggle("Kích Hoạt Auto Bounty", _G.AutoBounty, function(state)
    _G.AutoBounty = state
    print("Auto Bounty đang:", state)
    if state then NatureUI.ThayDoiStatus("Đang săn...") else NatureUI.ThayDoiStatus("Đã tắt") end
end)

NatureUI.AddToggle("Đánh Xuyên Safe Zone", _G.BypassSafeZone, function(state)
    _G.BypassSafeZone = state
    print("Bypass Safe Zone:", state)
end)

NatureUI.AddToggle("Tự Chuyển Server Khi Mục Tiêu Chết", _G.HopIfTargetDead, function(state)
    _G.HopIfTargetDead = state
    print("Hop Server:", state)
end)


-- ══════════════════════════════════════════════════════════════════
--  SCAN PLAYER THẬT — PvP + SafeZone + Level + Hunting/Wait
-- ══════════════════════════════════════════════════════════════════

local lp = Players.LocalPlayer

local function isPvPEnabled(player)
    if not player then return false end
    local ok, val = pcall(function() return player:GetAttribute("PvpDisabled") end)
    if not ok then return true end
    return val ~= true
end

local function CheckSafeZone(character)
    local zones = workspace:FindFirstChild("_WorldOrigin")
        and workspace["_WorldOrigin"]:FindFirstChild("SafeZones")
    if not zones then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    for _, v in pairs(zones:GetChildren()) do
        if v:IsA("BasePart") and (v.Position - root.Position).Magnitude <= 400 then
            return true
        end
    end
    return false
end

local function GetHPPct(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.MaxHealth <= 0 then return 0 end
    return math.clamp(math.floor(hum.Health / hum.MaxHealth * 100), 0, 100)
end

local function GetLevel(player)
    local ok, ls = pcall(function() return player:FindFirstChild("leaderstats") end)
    if not ok or not ls then return "?" end
    local lv = ls:FindFirstChild("Level") or ls:FindFirstChild("Lv") or ls:FindFirstChild("level")
    return lv and tostring(lv.Value) or "?"
end

local function GetDist(charA, charB)
    local rA = charA and charA:FindFirstChild("HumanoidRootPart")
    local rB = charB and charB:FindFirstChild("HumanoidRootPart")
    if not rA or not rB then return math.huge end
    return (rA.Position - rB.Position).Magnitude
end

-- Registry
local _targetReg = {}  -- [name] = { row, player }
local _playerReg = {}  -- [name] = { row }

local function RemoveTarget(name)
    if _targetReg[name] then
        pcall(function() _targetReg[name].row:Remove() end)
        _targetReg[name] = nil
    end
end

local function RemovePlayer(name)
    if _playerReg[name] then
        pcall(function() _playerReg[name].row:Remove() end)
        _playerReg[name] = nil
    end
end

-- Tìm target gần nhất để set hunting
local function UpdateHuntingStatus()
    local myChar = lp.Character
    if not myChar then return end

    local closestName, closestDist = nil, math.huge
    for name, data in pairs(_targetReg) do
        local char = data.player.Character
        if char then
            local d = GetDist(myChar, char)
            if d < closestDist then
                closestDist = d
                closestName = name
            end
        end
    end

    for name, data in pairs(_targetReg) do
        if name == closestName then
            data.row.Status = "hunting"
            NatureUI.ThayDoiTarget(name)
        else
            data.row.Status = "waiting"
        end
    end

    if not closestName then
        NatureUI.ThayDoiTarget("None")
        NatureUI.ThayDoiStatus("Scanning")
    else
        NatureUI.ThayDoiStatus("Hunting")
    end
end

local function ScanPlayers()
    -- Xoá player đã rời
    for name in pairs(_targetReg) do
        if not Players:FindFirstChild(name) then RemoveTarget(name) end
    end
    for name in pairs(_playerReg) do
        if not Players:FindFirstChild(name) then RemovePlayer(name) end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end
        local char = player.Character
        if not char then continue end

        local name   = player.Name
        local hp     = GetHPPct(char)
        local lv     = GetLevel(player)
        local pvpOn  = isPvPEnabled(player)
        local inSafe = CheckSafeZone(char)

        -- Tab Players: tất cả player
        if not _playerReg[name] then
            local row = NatureUI.AddPlayerRow(name, lv, hp)
            _playerReg[name] = { row = row }
            player.AncestryChanged:Connect(function()
                if not player.Parent then RemovePlayer(name) end
            end)
        else
            _playerReg[name].row.HP = hp
        end

        -- Tab Home (Targets): chỉ PvP ON + không SafeZone
        if pvpOn and not inSafe then
            if not _targetReg[name] then
                local row = NatureUI.AddTargetRow(name, lv, hp)
                row.Status = "waiting"
                _targetReg[name] = { row = row, player = player }

                player.AncestryChanged:Connect(function()
                    if not player.Parent then
                        RemoveTarget(name)
                        UpdateHuntingStatus()
                    end
                end)

                -- Theo dõi safezone / pvp realtime
                task.spawn(function()
                    while _alive and _targetReg[name] do
                        task.wait()
                        local c = player.Character
                        if not c or not isPvPEnabled(player) or CheckSafeZone(c) then
                            RemoveTarget(name)
                            UpdateHuntingStatus()
                            break
                        end
                        _targetReg[name].row.HP = GetHPPct(c)
                    end
                end)
            else
                _targetReg[name].row.HP = hp
            end
        else
            if _targetReg[name] then
                RemoveTarget(name)
            end
        end
    end

    UpdateHuntingStatus()
end

-- Scan ngay khi bật
NatureUI.ClearAllTargets()
NatureUI.ClearAllPlayers()
NatureUI.ThayDoiTarget("Scanning...")
ScanPlayers()

-- Auto rescan + update hunting mỗi 3 giây
task.spawn(function()
    while _alive do
        task.wait()
        pcall(ScanPlayers)
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait()
    pcall(ScanPlayers)
end)

return NatureUI
