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

    local hasVicious = false
    for _, mob in ipairs(monsters:GetChildren()) do
        if string.find(mob.Name, "Vicious") then
            hasVicious = true
            break
        end
    end

    if not hasVicious then
        print("no stingers bud")
        serverHop()
        return
    end

    local hopped = false
    local function triggerHop()
        if hopped then return end
        hopped = true
        print("triggering forced server hop...")
        serverHop()
    end

    -- 1. START THE WATCHER FIRST (Independent thread so it can't be killed by loadstring errors)
    task.spawn(function()
        task.wait(3) -- let things settle on spawn
        
        while not hopped do
            task.wait(0.3) -- check every 300ms aggressively
            local currentMonsters = workspace:FindFirstChild("Monsters")
            local stillHasVicious = false
            
            if currentMonsters then
                for _, mob in ipairs(currentMonsters:GetChildren()) do
                    if string.find(mob.Name, "Vicious") then
                        stillHasVicious = true
                        break
                    end
                end
            end
            
            -- If Vicious is gone from the folder, hop instantly
            if not stillHasVicious then
                print("vicious bee is officially gone, hopping...")
                triggerHop()
                break
            end
        end
    end)

    -- 2. THE BIG RED BUTTON (Absolute max 5-minute safety net)
    task.spawn(function()
        task.wait(300)
        if not hopped then
            print("safety net timer reached: forcing hop")
            triggerHop()
        end
    end)

    -- 3. EXECUTE EXTERNAL SCRIPT AFTER (If it errors, the watcher is already safe running above)
    print("vic is here, executing script...")
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
    end)
end
