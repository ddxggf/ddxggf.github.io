--[[
  窗口（460×330）+ 四页侧边栏
    1 修改角色属性：改速度 / 改跳跃力 / 穿墙 / 飞行
       穿墙=每帧（Stepped）把自己角色所有 BasePart 的 CanCollide 设成 false
       不做射线、不做贴地、不改 CFrame；站着/落地交给 Humanoid 自己
       飞行=LinearVelocity 吊着人，摇杆按角色朝向飞；飞行时碰撞恢复，所以撞墙会停
    2 方块无碰撞：点按钮 → 点屏幕上的方块 → 那块变无碰撞；右侧列表，每行带"查看"（高亮 / 连线两种方式）
    3 方块尺寸：点按钮 → 点一块方块 → 读出它的长（X）/ 宽（Z）/ 高（Y）
    4 空
  放置：StarterPlayer → StarterPlayerScripts → LocalScript
]]

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("MyWindow")
if old then old:Destroy() end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

local function filterParams()
    local p = RaycastParams.new()
    local ok = pcall(function() p.FilterType = Enum.RaycastFilterType.Exclude end)
    if not ok then p.FilterType = Enum.RaycastFilterType.Blacklist end
    return p
end

local function overlapParams()
    local o = OverlapParams.new()
    local ok = pcall(function() o.FilterType = Enum.RaycastFilterType.Exclude end)
    if not ok then o.FilterType = Enum.RaycastFilterType.Blacklist end
    return o
end

local rayP  = filterParams()
local overP = overlapParams()

local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

-- ===== 屏幕容器 / 主窗 =====
-- 关窗口时统一复位的登记表（表本身一定存在，方法在文件末尾填）
local Cleanup = { done = false, run = function() end }
local origSpeed = nil      -- 打开窗口前的走路速度
local origJump = nil       -- 打开窗口前的跳跃力
local origUseJumpPower = nil -- 原来用的是 JumpPower 还是 JumpHeight

local gui = Instance.new("ScreenGui")
gui.Name = "MyWindow"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10
gui.Parent = playerGui

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(460, 330)
win.Position = UDim2.fromScale(0.5, 0.4)
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Active = true
win.Parent = gui
corner(win, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(48, 48, 48)
stroke.Parent = win

-- ===== 标题栏 =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, -2, 0, 42)
titleBar.Position = UDim2.fromOffset(1, 1)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = win
corner(titleBar, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "豆包中心"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -36, 0.5, 0)
close.AnchorPoint = Vector2.new(0, 0.5)
close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Text = "×"
close.Font = Enum.Font.SourceSansBold
close.TextSize = 18
close.TextColor3 = Color3.fromRGB(160, 160, 160)
close.Parent = titleBar
corner(close, 6)

close.MouseEnter:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
close.MouseLeave:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.TextColor3 = Color3.fromRGB(160, 160, 160)
end)
local function doClose()
    Cleanup.run()
    gui:Destroy()
end

close.MouseButton1Click:Connect(doClose)
pcall(function() close.Activated:Connect(doClose) end)

-- 不管是点 ×、脚本删 gui、还是别的原因没了，都复位一次
pcall(function()
    gui.Destroying:Connect(function()
        Cleanup.run()
    end)
end)

-- ===== 侧边栏 =====
local sidebar = Instance.new("ScrollingFrame")
sidebar.Position = UDim2.fromOffset(1, 42)
sidebar.Size = UDim2.new(0, 128, 1, -43)
sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
sidebar.BorderSizePixel = 0
sidebar.Active = true
sidebar.ScrollBarThickness = 4
sidebar.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
pcall(function() sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
sidebar.Parent = win
corner(sidebar, 10)

local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingLeft = UDim.new(0, 8)
sidePad.PaddingRight = UDim.new(0, 8)
sidePad.PaddingTop = UDim.new(0, 8)

local sideList = Instance.new("UIListLayout", sidebar)
sideList.Padding = UDim.new(0, 6)
sideList.SortOrder = Enum.SortOrder.LayoutOrder

-- ===== 页面容器 =====
local pages = Instance.new("Frame")
pages.Position = UDim2.fromOffset(129, 42)
pages.Size = UDim2.new(1, -129, 1, -42)
pages.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
pages.BorderSizePixel = 0
pages.Active = true
pages.Parent = win

local page1 = Instance.new("Frame")
page1.Size = UDim2.fromScale(1, 1)
page1.BackgroundTransparency = 1
page1.Parent = pages

local page2 = Instance.new("Frame")
page2.Size = UDim2.fromScale(1, 1)
page2.BackgroundTransparency = 1
page2.Visible = false
page2.Parent = pages

local page3 = Instance.new("Frame")
page3.Size = UDim2.fromScale(1, 1)
page3.BackgroundTransparency = 1
page3.Visible = false
page3.Parent = pages

local page4 = Instance.new("Frame")
page4.Size = UDim2.fromScale(1, 1)
page4.BackgroundTransparency = 1
page4.Visible = false
page4.Parent = pages

-- 备用空页（5~10），以后往里加功能
local emptyPages = {}
for _ = 5, 10 do
    local p = Instance.new("Frame")
    p.Size = UDim2.fromScale(1, 1)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = pages
    emptyPages[#emptyPages + 1] = p
end

-- ===== 状态回显（放在 pages 上，三页共用） =====
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 18)
status.Position = UDim2.new(0, 14, 1, -24)
status.BackgroundTransparency = 1
status.Text = ""
status.Font = Enum.Font.SourceSans
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(120, 120, 120)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = pages

local function say(text, ok)
    status.Text = text
    if ok == true then
        status.TextColor3 = Color3.fromRGB(110, 200, 130)
    elseif ok == false then
        status.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        status.TextColor3 = Color3.fromRGB(120, 120, 120)
    end
end

-- ===== 侧边栏按钮 =====
local pagesList = { page1, page2, page3, page4 }
for _, p in ipairs(emptyPages) do
    pagesList[#pagesList + 1] = p
end
local buttons = {}

local cancelPick = nil

local function setPage(index)
    if cancelPick then cancelPick() end
    for i, p in ipairs(pagesList) do p.Visible = (i == index) end
    for i, b in ipairs(buttons) do
        if i == index then
            b.BackgroundColor3 = Color3.fromRGB(30, 70, 140)
            b.TextColor3 = Color3.fromRGB(245, 245, 245)
        else
            b.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            b.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

local function makeCategory(name, order, pageIndex)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = name
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.Parent = sidebar
    corner(btn, 6)
    local p = Instance.new("UIPadding", btn)
    p.PaddingLeft = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() setPage(pageIndex) end)
    buttons[pageIndex] = btn
end

makeCategory("修改角色属性", 1, 1)
makeCategory("方块无碰撞", 2, 2)
makeCategory("方块尺寸", 3, 3)
makeCategory("空4", 4, 4)
makeCategory("高亮 ESP", 5, 5)
for i = 6, 10 do
    makeCategory("空" .. i, i, i)
end

-- ===== 输入行 =====
local function makeInputRow(parent, y, placeholder, onSubmit, defaultText)
    local row = Instance.new("Frame")
    row.Position = UDim2.fromOffset(14, y)
    row.Size = UDim2.new(1, -28, 0, 40)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -80, 1, 0)
    box.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.SourceSans
    box.TextSize = 13
    box.Text = defaultText or ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    box.TextColor3 = Color3.fromRGB(235, 235, 235)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = row
    corner(box, 6)
    local bp = Instance.new("UIPadding", box)
    bp.PaddingLeft = UDim.new(0, 10)
    bp.PaddingRight = UDim.new(0, 10)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(68, 40)
    btn.Position = UDim2.new(1, -68, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = "修改"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = row
    corner(btn, 6)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    end)

    local function fire()
        local v = tonumber(box.Text)
        if not v then
            say("请输入数字", false)
            return
        end
        onSubmit(v, box)
    end

    btn.MouseButton1Click:Connect(fire)
    box.FocusLost:Connect(function(enter) if enter then fire() end end)
end

-- ===== 开关行 =====
local function makeToggle(parent, y, labelText, onChange)
    local row = Instance.new("Frame")
    row.Position = UDim2.fromOffset(14, y)
    row.Size = UDim2.new(1, -28, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -130, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Size = UDim2.fromOffset(34, 18)
    stateLabel.Position = UDim2.new(1, -94, 0.5, 0)
    stateLabel.AnchorPoint = Vector2.new(0, 0.5)
    stateLabel.BackgroundTransparency = 1
    stateLabel.Text = "关"
    stateLabel.Font = Enum.Font.SourceSans
    stateLabel.TextSize = 11
    stateLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    stateLabel.TextXAlignment = Enum.TextXAlignment.Right
    stateLabel.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 22)
    track.Position = UDim2.new(1, -50, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 8)

    local state = false

    local function paint()
        if state then
            track.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
            knob.Position = UDim2.fromOffset(21, 3)
            stateLabel.Text = "开"
            stateLabel.TextColor3 = Color3.fromRGB(110, 200, 130)
        else
            track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            knob.Position = UDim2.fromOffset(3, 3)
            stateLabel.Text = "关"
            stateLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
        end
    end

    local api = {}
    function api.Set(v, silent)
        state = v and true or false
        paint()
        if not silent and onChange then onChange(state) end
    end
    api.Get = function() return state end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            api.Set(not state)
        end
    end)

    return api
end

-- ===== 普通按钮（满宽） =====
local function makeButton(parent, y, text, onClick)
    local btn = Instance.new("TextButton")
    btn.Position = UDim2.fromOffset(14, y)
    btn.Size = UDim2.new(1, -28, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(225, 225, 225)
    btn.Parent = parent
    corner(btn, 6)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    end)
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick() end
    end)
    return btn
end

-- ===== 下拉选择框 =====
local function makeModeDropdown(parent, y, options, initial, onPick)
    local labelMap = {}
    for _, o in ipairs(options) do labelMap[o.value] = o.label end

    local box = Instance.new("Frame")
    box.Position = UDim2.fromOffset(14, y)
    box.Size = UDim2.new(1, -28, 0, 36)
    box.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    box.BorderSizePixel = 0
    box.ClipsDescendants = true
    box.ZIndex = 4
    box.Parent = parent
    corner(box, 6)

    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 36)
    head.BackgroundTransparency = 1
    head.AutoButtonColor = false
    head.Text = "贴地方式：" .. (labelMap[initial] or initial)
    head.Font = Enum.Font.SourceSans
    head.TextSize = 12
    head.TextColor3 = Color3.fromRGB(215, 215, 215)
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.ZIndex = 5
    head.Parent = box
    local hp = Instance.new("UIPadding", head)
    hp.PaddingLeft = UDim.new(0, 12)
    hp.PaddingRight = UDim.new(0, 12)

    local list = Instance.new("Frame")
    list.Position = UDim2.fromOffset(0, 36)
    list.Size = UDim2.new(1, 0, 0, 0)
    list.BackgroundTransparency = 1
    list.Visible = false
    list.ZIndex = 5
    list.Parent = box

    local ll = Instance.new("UIListLayout", list)
    ll.Padding = UDim.new(0, 3)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    local lp = Instance.new("UIPadding", list)
    lp.PaddingLeft = UDim.new(0, 6)
    lp.PaddingRight = UDim.new(0, 6)
    lp.PaddingBottom = UDim.new(0, 6)

    local open = false
    local current = initial
    local rowsH = 0

    local function closeList()
        open = false
        list.Visible = false
        box.Size = UDim2.new(1, -28, 0, 36)
    end

    local function openList()
        open = true
        list.Visible = true
        list.Size = UDim2.new(1, 0, 0, rowsH)
        box.Size = UDim2.new(1, -28, 0, 36 + rowsH)
    end

    for i, o in ipairs(options) do
        rowsH = rowsH + 3 + 30
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 30)
        item.LayoutOrder = i
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        item.BorderSizePixel = 0
        item.AutoButtonColor = false
        item.Text = o.label
        item.Font = Enum.Font.SourceSans
        item.TextSize = 12
        item.TextColor3 = Color3.fromRGB(200, 200, 200)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.ZIndex = 6
        item.Parent = list
        corner(item, 5)
        local ip = Instance.new("UIPadding", item)
        ip.PaddingLeft = UDim.new(0, 10)

        item.MouseButton1Click:Connect(function()
            current = o.value
            head.Text = "贴地方式：" .. o.label
            closeList()
            if onPick then onPick(o.value) end
        end)
    end

    head.MouseButton1Click:Connect(function()
        if open then closeList() else openList() end
    end)

    return { Get = function() return current end }
end

-- ===== 第 1 页：角色属性 =====
local FLY_SPEED = 40          -- 飞行速度（下面输入框可以改）

makeInputRow(page1, 12, "修改速度", function(v, box)
    local hum = getHumanoid()
    if not hum then return end
    if origSpeed == nil then origSpeed = hum.WalkSpeed end
    local n = math.clamp(v, 0, 500)
    hum.WalkSpeed = n
    box.Text = tostring(n)
    say("移动速度已设为 " .. n, true)
end)

makeInputRow(page1, 58, "修改跳跃力", function(v, box)
    local hum = getHumanoid()
    if not hum then return end
    if origJump == nil then
        origJump = hum.JumpPower
        origUseJumpPower = hum.UseJumpPower
    end
    local n = math.clamp(v, 0, 500)
    hum.JumpPower = n
    hum.UseJumpPower = true
    box.Text = tostring(n)
    say("跳跃力已设为 " .. n, true)
end)

makeInputRow(page1, 200, "修改飞行速度", function(v, box)
    local n = math.clamp(v, 1, 500)
    FLY_SPEED = n
    box.Text = tostring(n)
    say("飞行速度已设为 " .. n, true)
end, tostring(FLY_SPEED))

-- ===== 穿墙：只关人物碰撞，不做任何贴地 =====
local noclipOn = false
local flying = false        -- 飞行时也穿墙（每帧关碰撞）
local charCollide = {}    -- 被我关掉碰撞的人物部件
local loopConn = nil
local noclipToggle = nil
local charConn = nil

local setNoclip = nil       -- 先占位，step 里要用

-- 每帧（物理步进之前）把自己角色的部件碰撞关掉
local function disableCharCollision()
    -- 飞行时也照关，飞行=穿墙
    local char = player.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.CanCollide then
                charCollide[p] = true
                p.CanCollide = false
            end
        end
    end
end

local function restoreCharCollision()
    for part in pairs(charCollide) do
        if part.Parent then
            part.CanCollide = true
        end
    end
    charCollide = {}
end

-- 和常见 Noclip 一样：Stepped 每帧关一次，防被系统改回去
local function step()
    if not noclipOn then return end
    if not gui.Parent then      -- 窗口没了还开着穿墙？立刻收
        setNoclip(false)
        return
    end
    disableCharCollision()
end

setNoclip = function(on)
    if on then
        noclipOn = true
        disableCharCollision()
        if loopConn then loopConn:Disconnect() end
        loopConn = RunService.Stepped:Connect(step)
        say("穿墙已开启（只关人物碰撞）", true)
    else
        noclipOn = false
        if loopConn then loopConn:Disconnect(); loopConn = nil end
        restoreCharCollision()
        say("穿墙已关闭（人物碰撞已恢复）", nil)
    end
end

noclipToggle = makeToggle(page1, 104, "穿墙", function(state)
    setNoclip(state)
end)

-- 重生后重新关一次人物碰撞（新角色是新模型）
player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    if noclipOn and not flying then
        task.wait(0.2)
        disableCharCollision()
    end
end)

-- ===== 飞行：朝向跟着镜头，摇杆按镜头方向推 =====
local FLY_ALT = 2.5           -- 开启后只抬这么高，让脚离地就行
local FLY_UP_SPEED = 8        -- 抬脚离地时的上升速度
local FLY_PROBE = 2.2         -- 往前探多少格判断“要撞上了”
local flyLifted = false       -- 起飞抬升是否已经完成（只抬一次）
local flyBlockUntil = 0       -- 撞墙后的短暂停住，避免每帧抖动

local flyConn = nil
local controlsObj = nil
local flyBaseY = nil

-- 飞行时把动画系统整个摘掉：四肢僵住、伸直，一点动画都不播
local flyAnimator = nil

local function freezeBody(hum)
    if not hum then return end
    local char = hum.Parent
    if not char then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        pcall(function()
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
        end)
        flyAnimator = animator
        animator.Parent = nil          -- 摘掉动画器
    end
    -- 骨骼归到默认姿势，人就是直挺挺站着的形状，然后彻底不动
    for _, m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") then
            pcall(function() m.Transform = CFrame.new() end)
        end
    end
end

local function thawBody(hum)
    if flyAnimator and hum then
        flyAnimator.Parent = hum
    end
    flyAnimator = nil
end

-- 专门给飞行用的射线：只认“真的有碰撞”的部件，和物理判定一致
local flyRay = nil
do
    local ok, p = pcall(function()
        local rp = RaycastParams.new()
        local okType = pcall(function() rp.FilterType = Enum.RaycastFilterType.Exclude end)
        if not okType then rp.FilterType = Enum.RaycastFilterType.Blacklist end
        pcall(function() rp.RespectCanCollide = true end)
        return rp
    end)
    if ok then flyRay = p end
end

-- 拿官方的移动摇杆向量（X 左右，Z 前后，-1 是往前推）
local function getMoveVector()
    if not controlsObj then
        local ps = player:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if pm then
            local ok, mod = pcall(require, pm)
            if ok and mod then
                local ok2, c = pcall(function() return mod:GetControls() end)
                if ok2 then controlsObj = c end
            end
        end
    end
    if controlsObj then
        local ok, mv = pcall(function() return controlsObj:GetMoveVector() end)
        if ok and mv then return mv end
    end
    return Vector3.new(0, 0, 0)
end

-- 用 LinearVelocity 吊着人（Y 也给速度才能真正升空），转向用 AlignOrientation
local flyAtt = nil
local flyLV = nil
local flyAO = nil

local function buildFlyBody(root)
    if flyLV then flyLV:Destroy(); flyLV = nil end
    if flyAO then flyAO:Destroy(); flyAO = nil end
    if flyAtt then flyAtt:Destroy(); flyAtt = nil end
    if not root then return end

    flyAtt = Instance.new("Attachment")
    flyAtt.Name = "飞行"
    flyAtt.Parent = root

    flyLV = Instance.new("LinearVelocity")
    flyLV.Attachment0 = flyAtt
    flyLV.MaxForce = 50000
    flyLV.RelativeTo = Enum.ActuatorRelativeTo.World
    flyLV.VectorVelocity = Vector3.new(0, 0, 0)
    flyLV.Parent = root

    -- 转向约束：不去每帧写 CFrame（写 CFrame 会把速度清掉，人就原地不动）
    local ok, ao = pcall(function()
        local a = Instance.new("AlignOrientation")
        a.Attachment0 = flyAtt
        a.Mode = Enum.OrientationAlignmentMode.OneAttachment
        a.MaxTorque = 50000
        a.RigidityEnabled = true
        a.Parent = root
        return a
    end)
    if ok then flyAO = ao end
end

local setFly = nil          -- 先占位，flyStep 里要用

local function flyStep()
    if not flying then return end
    if not gui.Parent then      -- 窗口没了还飞着？立刻收
        setFly(false)
        return
    end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return end

    -- 飞行时照样穿墙：每帧把碰撞关掉
    disableCharCollision()

    -- 关掉 Humanoid 的自动转向，否则它会按摇杆方向拧人
    if hum then hum.AutoRotate = false end
    if hum and hum:FindFirstChildOfClass("Animator") then freezeBody(hum) end

    -- 角色重生或约束被清掉时补回来
    if not flyLV or not flyLV.Parent or not flyAtt or not flyAtt.Parent then
        buildFlyBody(root)
    end

    local mv = getMoveVector()
    -- 摇杆死区，静止时不要飘
    local mx, mz = mv.X, mv.Z
    if math.abs(mx) < 0.12 then mx = 0 end
    if math.abs(mz) < 0.12 then mz = 0 end

    local cam = workspace.CurrentCamera
    local look = nil        -- 完整朝向（含上下俯仰）
    local rightH = nil      -- 右方向，只取水平
    if cam then
        local cl = cam.CFrame.LookVector
        if Vector3.new(cl.X, cl.Y, cl.Z).Magnitude > 0.01 then
            look = cl.Unit
            local h = Vector3.new(cl.X, 0, cl.Z)
            if h.Magnitude > 0.01 then
                rightH = Vector3.new(-h.Unit.Z, 0, h.Unit.X)
            end
        end
    end
    if not look then
        look = root.CFrame.LookVector
        local h = Vector3.new(look.X, 0, look.Z)
        if h.Magnitude > 0.01 then
            rightH = Vector3.new(-h.Unit.Z, 0, h.Unit.X)
        else
            rightH = Vector3.new(1, 0, 0)
        end
    end

    -- 前推沿镜头指的完整方向（镜头抬 45°就真的往上 45°飞），左右只平移
    local dir = look * (-mz) + rightH * mx
    if dir.Magnitude > 1 then dir = dir.Unit end

    -- 起飞抬升只做一次：抬到脚离地就永久结束，之后上下完全听摇杆+镜头
    local yVel = dir.Y * FLY_SPEED
    if not flyLifted then
        local targetY = (flyBaseY or root.Position.Y) + FLY_ALT
        if root.Position.Y < targetY - 0.3 then
            yVel = math.max(yVel, FLY_UP_SPEED)
        else
            flyLifted = true
        end
    end

    local vx = dir.X * FLY_SPEED
    local vz = dir.Z * FLY_SPEED

    -- 不再探墙、不再停：飞行时墙随便穿

    -- 转向：目标直接取相机的完整朝向（含俯仰），所以抬头镜头人也会仰起来
    if flyAO and cam then
        pcall(function()
            local cc = cam.CFrame
            flyAO.CFrame = CFrame.new(0, 0, 0) * (cc - cc.Position)
        end)
    end

    if flyLV then
        flyLV.VectorVelocity = Vector3.new(vx, yVel, vz)
    end
end

setFly = function(on)
    if on then
        flying = true
        -- 飞行也能穿墙：碰撞继续关着
        disableCharCollision()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        flyBaseY = root and root.Position.Y or nil
        flyLifted = false
        flyBlockUntil = 0
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
        freezeBody(hum)
        buildFlyBody(root)
        if flyConn then flyConn:Disconnect() end
        flyConn = RunService.Heartbeat:Connect(flyStep)
        say("飞行已开启（速度 " .. FLY_SPEED .. "，人物朝向跟镜头）", true)
    else
        flying = false
        flyBaseY = nil
        flyLifted = false
        flyBlockUntil = 0
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyLV then flyLV:Destroy(); flyLV = nil end
        if flyAO then flyAO:Destroy(); flyAO = nil end
        if flyAtt then flyAtt:Destroy(); flyAtt = nil end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
        thawBody(hum)
        if noclipOn then
            disableCharCollision()
        else
            restoreCharCollision()
        end
        say("飞行已关闭", nil)
    end
end

local flyToggle = makeToggle(page1, 148, "飞行", function(state)
    setFly(state)
end)

-- ===== 屏幕点选：手机没有准心，直接点哪块就选哪块 =====
local picking = nil     -- nil / "mark"（变无碰撞）/ "size"（读尺寸）
local pickBtn = nil
local sizeBtn = nil
local setPicking = nil

local function inWin(pos)
    local ap, as = win.AbsolutePosition, win.AbsoluteSize
    return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

local function partAt(pos)
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local ray = cam:ScreenPointToRay(pos.X, pos.Y)
    rayP.FilterDescendantsInstances = { player.Character }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 800, rayP)
    local inst = hit and hit.Instance
    if inst and inst:IsA("BasePart") and not inst:IsA("Terrain") then
        return inst
    end
    return nil
end

-- ===== 第 2 页：点方块 → 变无碰撞，并列进列表 =====
local marked = {}        -- part -> 这一行的 Frame
local markedCount = 0
local viewMode = "box"   -- box / line 连线
local viewObj = nil

local function clearView()
    if viewObj then
        viewObj:Destroy()
        viewObj = nil
    end
end

local function viewPart(part)
    if not part or not part.Parent then
        clearView()
        return
    end
    clearView()

    if viewMode == "box" then
        local box = Instance.new("SelectionBox")
        box.Adornee = part
        box.Color3 = Color3.fromRGB(90, 190, 255)
        box.LineThickness = 0.18
        box.SurfaceTransparency = 0.15
        box.Parent = workspace
        viewObj = box
    else
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            say("找不到人物位置，拉不了线", false)
            return
        end
        local a = root.Position
        local b = part.Position
        local len = (b - a).Magnitude
        if len < 0.2 then return end
        local line = Instance.new("Part")
        line.Name = "查看连线"
        line.Anchored = true
        line.CanCollide = false
        line.CanQuery = false
        line.CanTouch = false
        line.Material = Enum.Material.Neon
        line.Color = Color3.fromRGB(90, 190, 255)
        line.Transparency = 0.3
        line.Size = Vector3.new(0.25, 0.25, len)
        line.CFrame = CFrame.lookAt((a + b) / 2, b)
        line.Parent = workspace
        viewObj = line
    end

    local mine = viewObj
    task.delay(4, function()
        if viewObj == mine then clearView() end
    end)
end

pickBtn = Instance.new("TextButton")
pickBtn.Position = UDim2.fromOffset(14, 8)
pickBtn.Size = UDim2.new(1, -28, 0, 36)
pickBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
pickBtn.BorderSizePixel = 0
pickBtn.AutoButtonColor = false
pickBtn.Text = "点我开始选方块（变无碰撞）"
pickBtn.Font = Enum.Font.SourceSansBold
pickBtn.TextSize = 12
pickBtn.TextColor3 = Color3.fromRGB(225, 225, 225)
pickBtn.Parent = page2
corner(pickBtn, 6)

local viewToggle = Instance.new("TextButton")
viewToggle.Position = UDim2.fromOffset(14, 52)
viewToggle.Size = UDim2.fromOffset(146, 28)
viewToggle.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
viewToggle.BorderSizePixel = 0
viewToggle.AutoButtonColor = false
viewToggle.Text = "查看方式：高亮"
viewToggle.Font = Enum.Font.SourceSansBold
viewToggle.TextSize = 11
viewToggle.TextColor3 = Color3.fromRGB(215, 215, 215)
viewToggle.Parent = page2
corner(viewToggle, 6)

local restoreBtn = Instance.new("TextButton")
restoreBtn.Position = UDim2.new(1, -160, 0, 52)
restoreBtn.Size = UDim2.fromOffset(146, 28)
restoreBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
restoreBtn.BorderSizePixel = 0
restoreBtn.AutoButtonColor = false
restoreBtn.Text = "全部恢复"
restoreBtn.Font = Enum.Font.SourceSansBold
restoreBtn.TextSize = 11
restoreBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
restoreBtn.Parent = page2
corner(restoreBtn, 6)

local listBox = Instance.new("ScrollingFrame")
listBox.Position = UDim2.fromOffset(14, 92)
listBox.Size = UDim2.new(1, -28, 1, -122)
listBox.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
listBox.BorderSizePixel = 0
listBox.ScrollBarThickness = 4
listBox.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
listBox.CanvasSize = UDim2.new(0, 0, 0, 0)
listBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
listBox.ScrollingDirection = Enum.ScrollingDirection.Y
listBox.Parent = page2
corner(listBox, 6)

local listLayout = Instance.new("UIListLayout", listBox)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
local listPad = Instance.new("UIPadding", listBox)
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 4)
listPad.PaddingTop = UDim.new(0, 4)

local function addRow(part)
    markedCount = markedCount + 1
    local index = markedCount

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.LayoutOrder = index
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    row.BorderSizePixel = 0
    row.Parent = listBox

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -66, 1, 0)
    name.Position = UDim2.fromOffset(8, 0)
    name.BackgroundTransparency = 1
    name.Text = string.format("#%d  %s  %.1f×%.1f×%.1f", index, part.Name, part.Size.X, part.Size.Y, part.Size.Z)
    name.Font = Enum.Font.SourceSans
    name.TextSize = 10
    name.TextColor3 = Color3.fromRGB(200, 200, 200)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = row

    local view = Instance.new("TextButton")
    view.Size = UDim2.fromOffset(50, 22)
    view.Position = UDim2.new(1, -54, 0.5, -11)
    view.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    view.BorderSizePixel = 0
    view.AutoButtonColor = false
    view.Text = "查看"
    view.Font = Enum.Font.SourceSansBold
    view.TextSize = 10
    view.TextColor3 = Color3.fromRGB(210, 210, 210)
    view.Parent = row
    corner(view, 4)

    view.MouseButton1Click:Connect(function()
        if part.Parent then
            viewPart(part)
            say("已定位 #" .. index .. "，看屏幕上高亮的地方", true)
        else
            say("这块已经被删掉了", false)
        end
    end)

    marked[part] = row
end

local function markPart(part)
    if marked[part] then
        say("这块已经在列表里了", nil)
        return
    end
    if not part.CanCollide then
        say("这块本来就是无碰撞的", nil)
        return
    end
    part.CanCollide = false
    addRow(part)
    say("已加入列表，现在是第 " .. markedCount .. " 块", true)
end

viewToggle.MouseButton1Click:Connect(function()
    if viewMode == "box" then
        viewMode = "line"
        viewToggle.Text = "查看方式：连线"
    else
        viewMode = "box"
        viewToggle.Text = "查看方式：高亮"
    end
end)

restoreBtn.MouseButton1Click:Connect(function()
    local n = 0
    for part, row in pairs(marked) do
        if part.Parent then
            part.CanCollide = true
            n = n + 1
        end
        if row then row:Destroy() end
    end
    marked = {}
    markedCount = 0
    clearView()
    say("已恢复 " .. n .. " 块", nil)
end)

-- ===== 第 3 页：点方块读长宽高 =====
local lastSizePart = nil

local sizeInfo = Instance.new("TextLabel")
sizeInfo.Position = UDim2.fromOffset(14, 54)
sizeInfo.Size = UDim2.new(1, -28, 1, -80)
sizeInfo.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
sizeInfo.BorderSizePixel = 0
sizeInfo.Text = "还没选方块。\n点上面的按钮，然后去窗口外面点一块方块。"
sizeInfo.Font = Enum.Font.SourceSans
sizeInfo.TextSize = 12
sizeInfo.TextColor3 = Color3.fromRGB(190, 190, 190)
sizeInfo.TextWrapped = true
sizeInfo.TextXAlignment = Enum.TextXAlignment.Left
sizeInfo.TextYAlignment = Enum.TextYAlignment.Top
sizeInfo.Parent = page3
corner(sizeInfo, 6)
local infoPad = Instance.new("UIPadding", sizeInfo)
infoPad.PaddingLeft = UDim.new(0, 10)
infoPad.PaddingTop = UDim.new(0, 8)

sizeBtn = Instance.new("TextButton")
sizeBtn.Position = UDim2.fromOffset(14, 8)
sizeBtn.Size = UDim2.new(1, -28, 0, 36)
sizeBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
sizeBtn.BorderSizePixel = 0
sizeBtn.AutoButtonColor = false
sizeBtn.Text = "点我选一块方块（读长宽高）"
sizeBtn.Font = Enum.Font.SourceSansBold
sizeBtn.TextSize = 12
sizeBtn.TextColor3 = Color3.fromRGB(225, 225, 225)
sizeBtn.Parent = page3
corner(sizeBtn, 6)

local function showSize(part)
    lastSizePart = part
    local s = part.Size
    sizeInfo.Text = string.format(
        "名称：%s\n\n长（X）：%.2f\n宽（Z）：%.2f\n高（Y）：%.2f",
        part.Name, s.X, s.Z, s.Y
    )
    say("读到了：" .. part.Name, true)
end

-- ===== 第 4 页：空 =====

-- ===== 第 5 页：高亮 ESP（高亮 + 名字 + 血量 + 距离）=====
local espPage = emptyPages[1]

local espOn = false
local espTracks = {}
local espLast = 0
local espToggle = nil
local espStat = nil
local espUpdate = nil

local function espClear()
    for char, rec in pairs(espTracks) do
        if rec.highlight then
            pcall(function() rec.highlight:Destroy() end)
        end
        if rec.billboard then
            pcall(function() rec.billboard:Destroy() end)
        end
    end
    espTracks = {}
end

local function espAdd(char, head, hum)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = Color3.fromRGB(0, 170, 255)
    hl.FillTransparency = 0.45
    hl.OutlineColor = Color3.fromRGB(0, 225, 255)
    hl.OutlineTransparency = 0
    pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Tag"
    bb.Size = UDim2.fromOffset(180, 56)
    bb.StudsOffset = Vector3.new(0, 2.6, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 600
    bb.Adornee = head
    bb.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.3
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = bb

    espTracks[char] = { highlight = hl, billboard = bb, label = label }
end

espUpdate = function()
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    -- 清掉已经没了的角色
    for char, rec in pairs(espTracks) do
        if not char.Parent or not char:FindFirstChildOfClass("Humanoid") then
            if rec.highlight then pcall(function() rec.highlight:Destroy() end) end
            if rec.billboard then pcall(function() rec.billboard:Destroy() end) end
            espTracks[char] = nil
        end
    end

    -- 新增角色（顶层模型 + 所有玩家角色）
    local seen = {}
    local function consider(m)
        if seen[m] then return end
        seen[m] = true
        if espTracks[m] then return end
        local hum = m:FindFirstChildOfClass("Humanoid")
        local head = m:FindFirstChild("Head")
        if hum and head then
            espAdd(m, head, hum)
        end
    end

    for _, c in ipairs(workspace:GetChildren()) do
        if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then
            consider(c)
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            consider(plr.Character)
        end
    end

    -- 刷新文字：名字 / 血量 / 距离 studs
    local counted = 0
    for char, rec in pairs(espTracks) do
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if hum and rec.label and root then
            counted = counted + 1
            local nm = hum.DisplayName
            if not nm or nm == "" then nm = char.Name end
            local hp = math.max(0, math.floor(hum.Health))
            local maxhp = math.max(1, math.floor(hum.MaxHealth))
            local dist = math.floor((root.Position - myPos).Magnitude)
            rec.label.Text = nm .. "\n" .. hp .. "/" .. maxhp .. "\n" .. dist .. " studs"

            local ratio = hp / maxhp
            if ratio > 0.6 then
                rec.label.TextColor3 = Color3.fromRGB(120, 240, 150)
            elseif ratio > 0.3 then
                rec.label.TextColor3 = Color3.fromRGB(255, 220, 110)
            else
                rec.label.TextColor3 = Color3.fromRGB(255, 110, 110)
            end
        end
    end

    if espStat then
        espStat.Text = "已标记 " .. counted .. " 个角色"
    end
end

espToggle = makeToggle(espPage, 12, "高亮 ESP", function(state)
    espOn = state
    if espOn then
        if espUpdate then espUpdate() end
    else
        espClear()
        if espStat then espStat.Text = "已关闭" end
    end
end)

espStat = Instance.new("TextLabel")
espStat.Position = UDim2.fromOffset(14, 68)
espStat.Size = UDim2.new(1, -28, 0, 18)
espStat.BackgroundTransparency = 1
espStat.Text = "已关闭"
espStat.Font = Enum.Font.SourceSans
espStat.TextSize = 11
espStat.TextColor3 = Color3.fromRGB(140, 140, 140)
espStat.TextXAlignment = Enum.TextXAlignment.Left
espStat.Parent = espPage

local espHint = Instance.new("TextLabel")
espHint.Position = UDim2.fromOffset(14, 92)
espHint.Size = UDim2.new(1, -28, 0, 46)
espHint.BackgroundTransparency = 1
espHint.Text = "高亮所有人形模型，头顶显示名字、血量、离你多少 studs。每 0.25 秒刷新一次；死亡、退出、重生的角色会自动处理。"
espHint.Font = Enum.Font.SourceSans
espHint.TextSize = 10
espHint.TextColor3 = Color3.fromRGB(120, 120, 120)
espHint.TextWrapped = true
espHint.TextXAlignment = Enum.TextXAlignment.Left
espHint.TextYAlignment = Enum.TextYAlignment.Top
espHint.Parent = espPage

RunService.Heartbeat:Connect(function()
    if not espOn then return end
    local now = os.clock()
    if now - espLast < 0.25 then return end
    espLast = now
    if espUpdate then espUpdate() end
end)


setPicking = function(mode, quiet)
    picking = mode
    if pickBtn then
        pickBtn.Text = (mode == "mark") and "点窗口外任意方块（点这里取消）" or "点我开始选方块（变无碰撞）"
    end
    if sizeBtn then
        sizeBtn.Text = (mode == "size") and "点窗口外任意方块（点这里取消）" or "点我选一块方块（读长宽高）"
    end
    if not quiet then
        if mode then
            say("去窗口外面点一下你想选的那块方块", true)
        else
            say("已取消选择", nil)
        end
    end
end

pickBtn.MouseButton1Click:Connect(function()
    if picking == "mark" then
        setPicking(nil)
    else
        setPicking("mark")
    end
end)

cancelPick = function()
    if picking then setPicking(nil, true) end
end

sizeBtn.MouseButton1Click:Connect(function()
    if picking == "size" then
        setPicking(nil)
    else
        setPicking("size")
    end
end)

UIS.InputBegan:Connect(function(input)
    if not picking then return end
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end

    local pos = input.Position
    if inWin(pos) then return end   -- 点在窗口自己身上，交给窗口里的按钮

    local part = partAt(pos)
    if not part then
        say("这里没点到方块，换个位置再点", false)
        return
    end

    if picking == "mark" then
        markPart(part)
    else
        showSize(part)
    end
    setPicking(nil, true)
end)
setPage(1)

-- ===== 拖动：标题栏按下即跟手，全屏跟随，按位移增量累加 =====
local dragging = false
local dragInput = nil
local dragTouch = nil
local lastPos = nil
local DRAG_MAX_DELTA = 150   -- 单帧异常跳变忽略

-- 把位置统一成纯 Offset：Scale 参与累加会漂
local function normalizePos()
    local ap = win.AbsolutePosition
    local as = win.AbsoluteSize
    win.Position = UDim2.fromOffset(
        ap.X + as.X * win.AnchorPoint.X,
        ap.Y + as.Y * win.AnchorPoint.Y
    )
end

local function beginDrag(input)
    if dragging then return end
    dragging = true
    dragInput = input
    dragTouch = (input.UserInputType == Enum.UserInputType.Touch) and input or nil
    lastPos = input.Position
    normalizePos()
end

local function endDrag()
    dragging = false
    dragInput = nil
    dragTouch = nil
    lastPos = nil
end

local function moveDrag(dx, dy)
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local as = win.AbsoluteSize
    local ax, ay = win.AnchorPoint.X, win.AnchorPoint.Y
    local x = math.clamp(win.Position.X.Offset + dx, as.X * ax, math.max(as.X * ax, vp.X - as.X * (1 - ax)))
    local y = math.clamp(win.Position.Y.Offset + dy, as.Y * ay, math.max(as.Y * ay, vp.Y - as.Y * (1 - ay)))
    win.Position = UDim2.fromOffset(x, y)
end

titleBar.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end

    local t = input.UserInputType
    if t == Enum.UserInputType.Touch then
        if input ~= dragTouch then return end
    elseif t == Enum.UserInputType.MouseMovement then
        if not dragInput or dragInput.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    else
        return
    end

    local d = input.Delta
    if d.Magnitude <= 0 then
        if not lastPos then return end
        d = input.Position - lastPos
    end
    lastPos = input.Position
    if d.Magnitude <= 0 or d.Magnitude > DRAG_MAX_DELTA then return end

    moveDrag(d.X, d.Y)
end)

UIS.InputEnded:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 then
        endDrag()
    elseif t == Enum.UserInputType.Touch and input == dragTouch then
        endDrag()
    end
end)

-- ===== 关窗口：穿墙、飞行、速度、跳跃力、点选全部复位 =====
Cleanup.run = function()
    if Cleanup.done then return end
    Cleanup.done = true

    pcall(function()
        if flying and setFly then setFly(false) end
    end)
    pcall(function()
        if noclipOn and setNoclip then setNoclip(false) end
    end)
    pcall(function()
        local hum = getHumanoid()
        if hum then
            if origSpeed ~= nil then hum.WalkSpeed = origSpeed end
            if origJump ~= nil then
                hum.JumpPower = origJump
                if origUseJumpPower ~= nil then
                    hum.UseJumpPower = origUseJumpPower
                end
            end
        end
    end)
    pcall(function()
        if setPicking then setPicking(nil, true) end
    end)
    pcall(function() clearView() end)
    pcall(function() espOn = false; espClear() end)
    FLY_SPEED = 40
end
