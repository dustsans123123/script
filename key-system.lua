local W = game:GetService("Workspace")
local L = game:GetService("Lighting")
local T = W:FindFirstChildOfClass("Terrain")

-- 1. Xóa toàn bộ vật thể trong Workspace (trừ Camera và Terrain)
for _, object in ipairs(W:GetChildren()) do
    if not object:IsA("Camera") and not object:IsA("Terrain") then
        pcall(function()
            object:Destroy()
        end)
    end
end

-- 2. Xóa sạch địa hình (Terrain)
if T then
    T:Clear()
end

-- 3. Xóa sạch bầu trời và các hiệu ứng ánh sáng
for _, effect in ipairs(L:GetChildren()) do
    pcall(function()
        effect:Destroy()
    end)
end

-- 4. Chỉnh bầu trời thành một màu đen kịt (Black Void)
L.FogEnd = 9e9 -- Đẩy sương mù ra xa vô tận
L.Brightness = 0
L.ClockTime = 0
L.GlobalShadows = false
L.OutdoorAmbient = Color3.new(0, 0, 0)
L.Ambient = Color3.new(0, 0, 0)

-- Tạo một Sky mới trống rỗng để đè lên bầu trời cũ nếu cần
local blackSky = Instance.new("Sky")
blackSky.SkyboxBk = "rbxassetid://0"
blackSky.SkyboxDn = "rbxassetid://0"
blackSky.SkyboxFt = "rbxassetid://0"
blackSky.SkyboxLf = "rbxassetid://0"
blackSky.SkyboxRt = "rbxassetid://0"
blackSky.SkyboxUp = "rbxassetid://0"
blackSky.SunTextureId = ""
blackSky.MoonTextureId = ""
blackSky.Parent = L

-- 5. Ngăn chặn các vật thể mới được sinh ra (Optional)
W.DescendantAdded:Connect(function(v)
    task.wait()
    pcall(function() v:Destroy() end)
end)

print("Map và Bầu trời đã được xóa sạch!")
