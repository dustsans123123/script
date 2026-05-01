-- ==========================================
-- SCRIPT TỐI ƯU FPS (BẢN NHỎ GỌN + XÓA MAP)
-- ==========================================

-- 1. Tự động Copy Link Discord
local discordLink = "https://discord.gg/Nhw6G2R9xy"
if setclipboard then
    setclipboard(discordLink)
else
    print("Link Discord: " .. discordLink)
end

-- Service
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Xóa UI cũ
if CoreGui:FindFirstChild("FPSBoostSmall") then
    CoreGui.FPSBoostSmall:Destroy()
end

-- 2. Tạo Giao diện (UI) NHỎ GỌN - ĐƯA LÊN TRÊN
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSBoostSmall"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3 -- Hơi trong suốt cho đẹp
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 127)
MainFrame.AnchorPoint = Vector2.new(0.5, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.02, 0) -- Đưa lên sát mép trên
MainFrame.Size = UDim2.new(0, 220, 0, 80) -- Kích thước nhỏ gọn

-- Bo góc UI
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Tên Acc
local AccLabel = Instance.new("TextLabel")
AccLabel.Parent = MainFrame
AccLabel.BackgroundTransparency = 1
AccLabel.Position = UDim2.new(0, 5, 0.1, 0)
AccLabel.Size = UDim2.new(1, -10, 0.4, 0)
AccLabel.Font = Enum.Font.GothamBold
AccLabel.Text = "Acc: " .. LocalPlayer.Name
AccLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AccLabel.TextSize = 14
AccLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Hiện FPS
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Parent = MainFrame
FPSLabel.BackgroundTransparency = 1
FPSLabel.Position = UDim2.new(0, 5, 0.5, 0)
FPSLabel.Size = UDim2.new(1, -10, 0.4, 0)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Text = "FPS: Đang tính..."
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
FPSLabel.TextSize = 16
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

-- 3. Logic tính FPS
local frames = 0
local lastUpdate = os.clock()

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local currentTime = os.clock()
    if currentTime - lastUpdate >= 1 then
        FPSLabel.Text = "FPS: " .. frames
        frames = 0
        lastUpdate = currentTime
    end
end)

-- 4. TÍNH NĂNG XÓA MAP (FPS BOOST CỰC MẠNH)
local function DeleteMap()
    -- Tắt hiệu ứng ánh sáng
    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1

    -- Xóa các thành phần trong Workspace (Map, cây cối, biển...)
    -- Chỉ giữ lại Terrain và những thứ quan trọng để không bị lỗi game
    local toDelete = {"Map", "Sea", "Buildings", "Trees", "Shops", "NPCs"} -- Các folder phổ biến trong Blox Fruits

    for _, folder in pairs(workspace:GetChildren()) do
        if folder.Name == "Map" or folder.Name == "Sea" or folder.Name == "Cỏ" then
            folder:Destroy()
        end
    end

    -- Biến mọi thứ còn lại thành nhựa cực nhẹ
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            -- Nếu là mây hoặc hiệu ứng thì xóa luôn
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then
            v:Destroy()
        end
    end
    print("Đã xóa Map và tối ưu hóa Texture!")
end

-- Chạy hàm xóa map
DeleteMap()

-- Nút tắt nhanh UI
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
