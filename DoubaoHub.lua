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

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

-- 窗口登场：先缩到 0.86，再用 0.68 秒慢慢展开到正常大小
local winScale = Instance.new("UIScale")
winScale.Scale = 0.86
winScale.Parent = win
task.delay(0.03, function()
    TweenService:Create(winScale,
        TweenInfo.new(0.68, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Scale = 1 }):Play()
end)

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
title.Size = UDim2.new(1, -105, 1, 0)
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

-- ===== 最小化按钮（× 左边）=====
local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(28, 28)
mini.Position = UDim2.new(1, -70, 0.5, 0)
mini.AnchorPoint = Vector2.new(0, 0.5)
mini.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mini.BorderSizePixel = 0
mini.AutoButtonColor = false
mini.Text = "-"
mini.Font = Enum.Font.SourceSansBold
mini.TextSize = 16
mini.TextColor3 = Color3.fromRGB(160, 160, 160)
mini.Parent = titleBar
corner(mini, 6)

mini.MouseEnter:Connect(function()
    mini.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mini.TextColor3 = Color3.fromRGB(230, 230, 230)
end)
mini.MouseLeave:Connect(function()
    mini.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mini.TextColor3 = Color3.fromRGB(160, 160, 160)
end)

local minimized = false
local FULL_SIZE = UDim2.fromOffset(460, 330)
local MINI_SIZE = UDim2.fromOffset(128, 32)

-- 最小化 / 展开的过渡：只加动画，尺寸、位置数值跟以前一模一样
local T_MINI = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local minTweens = {}

local function tweenTo(obj, goal)
    local old = minTweens[obj]
    if old then pcall(function() old:Cancel() end) end
    local tw = TweenService:Create(obj, T_MINI, goal)
    minTweens[obj] = tw
    tw:Play()
end

local function applyMinimize()
    if minimized then
        title.TextXAlignment = Enum.TextXAlignment.Right
        title.TextSize = 13
        close.Visible = false
        mini.TextSize = 13
        tweenTo(win, {
            Size = MINI_SIZE,
            Position = UDim2.new(win.Position.X.Scale, win.Position.X.Offset, win.Position.Y.Scale, win.Position.Y.Offset - 149),
        })
        tweenTo(titleBar, { Size = UDim2.new(1, -2, 0, 32) })
        tweenTo(title, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -46, 1, 0) })
        tweenTo(mini, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -26, 0.5, 0) })
    else
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextSize = 15
        close.Visible = true
        mini.TextSize = 16
        tweenTo(win, {
            Size = FULL_SIZE,
            Position = UDim2.new(win.Position.X.Scale, win.Position.X.Offset, win.Position.Y.Scale, win.Position.Y.Offset + 149),
        })
        tweenTo(titleBar, { Size = UDim2.new(1, -2, 0, 42) })
        tweenTo(title, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -105, 1, 0) })
        tweenTo(mini, { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -70, 0.5, 0) })
    end
end

local miniLast = 0
local function toggleMini()
    local now = os.clock()
    if now - miniLast < 0.55 then return end
    miniLast = now
    minimized = not minimized
    applyMinimize()
end

mini.MouseButton1Click:Connect(toggleMini)
pcall(function() mini.Activated:Connect(toggleMini) end)

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

local page1 = Instance.new("ScrollingFrame")
page1.Size = UDim2.new(1, 0, 1, -26)
page1.BackgroundTransparency = 1
page1.BorderSizePixel = 0
page1.ScrollBarThickness = 6
page1.ScrollBarImageColor3 = Color3.fromRGB(74, 78, 90)
page1.ScrollBarImageTransparency = 0.15
page1.CanvasSize = UDim2.fromOffset(0, 0)
page1.AutomaticCanvasSize = Enum.AutomaticSize.Y
page1.ScrollingDirection = Enum.ScrollingDirection.Y
page1.Parent = pages

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
local pagesList = { page1, page3, page4 }
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
makeCategory("方块尺寸", 2, 2)
makeCategory("高亮 ESP", 3, 3)
makeCategory("空4", 4, 4)
makeCategory("瞬移点", 5, 5)
for i = 6, 9 do
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

-- ===== 开关行（整行版 / 半宽版共用这一套实现）=====
-- 颜色、滑块、"开/关"文字完全一致；只有轨道和字号按宽窄缩一档
local T_TOGGLE = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function buildToggle(parent, x, y, w, labelText, onChange)
    local compact = (w ~= nil)
    local trackW = compact and 34 or 40
    local trackH = compact and 20 or 22
    local knobS  = compact and 14 or 16
    local fontS  = compact and 11 or 13
    local stateW = compact and 26 or 34
    local gapR   = compact and 6 or 10      -- 轨道离右边缘
    local gapM   = compact and 4 or 10      -- "开/关"字与轨道之间
    local labelR = gapR + trackW + gapM + stateW + (compact and 6 or 8)
    local padL   = compact and 10 or 12
    local knobY  = (trackH - knobS) / 2
    local OFF_BG = Color3.fromRGB(64, 64, 68)      -- 关闭态底色（比原来的 40,40,40 亮一档）
    local ON_BG  = Color3.fromRGB(60, 140, 255)    -- 开启态蓝色（保持原样）

    local row = Instance.new("Frame")
    row.Position = UDim2.fromOffset(x, y)
    row.Size = compact and UDim2.fromOffset(w, 44) or UDim2.new(1, -28, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -labelR, 1, 0)
    label.Position = UDim2.fromOffset(padL, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = fontS
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Size = UDim2.fromOffset(stateW, 18)
    stateLabel.Position = UDim2.new(1, -(gapR + trackW + gapM + stateW), 0.5, 0)
    stateLabel.AnchorPoint = Vector2.new(0, 0.5)
    stateLabel.BackgroundTransparency = 1
    stateLabel.Text = "关"
    stateLabel.Font = Enum.Font.SourceSans
    stateLabel.TextSize = 11
    stateLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    stateLabel.TextXAlignment = Enum.TextXAlignment.Right
    stateLabel.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(trackW, trackH)
    track.Position = UDim2.new(1, -(gapR + trackW), 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = OFF_BG
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, trackH / 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(knobS, knobS)
    knob.Position = UDim2.fromOffset(3, knobY)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, knobS / 2)

    -- 透明按钮盖住整行：点文字、点空白都能切换，手机上也一样
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = row

    local state = false
    local api = {}
    local posTween, colTween = nil, nil

    -- 开关是滑过去 + 颜色淡过去的，不是硬跳
    function api.Set(v, silent)
        state = (v == true)
        if state then
            stateLabel.Text = "开"
            stateLabel.TextColor3 = Color3.fromRGB(110, 200, 130)
        else
            stateLabel.Text = "关"
            stateLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
        end

        local goalX = state and (trackW - knobS - 3) or 3
        if posTween then pcall(function() posTween:Cancel() end) end
        posTween = TweenService:Create(knob, T_TOGGLE, { Position = UDim2.fromOffset(goalX, knobY) })
        posTween:Play()

        if colTween then pcall(function() colTween:Cancel() end) end
        colTween = TweenService:Create(track, T_TOGGLE, { BackgroundColor3 = state and ON_BG or OFF_BG })
        colTween:Play()

        if not silent and onChange then onChange(state) end
    end

    function api.Get()
        return state
    end

    hit.MouseButton1Click:Connect(function() api.Set(not state) end)
    return api
end

-- 整行版：默认 14 左边距、满宽
local function makeToggle(parent, y, labelText, onChange)
    return buildToggle(parent, 14, y, nil, labelText, onChange)
end

-- 半宽版：指定 x、宽度（ESP 页一行两个）
local function makeToggleAt(parent, x, y, w, labelText, onChange)
    return buildToggle(parent, x, y, w, labelText, onChange)
end

-- ===== 勾选框行（ESP 页用，方框里打勾的那种）=====
local CHK_OFF = Color3.fromRGB(64, 64, 68)
local CHK_ON  = Color3.fromRGB(60, 140, 255)
local CHK_BORDER_OFF = Color3.fromRGB(90, 94, 104)
local CHK_BORDER_ON  = Color3.fromRGB(120, 190, 255)

local function makeCheckRow(parent, x, y, w, labelText, onChange)
    local row = Instance.new("Frame")
    row.Position = UDim2.fromOffset(x, y)
    row.Size = w and UDim2.fromOffset(w, 44) or UDim2.new(1, -28, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(18, 18)
    box.Position = UDim2.fromOffset(10, 13)
    box.BackgroundColor3 = CHK_OFF
    box.BorderSizePixel = 0
    box.Parent = row
    corner(box, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = CHK_BORDER_OFF
    stroke.Transparency = 0
    stroke.Parent = box

    local tick = Instance.new("TextLabel")
    tick.Size = UDim2.fromScale(1, 1)
    tick.BackgroundTransparency = 1
    tick.Text = "✓"
    tick.Font = Enum.Font.SourceSansBold
    tick.TextSize = 13
    tick.TextColor3 = Color3.fromRGB(255, 255, 255)
    tick.TextYAlignment = Enum.TextYAlignment.Center
    tick.Visible = false
    tick.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -46, 1, 0)
    label.Position = UDim2.fromOffset(36, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 11
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = row

    local state = false
    local api = {}
    local colorTween = nil

    function api.Set(v, silent)
        state = (v == true)
        tick.Visible = state
        if colorTween then pcall(function() colorTween:Cancel() end) end
        colorTween = TweenService:Create(box, T_TOGGLE, { BackgroundColor3 = state and CHK_ON or CHK_OFF })
        colorTween:Play()
        stroke.Color = state and CHK_BORDER_ON or CHK_BORDER_OFF
        if not silent and onChange then onChange(state) end
    end

    function api.Get()
        return state
    end

    hit.MouseButton1Click:Connect(function() api.Set(not state) end)
    return api
end

-- ===== 单选框组：一组里只能选一个 =====
-- 用法：local g = makeRadioGroup(pageX, 14, 12, 303, {"轮廓", "方框", "两者"}, 1,
--            function(index, text) ... end)
-- g.Set(2) 切换 / g.Set(2, true) 静默 / g.Get() 取当前序号
local function makeRadioGroup(parent, x, y, w, options, initial, onChange)
    local ROW_H, GAP = 44, 4
    local count = #options

    local holder = Instance.new("Frame")
    holder.Position = UDim2.fromOffset(x, y)
    holder.Size = UDim2.fromOffset(w, count * ROW_H + (count - 1) * GAP)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local items = {}
    local current = initial or 1
    local api = {}

    local function paint()
        for i, it in ipairs(items) do
            local on = (i == current)
            it.ring.BackgroundColor3 = on and CHK_ON or CHK_OFF
            it.stroke.Color = on and CHK_BORDER_ON or CHK_BORDER_OFF
            it.dot.Visible = on
        end
    end

    function api.Set(index, silent)
        index = math.floor(tonumber(index) or current)
        if index < 1 or index > count then return end
        if index == current then
            paint()
            return
        end
        current = index
        paint()
        if not silent and onChange then onChange(current, options[current]) end
    end

    function api.Get()
        return current, options[current]
    end

    for i, text in ipairs(options) do
        local row = Instance.new("Frame")
        row.Position = UDim2.fromOffset(0, (i - 1) * (ROW_H + GAP))
        row.Size = UDim2.fromOffset(w, ROW_H)
        row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        row.BorderSizePixel = 0
        row.Parent = holder
        corner(row, 6)

        local ring = Instance.new("Frame")
        ring.Size = UDim2.fromOffset(18, 18)
        ring.Position = UDim2.fromOffset(10, 13)
        ring.BackgroundColor3 = CHK_OFF
        ring.BorderSizePixel = 0
        ring.Parent = row
        corner(ring, 9)

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = CHK_BORDER_OFF
        stroke.Transparency = 0
        stroke.Parent = ring

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(8, 8)
        dot.Position = UDim2.fromOffset(5, 5)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BorderSizePixel = 0
        dot.Visible = false
        dot.Parent = ring
        corner(dot, 4)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -46, 1, 0)
        label.Position = UDim2.fromOffset(36, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(235, 235, 235)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.AutoButtonColor = false
        hit.Parent = row

        hit.MouseButton1Click:Connect(function()
            if current == i then return end
            current = i
            paint()
            if onChange then onChange(current, text) end
        end)

        items[i] = { ring = ring, stroke = stroke, dot = dot, label = label }
    end

    paint()
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
local setWalkAir = nil      -- 踏空行走，飞行时两边互斥
local walkAirToggle = nil

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
        if setWalkAir then setWalkAir(false) end   -- 飞行和踏空行走互斥
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

-- ===== 踏空行走：只补垂直速度，不碰位置、不碰朝向，所以不会打转 =====
local walkAirOn = false
local walkAirConn = nil
local walkPad = nil       -- 脚底那块透明实心板
local walkPadY = nil      -- 板的固定高度：只跟 X/Z，Y 钉死不动

local function removeWalkPad()
    if walkPad then
        pcall(function() walkPad:Destroy() end)
        walkPad = nil
    end
    -- 保险：把场景里所有残留的板都清掉
    for _, o in ipairs(workspace:GetChildren()) do
        if o.Name == "WalkAirPad" then
            pcall(function() o:Destroy() end)
        end
    end
    walkPadY = nil
end

local function footYOf(char)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    -- 优先量真实包围盒底（最准），量不到或者散架了就退回公式
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size and math.abs((cf.Position.Y - size.Y * 0.5) - root.Position.Y) < 7 then
        return cf.Position.Y - size.Y * 0.5
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hip = (hum and hum.HipHeight) or 2
    return root.Position.Y - (root.Size.Y * 0.5 + hip)
end

local function createWalkPad(y)
    removeWalkPad()
    local pad = Instance.new("Part")
    pad.Name = "WalkAirPad"
    pad.Size = Vector3.new(5, 4, 5)
    pad.Anchored = true
    pad.CanCollide = true
    pad.CanTouch = false
    pad.CanQuery = false
    pad.Transparency = 1
    pad.Material = Enum.Material.SmoothPlastic
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad.Parent = workspace
    walkPad = pad
    walkPadY = y
end

setWalkAir = function(on, quiet)
    if walkAirConn then walkAirConn:Disconnect(); walkAirConn = nil end
    walkAirOn = on and true or false
    removeWalkPad()

    if walkAirOn then
        if flying and setFly then setFly(false) end   -- 飞行先关，不然两边抢高度

        local char = player.Character
        local fy = footYOf(char)
        if fy then
            createWalkPad(fy - 2.35)
        end

        -- 开启时如果正在高速下坠：用 10 个真实帧把垂直速度刹到 0，别让一帧就穿过板
        local brakeLeft = 0
        local brakeStep = 0
        do
            local r0 = char and char:FindFirstChild("HumanoidRootPart")
            local vy0 = r0 and r0.AssemblyLinearVelocity.Y or 0
            if vy0 < -6 then
                brakeLeft = 1
                brakeStep = math.abs(vy0)
                -- 按下的这一刻就先刹一次，不等心跳
                local vv0 = r0.AssemblyLinearVelocity
                r0.AssemblyLinearVelocity = Vector3.new(vv0.X, 0, vv0.Z)
            end
        end

        local walkWasUp = false
        local walkSettle = 0
        walkAirConn = RunService.Heartbeat:Connect(function(dt)
            if flying or not walkAirOn then return end
            local c = player.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if not r then return end

            -- 板没了（重生等）就按当前脚底重建一块
            if not walkPad or not walkPad.Parent then
                local fy2 = footYOf(c)
                if not fy2 then return end
                createWalkPad(fy2 - 2.35)
            end

            local fy = footYOf(c)
            if not fy or not walkPadY then return end

            local v = r.AssemblyLinearVelocity
            local target = fy - 2.35

            -- 记下"这一跳正在往上走"
            if v.Y > 2 then
                walkWasUp = true
                walkSettle = 0
            end

            if walkWasUp and v.Y <= 0 then
                -- 到顶了：只垫这一次，而且必须真跳上去 1.5 格以上才垫
                walkWasUp = false
                if target > walkPadY + 1.5 then
                    walkPadY = target
                end
            end

            -- 比板低一截：站稳在更低的地面才降，掉落途中绝不跟
            if target < walkPadY - 1.5 then
                local hum = c:FindFirstChildOfClass("Humanoid")
                local st = hum and hum:GetState()
                if st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running then
                    walkSettle = walkSettle + (dt or 0)
                    if walkSettle > 0.35 then
                        walkPadY = target
                        walkSettle = 0
                    end
                else
                    walkSettle = 0
                end
            else
                walkSettle = 0
            end

            -- 下坠刹车：每帧抬 1/10 的原始速度，10 帧内归零（已经落到板上就不动它）
            if brakeLeft > 0 then
                brakeLeft = brakeLeft - 1
                local vv = r.AssemblyLinearVelocity
                if vv.Y < 0 then
                    local ny = math.min(0, vv.Y + brakeStep)
                    r.AssemblyLinearVelocity = Vector3.new(vv.X, ny, vv.Z)
                else
                    brakeLeft = 0
                end
            end

            -- 只有 X/Z 每帧跟人；Y 全程钉死，只在"到顶"那一下换一次
            walkPad.Position = Vector3.new(r.Position.X, walkPadY, r.Position.Z)
            -- 碰撞常开：人在板下方才关，免得撞头
            walkPad.CanCollide = (r.Position.Y >= walkPadY)
        end)
    end

    if walkAirToggle then walkAirToggle.Set(walkAirOn, true) end
    if not quiet then
        say(walkAirOn and "踏空行走已开启（脚下一块透明的板）" or "踏空行走已关闭，脚下的板已清除", walkAirOn or nil)
    end
end

-- 重生换了新角色，板要挪到新脚底下
player.CharacterAdded:Connect(function(char)
    if not walkAirOn then return end
    task.delay(0.35, function()
        if not walkAirOn then return end
        local fy = footYOf(char)
        if fy then createWalkPad(fy - 2.35) end
    end)
end)

-- ===== 点按钮弹出的小窗（里面就一个踏空行走开关） =====
local walkAirPanel = nil

local function buildWalkAirPanel()
    -- 独立小窗：不挂遮罩，直接浮在主窗外面，随便拖
    local panel = Instance.new("TextButton")
    panel.Name = "WalkAirPanel"
    panel.Size = UDim2.fromOffset(210, 104)
    local gsz = gui.AbsoluteSize
    local cam = workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(390, 720)
    local cw = (gsz.X > 100) and gsz.X or vp.X
    local ch = (gsz.Y > 100) and gsz.Y or (vp.Y - 36)
    panel.Position = UDim2.fromOffset(math.max(4, cw - 120), math.max(4, ch - 96))
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    panel.BorderSizePixel = 0
    panel.AutoButtonColor = false
    panel.Text = ""
    panel.ZIndex = 21
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 8)

    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = Color3.fromRGB(62, 62, 68)
    stroke2.Thickness = 1
    stroke2.Parent = panel

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -50, 0, 26)
    t.Position = UDim2.fromOffset(14, 0)
    t.BackgroundTransparency = 1
    t.Text = "踏空行走"
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 13
    t.TextColor3 = Color3.fromRGB(235, 235, 235)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 23
    t.Parent = panel

    local xBtn = Instance.new("TextButton")
    xBtn.Size = UDim2.fromOffset(22, 22)
    xBtn.Position = UDim2.new(1, -28, 0, 2)
    xBtn.BackgroundTransparency = 1
    xBtn.BorderSizePixel = 0
    xBtn.AutoButtonColor = false
    xBtn.Text = "×"
    xBtn.Font = Enum.Font.SourceSansBold
    xBtn.TextSize = 16
    xBtn.TextColor3 = Color3.fromRGB(190, 190, 190)
    xBtn.ZIndex = 24
    xBtn.Parent = panel

    -- 标题那一横条可以拖着走，范围限制在主窗口里面
    local dragBar = Instance.new("TextButton")
    dragBar.Size = UDim2.new(1, -44, 0, 26)
    dragBar.Position = UDim2.fromOffset(0, 0)
    dragBar.BackgroundTransparency = 1
    dragBar.BorderSizePixel = 0
    dragBar.AutoButtonColor = false
    dragBar.Text = ""
    dragBar.ZIndex = 23
    dragBar.Parent = panel

    local pDrag = false
    local pDragFrom = nil
    local pCenterFrom = nil

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pDrag = true
            pDragFrom = input.Position
            local ap, as = panel.AbsolutePosition, panel.AbsoluteSize
            pCenterFrom = Vector2.new(ap.X + as.X / 2, ap.Y + as.Y / 2)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not pDrag then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end

        local d = input.Position - pDragFrom
        local cx, cy = pCenterFrom.X + d.X, pCenterFrom.Y + d.Y
        local halfW, halfH = panel.AbsoluteSize.X / 2, panel.AbsoluteSize.Y / 2
        local gp, gs = gui.AbsolutePosition, gui.AbsoluteSize
        cx = math.clamp(cx, gp.X + halfW, math.max(gp.X + halfW, gp.X + gs.X - halfW))
        cy = math.clamp(cy, gp.Y + halfH, math.max(gp.Y + halfH, gp.Y + gs.Y - halfH))
        panel.Position = UDim2.fromOffset(cx - halfW - gp.X, cy - halfH - gp.Y)
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pDrag = false
        end
    end)

    walkAirToggle = makeToggleAt(panel, 14, 36, 182, "开启踏空行走", function(state)
        setWalkAir(state)
    end)

    -- 关窗就把踏空行走一起关掉，下次打开是干净的关闭状态
    local function closePanel()
        panel.Visible = false
        setWalkAir(false, true)
        if walkAirToggle then walkAirToggle.Set(false, true) end
    end

    -- 只有右上角那个 × 能关，点遮罩空白不关
    xBtn.MouseButton1Click:Connect(closePanel)

    walkAirPanel = panel
end

buildWalkAirPanel()

-- 第 1 页底部那个按钮：点了就把小窗调出来
makeButton(page1, 254, "踏空行走", function()
    if walkAirPanel then
        setWalkAir(false, true)                    -- 打开永远是关闭态
        if walkAirToggle then walkAirToggle.Set(false, true) end
        walkAirPanel.Visible = true
    end
end)

-- ===== 屏幕点选：手机没有准心，直接点哪块就选哪块 =====
local picking = nil     -- nil / "size"（读尺寸）
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

-- ===== 第 2 页：点方块读长宽高 =====
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

-- ===== 第 3 页：高亮 ESP（2D 投影标签 + 轮廓 + 无限/NaN 血量）=====
local espPage = page4

local espOn = false         -- 轮廓高亮（Highlight），只管轮廓这一件事
local espTextOn = false     -- 头顶文字
local espBoxOn = false      -- 2D 方框，无数量上限
local espSelfOn = false     -- 是否把玩家自己也算进去
local espMute = {}          -- [player] = true 表示这个玩家的文字被禁用
local espTargets = {}      -- [char] = { label = TextLabel }
local espHl = {}           -- [char] = Highlight（受引擎 31 上限约束）
local espLastScan = 0
local espToggle = nil
local ESP_MAX_HL = 31

-- 标签不用 BillboardGui，改放 ScreenGui 里自己投影，永远不会被视口裁掉
-- 老的一份先删掉，不然脚本跑两遍会叠两个 ESP 层
local oldEsp = playerGui:FindFirstChild("ESP_Screen")
if oldEsp then oldEsp:Destroy() end

local espScreen = Instance.new("ScreenGui")
espScreen.Name = "ESP_Screen"
espScreen.IgnoreGuiInset = true
espScreen.ResetOnSpawn = false
espScreen.DisplayOrder = 5
espScreen.Enabled = false
espScreen.Parent = playerGui

-- 取模型的世界坐标（优先 HumanoidRootPart，退到 GetPivot），两处共用
local function modelWorldPos(m)
    if not m then return Vector3.new(0, 0, 0) end
    local r = m:FindFirstChild("HumanoidRootPart")
    if r then return r.Position end
    local ok, cf = pcall(function() return m:GetPivot() end)
    if ok and cf then return cf.Position end
    return Vector3.new(0, 0, 0)
end

-- 数字格式化：inf → 无限，NaN → NaN，有限值取整
local function fmtNum(v)
    if v ~= v then return "NaN" end
    if v == math.huge then return "无限" end
    if v == -math.huge then return "-无限" end
    if v >= 1e13 then return "无限" end
    return tostring(math.floor(v))
end

-- 只有 0 血及以下才红；NaN / 无限用中性色，正常血统一白色
local function hpColor(hp, maxhp)
    if hp == hp and hp <= 0 then
        return Color3.fromRGB(255, 95, 95)
    end
    if hp ~= hp or hp == math.huge or hp == -math.huge then
        return Color3.fromRGB(205, 210, 225)
    end
    -- 血量 10000 及以上：亮白
    if hp >= 10000 then
        return Color3.fromRGB(255, 255, 255)
    end
    -- 血量 1000 及以上：金橙
    if hp >= 1000 then
        return Color3.fromRGB(255, 165, 40)
    end
    -- 血量 500 及以上：玫红
    if hp >= 500 then
        return Color3.fromRGB(255, 100, 180)
    end
    -- 血量 200 及以上：紫
    if hp >= 200 then
        return Color3.fromRGB(185, 120, 255)
    end
    -- 血量 150 及以上：青
    if hp >= 150 then
        return Color3.fromRGB(80, 200, 255)
    end
    -- 血量掉到一半以下：黄
    if maxhp and maxhp == maxhp and maxhp > 0 and hp < maxhp * 0.5 then
        return Color3.fromRGB(255, 222, 80)
    end
    -- 一半以上到满血：绿
    return Color3.fromRGB(110, 240, 130)
end

-- 是不是“人形/怪物”模型：Humanoid 或有骨骼动画控制器，或带 Head 的 PrimaryPart 模型
local function isCharModel(c)
    if c:FindFirstChildOfClass("Humanoid") then return true end
    if c:FindFirstChildOfClass("AnimationController") or c:FindFirstChildOfClass("Animator") then return true end
    local head = c:FindFirstChild("Head")
    if head and head:IsA("BasePart") and c.PrimaryPart then return true end
    return false
end

-- 收集人形/怪物模型：workspace 顶层 + 往下钻三层文件夹 + 所有玩家角色
local function collectChars()
    local raw = {}
    local function walk(container, depth)
        for _, c in ipairs(container:GetChildren()) do
            if c:IsA("Model") then
                if isCharModel(c) then
                    raw[#raw + 1] = c
                end
            elseif c:IsA("Folder") and depth > 0 then
                walk(c, depth - 1)
            end
        end
    end
    walk(workspace, 3)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then raw[#raw + 1] = plr.Character end
    end
    local selfChar = nil
    if not espSelfOn then
        selfChar = player.Character
    end
    local seen, out = {}, {}
    for _, m in ipairs(raw) do
        if m ~= selfChar and not seen[m] then
            seen[m] = true
            out[#out + 1] = m
        end
    end
    return out
end

-- 标签挂在哪个世界点：优先头顶，没有 Head 就退到根部
local function charAnchor(char)
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position + Vector3.new(0, 1.05, 0)
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if root and root:IsA("BasePart") then
        return root.Position + Vector3.new(0, 2.1, 0)
    end
    -- 最后兜底：包围盒顶部，任何形状的怪物模型都能算出来
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then
        return cf.Position + Vector3.new(0, size.Y * 0.5 + 0.8, 0)
    end
    return nil
end

local function espClear()
    for _, rec in pairs(espTargets) do
        if rec.label then pcall(function() rec.label:Destroy() end) end
        if rec.box then pcall(function() rec.box:Destroy() end) end
    end
    espTargets = {}
    for _, hl in pairs(espHl) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    espHl = {}
end

-- ESP 方框用的包围盒：只统计离躯干 6 格以内的部件。
-- 角色死亡后四肢会甩出去很远，旧办法 GetBoundingBox 会把它们全框进来，
-- 框就被撑得又长又斜；限定距离后死没死都是正常大小。
local function espBoxOf(m)
    local hum = m:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or m:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
        if ok and cf and size then return cf, size end
        return nil
    end

    local rp = root.Position
    local mnX, mnY, mnZ = math.huge, math.huge, math.huge
    local mxX, mxY, mxZ = -math.huge, -math.huge, -math.huge
    local found = false

    local function addPart(p)
        if not p or not p:IsA("BasePart") then return end
        if (p.Position - rp).Magnitude > 6 then return end
        local hs = p.Size * 0.5
        if p.Position.X - hs.X < mnX then mnX = p.Position.X - hs.X end
        if p.Position.Y - hs.Y < mnY then mnY = p.Position.Y - hs.Y end
        if p.Position.Z - hs.Z < mnZ then mnZ = p.Position.Z - hs.Z end
        if p.Position.X + hs.X > mxX then mxX = p.Position.X + hs.X end
        if p.Position.Y + hs.Y > mxY then mxY = p.Position.Y + hs.Y end
        if p.Position.Z + hs.Z > mxZ then mxZ = p.Position.Z + hs.Z end
        found = true
    end

    addPart(root)
    for _, c in ipairs(m:GetChildren()) do
        addPart(c)
    end

    if not found then return nil end

    local cx = (mnX + mxX) * 0.5
    local cy = (mnY + mxY) * 0.5
    local cz = (mnZ + mxZ) * 0.5
    local sx = mxX - mnX + 0.5
    local sy = mxY - mnY + 0.35
    local sz = mxZ - mnZ + 0.5
    return CFrame.new(cx, cy, cz), Vector3.new(sx, sy, sz)
end

local function espScan()
    local chars = collectChars()
    local alive = {}
    for _, m in ipairs(chars) do
        alive[m] = true
        if not espTargets[m] then
            -- 先算体积：部件被删空的模型算不出框，给它立标签就会变成
            -- "名字悬在空白处定住"，这种直接不登记
            local okP, pcf = pcall(function() return m:GetPivot() end)
            local bcf, bsize = espBoxOf(m)
            if bcf and bsize and okP and pcf and (bsize.X + bsize.Y + bsize.Z) >= 1 then
                local lb = Instance.new("TextLabel")
                lb.Name = "ESP_Tag"
                lb.BackgroundTransparency = 1
                lb.AnchorPoint = Vector2.new(0.5, 0.5)
                lb.Size = UDim2.fromOffset(190, 58)
                lb.Font = Enum.Font.SourceSansBold
                lb.TextSize = 12
                lb.TextWrapped = true
                lb.TextColor3 = Color3.fromRGB(255, 255, 255)
                lb.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lb.TextStrokeTransparency = 0.35
                lb.Text = ""
                lb.Visible = false
                lb.Parent = espScreen

                local bx = Instance.new("Frame")
                bx.Name = "ESP_Box"
                bx.BackgroundTransparency = 1
                bx.Visible = false
                bx.ZIndex = 1
                bx.Parent = espScreen
                local bs = Instance.new("UIStroke", bx)
                bs.Thickness = 1.5
                bs.Color = Color3.fromRGB(0, 210, 255)
                bs.Transparency = 0

                local owner = nil
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character == m then
                        owner = plr
                        break
                    end
                end

                local rec = {
                    label = lb, box = bx, stroke = bs, player = owner,
                    size = bsize, localCF = pcf:ToObjectSpace(bcf),
                }
                espTargets[m] = rec
            end
        end
    end

    -- 清掉已经消失 / 死透的角色
    local dead = {}
    for m in pairs(espTargets) do
        if not alive[m] or not m.Parent then
            dead[#dead + 1] = m
        end
    end
    for _, m in ipairs(dead) do
        local rec = espTargets[m]
        if rec then
            if rec.label then pcall(function() rec.label:Destroy() end) end
            if rec.box then pcall(function() rec.box:Destroy() end) end
        end
        espTargets[m] = nil
        local hl = espHl[m]
        if hl then
            pcall(function() hl:Destroy() end)
            espHl[m] = nil
        end
    end

    -- 每轮重算包围盒：怪物走动、骨骼动画变形时，2D 框能跟着走而不是钉在原地
    for m, rec in pairs(espTargets) do
        local okP, pcf = pcall(function() return m:GetPivot() end)
        local bcf, bsize = espBoxOf(m)
        if bcf and bsize and okP and pcf then
            rec.size = bsize
            rec.localCF = pcf:ToObjectSpace(bcf)
        else
            rec.size = nil
            rec.localCF = nil
        end
    end

    -- 轮廓：引擎每个 MeshPart 最多 31 个 Highlight，按距离取最近的，表现稳定
    local myPos = modelWorldPos(player.Character)
    local near = {}
    for m in pairs(espTargets) do
        local wp = charAnchor(m)
        if wp then
            near[#near + 1] = { m = m, d = (wp - myPos).Magnitude }
        end
    end
    table.sort(near, function(a, b) return a.d < b.d end)

    -- 轮廓开关关掉时，只清轮廓，不动文字和方框
    if not espOn then
        for m in pairs(espHl) do
            local hl = espHl[m]
            if hl then pcall(function() hl:Destroy() end) end
        end
        espHl = {}
        return
    end

    local wanted = {}
    for i = 1, math.min(#near, ESP_MAX_HL) do
        wanted[near[i].m] = true
    end

    for m in pairs(wanted) do
        if not espHl[m] then
            local hl = Instance.new("Highlight")
            hl.Name = "ESP_Highlight"
            hl.FillColor = Color3.fromRGB(0, 170, 255)
            hl.FillTransparency = 0.45
            hl.OutlineColor = Color3.fromRGB(0, 225, 255)
            hl.OutlineTransparency = 0
            pcall(function() hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
            hl.Parent = m
            espHl[m] = hl
        end
    end

    local drop = {}
    for m in pairs(espHl) do
        if not wanted[m] or not m.Parent then drop[#drop + 1] = m end
    end
    for _, m in ipairs(drop) do
        local hl = espHl[m]
        if hl then pcall(function() hl:Destroy() end) end
        espHl[m] = nil
    end
end

-- 是不是标准玩家骨架（R6 / R15 + 人形根部 + 头）。
-- 有名字有血量的怪物也可能是 Humanoid，但极少同时满足这三条，
-- 用它挡住"把怪物练成玩家角色"的误判
local function isPlayerRig(m, hum)
    if not m or not hum then return false end
    local ok, rt = pcall(function() return hum.RigType end)
    if not ok or not rt then return false end
    if rt ~= Enum.HumanoidRigType.R6 and rt ~= Enum.HumanoidRigType.R15 then return false end
    if not m:FindFirstChild("HumanoidRootPart") then return false end
    local head = m:FindFirstChild("Head")
    if not (head and head:IsA("BasePart")) then return false end
    return true
end

local function espRender()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local myChar = player.Character
    local myPos = modelWorldPos(myChar)

    for m, rec in pairs(espTargets) do
        local lb = rec.label
        local hum = m:FindFirstChildOfClass("Humanoid")
        local wp = charAnchor(m)
        if lb and wp then
            local sp = cam:WorldToViewportPoint(wp)
            local muted = rec.player and espMute[rec.player]
            if sp.Z <= 1 or not espTextOn or muted or not rec.size then
                lb.Visible = false
            else
                local x, y = sp.X, sp.Y
                local padX, padY = 60, 34
                local edge = false
                if x < padX then x = padX; edge = true
                elseif x > vp.X - padX then x = vp.X - padX; edge = true end
                if y < padY then y = padY; edge = true
                elseif y > vp.Y - padY then y = vp.Y - padY; edge = true end

                lb.Visible = true
                lb.Position = UDim2.fromOffset(math.floor(x), math.floor(y))

                local dxz = Vector2.new(wp.X - myPos.X, wp.Z - myPos.Z).Magnitude
                local nm = m.Name
                local hpStr = "无血量数据"
                local col = Color3.fromRGB(205, 210, 225)
                if hum then
                    if hum.DisplayName and hum.DisplayName ~= "" then nm = hum.DisplayName end
                    hpStr = fmtNum(hum.Health) .. " / " .. fmtNum(hum.MaxHealth)
                    -- 血量不设上限的东西（怪物）用琥珀色单独标出来，别跟玩家混在一起
                    local maxHp = hum.MaxHealth
                    if maxHp == math.huge or maxHp ~= maxHp or hum.Health ~= hum.Health then
                        col = Color3.fromRGB(255, 176, 64)
                    else
                        col = hpColor(hum.Health, hum.MaxHealth)
                    end
                end
                if m == myChar then col = Color3.fromRGB(150, 220, 255) end

                -- 名字后面不再标"人 / 尸体"，只留纯名字
                lb.Text = nm .. "\n" .. hpStr .. "\n" .. tostring(math.floor(dxz)) .. " studs"
                lb.TextColor3 = col
                lb.TextTransparency = edge and 0.3 or 0
                lb.TextSize = (dxz > 700) and 10 or 12
            end
        elseif lb then
            lb.Visible = false
        end

        -- 方框模式：投影包围盒 8 个角，算出屏幕矩形
        local box = rec.box
        if box then
            if espBoxOn and rec.size and rec.localCF then
                local okP, pcf = pcall(function() return m:GetPivot() end)
                local shownBox = false
                if okP and pcf then
                    local bcf = pcf * rec.localCF
                    local sz = rec.size
                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge
                    for ix = -1, 1, 2 do
                        for iy = -1, 1, 2 do
                            for iz = -1, 1, 2 do
                                local wpt = bcf * Vector3.new(sz.X * 0.5 * ix, sz.Y * 0.5 * iy, sz.Z * 0.5 * iz)
                                local sp2 = cam:WorldToViewportPoint(wpt)
                                if sp2.Z > 0 then
                                    shownBox = true
                                    if sp2.X < minX then minX = sp2.X end
                                    if sp2.Y < minY then minY = sp2.Y end
                                    if sp2.X > maxX then maxX = sp2.X end
                                    if sp2.Y > maxY then maxY = sp2.Y end
                                end
                            end
                        end
                    end
                    if shownBox then
                        minX = math.max(0, minX)
                        minY = math.max(0, minY)
                        maxX = math.min(vp.X, maxX)
                        maxY = math.min(vp.Y, maxY)
                        local w, h = maxX - minX, maxY - minY
                        if w >= 2 and h >= 2 then
                            box.Visible = true
                            box.Position = UDim2.fromOffset(math.floor(minX), math.floor(minY))
                            box.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
                            if rec.stroke then
                                if rec.player and espMute[rec.player] then
                                    rec.stroke.Color = Color3.fromRGB(120, 120, 120)
                                else
                                    rec.stroke.Color = Color3.fromRGB(0, 210, 255)
                                end
                            end
                        else
                            box.Visible = false
                        end
                    else
                        box.Visible = false
                    end
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        end
    end

end


-- 先声明，两个勾选框要互相取消，闭包得先拿到对方
local espBoxToggle = nil

local function clearEspHighlights()
    for m in pairs(espHl) do
        local hl = espHl[m]
        if hl then pcall(function() hl:Destroy() end) end
    end
    espHl = {}
end

espToggle = makeCheckRow(espPage, 14, 12, 148, "高亮 ESP", function(state)
    espOn = state
    if state then
        espLastScan = 0
        pcall(espScan)
        pcall(espRender)
    else
        clearEspHighlights()
    end
end)

local espTextToggle = makeToggleAt(espPage, 168, 12, 148, "显示文字", function(state)
    espTextOn = state
    espScreen.Enabled = (espTextOn or espBoxOn)
    if state then
        espLastScan = 0
    else
        for _, rec in pairs(espTargets) do
            if rec.label then rec.label.Visible = false end
        end
    end
end)

espBoxToggle = makeCheckRow(espPage, 14, 60, 148, "方框 ESP", function(state)
    espBoxOn = state
    espScreen.Enabled = (espTextOn or espBoxOn)
    if state then
        espLastScan = 0
    else
        for _, rec in pairs(espTargets) do
            if rec.box then rec.box.Visible = false end
        end
    end
end)

local espSelfToggle = makeToggleAt(espPage, 168, 60, 148, "显示玩家自身", function(state)
    espSelfOn = state
    espLastScan = 0
    if not state then
        local mc = player.Character
        local rec = mc and espTargets[mc]
        if rec then
            if rec.label then pcall(function() rec.label:Destroy() end) end
            if rec.box then pcall(function() rec.box:Destroy() end) end
            espTargets[mc] = nil
            local hl = espHl[mc]
            if hl then
                pcall(function() hl:Destroy() end)
                espHl[mc] = nil
            end
        end
    end
end)

-- ===== 禁用指定玩家的文字 =====
local muteDrop = nil
local dropLayout = nil
local rebuildMuteList = nil
local muteToggleBtn = nil

local function makeFlatButton(parent, x, y, w, h, text, onClick)
    local btn = Instance.new("TextButton")
    btn.Position = UDim2.fromOffset(x, y)
    btn.Size = UDim2.fromOffset(w, h)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(225, 225, 225)
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.ZIndex = 2
    btn.Parent = parent
    corner(btn, 6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(34, 34, 34) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26) end)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return btn
end

muteToggleBtn = makeFlatButton(espPage, 14, 144, 303, 32, "选择玩家禁用 v", function()
    if not muteDrop then return end
    muteDrop.Visible = not muteDrop.Visible
    if muteDrop.Visible then
        muteToggleBtn.Text = "选择玩家禁用 ^"
        if rebuildMuteList then pcall(rebuildMuteList) end
    else
        muteToggleBtn.Text = "选择玩家禁用 v"
    end
end)

muteDrop = Instance.new("ScrollingFrame")
muteDrop.Position = UDim2.fromOffset(14, 180)
muteDrop.Size = UDim2.new(1, -28, 0, 96)
muteDrop.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
muteDrop.BorderSizePixel = 0
muteDrop.ScrollBarThickness = 4
muteDrop.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
muteDrop.CanvasSize = UDim2.new(0, 0, 0, 0)
muteDrop.Visible = false
muteDrop.ZIndex = 6
pcall(function() muteDrop.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
muteDrop.Parent = espPage
corner(muteDrop, 6)

dropLayout = Instance.new("UIListLayout")
dropLayout.Padding = UDim.new(0, 1)
dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropLayout.Parent = muteDrop

rebuildMuteList = function()
    for _, c in ipairs(muteDrop:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local plrs = Players:GetPlayers()
    if #plrs == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 26)
        empty.BackgroundTransparency = 1
        empty.Text = "当前没有其他玩家"
        empty.Font = Enum.Font.SourceSans
        empty.TextSize = 11
        empty.TextColor3 = Color3.fromRGB(110, 110, 110)
        empty.ZIndex = 7
        empty.Parent = muteDrop
        return
    end
    for i, plr in ipairs(plrs) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.LayoutOrder = i
        row.BackgroundColor3 = espMute[plr] and Color3.fromRGB(40, 24, 24) or Color3.fromRGB(24, 24, 24)
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = (espMute[plr] and "✕ " or "· ") .. plr.DisplayName
        row.Font = Enum.Font.SourceSansBold
        row.TextSize = 11
        row.TextColor3 = espMute[plr] and Color3.fromRGB(255, 130, 130) or Color3.fromRGB(200, 200, 200)
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.ZIndex = 7
        row.Parent = muteDrop
        local pad = Instance.new("UIPadding", row)
        pad.PaddingLeft = UDim.new(0, 10)
        row.MouseButton1Click:Connect(function()
            espMute[plr] = (not espMute[plr]) and true or nil
            rebuildMuteList()
        end)
    end
end


RunService.Heartbeat:Connect(function()
    if not espOn and not espTextOn and not espBoxOn then return end
    local now = os.clock()
    if now - espLastScan >= 0.3 then
        espLastScan = now
        pcall(espScan)
    end
    pcall(espRender)
end)

-- ===== 第 5 页：瞬移点（记录 / 选中 / 重命名 / 删除 / 按坐标瞬移） =====
local tpPage = emptyPages[1]
local tpPoints = {}
local tpSelected = nil
local tpList = nil
local rebuildTpList = nil
local tpRebuilding = false
local tpPendingEdit = nil
local updateTpSel = nil
local tpSelName = nil
local tpBoxX, tpBoxY, tpBoxZ = nil, nil, nil

local function fmtCoord(p)
    return math.floor(p.X) .. ", " .. math.floor(p.Y) .. ", " .. math.floor(p.Z)
end

local function doTeleport(pos, labelText)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        say("角色还没加载好", false)
        return
    end
    root.CFrame = CFrame.new(pos)
    say("已瞬移" .. (labelText and ("：" .. labelText) or ""), true)
end

makeButton(tpPage, 12, "记录当前位置为瞬移点", function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        say("角色还没加载好", false)
        return
    end
    tpPoints[#tpPoints + 1] = { name = "点" .. (#tpPoints + 1), pos = root.Position }
    tpPendingEdit = #tpPoints
    tpSelected = #tpPoints
    if rebuildTpList then rebuildTpList() end
    if updateTpSel then updateTpSel() end
    say("已添加瞬移点，给它起个名字（不填就用 点" .. #tpPoints .. "）", true)
end)

-- 选中条：显示选中那条的名字和坐标，右边一个"瞬移"
local tpSelBar = Instance.new("Frame")
tpSelBar.Position = UDim2.fromOffset(14, 56)
tpSelBar.Size = UDim2.fromOffset(303, 34)
tpSelBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
tpSelBar.BorderSizePixel = 0
tpSelBar.Parent = tpPage
corner(tpSelBar, 6)

tpSelName = Instance.new("TextLabel")
tpSelName.Position = UDim2.fromOffset(10, 0)
tpSelName.Size = UDim2.new(1, -84, 1, 0)
tpSelName.BackgroundTransparency = 1
tpSelName.Text = "未选择瞬移点（点列表里的一条）"
tpSelName.Font = Enum.Font.SourceSansBold
tpSelName.TextSize = 10
tpSelName.TextColor3 = Color3.fromRGB(160, 160, 160)
tpSelName.TextXAlignment = Enum.TextXAlignment.Left
tpSelName.TextTruncate = Enum.TextTruncate.AtEnd
tpSelName.Parent = tpSelBar

local tpGoBtn = Instance.new("TextButton")
tpGoBtn.Position = UDim2.new(1, -70, 0, 0)
tpGoBtn.Size = UDim2.fromOffset(70, 34)
tpGoBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
tpGoBtn.BorderSizePixel = 0
tpGoBtn.AutoButtonColor = false
tpGoBtn.Text = "瞬移"
tpGoBtn.Font = Enum.Font.SourceSansBold
tpGoBtn.TextSize = 12
tpGoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpGoBtn.Parent = tpSelBar
corner(tpGoBtn, 6)

tpGoBtn.MouseButton1Click:Connect(function()
    if not tpSelected or not tpPoints[tpSelected] then
        say("先在列表里点一条瞬移点", false)
        return
    end
    doTeleport(tpPoints[tpSelected].pos, tpPoints[tpSelected].name)
end)

-- XYZ 三个独立输入框 + 按坐标瞬移
local function makeXyzBox(x, ph)
    local b = Instance.new("TextBox")
    b.Position = UDim2.fromOffset(x, 96)
    b.Size = UDim2.fromOffset(58, 34)
    b.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.SourceSans
    b.TextSize = 12
    b.Text = ""
    b.PlaceholderText = ph
    b.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    b.TextXAlignment = Enum.TextXAlignment.Center
    b.ClearTextOnFocus = false
    b.Parent = tpPage
    corner(b, 6)
    return b
end

tpBoxX = makeXyzBox(14, "X")
tpBoxY = makeXyzBox(76, "Y")
tpBoxZ = makeXyzBox(138, "Z")

local tpXyzGo = Instance.new("TextButton")
tpXyzGo.Position = UDim2.fromOffset(198, 96)
tpXyzGo.Size = UDim2.fromOffset(54, 34)
tpXyzGo.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
tpXyzGo.BorderSizePixel = 0
tpXyzGo.AutoButtonColor = false
tpXyzGo.Text = "按坐标瞬移"
tpXyzGo.Font = Enum.Font.SourceSansBold
tpXyzGo.TextSize = 9
tpXyzGo.TextColor3 = Color3.fromRGB(255, 255, 255)
tpXyzGo.Parent = tpPage
corner(tpXyzGo, 6)

tpXyzGo.MouseButton1Click:Connect(function()
    local x = tonumber(tpBoxX.Text)
    local y = tonumber(tpBoxY.Text)
    local z = tonumber(tpBoxZ.Text)
    -- 哪个没填就按 0 算；三个都空才拦一下，免得直接飞原点
    if not x and not y and not z then
        say("X / Y / Z 至少要填一个", false)
        return
    end
    x = x or 0
    y = y or 0
    z = z or 0
    say("瞬移到 " .. x .. ", " .. y .. ", " .. z, true)
    doTeleport(Vector3.new(x, y, z), nil)
end)

-- 预览：在目标坐标放一个可见的标记点，屏幕标签一直显示距离（隔多远都看得见）
local previewPart = nil
local previewScreen = nil
local previewTag = nil

local previewBtn = Instance.new("TextButton")
previewBtn.Position = UDim2.fromOffset(254, 96)
previewBtn.Size = UDim2.fromOffset(49, 34)
previewBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
previewBtn.BorderSizePixel = 0
previewBtn.AutoButtonColor = false
previewBtn.Text = "预览"
previewBtn.Font = Enum.Font.SourceSansBold
previewBtn.TextSize = 10
previewBtn.TextColor3 = Color3.fromRGB(225, 225, 225)
previewBtn.Parent = tpPage
corner(previewBtn, 6)

previewScreen = Instance.new("ScreenGui")
previewScreen.Name = "TpPreviewTag"
previewScreen.IgnoreGuiInset = true
previewScreen.ResetOnSpawn = false
previewScreen.DisplayOrder = 6
previewScreen.Enabled = false
previewScreen.Parent = playerGui

previewTag = Instance.new("TextLabel")
previewTag.Size = UDim2.fromOffset(150, 22)
previewTag.AnchorPoint = Vector2.new(0.5, 0.5)
previewTag.BackgroundTransparency = 1
previewTag.Text = ""
previewTag.Font = Enum.Font.SourceSansBold
previewTag.TextSize = 12
previewTag.TextColor3 = Color3.fromRGB(120, 220, 255)
previewTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
previewTag.TextStrokeTransparency = 0.3
previewTag.Visible = false
previewTag.Parent = previewScreen

endPreview = function()
    if previewPart then
        pcall(function() previewPart:Destroy() end)
        previewPart = nil
    end
    if previewTag then previewTag.Visible = false end
    if previewScreen then previewScreen.Enabled = false end
    if previewBtn then previewBtn.Text = "预览" end
end

local function startPreview(pos)
    endPreview()

    local marker = Instance.new("Part")
    marker.Name = "TpPreviewMarker"
    marker.Shape = Enum.PartType.Ball
    marker.Size = Vector3.new(1.4, 1.4, 1.4)
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(80, 200, 255)
    marker.Position = pos
    marker.Parent = workspace
    previewPart = marker

    previewScreen.Enabled = true
    previewBtn.Text = "清除"
end

previewBtn.MouseButton1Click:Connect(function()
    if previewPart and previewPart.Parent then
        endPreview()
        say("已清除预览点", nil)
        return
    end
    local x = tonumber(tpBoxX.Text)
    local y = tonumber(tpBoxY.Text)
    local z = tonumber(tpBoxZ.Text)
    if not x and not y and not z then
        say("X / Y / Z 至少要填一个", false)
        return
    end
    x = x or 0
    y = y or 0
    z = z or 0
    startPreview(Vector3.new(x, y, z))
    say("预览点已放在 " .. x .. ", " .. y .. ", " .. z, true)
end)

-- 标签每帧跟着标记点走，超出屏幕就贴到边上
RunService.Heartbeat:Connect(function()
    if not previewPart or not previewPart.Parent then
        if previewTag and previewTag.Visible then previewTag.Visible = false end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local myPos = modelWorldPos(player.Character)
    local sp = cam:WorldToViewportPoint(previewPart.Position)
    local dist = (previewPart.Position - myPos).Magnitude

    local x, y = sp.X, sp.Y
    if sp.Z <= 0 then
        x, y = vp.X * 0.5, vp.Y - 30
    else
        local padX, padY = 64, 26
        if x < padX then x = padX elseif x > vp.X - padX then x = vp.X - padX end
        if y < padY then y = padY elseif y > vp.Y - padY then y = vp.Y - padY end
    end

    previewTag.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    previewTag.Text = "预览点 " .. math.floor(dist) .. " 格"
    previewTag.Visible = true
end)

-- 列表
tpList = Instance.new("ScrollingFrame")
tpList.Position = UDim2.fromOffset(14, 136)
tpList.Size = UDim2.new(1, -28, 1, -160)
tpList.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
tpList.BorderSizePixel = 0
tpList.ScrollBarThickness = 4
tpList.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
tpList.CanvasSize = UDim2.new(0, 0, 0, 0)
pcall(function() tpList.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
tpList.Parent = tpPage
corner(tpList, 6)

local tpLayout = Instance.new("UIListLayout")
tpLayout.Padding = UDim.new(0, 1)
tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
tpLayout.Parent = tpList

updateTpSel = function()
    local it = tpSelected and tpPoints[tpSelected]
    if it then
        tpSelName.Text = tpSelected .. ". " .. it.name .. "   " .. fmtCoord(it.pos)
        tpSelName.TextColor3 = Color3.fromRGB(150, 220, 255)
        if tpBoxX then tpBoxX.Text = tostring(math.floor(it.pos.X)) end
        if tpBoxY then tpBoxY.Text = tostring(math.floor(it.pos.Y)) end
        if tpBoxZ then tpBoxZ.Text = tostring(math.floor(it.pos.Z)) end
    else
        tpSelName.Text = "未选择瞬移点（点列表里的一条）"
        tpSelName.TextColor3 = Color3.fromRGB(160, 160, 160)
    end
end

rebuildTpList = function()
    tpRebuilding = true
    for _, c in ipairs(tpList:GetChildren()) do
        if c ~= tpLayout then c:Destroy() end
    end

    if #tpPoints == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 34)
        empty.BackgroundTransparency = 1
        empty.Text = "还没有瞬移点，点上面按钮记录一个"
        empty.Font = Enum.Font.SourceSans
        empty.TextSize = 11
        empty.TextColor3 = Color3.fromRGB(110, 110, 110)
        empty.Parent = tpList
        tpRebuilding = false
        return
    end

    for i, item in ipairs(tpPoints) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundTransparency = 1
        row.LayoutOrder = i
        row.Parent = tpList

        local nameBtn = Instance.new("TextButton")
        nameBtn.Position = UDim2.fromOffset(0, 0)
        nameBtn.Size = UDim2.fromOffset(84, 34)
        nameBtn.BackgroundColor3 = (tpSelected == i) and Color3.fromRGB(30, 70, 140) or Color3.fromRGB(24, 24, 24)
        nameBtn.BorderSizePixel = 0
        nameBtn.AutoButtonColor = false
        nameBtn.Text = i .. ". " .. item.name
        nameBtn.Font = Enum.Font.SourceSansBold
        nameBtn.TextSize = 10
        nameBtn.TextColor3 = (tpSelected == i) and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(200, 200, 200)
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
        nameBtn.Parent = row
        corner(nameBtn, 6)
        local np = Instance.new("UIPadding", nameBtn)
        np.PaddingLeft = UDim.new(0, 8)

        local edit = Instance.new("TextBox")
        edit.Position = UDim2.fromOffset(0, 0)
        edit.Size = UDim2.fromOffset(84, 34)
        edit.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        edit.BorderSizePixel = 0
        edit.Font = Enum.Font.SourceSansBold
        edit.TextSize = 10
        edit.TextColor3 = Color3.fromRGB(235, 235, 235)
        edit.TextXAlignment = Enum.TextXAlignment.Left
        edit.Text = item.name
        edit.ClearTextOnFocus = false
        edit.Visible = false
        edit.ZIndex = 3
        edit.Parent = row
        corner(edit, 6)
        local ep = Instance.new("UIPadding", edit)
        ep.PaddingLeft = UDim.new(0, 8)

        local coordLb = Instance.new("TextLabel")
        coordLb.Position = UDim2.fromOffset(86, 0)
        coordLb.Size = UDim2.fromOffset(62, 34)
        coordLb.BackgroundTransparency = 1
        coordLb.Text = fmtCoord(item.pos)
        coordLb.Font = Enum.Font.SourceSans
        coordLb.TextSize = 8
        coordLb.TextColor3 = Color3.fromRGB(130, 130, 130)
        coordLb.TextXAlignment = Enum.TextXAlignment.Left
        coordLb.TextTruncate = Enum.TextTruncate.AtEnd
        coordLb.Parent = row

        local jumpBtn = Instance.new("TextButton")
        jumpBtn.Position = UDim2.fromOffset(150, 0)
        jumpBtn.Size = UDim2.fromOffset(44, 34)
        jumpBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
        jumpBtn.BorderSizePixel = 0
        jumpBtn.AutoButtonColor = false
        jumpBtn.Text = "瞬移"
        jumpBtn.Font = Enum.Font.SourceSansBold
        jumpBtn.TextSize = 10
        jumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        jumpBtn.ZIndex = 2
        jumpBtn.Parent = row
        corner(jumpBtn, 6)
        jumpBtn.MouseButton1Click:Connect(function()
            doTeleport(item.pos, item.name)
        end)

        edit.FocusLost:Connect(function()
            if tpRebuilding then return end
            local txt = edit.Text
            if txt == nil or txt == "" then txt = "点" .. i end
            item.name = string.sub(txt, 1, 20)
            rebuildTpList()
            updateTpSel()
        end)

        nameBtn.MouseButton1Click:Connect(function()
            tpSelected = i
            updateTpSel()
            rebuildTpList()
        end)

        if tpPendingEdit == i then
            tpPendingEdit = nil
            edit.Text = item.name
            edit.Visible = true
            nameBtn.Visible = false
            task.defer(function()
                if edit.Parent then
                    pcall(function() edit:CaptureFocus() end)
                end
            end)
        end

        local renameBtn = makeFlatButton(row, 196, 0, 52, 34, "重命名", function()
            edit.Text = item.name
            edit.Visible = true
            nameBtn.Visible = false
            edit:CaptureFocus()
        end)

        local delBtn = makeFlatButton(row, 250, 0, 40, 34, "删除", function()
            table.remove(tpPoints, i)
            if tpSelected == i then
                tpSelected = nil
            elseif tpSelected and tpSelected > i then
                tpSelected = tpSelected - 1
            end
            rebuildTpList()
            updateTpSel()
            say("已删除 " .. item.name, true)
        end)
    end
    tpRebuilding = false
end

rebuildTpList()
updateTpSel()


setPicking = function(mode, quiet)
    picking = mode
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

    showSize(part)
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
    -- 最小化/展开动画还在跑就先全部停掉，不然拖着会跟补间打架
    for obj in pairs(minTweens) do
        pcall(function() minTweens[obj]:Cancel() end)
    end
    minTweens = {}
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
        if walkAirOn and setWalkAir then setWalkAir(false) end
        if walkAirToggle then walkAirToggle.Set(false, true) end
    end)
    pcall(function()
        if noclipOn and setNoclip then setNoclip(false) end
    end)
    pcall(function()
        if endPreview then endPreview() end
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
    pcall(function()
        espOn = false
        espTextOn = false
        espBoxOn = false
        espSelfOn = false
        espClear()
        espScreen.Enabled = false
        if espToggle then espToggle.Set(false, true) end
        if espTextToggle then espTextToggle.Set(false, true) end
        if espBoxToggle then espBoxToggle.Set(false, true) end
        if espSelfToggle then espSelfToggle.Set(false, true) end
        if espScreen and espScreen.Parent then pcall(function() espScreen:Destroy() end) end
    end)
    FLY_SPEED = 40
end
