--[[
    ========================================================================
    [HYPER-FOCUSED: GODHUMAN & MAX LEVEL SPEEDRUN]
    Bản Kaitun Chuyên Biệt - Chỉ tập trung vào 2 mục tiêu tối thượng:
    1. MAX LEVEL (2800) BẰNG CHIẾN THUẬT SPEEDRUN TỐI ƯU NHẤT
    2. SỞ HỮU VÕ TỐI THƯỢNG GODHUMAN (CÀY 10 VÕ 400 MASTERY & 4 NGUYÊN LIỆU)
    
    🛡️ CƠ CHẾ BẢO VỆ TRÁI ÁC QUỶ (FRUIT PROTECTION VAULT):
    - Tự động cất ngay toàn bộ Trái Ác Quỷ vào Balo / Kho lưu trữ.
    - Tuyệt đối BẢO VỆ các Trái Ác Quỷ có giá trị (Kitsune, Dragon, Leopard,
      Dough, T-Rex, Mammoth, Spirit, Venom, Buddha, Portal, Blizzard, Rumble...).
    - Khi đi Raid cày Frags hoặc nộp cho Trevor mở Sea 3: TUYỆT ĐỐI KHÔNG
      được sử dụng trái quý! Chỉ ưu tiên mua bằng 100k Beli hoặc trái rác an toàn!
    ========================================================================
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

-- ========================================================
-- [1. CẤU HÌNH SPEEDRUN: GODHUMAN & MAX LEVEL]
-- ========================================================
local Config = {
    HubName = "Kaitun Godhuman & Max Level",
    DebugMode = true,        -- BẬT DEBUG: In chi tiết từng bước & cảnh báo lỗi ra Console (F9)
    Disable3DRender = false, -- MẶC ĐỊNH BẬT 3D khi test/debug để quan sát nhân vật (bấm nút trên HUD để tắt khi treo lâu)
    Team = "Marines",
    FPSCap = 30,             -- 30 FPS khi test debug (có thể hạ xuống 15 khi treo lâu)
    NativeFPSBoost = true,
    TweenSpeed = 285,
    FlyHeight = 20,
    FastAttack = true,
    AttackDistance = 35,
    BringMob = true,
    BringMobLimit = 3,
    BringMobDistance = 180,
    SkySkipSea1 = true,      -- Nhảy cấp Sea 1 với Shanda (Lv 10-70) và God's Guard (Lv 70-120)
    AutoMelee = true,        -- Cày 10 võ lên 400 Mastery
    TargetMastery = 400,
    AutoGodhuman = true,     -- Tự thu thập 4 nguyên liệu và mua Godhuman
    AutoSecondSea = true,    -- Mở Sea 2 ngay khi Lv 700+
    AutoThirdSea = true,     -- Mở Sea 3 ngay khi Lv 1500+
    AutoStoreFruit = true,   -- Cất trái ác quỷ vào kho
    AutoStats = true,        -- Tự cộng chỉ số Melee & Defense
    AutoCodes = true,        -- Tự nhập code x2 EXP
    AutoRollFruit = true,    -- AUTO ROLL TRÁI TỪ XA: Tự động Gacha Zioles từ xa mỗi 2 tiếng và cất ngay vào kho
}

-- ========================================================
-- [HỆ THỐNG DEBUG LOGGER CHUYÊN SÂU]
-- ========================================================
local HUD = {} -- Định nghĩa trước để Logger có thể đẩy text lên HUD
local Logger = {
    LastLog = "",
    LastError = nil,
    LastErrorTime = 0
}

function Logger.Log(tag, ...)
    local args = { ... }
    for i = 1, #args do args[i] = tostring(args[i]) end
    local msg = table.concat(args, " ")
    Logger.LastLog = string.format("[%s] %s", tag, msg)
    if Config.DebugMode then
        print(string.format("[DEBUG][%s] %s", tag, msg))
        if rconsoleprint then
            pcall(function() rconsoleprint(string.format("[DEBUG][%s] %s\n", tag, msg)) end)
        end
    end
    if HUD and HUD.SetDebug then HUD.SetDebug(Logger.LastLog) end
end

function Logger.Warn(tag, ...)
    local args = { ... }
    for i = 1, #args do args[i] = tostring(args[i]) end
    local msg = table.concat(args, " ")
    warn(string.format("[WARN][%s] %s", tag, msg))
    if rconsolewarn then
        pcall(function() rconsolewarn(string.format("[WARN][%s] %s\n", tag, msg)) end)
    end
    if HUD and HUD.SetDebug then HUD.SetDebug("⚠️ " .. msg) end
end

function Logger.Error(tag, err, trace)
    local msg = tostring(err)
    if (tick() - Logger.LastErrorTime) > 3 or Logger.LastError ~= msg then
        Logger.LastError = msg
        Logger.LastErrorTime = tick()
        local traceInfo = trace or debug.traceback()
        warn(string.format("[ERROR][%s] %s\nStack trace:\n%s", tag, msg, tostring(traceInfo)))
        if HUD and HUD.SetDebug then HUD.SetDebug("❌ " .. msg) end
    end
end

-- ========================================================
-- [2. DANH SÁCH BẢO VỆ TRÁI ÁC QUỶ (VALUABLE FRUIT VAULT)]
-- ========================================================
-- Các trái này TUYỆT ĐỐI KHÔNG BAO GIỜ ĐƯỢC PHÉP HIẾN TẾ LÀM VÉ RAID HOẶC NỘP TREVOR!
local VALUABLE_FRUITS_BLACKLIST = {
    ["Kitsune"] = true, ["Dragon"] = true, ["Leopard"] = true, ["Spirit"] = true,
    ["Control"] = true, ["Venom"] = true, ["Shadow"] = true, ["Dough"] = true,
    ["T-Rex"] = true, ["Mammoth"] = true, ["Gravity"] = true, ["Blizzard"] = true,
    ["Pain"] = true, ["Rumble"] = true, ["Portal"] = true, ["Phoenix"] = true,
    ["Sound"] = true, ["Spider"] = true, ["Love"] = true, ["Buddha"] = true,
    ["Quake"] = true, ["Magma"] = true, ["Ghost"] = true, ["Light"] = true
}

-- Danh sách các trái rác an toàn ĐƯỢC PHÉP dùng làm vé Raid nếu không có Beli
local SAFE_TRASH_FRUITS = {
    ["Rocket"] = true, ["Spin"] = true, ["Blade"] = true, ["Spring"] = true,
    ["Bomb"] = true, ["Smoke"] = true, ["Spike"] = true, ["Flame"] = true,
    ["Falcon"] = true, ["Sand"] = true, ["Diamond"] = true
}

-- ========================================================
-- [3. BẢO MẬT & GAME BYPASS (SECURITY)]
-- ========================================================
local Security = {}

function Security.Init()
    local ok, err = pcall(function()
        if getrawmetatable and setreadonly and newcclosure then
            local grm = getrawmetatable(game)
            setreadonly(grm, false)
            local oldNamecall = grm.__namecall

            local BlockedRemotes = {
                ["TeleportDetect"] = true, ["CHECKER_1"] = true, ["CHECKER"] = true,
                ["GUI_CHECK"] = true, ["OneMoreTime"] = true, ["checkingSPEED"] = true,
                ["BANREMOTE"] = true, ["PERMAIDBAN"] = true, ["KICKREMOTE"] = true,
                ["BR_KICKPC"] = true, ["BR_KICKMOBILE"] = true
            }

            grm.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                local args = { ... }
                if (method == "FireServer" or method == "InvokeServer") and #args > 0 then
                    local firstArg = tostring(args[1])
                    if BlockedRemotes[firstArg] or BlockedRemotes[self.Name] then
                        return nil
                    end
                end
                return oldNamecall(self, ...)
            end)
            Logger.Log("SECURITY", "Khởi tạo Namecall bypass thành công")
        else
            Logger.Warn("SECURITY", "Executor không hỗ trợ getrawmetatable/setreadonly, bỏ qua hook Namecall")
        end
    end)
    if not ok then
        Logger.Warn("SECURITY", "Lỗi khởi tạo Security Namecall:", err)
    end

    -- Anti-Idle
    pcall(function()
        for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable()
            elseif conn.Disconnect then conn:Disconnect() end
        end
    end)

    -- Noclip
    RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Auto Dodge (Ken Haki)
    task.spawn(function()
        while true do
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local commE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommE")
                    if commE then
                        commE:FireServer("Dodge", nil, 30, true, workspace:GetServerTimeNow())
                    end
                end
            end)
            task.wait(1.5)
        end
    end)

    -- Auto Rejoin
    pcall(function()
        local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
        if promptGui then
            local overlay = promptGui:WaitForChild("promptOverlay", 5)
            if overlay then
                overlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        task.wait(1)
                        if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
                            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
                        else
                            TeleportService:Teleport(game.PlaceId)
                        end
                    end
                end)
            end
        end
    end)
end

function Security.ApplyNoFall(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and not hrp:FindFirstChild("KaitunNoFall") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "KaitunNoFall"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.P = 1000
        bv.Parent = hrp
    end
end

-- ========================================================
-- [4. NETWORK & ATTACK REMOTE]
-- ========================================================
local Network = {}
local CommF_ = nil

local function GetCommF()
    if CommF_ then return CommF_ end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
    if remotes then
        CommF_ = remotes:FindFirstChild("CommF_") or remotes:WaitForChild("CommF_", 5)
    end
    return CommF_
end

function Network.InvokeCommF(...)
    local remote = GetCommF()
    if not remote then
        Logger.Warn("NETWORK", "Không tìm thấy Remote CommF_ trong ReplicatedStorage!")
        return nil
    end
    for attempt = 1, 3 do
        local ok, res = pcall(function(...) return remote:InvokeServer(...) end, ...)
        if ok then return res end
        task.wait(0.2)
    end
    Logger.Warn("NETWORK", "InvokeCommF thất bại sau 3 lần gọi! Args[1]:", tostring((...)))
    return nil
end

local cachedAttackRemote, cachedAttackId = nil, nil
function Network.GetAttackRemote()
    if cachedAttackRemote and cachedAttackId then return cachedAttackRemote, cachedAttackId end
    local folders = { ReplicatedStorage:FindFirstChild("Util"), ReplicatedStorage:FindFirstChild("Common"), ReplicatedStorage:FindFirstChild("Remotes"), ReplicatedStorage:FindFirstChild("Assets"), ReplicatedStorage:FindFirstChild("FX") }
    for _, f in ipairs(folders) do
        if f then
            for _, c in ipairs(f:GetChildren()) do
                if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                    cachedAttackRemote, cachedAttackId = c, c:GetAttribute("Id")
                    return cachedAttackRemote, cachedAttackId
                end
            end
        end
    end
    return cachedAttackRemote, cachedAttackId
end

-- ========================================================
-- [5. FAST TRAVEL & BIỂN (SEA DETECTION)]
-- ========================================================
local FastTravel = {}

function FastTravel.GetSea()
    local mapAttr = workspace:GetAttribute("MAP")
    if mapAttr == "Sea1" then return 1 end
    if mapAttr == "Sea2" then return 2 end
    if mapAttr == "Sea3" then return 3 end
    if game.PlaceId == 2753915549 then return 1 end
    if game.PlaceId == 4442272183 then return 2 end
    if game.PlaceId == 7449423635 then return 3 end
    return 1
end

function FastTravel.IsSea1() return FastTravel.GetSea() == 1 end
function FastTravel.IsSea2() return FastTravel.GetSea() == 2 end
function FastTravel.IsSea3() return FastTravel.GetSea() == 3 end

local Portals = {
    [1] = { Vector3.new(61163, 11, 1819), Vector3.new(-4650, 872, -1775), Vector3.new(-7900, 5578, -520) },
    [2] = { Vector3.new(-390, 332, 673), Vector3.new(2285, 15, 905), Vector3.new(923, 126, 32852), Vector3.new(-6509, 83, -133) },
    [3] = { Vector3.new(5700, 1015, -215), Vector3.new(-12550, 340, -7500), Vector3.new(-5000, 350, -3035) }
}

local lastTravelTime = 0
function FastTravel.SmartTravel(targetPos)
    if typeof(targetPos) == "CFrame" then targetPos = targetPos.Position end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local currentPos = char.HumanoidRootPart.Position
    local directDist = (currentPos - targetPos).Magnitude
    if directDist < 1500 or (tick() - lastTravelTime) < 1.5 then return end

    if FastTravel.IsSea1() and LocalPlayer:GetAttribute("CurrentLocation") == "Underwater City" and directDist >= 2500 then
        Network.InvokeCommF("requestEntrance", Vector3.new(3864, 6, -1926))
        lastTravelTime = tick()
        task.wait(0.5)
        return
    end

    local portals = Portals[FastTravel.GetSea()]
    if not portals then return end

    local bestPortal = nil
    local minTargetDist = directDist
    for _, p in ipairs(portals) do
        local d = (p - targetPos).Magnitude
        if d < minTargetDist then
            minTargetDist = d
            bestPortal = p
        end
    end

    if bestPortal and minTargetDist < (directDist - 800) then
        Network.InvokeCommF("requestEntrance", bestPortal)
        lastTravelTime = tick()
        task.wait(0.5)
    end
end

function FastTravel.TeleportLocation(locName)
    locName = string.lower(tostring(locName))
    if FastTravel.IsSea1() then
        if locName:find("sky 3") then Network.InvokeCommF("requestEntrance", Vector3.new(-7900, 5578, -520))
        elseif locName:find("sky 2") or locName:find("sky 1") then Network.InvokeCommF("requestEntrance", Vector3.new(-4650, 872, -1775)) end
    elseif FastTravel.IsSea3() then
        if locName:find("mansion") then Network.InvokeCommF("requestEntrance", Vector3.new(-12550, 340, -7500))
        elseif locName:find("castle") then Network.InvokeCommF("requestEntrance", Vector3.new(-5000, 350, -3035))
        elseif locName:find("hydra") then Network.InvokeCommF("requestEntrance", Vector3.new(5700, 1015, -215)) end
    end
end

-- ========================================================
-- [6. TWEEN ENGINE VỚI BỘ CHỐNG KẸT (ANTI-STUCK)]
-- ========================================================
local TweenEngine = {}
local activeTween = nil
local lastStuckPos = nil
local stuckTimer = 0

function TweenEngine.Stop()
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
    lastStuckPos = nil
end

function TweenEngine.To(targetCFrame, speed, height)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return nil end

    local hrp = char.HumanoidRootPart
    char.Humanoid.Sit = false

    if typeof(targetCFrame) == "Vector3" then targetCFrame = CFrame.new(targetCFrame) end
    FastTravel.SmartTravel(targetCFrame.Position)

    local offsetHeight = height or Config.FlyHeight or 20
    local targetPos = targetCFrame.Position + Vector3.new(0, offsetHeight, 0)
    local rot = hrp.CFrame - hrp.Position
    local finalCF = CFrame.new(targetPos) * rot

    local dist = (hrp.Position - finalCF.Position).Magnitude
    if dist <= 4 then
        TweenEngine.Stop()
        return nil
    end

    local actualSpeed = math.min(speed or Config.TweenSpeed or 285, 350)
    local duration = dist / actualSpeed
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)

    if activeTween then activeTween:Cancel() end
    activeTween = TweenService:Create(hrp, info, { CFrame = finalCF })
    activeTween:Play()

    -- Anti-Stuck Detection
    if not lastStuckPos then
        lastStuckPos = hrp.Position
        stuckTimer = tick()
    else
        local dMoved = (hrp.Position - lastStuckPos).Magnitude
        if dMoved < 3 and (tick() - stuckTimer) >= 3 then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
            lastStuckPos = hrp.Position
            stuckTimer = tick()
        elseif dMoved >= 5 then
            lastStuckPos = hrp.Position
            stuckTimer = tick()
        end
    end

    return activeTween
end

function TweenEngine.ToWait(targetCFrame, speed, height)
    local tw = TweenEngine.To(targetCFrame, speed, height)
    if tw then tw.Completed:Wait() end
end

-- ========================================================
-- [7. COMBAT & FAST ATTACK & BRING MOB]
-- ========================================================
local FastAttack = {}

function FastAttack.EnsureBuso()
    local char = LocalPlayer.Character
    if char and not char:FindFirstChild("HasBuso") then
        Network.InvokeCommF("Buso")
    end
end

function FastAttack.EquipWeapon(prefType)
    prefType = prefType or "Melee"
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end

    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and (equipped.ToolTip == prefType or (prefType == "Melee" and equipped.ToolTip == "Sword")) then
        FastAttack.EnsureBuso()
        return equipped
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.ToolTip == prefType then
                char.Humanoid:EquipTool(t)
                FastAttack.EnsureBuso()
                return t
            end
        end
        if prefType == "Melee" then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.ToolTip == "Sword" then
                    char.Humanoid:EquipTool(t)
                    FastAttack.EnsureBuso()
                    return t
                end
            end
        end
    end
end

local lastHitTime = 0
function FastAttack.Execute()
    if not Config.FastAttack or (tick() - lastHitTime) < 0.05 then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    FastAttack.EquipWeapon("Melee")

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end

    local parts = {}
    local primaryHead = nil

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:IsA("Model") and enemy ~= char then
            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
            local eHum = enemy:FindFirstChildOfClass("Humanoid")
            if eHrp and eHum and eHum.Health > 0 then
                if (char.HumanoidRootPart.Position - eHrp.Position).Magnitude <= Config.AttackDistance then
                    if not primaryHead then primaryHead = enemy:FindFirstChild("Head") end
                    for _, p in ipairs(enemy:GetChildren()) do
                        if p:IsA("BasePart") then
                            parts[#parts + 1] = { enemy, p }
                        end
                    end
                end
            end
        end
    end

    if #parts == 0 or not primaryHead then return end

    local netFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
    if netFolder then
        local regAtk = netFolder:FindFirstChild("RE/RegisterAttack")
        local regHit = netFolder:FindFirstChild("RE/RegisterHit")
        local seedRem = netFolder:FindFirstChild("seed")

        if regAtk and regHit then
            regAtk:FireServer()
            local salt = tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
            regHit:FireServer(primaryHead, parts, {}, salt)

            local atkRem, atkId = Network.GetAttackRemote()
            if atkRem and atkId and seedRem then
                local sSeed = seedRem:InvokeServer() or 1
                local xKey = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
                local encMethod = string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(bit32.bxor(string.byte(c), xKey))
                end)
                local sToken = bit32.bxor(atkId + 909090, sSeed * 2)
                atkRem:FireServer(encMethod, sToken, primaryHead, parts)
            end
            lastHitTime = tick()
        end
    end
end

local MobAura = {}
function MobAura.BringMob(mobName)
    if not Config.BringMob then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end

    local list = {}
    for _, e in ipairs(enemies:GetChildren()) do
        if e:IsA("Model") and (not mobName or e.Name == mobName) then
            local hrp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
            local hum = e:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if (char.HumanoidRootPart.Position - hrp.Position).Magnitude <= Config.BringMobDistance then
                    list[#list + 1] = e
                    if #list >= Config.BringMobLimit then break end
                end
            end
        end
    end

    if #list <= 1 then return end
    local lead = list[1]:FindFirstChild("HumanoidRootPart") or list[1].PrimaryPart
    if not lead then return end

    for i = 2, #list do
        local sub = list[i]:FindFirstChild("HumanoidRootPart") or list[i].PrimaryPart
        if sub then
            if not isnetworkowner or isnetworkowner(sub) then
                sub.CFrame = lead.CFrame
            end
        end
    end
end

function MobAura.GetNearest(filter)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local nearest, minDist = nil, math.huge
    for _, e in ipairs(enemies:GetChildren()) do
        if e:IsA("Model") then
            local hrp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
            local hum = e:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local match = true
                if filter then
                    if type(filter) == "table" then match = table.find(filter, e.Name) ~= nil
                    elseif type(filter) == "string" then match = (e.Name == filter or e.Name:find(filter) ~= nil) end
                end
                if match then
                    local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < minDist then
                        minDist = d
                        nearest = e
                    end
                end
            end
        end
    end
    return nearest
end

-- ========================================================
-- [7.5. QUẢN LÝ BỘ NHỚ VẬT PHẨM AN TOÀN (ITEM STORAGE)]
-- ========================================================
local ItemStorage = {
    Loaded = false,
    IRS = nil,
    KEYS = nil,
    MATCH = nil
}

function ItemStorage.Init()
    if ItemStorage.Loaded then return ItemStorage.IRS ~= nil end
    local ok = pcall(function()
        local irs = ReplicatedStorage:FindFirstChild("ItemReplicationService") or ReplicatedStorage:WaitForChild("ItemReplicationService", 3)
        if irs then
            ItemStorage.IRS = require(irs)
            ItemStorage.KEYS = require(irs:WaitForChild("KEYS", 3))
            local storageModule = ReplicatedStorage:FindFirstChild("ItemConfig") and ReplicatedStorage.ItemConfig:FindFirstChild("Storage")
            if storageModule then
                ItemStorage.MATCH = require(storageModule).match
            end
        end
    end)
    ItemStorage.Loaded = true
    if not ok or not ItemStorage.IRS then
        Logger.Warn("STORAGE", "ItemReplicationService không khả dụng trên Executor này. Kích hoạt fallback qua Network Remote.")
        return false
    end
    return true
end

-- ========================================================
-- [8. BẢO VỆ TRÁI ÁC QUỶ & QUẢN LÝ BALO (FRUIT VAULT)]
-- ========================================================
local FruitVault = {}

-- Kiểm tra xem một trái có phải là trái có giá trị cần bảo vệ không
function FruitVault.IsValuable(fruitName)
    if not fruitName then return false end
    for valKey, _ in pairs(VALUABLE_FRUITS_BLACKLIST) do
        if fruitName:find(valKey) then
            return true
        end
    end
    return false
end

-- Kiểm tra xem một trái có phải trái rác được phép hiến tế không
function FruitVault.IsSafeTrash(fruitName)
    if not fruitName then return false end
    if FruitVault.IsValuable(fruitName) then return false end
    for trashKey, _ in pairs(SAFE_TRASH_FRUITS) do
        if fruitName:find(trashKey) then
            return true
        end
    end
    return false
end

-- Tự động cất toàn bộ trái ác quỷ vào kho ngay khi có trong Balo/Người
function FruitVault.AutoStoreFruits()
    local bp, char = LocalPlayer.Backpack, LocalPlayer.Character
    for _, container in ipairs({ bp, char }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:find("Fruit") then
                    local oriName = tool:GetAttribute("OriginalName") or tool.Name
                    local inv = Network.InvokeCommF("getInventoryFruits")
                    local alreadyInStorage = false
                    if type(inv) == "table" then
                        for _, item in pairs(inv) do
                            if type(item) == "table" and item.Name == oriName then
                                alreadyInStorage = true
                                break
                            end
                        end
                    end

                    -- Nếu chưa cất vào kho -> Cất ngay lập tức!
                    if not alreadyInStorage then
                        Network.InvokeCommF("StoreFruit", oriName, tool)
                        print("[Fruit Vault] Đã cất an toàn trái:", oriName)
                    end
                end
            end
        end
    end
end

-- Tìm một trái rác an toàn trong kho để làm vé Raid hoặc nộp Trevor
-- TUYỆT ĐỐI KHÔNG CHỌN TRÁI CÓ GIÁ TRỊ!
function FruitVault.GetSafeTrashFruitFromStorage()
    if ItemStorage.Init() and ItemStorage.IRS and ItemStorage.MATCH then
        local ok, items = pcall(function() return ItemStorage.IRS:GetItems(ItemStorage.KEYS.QUANTITY) end)
        if ok and items then
            for _, itemData in pairs(items) do
                local item = ItemStorage.MATCH(itemData.ItemId)._ok
                if item and item.Display.Category == "Blox Fruit" then
                    local storageKey = item.Index.StorageKey
                    local price = item.Quality.MoneyPrice or 0

                    -- Chỉ lấy trái có giá < 1.000.000 Beli VÀ thuộc danh sách SAFE_TRASH VÀ không bị Blacklist
                    if price < 1000000 and FruitVault.IsSafeTrash(storageKey) and not FruitVault.IsValuable(storageKey) then
                        return storageKey
                    end
                end
            end
        end
    end

    -- Fallback qua Network Remote getInventoryFruits nếu require bị chặn
    local inv = Network.InvokeCommF("getInventoryFruits")
    if type(inv) == "table" then
        for _, it in pairs(inv) do
            if type(it) == "table" and it.Name then
                local k = it.Name
                if FruitVault.IsSafeTrash(k) and not FruitVault.IsValuable(k) then
                    return k
                end
            end
        end
    end
    return nil
end

-- Tự động Roll Trái Ác Quỷ Từ Xa (Remote Gacha Zioles Sniper)
local lastRollFruitTime = 0
local ROLL_COOLDOWN = 7200 -- Cooldown 2 tiếng
local ROLL_CACHE_FILE = ".kaitun_last_roll_" .. LocalPlayer.Name .. ".txt"

pcall(function()
    if isfile and readfile and isfile(ROLL_CACHE_FILE) then
        lastRollFruitTime = tonumber(readfile(ROLL_CACHE_FILE)) or 0
    end
end)

function FruitVault.GetTimeToNextRoll()
    local elapsed = os.time() - lastRollFruitTime
    if elapsed >= ROLL_COOLDOWN then
        return 0
    end
    return ROLL_COOLDOWN - elapsed
end

function FruitVault.AutoRollFruitRemote()
    if not Config.AutoRollFruit then return end
    local myLevel = LocalPlayer.Data.Level.Value
    local beli = LocalPlayer.Data.Beli.Value
    local rollCost = (myLevel * 1000) + 5000

    -- Nếu đã hết cooldown và đủ tiền Beli
    if FruitVault.GetTimeToNextRoll() == 0 and beli >= rollCost then
        local res = Network.InvokeCommF("Cousin", "Buy")
        lastRollFruitTime = os.time()
        pcall(function()
            if writefile then writefile(ROLL_CACHE_FILE, tostring(lastRollFruitTime)) end
        end)
        print("[Auto Gacha] Đã roll trái từ xa! Kết quả:", tostring(res))

        -- Cất ngay trái vừa roll được vào kho an toàn!
        task.wait(0.5)
        FruitVault.AutoStoreFruits()
    end
end

-- ========================================================
-- [9. HỆ THỐNG VÕ & GODHUMAN (MELEE ENGINE)]
-- ========================================================
local MeleeFarm = {}

local MeleePrices = {
    BlackLeg = { Beli = 150000, Frags = 0, Name = "Dark Step" },
    Electro = { Beli = 500000, Frags = 0, Name = "Electric" },
    FishmanKarate = { Beli = 750000, Frags = 0, Name = "Water Kung Fu" },
    DragonClaw = { Beli = 0, Frags = 1500, Name = "Dragon Breath" },
    Superhuman = { Beli = 3000000, Frags = 0, Name = "Superhuman" },
    DeathStep = { Beli = 2500000, Frags = 5000, Name = "Death Step" },
    SharkmanKarate = { Beli = 2500000, Frags = 5000, Name = "Sharkman Karate" },
    ElectricClaw = { Beli = 2500000, Frags = 5000, Name = "Electric Claw" },
    DragonTalon = { Beli = 2500000, Frags = 5000, Name = "Dragon Talon" },
    Godhuman = { Beli = 5000000, Frags = 5000, Name = "Godhuman" },
}

local NPCPositions = {
    BlackLeg = { [1] = Vector3.new(-985, 14, 3988), [2] = Vector3.new(-4754, 35, -4849), [3] = Vector3.new(-5045, 372, -3178) },
    Electro = { [1] = Vector3.new(-5384, 14, -2149), [2] = Vector3.new(-4864, 35, -4765), [3] = Vector3.new(-4994, 315, -3201) },
    FishmanKarate = { [1] = Vector3.new(61585, 19, 987), [2] = Vector3.new(-4957, 35, -4668), [3] = Vector3.new(-5022, 372, -3187) },
    DragonClaw = { [2] = Vector3.new(702, 187, 653), [3] = Vector3.new(-4980, 372, -3205) },
    Superhuman = { [2] = Vector3.new(1379, 247, -5190), [3] = Vector3.new(-5004, 372, -3194) },
    DeathStep = { [2] = Vector3.new(6356, 296, -6763), [3] = Vector3.new(-4997, 315, -3220) },
    SharkmanKarate = { [2] = Vector3.new(-2602, 239, -10317), [3] = Vector3.new(-4974, 315, -3221) },
    ElectricClaw = { [3] = Vector3.new(-10371, 331, -10131) },
    DragonTalon = { [3] = Vector3.new(5661, 1210, 863) },
    Godhuman = { [3] = Vector3.new(-13774, 333, -9879) },
}

function MeleeFarm.GetMastery(key)
    if ItemStorage.Init() and ItemStorage.IRS and ItemStorage.MATCH then
        local ok, masteries = pcall(function() return ItemStorage.IRS:GetItems(ItemStorage.KEYS.MASTERY) end)
        if ok and masteries then
            local targetName = MeleePrices[key] and MeleePrices[key].Name
            for _, m in pairs(masteries) do
                local item = ItemStorage.MATCH(m.ItemId)._ok
                if item and item.Display.Category == "Fighting Style" then
                    if item.Index.StorageKey == targetName or item.Index.StorageKey == key then
                        return tonumber(m.Value) or 0
                    end
                end
            end
        end
    end

    -- Fallback: kiểm tra Mastery trong Balo/Người
    local targetName = MeleePrices[key] and MeleePrices[key].Name
    local bp, char = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    for _, container in ipairs({ bp, char }) do
        if container then
            local tool = container:FindFirstChild(targetName or key)
            if tool and tool:FindFirstChild("Level") then
                return tonumber(tool.Level.Value) or 0
            end
        end
    end
    return 0
end

function MeleeFarm.GetMaterial(name)
    if ItemStorage.Init() and ItemStorage.IRS and ItemStorage.MATCH then
        local ok, items = pcall(function() return ItemStorage.IRS:GetItems(ItemStorage.KEYS.QUANTITY) end)
        if ok and items then
            for _, it in pairs(items) do
                local item = ItemStorage.MATCH(it.ItemId)._ok
                if item and item.Display.Category == "Material" and item.Index.StorageKey == name then
                    return tonumber(it.Value) or 0
                end
            end
        end
    end

    -- Fallback qua Network Remote getInventory
    local inv = Network.InvokeCommF("getInventory")
    if type(inv) == "table" then
        for _, it in pairs(inv) do
            if type(it) == "table" and it.Name == name then
                return tonumber(it.Count) or tonumber(it.Value) or 0
            end
        end
    end
    return 0
end

function MeleeFarm.AutoBuyHaki()
    local char = LocalPlayer.Character
    if not char then return end
    local beli = LocalPlayer.Data.Beli.Value
    if not CollectionService:HasTag(char, "Buso") and beli >= 25000 then Network.InvokeCommF("BuyHaki", "Buso") end
    if not CollectionService:HasTag(char, "Geppo") and beli >= 10000 then Network.InvokeCommF("BuyHaki", "Geppo") end
    if not CollectionService:HasTag(char, "Soru") and beli >= 100000 then Network.InvokeCommF("BuyHaki", "Soru") end
end

function MeleeFarm.GoToBuyer(key)
    local sea = FastTravel.GetSea()
    local pos = NPCPositions[key] and NPCPositions[key][sea]
    if pos then
        TweenEngine.ToWait(pos, 300, 5)
        return true
    end
    return false
end

-- ========================================================
-- [10. SMART LEVEL FARMING (SEA 1 SKY SKIP & BEST QUEST)]
-- ========================================================
local LevelFarm = {}
local CachedQuests = nil
local CachedNPCList = nil
pcall(function()
    CachedQuests = require(ReplicatedStorage:WaitForChild("Quests", 5))
    CachedNPCList = require(ReplicatedStorage:WaitForChild("GuideModule", 5)).Data.NPCList
end)

local CurrentQuestTarget = ""
local CurrentQuestName = ""
pcall(function()
    ReplicatedStorage.Remotes.QuestUpdate.OnClientEvent:Connect(function(data)
        if data and type(data) == "table" and data.Progress then
            for mob, _ in pairs(data.Progress) do CurrentQuestTarget = mob break end
            CurrentQuestName = data.InternalQuestName or ""
        else
            CurrentQuestTarget, CurrentQuestName = "", ""
        end
    end)
end)

function LevelFarm.GetBest()
    local lv = LocalPlayer.Data.Level.Value
    if lv >= 275 and lv < 300 then return { Q = "ColosseumQuest", M = "Togga Warrior", ID = 1 } end
    if lv >= 1450 and FastTravel.IsSea2() then return { Q = "ForgottenQuest", M = "Water Fighter", ID = 2 } end
    if lv >= 700 and FastTravel.IsSea1() then return { Q = "FountainQuest", M = "Galley Captain", ID = 2 } end

    local bestReq, bestQ, bestM, bestID = -1, nil, nil, nil
    if CachedQuests then
        for qName, sub in pairs(CachedQuests) do
            if qName ~= "BartiloQuest" and qName ~= "Trainees" and qName ~= "MarineQuest" then
                for id, info in pairs(sub) do
                    if info.LevelReq and info.LevelReq <= lv and info.LevelReq > bestReq then
                        for mob, c in pairs(info.Task) do
                            if c > 1 then
                                bestReq = info.LevelReq
                                bestQ, bestM, bestID = qName, tostring(mob), id
                            end
                        end
                    end
                end
            end
        end
    end
    return { Q = bestQ, M = bestM, ID = bestID }
end

function LevelFarm.GetNPCPos(qName)
    if not CachedNPCList then return nil end
    for _, npc in pairs(CachedNPCList) do
        if type(npc) == "table" then
            for _, v in pairs(npc) do
                if v == qName then return npc.Position end
            end
        end
    end
    return nil
end

function LevelFarm.Step()
    local lv = LocalPlayer.Data.Level.Value

    -- Sea 1 Sky Skip: Nhảy vọt cấp với Shanda & God's Guard
    if FastTravel.IsSea1() and Config.SkySkipSea1 then
        if lv >= 10 and lv < 70 then
            if LocalPlayer:GetAttribute("CurrentLocation") ~= "Upper Skylands" then
                FastTravel.TeleportLocation("sky 3")
                task.wait(1)
                return
            end
            local shanda = MobAura.GetNearest("Shanda")
            if shanda and shanda:FindFirstChild("HumanoidRootPart") then
                TweenEngine.To(shanda.HumanoidRootPart.CFrame, 350, 20)
                if (LocalPlayer.Character.HumanoidRootPart.Position - shanda.HumanoidRootPart.Position).Magnitude <= 40 then
                    MobAura.BringMob("Shanda")
                    FastAttack.Execute()
                end
            else
                TweenEngine.To(Vector3.new(-7783, 5576, -519), 350, 20)
            end
            return
        elseif lv >= 70 and lv < 120 then
            if LocalPlayer:GetAttribute("CurrentLocation") ~= "Skylands" then
                FastTravel.TeleportLocation("sky 2")
                task.wait(1)
                return
            end
            local guard = MobAura.GetNearest("God's Guard")
            if guard and guard:FindFirstChild("HumanoidRootPart") then
                TweenEngine.To(guard.HumanoidRootPart.CFrame, 350, 20)
                if (LocalPlayer.Character.HumanoidRootPart.Position - guard.HumanoidRootPart.Position).Magnitude <= 40 then
                    MobAura.BringMob("God's Guard")
                    FastAttack.Execute()
                end
            else
                TweenEngine.To(Vector3.new(-4698, 845, -1912), 350, 20)
            end
            return
        end
    end

    -- Farm theo Quest Chuẩn
    local qInfo = LevelFarm.GetBest()
    if not qInfo or not qInfo.Q then
        Logger.Warn("FARM", "Không tìm thấy nhiệm vụ phù hợp cho Lv " .. tostring(lv))
        return
    end

    if CurrentQuestTarget == "" then
        local npcPos = LevelFarm.GetNPCPos(qInfo.Q)
        if npcPos then
            Logger.Log("FARM", "Bay đến NPC nhận Quest:", qInfo.Q, "(ID: " .. tostring(qInfo.ID) .. ")")
            TweenEngine.To(npcPos, 350, 5)
            if (LocalPlayer.Character.HumanoidRootPart.Position - npcPos).Magnitude <= 15 then
                Network.InvokeCommF("StartQuest", qInfo.Q, qInfo.ID)
            end
        else
            Logger.Warn("FARM", "Không tìm thấy vị trí NPC cho quest:", qInfo.Q)
        end
    else
        local mob = MobAura.GetNearest(CurrentQuestTarget)
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            Logger.Log("FARM", "Đang đánh quái:", CurrentQuestTarget, "| Khoảng cách:", math.floor((LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude))
            TweenEngine.To(mob.HumanoidRootPart.CFrame, 350, 20)
            if (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude <= 40 then
                MobAura.BringMob(CurrentQuestTarget)
                FastAttack.Execute()
            end
        else
            local npcPos = LevelFarm.GetNPCPos(qInfo.Q)
            if npcPos then TweenEngine.To(npcPos + Vector3.new(0, 30, 0), 300) end
        end
    end
end

-- ========================================================
-- [11. AUTO RAID AN TOÀN (CHỈ DÙNG BELI HOẶC TRÁI RÁC)]
-- ========================================================
local AutoRaid = {}
local isRaiding = false
pcall(function()
    ReplicatedStorage.Remotes.Raids.OnClientEvent:Connect(function(act)
        if act == "StartTimer" then isRaiding = true else isRaiding = false end
    end)
end)

function AutoRaid.StartSafeRaid()
    if isRaiding then
        -- Clear phòng Raid
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, m in ipairs(enemies:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                    TweenEngine.To(m.HumanoidRootPart.CFrame, 350, 25)
                    FastAttack.Execute()
                    return true
                end
            end
        end
        local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
        if locations then
            for i = 5, 1, -1 do
                local isl = locations:FindFirstChild("Island " .. i)
                if isl then TweenEngine.To(isl:GetPivot() * CFrame.new(0, 70, 0), 350) break end
            end
        end
        return true
    end

    local bp, char = LocalPlayer.Backpack, LocalPlayer.Character
    local hasChip = bp:FindFirstChild("Special Microchip") or (char and char:FindFirstChild("Special Microchip"))

    if not hasChip then
        -- Ưu tiên 1: Mua bằng Beli (100.000)
        if LocalPlayer.Data.Beli.Value >= 100000 then
            Network.InvokeCommF("RaidsNpc", "Select", "Dark")
        else
            -- Ưu tiên 2: CHỈ DÙNG TRÁI RÁC AN TOÀN TRONG KHO (TUYỆT ĐỐI KHÔNG DÙNG TRÁI QUÝ)
            local trashFruitKey = FruitVault.GetSafeTrashFruitFromStorage()
            if trashFruitKey then
                Network.InvokeCommF("LoadFruit", trashFruitKey)
                task.wait(0.5)
                Network.InvokeCommF("RaidsNpc", "Select", "Dark")
                print("[Auto Raid] Đã dùng trái rác an toàn làm vé:", trashFruitKey)
            else
                -- Không có Beli và không có trái rác -> Bỏ qua, không mạo hiểm!
                return false
            end
        end
    end

    -- Bấm đài Raid
    if FastTravel.IsSea2() then
        local cd = workspace.Map.CircleIsland.RaidSummon2:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then fireclickdetector(cd) end
    elseif FastTravel.IsSea3() then
        local cd = workspace.Map["Boat Castle"].RaidSummon2:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then fireclickdetector(cd) end
    end
    return true
end

-- ========================================================
-- [12. GIAO DIỆN HUD CHUYÊN BIỆT (SPECIALIZED HUD)]
-- ========================================================
local HUD = {}
local lblStatus, lblGoal, lbl3D, lblRoll = nil, nil, nil, nil
local is3DRenderDisabled = false
local lblDebug = nil

local function Toggle3DRender()
    pcall(function()
        is3DRenderDisabled = not is3DRenderDisabled
        RunService:Set3dRenderingEnabled(not is3DRenderDisabled)
        if lbl3D then
            if is3DRenderDisabled then
                lbl3D.Text = "🎮 3D Render: TẮT (Tiết kiệm GPU) [Bấm để Bật]"
                lbl3D.TextColor3 = Color3.fromRGB(120, 255, 120)
            else
                lbl3D.Text = "🎮 3D Render: BẬT [Bấm để Tắt]"
                lbl3D.TextColor3 = Color3.fromRGB(255, 120, 120)
            end
        end
    end)
end

function HUD.Init()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GodhumanSpeedrunHUD"
    sg.ResetOnSpawn = false
    sg.Parent = (gethui and gethui()) or CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 380, 0, 248)
    frame.Position = UDim2.new(0.02, 0, 0.05, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    frame.BackgroundTransparency = 0.15
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 170, 0) -- Màu vàng kim tượng trưng Godhuman
    stroke.Thickness = 1.8

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Font = Enum.Font.FredokaOne
    title.Text = "⚡ GODHUMAN & MAX LEVEL SPEEDRUN"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextSize = 16
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    lblStatus = Instance.new("TextLabel", frame)
    lblStatus.Size = UDim2.new(1, -20, 0, 22)
    lblStatus.Position = UDim2.new(0, 10, 0, 34)
    lblStatus.Font = Enum.Font.GothamMedium
    lblStatus.Text = "Trạng thái: Đang khởi động..."
    lblStatus.TextColor3 = Color3.fromRGB(255, 240, 150)
    lblStatus.TextSize = 12
    lblStatus.BackgroundTransparency = 1
    lblStatus.TextXAlignment = Enum.TextXAlignment.Left

    lblGoal = Instance.new("TextLabel", frame)
    lblGoal.Size = UDim2.new(1, -20, 0, 22)
    lblGoal.Position = UDim2.new(0, 10, 0, 56)
    lblGoal.Font = Enum.Font.GothamBold
    lblGoal.Text = "Mục tiêu: Đang phân tích võ..."
    lblGoal.TextColor3 = Color3.fromRGB(100, 255, 180)
    lblGoal.TextSize = 12
    lblGoal.BackgroundTransparency = 1
    lblGoal.TextXAlignment = Enum.TextXAlignment.Left

    local stats = Instance.new("TextLabel", frame)
    stats.Size = UDim2.new(1, -20, 0, 22)
    stats.Position = UDim2.new(0, 10, 0, 78)
    stats.Font = Enum.Font.GothamBold
    stats.TextColor3 = Color3.fromRGB(200, 255, 255)
    stats.TextSize = 12
    stats.BackgroundTransparency = 1
    stats.TextXAlignment = Enum.TextXAlignment.Left

    local timer = Instance.new("TextLabel", frame)
    timer.Size = UDim2.new(1, -20, 0, 22)
    timer.Position = UDim2.new(0, 10, 0, 100)
    timer.Font = Enum.Font.Gotham
    timer.TextColor3 = Color3.fromRGB(180, 180, 220)
    timer.TextSize = 12
    timer.BackgroundTransparency = 1
    timer.TextXAlignment = Enum.TextXAlignment.Left

    -- Nút Tắt / Bật Render 3D Siêu Tiết Kiệm GPU
    local btn3D = Instance.new("TextButton", frame)
    btn3D.Size = UDim2.new(1, -20, 0, 28)
    btn3D.Position = UDim2.new(0, 10, 0, 126)
    btn3D.Font = Enum.Font.GothamBold
    btn3D.Text = "🎮 3D Render: BẬT [Bấm để Tắt (Tiết kiệm GPU)]"
    btn3D.TextColor3 = Color3.fromRGB(255, 120, 120)
    btn3D.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    btn3D.BorderSizePixel = 0
    Instance.new("UICorner", btn3D).CornerRadius = UDim.new(0, 6)
    btn3D.MouseButton1Click:Connect(Toggle3DRender)
    lbl3D = btn3D

    -- Nhãn đếm ngược Auto Roll Gacha
    lblRoll = Instance.new("TextLabel", frame)
    lblRoll.Size = UDim2.new(1, -20, 0, 22)
    lblRoll.Position = UDim2.new(0, 10, 0, 160)
    lblRoll.Font = Enum.Font.GothamBold
    lblRoll.Text = "🎲 Gacha Roll: Đang kiểm tra..."
    lblRoll.TextColor3 = Color3.fromRGB(255, 180, 255)
    lblRoll.BackgroundTransparency = 1
    lblRoll.TextXAlignment = Enum.TextXAlignment.Left
    lblRoll.TextSize = 12

    -- Nhãn Debug / Log trực tiếp trên màn hình
    lblDebug = Instance.new("TextLabel", frame)
    lblDebug.Size = UDim2.new(1, -20, 0, 24)
    lblDebug.Position = UDim2.new(0, 10, 0, 186)
    lblDebug.Font = Enum.Font.GothamMedium
    lblDebug.Text = "🐛 Debug: Khởi động hệ thống..."
    lblDebug.TextColor3 = Color3.fromRGB(130, 210, 255)
    lblDebug.BackgroundTransparency = 1
    lblDebug.TextXAlignment = Enum.TextXAlignment.Left
    lblDebug.TextTruncate = Enum.TextTruncate.AtEnd
    lblDebug.TextSize = 11

    local start = os.time()
    task.spawn(function()
        while true do
            pcall(function()
                local d = LocalPlayer:FindFirstChild("Data")
                if d then
                    stats.Text = string.format("Level: %d/2800 | Beli: %s | Frags: %s", d.Level.Value, tostring(d.Beli.Value), tostring(d.Fragments.Value))
                end
                local el = os.time() - start
                timer.Text = string.format("Thời gian treo máy: %02d:%02d:%02d", math.floor(el/3600), math.floor(math.fmod(el,3600)/60), math.floor(math.fmod(el,60)))

                -- Cập nhật đồng hồ đếm ngược Roll Trái
                local remain = FruitVault.GetTimeToNextRoll()
                if remain == 0 then
                    lblRoll.Text = "🎲 Gacha Roll: SẴN SÀNG ROLL NGAY TỪ XA!"
                    lblRoll.TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    local h = math.floor(remain / 3600)
                    local m = math.floor(math.fmod(remain, 3600) / 60)
                    local s = math.floor(math.fmod(remain, 60))
                    lblRoll.Text = string.format("🎲 Gacha Roll: Hồi chiêu sau %02d:%02d:%02d", h, m, s)
                    lblRoll.TextColor3 = Color3.fromRGB(255, 180, 255)
                end
            end)
            task.wait(1)
        end
    end)
end

function HUD.SetStatus(txt) if lblStatus then lblStatus.Text = "Trạng thái: " .. tostring(txt) end end
function HUD.SetGoal(txt) if lblGoal then lblGoal.Text = "Tiến độ Võ: " .. tostring(txt) end end
function HUD.SetDebug(txt)
    if lblDebug then
        lblDebug.Text = "🐛 " .. tostring(txt)
        local str = tostring(txt)
        if str:find("LỖI") or str:find("ERROR") or str:find("❌") then
            lblDebug.TextColor3 = Color3.fromRGB(255, 90, 90)
        elseif str:find("WARN") or str:find("⚠️") then
            lblDebug.TextColor3 = Color3.fromRGB(255, 200, 80)
        else
            lblDebug.TextColor3 = Color3.fromRGB(130, 210, 255)
        end
    end
end

-- ========================================================
-- [13. KHỞI ĐỘNG VÒNG LẶP ĐIỀU PHỐI HYPER-FOCUSED]
-- ========================================================
local function RunDiagnostics()
    Logger.Log("DIAGNOSTICS", "=== KIỂM TRA MÔI TRƯỜNG EXECUTOR & GAME ===")
    local tests = {
        ["getrawmetatable"] = type(getrawmetatable) == "function",
        ["setreadonly"] = type(setreadonly) == "function",
        ["newcclosure"] = type(newcclosure) == "function",
        ["getconnections"] = type(getconnections) == "function",
        ["fireclickdetector"] = type(fireclickdetector) == "function",
        ["gethui"] = type(gethui) == "function",
        ["Remote CommF_"] = (GetCommF() ~= nil),
        ["ItemStorage (IRS)"] = ItemStorage.Init()
    }
    for name, supported in pairs(tests) do
        if supported then
            Logger.Log("DIAGNOSTICS", string.format("✔ %s: HOẠT ĐỘNG TỐT", name))
        else
            Logger.Warn("DIAGNOSTICS", string.format("✘ %s: KHÔNG HỖ TRỢ / THIẾU (Đã bật cơ chế tự fallback)", name))
        end
    end
    Logger.Log("DIAGNOSTICS", "Sea hiện tại: " .. tostring(FastTravel.GetSea()) .. " | Level: " .. tostring(LocalPlayer.Data.Level.Value))
    Logger.Log("DIAGNOSTICS", "===========================================")
end

Security.Init()
if LocalPlayer.Character then Security.ApplyNoFall(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.5) Security.ApplyNoFall(c) end)

if not LocalPlayer.Team then
    repeat
        pcall(function() Network.InvokeCommF("SetTeam", Config.Team or "Pirates") end)
        task.wait(0.5)
    until LocalPlayer.Team
end

-- Tối ưu đồ họa
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    if workspace:FindFirstChild("Map") then
        for _, p in ipairs(workspace.Map:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency ~= 1 then p.Material = Enum.Material.SmoothPlastic p.CastShadow = false
            elseif p:IsA("ParticleEmitter") or p:IsA("Trail") then p.Enabled = false end
        end
    end
    if setfpscap and Config.FPSCap then setfpscap(Config.FPSCap) end
end)

HUD.Init()
RunDiagnostics()

-- Tự động kích hoạt Tắt Render 3D nếu Config bật
if Config.Disable3DRender then
    Toggle3DRender()
end

-- Vòng lặp nền: Bảo vệ cất Fruit, Auto Roll Từ Xa, Auto Stats, Đổi Xương
task.spawn(function()
    while true do
        local ok, err = pcall(function()
            -- 1. Luôn bảo vệ và cất ngay mọi trái vào Balo
            FruitVault.AutoStoreFruits()

            -- 2. Tự động Roll trái ác quỷ từ xa khi hết cooldown
            FruitVault.AutoRollFruitRemote()

            -- 3. Tự cộng chỉ số Melee & Defense
            local stats = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Stats")
            if stats then
                local maxCap = workspace:GetAttribute("LEVEL_CAP") or 2550
                local mLv = stats.Melee and stats.Melee.Level.Value or 0
                local dLv = stats.Defense and stats.Defense.Level.Value or 0
                if dLv < maxCap and (dLv < (LocalPlayer.Data.Level.Value / 80) or (maxCap - mLv) < 100) then
                    Network.InvokeCommF("AddPoint", "Defense", 999)
                elseif mLv < maxCap then
                    Network.InvokeCommF("AddPoint", "Melee", 999)
                else
                    Network.InvokeCommF("AddPoint", "Sword", 999)
                end
            end

            -- 4. Đổi xương tại Sea 3
            if FastTravel.IsSea3() then
                if MeleeFarm.GetMaterial("Bones") >= 50 then
                    Network.InvokeCommF("Bones", "Buy", 1, 1)
                end
            end
        end)
        if not ok then
            Logger.Error("BG_LOOP", err)
        end
        task.wait(1)
    end
end)

-- VÒNG LẶP THỰC THI CHÍNH: CHỈ TẬP TRUNG GODHUMAN VÀ MAX LEVEL
task.spawn(function()
    while true do
        local ok, err = pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then
                task.wait(0.5)
                return
            end

            local myLevel = LocalPlayer.Data.Level.Value
            local beli = LocalPlayer.Data.Beli.Value
            local frags = LocalPlayer.Data.Fragments.Value

            -- Tự mua Haki căn bản
            MeleeFarm.AutoBuyHaki()

            -- ========================================================
            -- [BƯỚC 1: MỞ KHÓA SEA 2 KHI ĐẠT LEVEL 700+]
            -- ========================================================
            if FastTravel.IsSea1() and myLevel >= 700 then
                HUD.SetStatus("Mở khóa Sea 2 (Dressrosa)...")
                Logger.Log("PROGRESS", "Bắt đầu chuỗi nhiệm vụ mở khóa Sea 2...")
                local travelRes = Network.InvokeCommF("TravelDressrosa")
                if type(travelRes) == "string" and travelRes:find("Cannot") then
                    local qData = Network.InvokeCommF("DressrosaQuestProgress")
                    if qData and not qData.UsedKey then
                        if not qData.TalkedDetective then
                            Network.InvokeCommF("DressrosaQuestProgress", "Detective")
                        elseif LocalPlayer.Backpack:FindFirstChild("Key") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack["Key"])
                            Network.InvokeCommF("DressrosaQuestProgress", "UseKey")
                        end
                    elseif qData and not qData.KilledIceBoss then
                        local boss = MobAura.GetNearest("Ice Admiral")
                        if boss and boss:FindFirstChild("HumanoidRootPart") then
                            TweenEngine.To(boss.HumanoidRootPart.CFrame, 350, 20)
                            FastAttack.Execute()
                        else
                            TweenEngine.To(CFrame.new(1328, 43, -1346), 300, 10)
                        end
                    else
                        Network.InvokeCommF("TravelDressrosa")
                    end
                end
                task.wait(0.5)
                return
            end

            -- ========================================================
            -- [BƯỚC 2: MỞ KHÓA SEA 3 KHI ĐẠT LEVEL 1500+]
            -- ========================================================
            if FastTravel.IsSea2() and myLevel >= 1500 then
                HUD.SetStatus("Mở khóa Sea 3 (Zou)...")
                Logger.Log("PROGRESS", "Bắt đầu chuỗi nhiệm vụ mở khóa Sea 3...")
                local unlockables = Network.InvokeCommF("GetUnlockables") or {}
                if not unlockables.FlamingoAccess then
                    -- Cần nộp 1 trái ác quỷ >= 1M cho Trevor
                    -- CHÚ Ý: CHỈ DÙNG TRÁI RÁC TRÊN 1M (NẾU CÓ) HOẶC CỐ GẮNG ROLL, KHÔNG DÙNG TRÁI QUÝ BLACKLIST!
                    local suitableFruit = nil
                    if ItemStorage.Init() and ItemStorage.IRS and ItemStorage.MATCH then
                        local okIRS, items = pcall(function() return ItemStorage.IRS:GetItems(ItemStorage.KEYS.QUANTITY) end)
                        if okIRS and items then
                            for _, it in pairs(items) do
                                local item = ItemStorage.MATCH(it.ItemId)._ok
                                if item and item.Display.Category == "Blox Fruit" and item.Quality.MoneyPrice >= 1000000 then
                                    local k = item.Index.StorageKey
                                    if not FruitVault.IsValuable(k) or k == "Quake" or k == "Gravity" or k == "Pain" then
                                        suitableFruit = k
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if not suitableFruit then
                        local inv = Network.InvokeCommF("getInventoryFruits")
                        if type(inv) == "table" then
                            for _, it in pairs(inv) do
                                if type(it) == "table" and it.Name then
                                    local k = it.Name
                                    if not FruitVault.IsValuable(k) or k == "Quake" or k == "Gravity" or k == "Pain" then
                                        suitableFruit = k
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if suitableFruit then
                        Logger.Log("SEA3", "Dùng trái nộp Trevor:", suitableFruit)
                        Network.InvokeCommF("LoadFruit", suitableFruit)
                        task.wait(0.5)
                        Network.InvokeCommF("TalkTrevor", "1")
                        Network.InvokeCommF("TalkTrevor", "2")
                        Network.InvokeCommF("TalkTrevor", "3")
                    else
                        Logger.Warn("SEA3", "Chưa có trái ác quỷ > 1M (không quý) để nộp Trevor, đang chờ Roll từ xa...")
                    end
                else
                    local zCheck = Network.InvokeCommF("ZQuestProgress", "Check")
                    if zCheck == 0 then
                        Network.InvokeCommF("TravelZou")
                        Network.InvokeCommF("ZQuestProgress", "Begin")
                        local indra = MobAura.GetNearest("rip_indra")
                        if indra and indra:FindFirstChild("HumanoidRootPart") then
                            TweenEngine.To(indra.HumanoidRootPart.CFrame, 350, 20)
                            FastAttack.Execute()
                        else
                            TweenEngine.To(CFrame.new(-2840, 7, -400), 300, 10)
                        end
                    elseif zCheck == 1 then
                        Network.InvokeCommF("TravelZou")
                    else
                        local swan = MobAura.GetNearest("Don Swan")
                        if swan and swan:FindFirstChild("HumanoidRootPart") then
                            TweenEngine.To(swan.HumanoidRootPart.CFrame, 350, 20)
                            FastAttack.Execute()
                        else
                            TweenEngine.To(CFrame.new(2288, 15, 863), 300, 10)
                        end
                    end
                end
                task.wait(0.5)
                return
            end

            -- ========================================================
            -- [BƯỚC 3: CÀY 10 VÕ THUẬT LÊN 400 MASTERY]
            -- ========================================================
            local MeleeList = {
                "BlackLeg", "Electro", "FishmanKarate",
                "DragonClaw", "Superhuman", "DeathStep", "SharkmanKarate",
                "ElectricClaw", "DragonTalon", "Godhuman"
            }

            for _, mKey in ipairs(MeleeList) do
                local mastery = MeleeFarm.GetMastery(mKey)
                local cfgPrice = MeleePrices[mKey]

                if mastery < Config.TargetMastery then
                    HUD.SetGoal(string.format("%s: %d/400", cfgPrice.Name, mastery))

                    -- Nếu chưa sở hữu: Kiểm tra tiền để mua
                    if mastery == 0 then
                        local canBuy = (beli >= cfgPrice.Beli) and (frags >= cfgPrice.Frags)
                        if canBuy then
                            HUD.SetStatus("Mua võ: " .. cfgPrice.Name)
                            Logger.Log("MELEE", "Đủ điều kiện mua võ:", cfgPrice.Name)
                            if MeleeFarm.GoToBuyer(mKey) then
                                if mKey == "DragonClaw" then
                                    Network.InvokeCommF("BlackbeardReward", "DragonClaw", "2")
                                else
                                    Network.InvokeCommF("Buy" .. mKey)
                                end
                                task.wait(1)
                            end
                        elseif frags < cfgPrice.Frags and (FastTravel.IsSea2() or FastTravel.IsSea3()) then
                            -- Thiếu Fragments -> Đi Raid cày Frags an toàn!
                            HUD.SetStatus("Cày Fragments đi Raid...")
                            Logger.Log("RAID", "Thiếu Fragments cho võ " .. cfgPrice.Name .. ", đi Raid...")
                            AutoRaid.StartSafeRaid()
                            return
                        end
                    end
                    break
                end
            end

            -- ========================================================
            -- [BƯỚC 4: THU THẬP NGUYÊN LIỆU GODHUMAN]
            -- ========================================================
            if MeleeFarm.GetMastery("Godhuman") == 0 then
                local GodhumanMaterials = {
                    { Name = "Dragon Scale", Max = 20, Sea = 3, Mob = "Dragon Crew Warrior" },
                    { Name = "Fish Tail", Max = 20, Sea = 3, Mob = "Fishman Raider" },
                    { Name = "Mystic Droplet", Max = 10, Sea = 2, Mob = "Water Fighter" },
                    { Name = "Magma Ore", Max = 20, Sea = 2, Mob = "Magma Ninja" }
                }

                for _, mat in ipairs(GodhumanMaterials) do
                    local count = MeleeFarm.GetMaterial(mat.Name)
                    if count < mat.Max then
                        HUD.SetGoal(string.format("Nguyên liệu: %s (%d/%d)", mat.Name, count, mat.Max))
                        if FastTravel.GetSea() ~= mat.Sea then
                            HUD.SetStatus("Chuyển Sea để farm " .. mat.Name)
                            Logger.Log("MATERIAL", "Cần đổi sang Sea " .. tostring(mat.Sea) .. " để farm " .. mat.Name)
                            if mat.Sea == 2 then Network.InvokeCommF("TravelDressrosa")
                            elseif mat.Sea == 3 then Network.InvokeCommF("TravelZou") end
                            task.wait(5)
                            return
                        end

                        local mob = MobAura.GetNearest(mat.Mob)
                        if mob and mob:FindFirstChild("HumanoidRootPart") then
                            TweenEngine.To(mob.HumanoidRootPart.CFrame, 350, 20)
                            if (char.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude <= 40 then
                                MobAura.BringMob(mat.Mob)
                                FastAttack.Execute()
                            end
                        end
                        return
                    end
                end

                -- Đã gom đủ 4 nguyên liệu: Mua Godhuman tại Sea 3
                if FastTravel.IsSea3() and beli >= 5000000 and frags >= 5000 then
                    HUD.SetStatus("Đang mua GODHUMAN!")
                    Logger.Log("GODHUMAN", "Đủ 4 nguyên liệu và tiền, đang đến NPC mua Godhuman!")
                    if MeleeFarm.GoToBuyer("Godhuman") then
                        Network.InvokeCommF("BuyGodhuman", true)
                        Network.InvokeCommF("BuyGodhuman")
                    end
                end
            end

            -- ========================================================
            -- [BƯỚC 5: CÀY CẤP ĐỘ LÊN MAX LEVEL (2800)]
            -- ========================================================
            local maxLevelCap = workspace:GetAttribute("LEVEL_CAP") or 2800
            if myLevel < maxLevelCap then
                HUD.SetStatus("Cày cấp: Lv " .. tostring(myLevel))
                LevelFarm.Step()
            else
                HUD.SetStatus("ĐÃ ĐẠT MAX LEVEL! Tiếp tục duy trì...")
                LevelFarm.Step()
            end

        end)
        if not ok then
            Logger.Error("MAIN_LOOP", err)
        end
        task.wait(0.05)
    end
end)

Logger.Log("INIT", "Khởi chạy bản Speedrun Godhuman & Max Level thành công!")
warn("[Kaitun Godhuman & Max Level] Đã khởi chạy bản Speedrun chuyên biệt thành công!")
