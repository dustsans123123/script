-- By Tuân Anh IOS
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Hàm kiểm tra vật thể có thể đổi màu không
local function CanChangeColor(obj)
    return obj:IsA("BasePart") and obj:IsDescendantOf(Workspace) and not obj:IsDescendantOf(LocalPlayer.Character)
end

-- Hàm biến vật thể thành đá với bề mặt phẳng
local function MakeStone(obj)
    if CanChangeColor(obj) then
        pcall(function()
            obj.Color = Color3.fromRGB(115, 115, 115) -- Màu xám đá
            obj.Material = Enum.Material.SmoothPlastic -- Làm phẳng bề mặt
            obj.Reflectance = 0 -- Loại bỏ độ bóng
        end)
    end
end

-- Áp dụng hiệu ứng đá phẳng cho toàn bộ vật thể hiện có
for _, obj in pairs(Workspace:GetDescendants()) do
    MakeStone(obj)
end

-- Khi có vật thể mới xuất hiện, tự động biến nó thành đá phẳng
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.2) -- Tăng thời gian chờ cho điện thoại
    MakeStone(obj)
end)

-- Xóa hiệu ứng gây lag trong game
local function RemoveUnnecessaryEffects(obj)
    pcall(function()
        if obj:IsA("ParticleEmitter") or
           obj:IsA("Beam") or
           obj:IsA("Trail") or
           obj:IsA("Fire") or
           obj:IsA("Smoke") or
           obj:IsA("Sparkles") or
           obj:IsA("Explosion") or
           obj:IsA("Highlight") or
           obj:IsA("Decal") or
           obj:IsA("Texture") or
           obj:IsA("PointLight") or
           obj:IsA("SurfaceLight") or
           obj:IsA("SpotLight") then
            obj:Destroy()
        end
    end)
end

-- Xóa tất cả hiệu ứng có sẵn trong game
for _, obj in pairs(Workspace:GetDescendants()) do
    RemoveUnnecessaryEffects(obj)
end

-- Khi có hiệu ứng mới xuất hiện, tự động xóa ngay lập tức
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    RemoveUnnecessaryEffects(obj)
end)

-- Tắt toàn bộ hiệu ứng ánh sáng để game sáng rõ hơn
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.FogEnd = 1000000 -- Xóa sương mù
    Lighting.Technology = Enum.Technology.Compatibility -- Tắt hiệu ứng bóng

    -- Xóa bầu trời nhưng không làm màn hình đen
    local sky = Lighting:FindFirstChild("Sky")
    if sky then
        sky:Destroy()
    end
end)

-- Xóa quần áo và đưa nhân vật về màu mặc định của Roblox
local function ResetCharacterAppearance(character)
    pcall(function()
        for _, obj in pairs(character:GetChildren()) do
            if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                obj:Destroy() -- Xóa quần áo
            end
            if obj:IsA("BodyColors") then
                obj:Destroy() -- Xóa màu tùy chỉnh
            end
        end

        -- Đặt lại màu sắc cơ thể thành mặc định
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(163, 162, 165) -- Màu mặc định của Roblox R6
            end
        end
    end)
end

-- Áp dụng lên nhân vật hiện tại của người chơi
if LocalPlayer.Character then
    ResetCharacterAppearance(LocalPlayer.Character)
end

-- Khi nhân vật respawn, tiếp tục reset ngoại hình
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1) -- Tăng thời gian chờ để đảm bảo nhân vật load xong trên điện thoại
    ResetCharacterAppearance(character)
end)

-- Xóa quần áo của tất cả quái vật trong game
local function RemoveEnemyClothes()
    if Workspace:FindFirstChild("Enemies") then
        for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
            ResetCharacterAppearance(enemy)
        end
    end
end

-- Xóa quần áo quái ngay khi script chạy
RemoveEnemyClothes()

-- Tự động xóa quần áo khi có quái mới xuất hiện
if Workspace:FindFirstChild("Enemies") then
    Workspace.Enemies.ChildAdded:Connect(function(enemy)
        task.wait(1) -- Tăng thời gian chờ trên điện thoại
        ResetCharacterAppearance(enemy)
    end)
end

print("Đã Fix Lag")
