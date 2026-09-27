print("v8")
local playeruser = "Yogotracer"

if game:GetService("Players").LocalPlayer.Name == playeruser then
    local ts = game:GetService("TeleportService")
    local ps = game:GetService("Players")
    local hs = game:GetService("HttpService")
    local lp = ps.LocalPlayer

    local function serverHop()
        print("finding fresh server...")
        
        -- Pulling from a reliable server list format
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            return hs:JSONDecode(game:HttpGet(url))
        end)
    
        if success and result and result.data then
            local servers = {}
            for _, s in ipairs(result.data) do
                -- Grab servers with open slots that aren't our current one
                if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId and s.playing >= 1 then
                    table.insert(servers, s.id)
                end
            end
            
            if #servers > 0 then
                -- Pick from the bottom of the list (lowest players) for better odds
                local targetServer = servers[#servers]
                print("hopping to instance: " .. targetServer)
                
                local tpSuccess, tpErr = pcall(function()
                    ts:TeleportToPlaceInstance(game.PlaceId, targetServer, lp)
                end)
                
                if tpSuccess then
                    return
                else
                    warn("instance rejected: " .. tostring(tpErr))
                end
            end
        end
        
        -- If specific instance fails, use the alternative place hopper method
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

    print("vic is here")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
    end)

    if not success then
        warn("loadstring error " .. tostring(err))
        return
    end

    while task.wait(0.5) do
        local currentMonsters = workspace:FindFirstChild("Monsters")
        if not currentMonsters then continue end

        local stillThere = false
        for _, mob in ipairs(currentMonsters:GetChildren()) do
            if string.find(mob.Name, "Vicious") then
                stillThere = true
                break
            end
        end
    
        if not stillThere then
            print("vic is bye bye")
            serverHop()
            break
        end
    end
end
