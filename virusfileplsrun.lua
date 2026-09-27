local playeruser = "Yogotracer"

if game:GetService("Players").LocalPlayer.Name == playeruser then
    local ts = game:GetService("TeleportService")
    local ps = game:GetService("Players")
    local hs = game:GetService("HttpService")
    local lp = ps.LocalPlayer

    local function serverHop()
        print("finding fresh server...")
        
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            return hs:JSONDecode(game:HttpGet(url))
        end)
    
        if success and result and result.data then
            local servers = {}
            for _, s in ipairs(result.data) do
                if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId and s.playing >= 1 then
                    table.insert(servers, s.id)
                end
            end
            
            if #servers > 0 then
                local targetServer = servers[math.random(1, #servers)]
                print("hopping to instance: " .. targetServer)
                
                local tpSuccess = pcall(function()
                    ts:TeleportToPlaceInstance(game.PlaceId, targetServer, lp)
                end)
                
                if tpSuccess then return end
            end
        end
        
        -- Fallback low-pop fetch
        pcall(function()
            local servers = hs:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=10"))
            if servers and servers.data then
                for _, s in ipairs(servers.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then
                        ts:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
                        return
                    end
                end
            end
        end)
    end

    local monsters = workspace:WaitForChild("Monsters", 10)
    if not monsters then
        serverHop()
        return
    end

    local viciousBee = nil
    for _, mob in ipairs(monsters:GetChildren()) do
        if string.find(mob.Name, "Vicious") then
            viciousBee = mob
            break
        end
    end

    if not viciousBee then
        print("no stingers bud")
        serverHop()
        return
    end

    print("vic is here, executing script...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
    end)

    if not success then
        warn("loadstring error " .. tostring(err))
        return
    end

    local hopped = false
    local function triggerHop()
        if hopped then return end
        hopped = true
        print("triggering forced server hop...")
        serverHop()
    end

    -- Safety Net 1: Ancestry hook
    local connection
    connection = viciousBee.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if connection then connection:Disconnect() end
            triggerHop()
        end
    end)

    -- Safety Net 2: Main loop check
    task.spawn(function()
        while not hopped do
            task.wait(0.5)
            if not viciousBee or not viciousBee.Parent then
                if connection then connection:Disconnect() end
                triggerHop()
                break
            end
        end
    end)

    -- Safety Net 3: The Big Red Button (Absolute max time fallback)
    -- If Vicious takes more than 5 minutes to kill or script locks up, force hop anyway
    task.spawn(function()
        task.wait(300) 
        if not hopped then
            print("safety net timer reached: forcing hop")
            triggerHop()
        end
    end)
end
