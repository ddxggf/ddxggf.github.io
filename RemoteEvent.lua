local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== 路径显示：点 → 斜杠 =====
local function slashPath(p)
    return (p:gsub("%.", "/"))
end

-- ===== 获取执行器全局函数的兼容写法 =====
local function getGlobalFn(name)
    local ok, v = pcall(function() return rawget(getfenv(), name) end)
    if ok and type(v) == "function" then return v end
    if getgenv then
        local ok2, env = pcall(getgenv)
        if ok2 and type(env) == "table" then
            local v2 = rawget(env, name)
            if type(v2) == "function" then return v2 end
        end
    end
    return rawget(_G, name)
end

-- ===== 提取脚本源码（多重尝试） =====
local function extractSource(obj)
    local ok, src = pcall(function() return obj.Source end)
    if ok and type(src) == "string" and #src > 0 then
        return src, "Source"
    end
    local apis = { "decompile", "getscriptbytecode", "getsource" }
    for _, name in ipairs(apis) do
        local fn = getGlobalFn(name)
        if fn then
            local ok2, res = pcall(fn, obj)
            if ok2 and type(res) == "string" and #res > 0 then
                return res, name
            end
        end
    end
    return nil, nil
end

-- ===== 界面容器 =====
local gui = Instance.new("ScreenGui")
gui.Name = "豆包中心"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- ===== 窗口本体 =====
local win = Instance.new("Frame")
win.Name = "Win"
win.Size = UDim2.fromOffset(500, 520)
win.Position = UDim2.fromScale(0.5, 0.45)
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1
stroke.Parent = win

-- ===== 标题栏 =====
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "豆包中心 · 脚本提取"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- ===== 关闭按钮 =====
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

close.MouseEnter:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
close.MouseLeave:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.TextColor3 = Color3.fromRGB(160, 160, 160)
end)

-- ===== 搜索框 =====
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 34)
searchBox.Position = UDim2.fromOffset(10, 50)
searchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 搜索脚本名 / 路径..."
searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(230, 230, 230)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = win

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.Parent = searchBox

local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(60, 60, 60)
searchStroke.Thickness = 1
searchStroke.Parent = searchBox

searchBox.Focused:Connect(function()
    searchStroke.Color = Color3.fromRGB(90, 140, 220)
end)
searchBox.FocusLost:Connect(function()
    searchStroke.Color = Color3.fromRGB(60, 60, 60)
end)

-- ===== 下拉框头部 =====
local dropdownHeader = Instance.new("TextButton")
dropdownHeader.Name = "DropdownHeader"
dropdownHeader.Size = UDim2.new(1, -20, 0, 36)
dropdownHeader.Position = UDim2.fromOffset(10, 90)
dropdownHeader.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
dropdownHeader.BorderSizePixel = 0
dropdownHeader.AutoButtonColor = false
dropdownHeader.Text = "  正在扫描 ReplicatedStorage 脚本..."
dropdownHeader.Font = Enum.Font.SourceSans
dropdownHeader.TextSize = 14
dropdownHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
dropdownHeader.TextXAlignment = Enum.TextXAlignment.Left
dropdownHeader.TextTruncate = Enum.TextTruncate.AtEnd
dropdownHeader.Parent = win

local ddStroke = Instance.new("UIStroke")
ddStroke.Color = Color3.fromRGB(60, 60, 60)
ddStroke.Thickness = 1
ddStroke.Parent = dropdownHeader

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(20, 36)
arrow.Position = UDim2.new(1, -24, 0, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "▾"
arrow.Font = Enum.Font.SourceSansBold
arrow.TextSize = 14
arrow.TextColor3 = Color3.fromRGB(160, 160, 160)
arrow.Parent = dropdownHeader

-- ===== 下拉列表 =====
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "ListFrame"
listFrame.Size = UDim2.new(1, -20, 0, 120)
listFrame.Position = UDim2.fromOffset(10, 130)
listFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Visible = false
listFrame.Parent = win

local listStroke = Instance.new("UIStroke")
listStroke.Color = Color3.fromRGB(60, 60, 60)
listStroke.Thickness = 1
listStroke.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 1)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- ===== 输入区 header =====
local inputHeader = Instance.new("Frame")
inputHeader.Name = "InputHeader"
inputHeader.Size = UDim2.new(1, -20, 0, 26)
inputHeader.Position = UDim2.fromOffset(10, 258)
inputHeader.BackgroundTransparency = 1
inputHeader.Parent = win

local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -80, 1, 0)
inputLabel.Position = UDim2.fromOffset(0, 0)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "脚本内容（只读）"
inputLabel.Font = Enum.Font.SourceSansBold
inputLabel.TextSize = 13
inputLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = inputHeader

local copyBtn = Instance.new("TextButton")
copyBtn.Name = "CopyBtn"
copyBtn.Size = UDim2.fromOffset(70, 22)
copyBtn.Position = UDim2.new(1, -70, 0.5, 0)
copyBtn.AnchorPoint = Vector2.new(0, 0.5)
copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
copyBtn.BorderSizePixel = 0
copyBtn.AutoButtonColor = false
copyBtn.Text = "复制"
copyBtn.Font = Enum.Font.SourceSansBold
copyBtn.TextSize = 13
copyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
copyBtn.Parent = inputHeader

local copyStroke = Instance.new("UIStroke")
copyStroke.Color = Color3.fromRGB(70, 70, 80)
copyStroke.Thickness = 1
copyStroke.Parent = copyBtn

copyBtn.MouseEnter:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
end)
copyBtn.MouseLeave:Connect(function()
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
end)

-- ===== 代码显示区 =====
local codeScroll = Instance.new("ScrollingFrame")
codeScroll.Name = "CodeScroll"
codeScroll.Size = UDim2.new(1, -20, 0, 220)
codeScroll.Position = UDim2.fromOffset(10, 288)
codeScroll.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
codeScroll.BorderSizePixel = 0
codeScroll.ScrollBarThickness = 6
codeScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
codeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
codeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
codeScroll.Parent = win

local csStroke = Instance.new("UIStroke")
csStroke.Color = Color3.fromRGB(60, 60, 60)
csStroke.Thickness = 1
csStroke.Parent = codeScroll

local codeBox = Instance.new("TextBox")
codeBox.Name = "CodeBox"
codeBox.Size = UDim2.new(1, -12, 0, 40)
codeBox.Position = UDim2.fromOffset(6, 6)
codeBox.BackgroundTransparency = 1
codeBox.Text = "（尚未选择脚本）"
codeBox.Font = Enum.Font.Code
codeBox.TextSize = 13
codeBox.TextColor3 = Color3.fromRGB(150, 200, 255)
codeBox.TextWrapped = false
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.MultiLine = true
codeBox.TextEditable = false
codeBox.ClearTextOnFocus = false
codeBox.Parent = codeScroll

-- ===== 根据行数自动调整 TextBox 高度 =====
local function setCodeText(text)
    codeBox.Text = text
    local lineCount = 1
    for _ in string.gmatch(text, "\n") do
        lineCount += 1
    end
    local h = math.max(lineCount * 18 + 12, 40)
    codeBox.Size = UDim2.new(1, -12, 0, h)
end

-- ===== 复制按钮 =====
local DEFAULT_TEXT = "（尚未选择脚本）"

local function copyToClipboard(text)
    local fn = getGlobalFn("setclipboard")
    if fn then
        local ok = pcall(fn, text)
        return ok
    end
    return false
end

copyBtn.MouseButton1Click:Connect(function()
    local txt = codeBox.Text
    if txt == "" or txt == DEFAULT_TEXT or #txt < 2 then
        copyBtn.Text = "无内容"
        task.wait(1)
        copyBtn.Text = "复制"
        return
    end
    local ok = copyToClipboard(txt)
    if ok then
        copyBtn.Text = "已复制"
        copyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        task.wait(1)
        copyBtn.Text = "复制"
        copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    else
        copyBtn.Text = "请手动复制"
        copyBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 40)
        task.wait(1.5)
        copyBtn.Text = "复制"
        copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    end
end)

-- ===== 扫描 & 过滤渲染 =====
local allScripts = {}
local scriptCount = 0
local currentFilter = ""

local function renderList(filter)
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local f = string.lower(filter or "")
    local filtered = {}
    for _, scr in ipairs(allScripts) do
        local pathDot = scr:GetFullName()
        local pathSlash = slashPath(pathDot)
        -- 输入 . 或 / 都能匹配
        if f == ""
            or string.find(string.lower(pathDot), f, 1, true)
            or string.find(string.lower(pathSlash), f, 1, true)
        then
            table.insert(filtered, scr)
        end
    end

    scriptCount = #filtered

    if #allScripts == 0 then
        dropdownHeader.Text = "  ReplicatedStorage 中没有脚本"
        setCodeText("ReplicatedStorage 下未扫描到任何 LocalScript / Script / ModuleScript。")
        return
    end

    if scriptCount == 0 then
        dropdownHeader.Text = "  没有匹配的脚本（共 " .. #allScripts .. " 个）"
        return
    end

    dropdownHeader.Text = "  脚本 (" .. scriptCount .. ") —— 点击展开"

    for i, scr in ipairs(filtered) do
        local pathDot = scr:GetFullName()
        local pathSlash = slashPath(pathDot)

        local item = Instance.new("TextButton")
        item.Name = "Item_" .. i
        item.Size = UDim2.new(1, 0, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        item.BorderSizePixel = 0
        item.AutoButtonColor = false
        -- 列表项显示斜杠路径
        item.Text = "  [" .. scr.ClassName .. "] " .. pathSlash
        item.Font = Enum.Font.Code
        item.TextSize = 12
        item.TextColor3 = Color3.fromRGB(200, 200, 200)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextTruncate = Enum.TextTruncate.AtEnd
        item.LayoutOrder = i
        item.Parent = listFrame

        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
        end)
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        end)
        item.MouseButton1Click:Connect(function()
            -- 头部显示斜杠路径
            dropdownHeader.Text = "  [" .. scr.ClassName .. "] " .. pathSlash
            listFrame.Visible = false
            arrow.Text = "▾"

            setCodeText("正在提取 " .. scr.Name .. " 的源码...")
            task.spawn(function()
                local src = extractSource(scr)
                if src then
                    setCodeText(src)  -- 源码原样显示，不做任何替换
                else
                    setCodeText(
                        "无法读取该脚本源码。\n\n" ..
                        "当前执行器不支持 decompile / getscriptbytecode，\n" ..
                        "或者该脚本在客户端没有可读的 Source。\n\n" ..
                        "脚本名: " .. scr.Name .. "\n" ..
                        "类名: " .. scr.ClassName .. "\n" ..
                        "路径: " .. pathSlash
                    )
                end
            end)
        end)
    end
end

local function scanAll()
    allScripts = {}
    local rs = game:GetService("ReplicatedStorage")
    if rs then
        for _, v in ipairs(rs:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("Script") or v:IsA("ModuleScript") then
                table.insert(allScripts, v)
            end
        end
    end
    table.sort(allScripts, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)
    renderList(currentFilter)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    currentFilter = searchBox.Text
    renderList(currentFilter)
end)

-- ===== 下拉开关 =====
dropdownHeader.MouseButton1Click:Connect(function()
    if scriptCount <= 0 then return end
    listFrame.Visible = not listFrame.Visible
    arrow.Text = listFrame.Visible and "▴" or "▾"
end)

-- ===== 拖动 =====
local dragging = false
local dragInput = nil
local dragTouch = nil
local lastPos = nil
local DRAG_MAX_DELTA = 150

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
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
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

-- ===== 关闭 =====
local function doClose()
    gui:Destroy()
end

close.MouseButton1Click:Connect(doClose)
pcall(function() close.Activated:Connect(doClose) end)

-- ===== 启动 =====
scanAll()