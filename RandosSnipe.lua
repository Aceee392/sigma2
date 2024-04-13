--[[
Credits List
ethereum: creating the base sniper
chocolog: providing type.huge
Edmond: offered tips for optimization
LordHippo: Updated Script
]]--

local osclock = os.clock()
if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(15)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
game:GetService("RunService"):Set3dRenderingEnabled(false)

local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers

local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")

local Library = require(rs:WaitForChild("Library"))

local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

local function processListingInfo(uid, gems, item, version, shiny, amount, boughtFrom, boughtStatus, class, failMessage)
    local gemamount = Players.LocalPlayer.leaderstats["💎 Diamonds"].Value
    local snipeMessage = "||".. Players.LocalPlayer.Name .. "||"
    local weburl, webContent, webcolor, webStatus
    local versionVal = { [1] = "Golden ", [2] = "Rainbow " }
    local versionStr = versionVal[version] or (version == nil and "")
    local mention = ( class == "Pet" and (Library.Directory.Pets[item].huge or Library.Directory.Pets[item].titanic)) and "<@" .. userid .. ">" or ""
    
    if boughtStatus then
        webcolor = tonumber(0x00ff00)
        snipeMessage = snipeMessage .. " just sniped " .. amount .. "x "
        webContent = mention
        webStatus = "Success!"
        weburl = webhook
    else
        webcolor = tonumber(0xff0000)
        weburl = webhookFail
        webStatus = failMessage
        snipeMessage = snipeMessage .. " failed to snipe " .. amount .. "x "
    end
    
    snipeMessage = snipeMessage .. "**" .. versionStr
    
    if shiny then
        snipeMessage = snipeMessage .. " Shiny "
    end
    
    snipeMessage = snipeMessage .. item .. "**"
    
    local message1 = {
        ['content'] = webContent,
        ['embeds'] = {
            {
                ["author"] = {
                    ["name"] = "Hippo Sniper 🦛",
                    ["icon_url"] = "",
                },
                ['title'] = snipeMessage,
                ["color"] = webcolor,
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ['fields'] = {
                    {
                        ['name'] = "__Price Per:__",
                        ['value'] = gems .. " 💎",
                    },
                    {
                        ['name'] = "__Bought from:__",
                        ['value'] = "||"..tostring(boughtFrom).."||",
                    },
                    {
                        ['name'] = "__Amount:__",
                        ['value'] = amount .. "x",
                    },
                    {
                        ['name'] = "__Remaining gems:__",
                        ['value'] = gemamount .. " 💎",
                    },      
                    {
                        ['name'] = "__PetID:__",
                        ['value'] = "||"..tostring(uid).."||",
                    },
                    {
                        ['name'] = "__Status:__",
                        ['value'] = webStatus,
                    },
                    {
                        ['name'] = "__Ping:__",
                        ['value'] = math.round(Players.LocalPlayer:GetNetworkPing() * 2000) .. "ms",
                    }
                },
                ["footer"] = {
                    ["icon_url"] = "", -- optional
                    ["text"] = "Heavily Modified by Root | Updated By LordHippo"
                }
            },
        }
    }

    local jsonMessage = http:JSONEncode(message1)
    local success, webMessage = pcall(function()
        http:PostAsync(weburl, jsonMessage)
    end)
    if success == false then
        local response = request({
            Url = weburl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonMessage
        })
    end
end

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
    signal = game:GetService("RunService").Heartbeat:Connect(function()
        if buytimestamp < workspace:GetServerTimeNow() then
            signal:Disconnect()
            signal = nil
        end
    end)
    repeat task.wait() until signal == nil
    local boughtPet, boughtMessage = rs.Network.Booths_RequestPurchase:InvokeServer(playerid, { [uid] = amount })
    processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, boughtMessage)
end

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
    if type(message) == "table" then
        local highestTimestamp = -math.huge
        local key = nil
        local listing = nil
        for v, value in pairs(message["Listings"] or {}) do
            if type(value) == "table" and value["ItemData"] and value["ItemData"]["data"] then
                local timestamp = value["Timestamp"]
                if timestamp > highestTimestamp then
                    highestTimestamp = timestamp
                    key = v
                    listing = value
                end
            end
        end
        if listing then
            local buytimestamp = listing["ReadyTimestamp"]
            local listTimestamp = listing["Timestamp"]
            local data = listing["ItemData"]["data"]
            local gems = tonumber(listing["DiamondCost"])
            local uid = key
            local item = data["id"]
            local version = data["pt"]
            local shiny = data["sh"]
            local amount = tonumber(data["_am"]) or 1
            local playerid = message['PlayerID']
            local class = tostring(listing["ItemData"]["class"])
            
            if string.find(item, "Huge Hunter") and gems <= 1000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
	    elseif string.find(item, "Huge Potion") and gems <= 50000 then
		coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif string.find(item, "Charm") and gems <= 5000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Pet" then
                local type = Library.Directory.Pets[item]
                if type.exclusiveLevel and gems <= 30000 and item ~= "Banana" and item ~= "Coin" then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.titanic and gems <= 100000000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                elseif type.huge and gems <= 10000000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                    return
                end
            elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and gems <= 30000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif (item == "Royalty Charm" or item == "Overload Charm") and gems <= 1000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Egg" and gems <= 100000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif ((string.find(item, "Key") and not string.find(item, "Lower")) or string.find(item, "Ticket")) and gems <= 2500 then 
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            elseif class == "Enchant" and gems <= 5000 then
                return
	    elseif class == "Enchant" and item == "Chest Mimic" and gems <= 100000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
	    elseif class == "Enchant" and item == "Lucky Block" and gems <= 10000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
	    elseif class == "Enchant" and item == "Massive Comet" and gems <= 10000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
	    elseif class == "Enchant" and item == "Super Lightning" and gems <= 100000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
	    elseif class == "Enchant" and item == "Shiny Hunter" and gems <= 1000000 then
                coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp)
                return
            end
        end
    end
end)

local function jumpToServer() 
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true" 
    local req = request({ Url = string.format(sfUrl, 15502339080, "Desc", 50) }) 
    local body = http:JSONDecode(req.Body) 
    local deep = math.random(1, 3)
    if deep > 1 then 
        for i = 1, deep, 1 do 
            req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, 15502339080, "Desc", 50) }) 
            body = http:JSONDecode(req.Body) 
            task.wait(0.1)
        end 
    end 
    local servers = {} 
    if body and body.data then 
        for i, v in next, body.data do 
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
    end
    local randomCount = #servers
    if not randomCount then
       randomCount = 2
    end
    ts:TeleportToPlaceInstance(15502339080, servers[math.random(1, randomCount)], game:GetService("Players").LocalPlayer) 
end

if PlayerInServer < 30 then
    while task.wait(10) do
        jumpToServer()
    end
end

for i = 1, PlayerInServer do
    for ii = 1,#alts do
        if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
            while task.wait(10) do
                jumpToServer()
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    getPlayers = Players:GetPlayers()
    PlayerInServer = #getPlayers
    if PlayerInServer < 20 then
        while task.wait(10) do
            jumpToServer()
        end
    end
end) 

Players.PlayerAdded:Connect(function(player)
    for i = 1,#alts do
        if player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
            task.wait(math.random(0, 60))
            while task.wait(10) do
                jumpToServer()
            end
        end
    end
end) 

local hopDelay = math.random(720, 1000)

while task.wait(1) do
    if math.floor(os.clock() - osclock) >= hopDelay then
        while task.wait(10) do
            jumpToServer()        
        end    
    end
end
