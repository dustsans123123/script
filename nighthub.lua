getgenv().Config = {
    Team = "Pirates",
    HideUI = true,
    HuntConfig = {
        ["Earned Notification Enabled"] = false,
        ["Reset Farm (New)"] = true,
        ["Chat"] = false,
        ["Farm Delay"] = 0.22, -- 0.15 - Super Fast(Risk - Kick) | 0.22 Fast | 0.35 Medium | Max 0.5
        ["Webhook"] = {
            Enabled = false,
            Url = ""
        }
    }
}
loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/2ffcdb62773f587bfb9eb0d52bb35b0c.lua"))()
