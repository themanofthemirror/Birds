local colors = {
     ["SCP-017"] = Color3.fromRGB(150, 0, 255),
     ["SCP-049"] = Color3.fromRGB(0, 200, 0),
     ["SCP-280"] = Color3.fromRGB(0, 100, 255),
     ["SCP-457"] = Color3.fromRGB(255, 100, 0),
     ["SCP-966"] = Color3.fromRGB(255, 255, 0),
     ["SCP-058"] = Color3.fromRGB(255, 0, 0),
     ["SCP-352-2"] = Color3.fromRGB(255, 0, 150),
     ["SCP-1350"] = Color3.fromRGB(0, 255, 255),
     ["SCP-173"] = Color3.fromRGB(200, 200, 200),
}

local legendLabels = {}
local tracerLines = {}
local hidden = false
local tracersEnabled = true
local active966Count = 0
local failed966Count = 0

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function getLegendKey(name)
     if name:find("SCP-966") then return "SCP-966" end
     return name
end

local function getColor(name)
     local key = getLegendKey(name)
     if colors[key] then return colors[key] end
     return Color3.fromRGB(255, 255, 255)
end

local function markTerminated(legendKey)
     if legendLabels[legendKey] then
          legendLabels[legendKey].Text = legendKey .. " (terminated)"
          legendLabels[legendKey].TextColor3 = Color3.fromRGB(100, 100, 100)
     end
     for _, t in pairs(tracerLines) do
          if t.LegendKey == legendKey then
               t.Line.Visible    = false
               t.Outline.Visible = false
          end
     end
end

local function createTracer(part, color, legendKey)
     local outline = Drawing.new("Line")
     outline.Thickness    = 3
     outline.Color        = Color3.fromRGB(25, 25, 25)
     outline.Transparency = 0.75
     outline.Visible      = false

     local line = Drawing.new("Line")
     line.Thickness    = 1.5
     line.Color        = color
     line.Transparency = 0.75
     line.Visible      = false

     local uid = part:GetDebugId()
     tracerLines[uid] = { Line = line, Outline = outline, Part = part, LegendKey = legendKey }
end

RunService:BindToRenderStep("SCP_Tracers", 300, function()
     if hidden or not tracersEnabled then
          for _, t in pairs(tracerLines) do
               t.Line.Visible    = false
               t.Outline.Visible = false
          end
          return
     end

     local fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
     local vx, vy = Camera.ViewportSize.X, Camera.ViewportSize.Y

     for _, t in pairs(tracerLines) do
          local part = t.Part

          if not part or not part.Parent then
               t.Line.Visible    = false
               t.Outline.Visible = false
          else
               local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

               if screenPos.Z > 0 and onScreen then
                    local to = Vector2.new(
                         math.clamp(screenPos.X, 0, vx),
                         math.clamp(screenPos.Y, 0, vy)
                    )

                    local distance = (Camera.CFrame.Position - part.Position).Magnitude
                    local transparency = math.clamp(1 - (distance / 200), 0.25, 0.75)

                    t.Line.Visible      = true
                    t.Line.From         = fromPos
                    t.Line.To           = to
                    t.Line.Transparency = transparency

                    t.Outline.Visible      = true
                    t.Outline.From         = fromPos
                    t.Outline.To           = to
                    t.Outline.Transparency = transparency - 0.15
               else
                    t.Line.Visible    = false
                    t.Outline.Visible = false
               end
          end
     end
end)


function addUi(part)
     if not part or part:FindFirstChild("Item-ESP") then return end

     local entityName = part.Parent.Name
     local color = getColor(entityName)
     local legendKey = getLegendKey(entityName)

     if entityName:find("SCP-966") then
          active966Count = active966Count + 1
     end

     local partGui = Instance.new("BillboardGui", part)
     partGui.Size = UDim2.new(1,0,1,0)
     partGui.AlwaysOnTop = true
     partGui.MaxDistance = 1000
     partGui.Name = "Item-ESP"
     local frame = Instance.new("Frame", partGui)
     frame.BackgroundColor3 = color
     frame.BackgroundTransparency = 0.75
     frame.Size = UDim2.new(2,0,2,0)
     frame.BorderSizePixel = 0
     local nameGui = Instance.new("BillboardGui", part)
     nameGui.Size = UDim2.new(6,0,3,0)
     nameGui.SizeOffset = Vector2.new(0,1)
     nameGui.AlwaysOnTop = true
     nameGui.MaxDistance = 1000
     nameGui.Name = "Name"
     local text = Instance.new("TextLabel", nameGui)
     text.Text = entityName
     text.TextColor3 = color
     text.TextTransparency = 0.25
     text.BackgroundTransparency = 1
     text.TextScaled = true
     text.Size = UDim2.new(1,0,1,0)
     text.Font = Enum.Font.GothamSemibold
     text.Name = "Text"

     createTracer(part, color, legendKey)

     part.AncestryChanged:Connect(function()
          if not part.Parent then
               if legendKey == "SCP-966" then
                    active966Count = active966Count - 1
                    if active966Count <= 0 then
                         markTerminated("SCP-966")
                    end
               else
                    markTerminated(legendKey)
               end
          end
     end)
end

local function createLegend()
     if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Legend") then return end

     local screenGui = Instance.new("ScreenGui")
     screenGui.Name = "ESP-Legend"
     screenGui.ResetOnSpawn = false
     screenGui.Parent = game.Players.LocalPlayer.PlayerGui

     local rowHeight = 22
     local totalRows = 0
     for _ in pairs(colors) do totalRows = totalRows + 1 end

     local frame = Instance.new("Frame", screenGui)
     frame.Size = UDim2.new(0, 180, 0, totalRows * rowHeight + 35)
     frame.Position = UDim2.new(0, 10, 1, -(totalRows * rowHeight + 45))
     frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
     frame.BackgroundTransparency = 0.3
     frame.BorderSizePixel = 0

     local corner = Instance.new("UICorner", frame)
     corner.CornerRadius = UDim.new(0, 8)

     local padding = Instance.new("UIPadding", frame)
     padding.PaddingLeft = UDim.new(0, 8)
     padding.PaddingTop = UDim.new(0, 5)

     local tracerToggle = Instance.new("Frame", frame)
     tracerToggle.Size = UDim2.new(1, -16, 0, 20)
     tracerToggle.Position = UDim2.new(0, 8, 0, 5)
     tracerToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
     tracerToggle.BorderSizePixel = 0
     local toggleCorner = Instance.new("UICorner", tracerToggle)
     toggleCorner.CornerRadius = UDim.new(0, 4)

     local tracerLabel = Instance.new("TextLabel", tracerToggle)
     tracerLabel.Size = UDim2.new(1, 0, 1, 0)
     tracerLabel.BackgroundTransparency = 1
     tracerLabel.Text = "⬤ Tracers ON"
     tracerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
     tracerLabel.TextSize = 11
     tracerLabel.Font = Enum.Font.GothamSemibold
     tracerLabel.TextXAlignment = Enum.TextXAlignment.Center

     local button = Instance.new("TextButton", tracerToggle)
     button.Size = UDim2.new(1, 0, 1, 0)
     button.BackgroundTransparency = 1
     button.Text = ""
     button.MouseButton1Click:Connect(function()
          tracersEnabled = not tracersEnabled
          if tracersEnabled then
               tracerLabel.Text = "⬤ Tracers ON"
               tracerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
          else
               tracerLabel.Text = "⬤ Tracers OFF"
               tracerLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
               for _, t in pairs(tracerLines) do
                    t.Line.Visible    = false
                    t.Outline.Visible = false
               end
          end
     end)

     local i = 0
     for name, color in pairs(colors) do
          local row = Instance.new("Frame", frame)
          row.Size = UDim2.new(1, -8, 0, rowHeight)
          row.Position = UDim2.new(0, 0, 0, i * rowHeight + 28)
          row.BackgroundTransparency = 1

          local dot = Instance.new("Frame", row)
          dot.Size = UDim2.new(0, 12, 0, 12)
          dot.Position = UDim2.new(0, 0, 0.5, -6)
          dot.BackgroundColor3 = color
          dot.BorderSizePixel = 0
          local dotCorner = Instance.new("UICorner", dot)
          dotCorner.CornerRadius = UDim.new(1, 0)

          local label = Instance.new("TextLabel", row)
          label.Size = UDim2.new(1, -20, 1, 0)
          label.Position = UDim2.new(0, 20, 0, 0)
          label.BackgroundTransparency = 1
          label.Text = name
          label.TextColor3 = color
          label.TextSize = 13
          label.Font = Enum.Font.GothamSemibold
          label.TextXAlignment = Enum.TextXAlignment.Left

          legendLabels[name] = label
          i = i + 1
     end
end

local function tryAddUi(getPartFunc, fallbackLegendKey)
     local success, part = pcall(getPartFunc)
     if success and part then
          local addSuccess = pcall(addUi, part)
          if not addSuccess then
               if fallbackLegendKey == "SCP-966" then
                    failed966Count = failed966Count + 1
                    if failed966Count >= 4 then markTerminated("SCP-966") end
               else
                    markTerminated(fallbackLegendKey)
               end
          end
     else
          if fallbackLegendKey == "SCP-966" then
               failed966Count = failed966Count + 1
               if failed966Count >= 4 then markTerminated("SCP-966") end
          else
               markTerminated(fallbackLegendKey)
          end
     end
end

local ws = game:GetService("Workspace")
local s2 = ws.Sectors.Sector2.SCPs
local s3 = ws.Sectors.Sector3.SCPs
local s4 = ws.Sectors.Sector4.SCPs

createLegend()

tryAddUi(function() return s4["SCP-058"].Torso end,                          "SCP-058")
tryAddUi(function() return s4["SCP-1350"].Main end,                          "SCP-1350")
tryAddUi(function() return s4["SCP-352-2"].HumanoidRootPart end,             "SCP-352-2")
tryAddUi(function() return s3["SCP-017"].HumanoidRootPart end,               "SCP-017")
tryAddUi(function() return s3["SCP-049"].HumanoidRootPart end,               "SCP-049")
tryAddUi(function() return s3["SCP-280"].HumanoidRootPart end,               "SCP-280")
tryAddUi(function() return s3["SCP-457"].HumanoidRootPart end,               "SCP-457")
tryAddUi(function() return s3["SCP-966"]["SCP-966-1"].HumanoidRootPart end,  "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-2"].HumanoidRootPart end,  "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-3"].HumanoidRootPart end,  "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-4"].HumanoidRootPart end,  "SCP-966")
tryAddUi(function() return s2["SCP-173"].HumanoidRootPart end,               "SCP-173")

UserInputService.InputBegan:Connect(function(input)
     if input.KeyCode == Enum.KeyCode.F5 then
          hidden = not hidden

          local legend = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Legend")
          if legend then legend.Enabled = not hidden end

          local function toggleGuis(parent)
               for _, obj in ipairs(parent:GetDescendants()) do
                    if obj:IsA("BillboardGui") and (obj.Name == "Item-ESP" or obj.Name == "Name") then
                         obj.Enabled = not hidden
                    end
               end
          end

          toggleGuis(ws.Sectors.Sector2.SCPs)
          toggleGuis(ws.Sectors.Sector3.SCPs)
          toggleGuis(ws.Sectors.Sector4.SCPs)
     end
end)
