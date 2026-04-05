local espSize = 2
local tracerThickness = 1.5
local settingsOpen = false

local colors = {
     ["SCP-1155"] = Color3.fromRGB(255, 165, 0),
     ["SCP-017"]  = Color3.fromRGB(150, 0, 255),
     ["SCP-049"]  = Color3.fromRGB(0, 200, 0),
     ["SCP-280"]  = Color3.fromRGB(0, 100, 255),
     ["SCP-457"]  = Color3.fromRGB(255, 100, 0),
     ["SCP-966"]  = Color3.fromRGB(255, 255, 0),
     ["SCP-058"]  = Color3.fromRGB(255, 0, 0),
     ["SCP-352-2"]= Color3.fromRGB(255, 0, 150),
     ["SCP-1350"] = Color3.fromRGB(0, 255, 255),
     ["SCP-173"]  = Color3.fromRGB(200, 200, 200),
	 ["SCP-914-X"] = Color3.fromRGB(255, 50, 50),
     ["SCP-610"] = Color3.fromRGB(234, 184, 146),
     ["SCP-049-2"] = Color3.fromRGB(0, 150, 100),
}

local instanceLocationNames = {
     {pos = Vector3.new(67.4,   408.1, 502.8), name = "Original Position"},
     {pos = Vector3.new(5.1,    406.9, 535.7), name = "S3L T Junction"},
     {pos = Vector3.new(-19.4,  406.7, 42.2),  name = "IDK man report it to BIRD"},
     {pos = Vector3.new(-250.8, 406.3, 268.1), name = "457 CZ"},
     {pos = Vector3.new(-380.6, 406.7, 291.2), name = "S3R Entrance 3"},
     {pos = Vector3.new(-259.2, 397.9, 385.9), name = "SCP-280 CZ"},
     {pos = Vector3.new(79.8,   407.5, 60.3),  name = "SCP-035 CZ"},
     {pos = Vector3.new(-14.8,  407.5, 41.3),  name = "SCP-173 CZ2"},
     {pos = Vector3.new(-311.4, 422.9, 271.3), name = "457 CZ Upstairs"},
     {pos = Vector3.new(-421.5, 408.1, 269.2), name = "S3R Entrance 2"},
     {pos = Vector3.new(-414.3, 408.1, 230.3), name = "S3R Entrance 1"},
     {pos = Vector3.new(-142.6, 407.1, 662.5), name = "S3M AUX"},
     {pos = Vector3.new(181.5,  407.5, 84.1),  name = "CDCVA"},
}

local function getLocationName(position)
     for _, entry in ipairs(instanceLocationNames) do
          if (position - entry.pos).Magnitude < 20 then
               return entry.name
          end
     end
     return "Unknown Location"
end

local function getDirectBasePart(model)
     for _, child in ipairs(model:GetChildren()) do
          if child:IsA("BasePart") then
               return child
          end
     end
end

local legendLabels = {}
local tracerLines = {}
local hidden = false
local tracersEnabled = true
local active966Count = 0
local failed966Count = 0

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local s2 = ws.Sectors.Sector2.SCPs
local s3 = ws.Sectors.Sector3.SCPs
local s4 = ws.Sectors.Sector4.SCPs

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
     outline.Thickness    = tracerThickness + 1.5
     outline.Color        = Color3.fromRGB(25, 25, 25)
     outline.Transparency = 0.75
     outline.Visible      = false

     local line = Drawing.new("Line")
     line.Thickness    = tracerThickness
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
     partGui.Size = UDim2.new(espSize, 0, espSize, 0)
     partGui.AlwaysOnTop = true
     partGui.MaxDistance = 1000
     partGui.Name = "Item-ESP"

     local frame = Instance.new("Frame", partGui)
     frame.BackgroundColor3 = color
     frame.BackgroundTransparency = 0.75
     frame.Size = UDim2.new(2, 0, 2, 0)
     frame.BorderSizePixel = 0

     local nameGui = Instance.new("BillboardGui", part)
     nameGui.Size = UDim2.new(6, 0, 3, 0)
     nameGui.SizeOffset = Vector2.new(0, 1)
     nameGui.AlwaysOnTop = true
     nameGui.MaxDistance = 1000
     nameGui.Name = "Name"

     local text = Instance.new("TextLabel", nameGui)
     text.Text = entityName
     text.TextColor3 = color
     text.TextTransparency = 0.25
     text.BackgroundTransparency = 1
     text.TextScaled = true
     text.Size = UDim2.new(1, 0, 1, 0)
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

local function setup1155()
     local ok, locations = pcall(function()
          return ws.Sectors.Sector3.SCPs["SCP-1155"].Locations
     end)
     if not ok or not locations then
          markTerminated("SCP-1155")
          return
     end

     local color = colors["SCP-1155"]

     local function clearTracer(part)
          local uid = part:GetDebugId()
          if tracerLines[uid] then
               tracerLines[uid].Line.Visible = false
               tracerLines[uid].Outline.Visible = false
               tracerLines[uid] = nil
          end
     end

     local function clearESP(part)
          if not part then return end
          local esp = part:FindFirstChild("Item-ESP")
          if esp then esp:Destroy() end
          local nameGui = part:FindFirstChild("Name")
          if nameGui then nameGui:Destroy() end
          clearTracer(part)
     end

     local function showESP(part, label)
          if not part then return end
          if part:FindFirstChild("Item-ESP") then return end

          local partGui = Instance.new("BillboardGui", part)
          partGui.Size = UDim2.new(4, 0, 4, 0)
          partGui.AlwaysOnTop = true
          partGui.MaxDistance = 1000
          partGui.Name = "Item-ESP"

          local frame = Instance.new("Frame", partGui)
          frame.BackgroundColor3 = color
          frame.BackgroundTransparency = 0.75
          frame.Size = UDim2.new(1, 0, 1, 0)
          frame.BorderSizePixel = 0

          local nameGui = Instance.new("BillboardGui", part)
          nameGui.Size = UDim2.new(24, 0, 6, 0)
          nameGui.SizeOffset = Vector2.new(0, 1)
          nameGui.AlwaysOnTop = true
          nameGui.MaxDistance = 1000
          nameGui.Name = "Name"

          local text = Instance.new("TextLabel", nameGui)
          text.Text = "SCP-1155 [" .. label .. "]"
          text.TextColor3 = color
          text.TextTransparency = 0.25
          text.BackgroundTransparency = 1
          text.TextScaled = true
          text.Size = UDim2.new(1, 0, 1, 0)
          text.Font = Enum.Font.GothamSemibold
          text.Name = "Text"

          createTracer(part, color, "SCP-1155")

          if legendLabels["SCP-1155"] then
               legendLabels["SCP-1155"].Text = "SCP-1155 [" .. label .. "]"
               legendLabels["SCP-1155"].TextColor3 = color
          end
     end

     local originalInstance = locations:FindFirstChild("Original")
     local originalPart = originalInstance and (
          originalInstance.PrimaryPart or getDirectBasePart(originalInstance)
     )

     if originalInstance and originalPart then
          local activeBool = originalInstance:FindFirstChild("Active")

          if activeBool and not activeBool.Value then
               showESP(originalPart, "Original Position")
          end

          if activeBool then
               activeBool:GetPropertyChangedSignal("Value"):Connect(function()
                    if not activeBool.Value then
                         showESP(originalPart, "Original Position")
                    else
                         clearESP(originalPart)
                    end
               end)
          end
     end

     for _, child in ipairs(locations:GetChildren()) do
          if child.Name ~= "Instance" then continue end

          local activeBool = child:FindFirstChild("Active")
          local part = child.PrimaryPart or getDirectBasePart(child)
          if not activeBool or not part then continue end

          local friendlyName = getLocationName(part.Position)

          if activeBool.Value then
               clearESP(originalPart)
               showESP(part, friendlyName)
          end

          activeBool:GetPropertyChangedSignal("Value"):Connect(function()
               if activeBool.Value then
                    clearESP(originalPart)
                    showESP(part, friendlyName)
               else
                    clearESP(part)
                    local anyActive = false
                    for _, c in ipairs(locations:GetChildren()) do
                         local ab = c:FindFirstChild("Active")
                         if ab and ab.Value then anyActive = true break end
                    end
                    if not anyActive and originalPart then
                         showESP(originalPart, "Original Position")
                    end
               end
          end)
     end

     if legendLabels["SCP-1155"] then
          legendLabels["SCP-1155"].Text = "SCP-1155 [Original Position]"
          legendLabels["SCP-1155"].TextColor3 = color
     end
end

local function setup914X()
     local Players = game:GetService("Players")
     local color = colors["SCP-914-X"]
     local tracked = {}

     local function is914X(player)
          local char = player.Character
          if not char then return false end
          local torso = char:FindFirstChild("Torso")
          if not torso then return false end
          local isBlack = torso.Color == Color3.new(0, 0, 0)
          if not isBlack then return false end
          local hasShirt = char:FindFirstChildOfClass("Shirt") ~= nil
          local hasPants = char:FindFirstChildOfClass("Pants") ~= nil
          local hasAccessory = char:FindFirstChildOfClass("Accessory") ~= nil
          return not hasShirt and not hasPants and not hasAccessory
     end

     local function update914XLegend()
          local count = 0
          for _ in pairs(tracked) do count = count + 1 end
          if legendLabels["SCP-914-X"] then
               if count == 0 then
                    legendLabels["SCP-914-X"].Text = "SCP-914-X (none active)"
                    legendLabels["SCP-914-X"].TextColor3 = Color3.fromRGB(100, 100, 100)
               else
                    legendLabels["SCP-914-X"].Text = "SCP-914-X (" .. count .. " active)"
                    legendLabels["SCP-914-X"].TextColor3 = color
               end
          end
     end

     local function removeESP(player)
          if not tracked[player.Name] then return end
          local torso = tracked[player.Name]
          tracked[player.Name] = nil

          local esp = torso:FindFirstChild("Item-ESP")
          if esp then esp:Destroy() end
          local nameGui = torso:FindFirstChild("Name")
          if nameGui then nameGui:Destroy() end

          local uid = torso:GetDebugId()
          if tracerLines[uid] then
               tracerLines[uid].Line.Visible = false
               tracerLines[uid].Outline.Visible = false
               tracerLines[uid] = nil
          end

          update914XLegend()
     end

     local function addESP(player)
          if tracked[player.Name] then return end
          local char = player.Character
          if not char then return end
          local torso = char:FindFirstChild("Torso")
          if not torso then return end

          tracked[player.Name] = torso

          local partGui = Instance.new("BillboardGui", torso)
          partGui.Size = UDim2.new(espSize, 0, espSize, 0)
          partGui.AlwaysOnTop = true
          partGui.MaxDistance = 1000
          partGui.Name = "Item-ESP"

          local frame = Instance.new("Frame", partGui)
          frame.BackgroundColor3 = color
          frame.BackgroundTransparency = 0.75
          frame.Size = UDim2.new(2, 0, 2, 0)
          frame.BorderSizePixel = 0

          local nameGui = Instance.new("BillboardGui", torso)
          nameGui.Size = UDim2.new(6, 0, 3, 0)
          nameGui.SizeOffset = Vector2.new(0, 1)
          nameGui.AlwaysOnTop = true
          nameGui.MaxDistance = 1000
          nameGui.Name = "Name"

          local text = Instance.new("TextLabel", nameGui)
          text.Text = "SCP-914-X [" .. player.Name .. "]"
          text.TextColor3 = color
          text.TextTransparency = 0.25
          text.BackgroundTransparency = 1
          text.TextScaled = true
          text.Size = UDim2.new(1, 0, 1, 0)
          text.Font = Enum.Font.GothamSemibold
          text.Name = "Text"

          createTracer(torso, color, "SCP-914-X")
          update914XLegend()
     end

     local function watchPlayer(player)
          local function onCharacter(char)
               removeESP(player)

               local torso = char:FindFirstChild("Torso")
               if not torso then
                    local added = char.ChildAdded:Wait()
                    while added.Name ~= "Torso" do
                         added = char.ChildAdded:Wait()
                    end
                    torso = added
               end

               if not torso then return end

               torso.Changed:Connect(function()
                    if is914X(player) then addESP(player) else removeESP(player) end
               end)

               char.ChildAdded:Connect(function()
                    if not is914X(player) then removeESP(player) end
               end)

               char.ChildRemoved:Connect(function()
                    if is914X(player) then addESP(player) end
               end)

               if is914X(player) then
                    addESP(player)
               end
          end

          if player.Character then
               onCharacter(player.Character)
          end
          player.CharacterAdded:Connect(onCharacter)
          player.CharacterRemoving:Connect(function()
               removeESP(player)
          end)
     end

     for _, player in ipairs(Players:GetPlayers()) do
          watchPlayer(player)
     end

     Players.PlayerAdded:Connect(function(player)
          watchPlayer(player)
     end)

     Players.PlayerRemoving:Connect(function(player)
          removeESP(player)
     end)

     update914XLegend()
end
local function setup610()
     local Players = game:GetService("Players")
     local color = colors["SCP-610"]
     local tracked = {}

     local function is610(player)
          local char = player.Character
          if not char then return false end
          local torso = char:FindFirstChild("Torso")
          if not torso then return false end
          local hasMorph = char:FindFirstChild("Morph") ~= nil
          local isOrange = torso.Color == Color3.fromRGB(234, 184, 146)
          return hasMorph and isOrange
     end

     local function update610Legend()
          local count = 0
          for _ in pairs(tracked) do count = count + 1 end
          if legendLabels["SCP-610"] then
               if count == 0 then
                    legendLabels["SCP-610"].Text = "SCP-610 (none active)"
                    legendLabels["SCP-610"].TextColor3 = Color3.fromRGB(100, 100, 100)
               else
                    legendLabels["SCP-610"].Text = "SCP-610 (" .. count .. " active)"
                    legendLabels["SCP-610"].TextColor3 = color
               end
          end
     end

     local function removeESP(player)
          if not tracked[player.Name] then return end
          local torso = tracked[player.Name]
          tracked[player.Name] = nil

          local esp = torso:FindFirstChild("Item-ESP")
          if esp then esp:Destroy() end
          local nameGui = torso:FindFirstChild("Name")
          if nameGui then nameGui:Destroy() end

          local uid = torso:GetDebugId()
          if tracerLines[uid] then
               tracerLines[uid].Line.Visible = false
               tracerLines[uid].Outline.Visible = false
               tracerLines[uid] = nil
          end

          update610Legend()
     end

     local function addESP(player)
          if tracked[player.Name] then return end
          local char = player.Character
          if not char then return end
          local torso = char:FindFirstChild("Torso")
          if not torso then return end

          tracked[player.Name] = torso

          local partGui = Instance.new("BillboardGui", torso)
          partGui.Size = UDim2.new(espSize, 0, espSize, 0)
          partGui.AlwaysOnTop = true
          partGui.MaxDistance = 1000
          partGui.Name = "Item-ESP"

          local frame = Instance.new("Frame", partGui)
          frame.BackgroundColor3 = color
          frame.BackgroundTransparency = 0.75
          frame.Size = UDim2.new(2, 0, 2, 0)
          frame.BorderSizePixel = 0

          local nameGui = Instance.new("BillboardGui", torso)
          nameGui.Size = UDim2.new(6, 0, 3, 0)
          nameGui.SizeOffset = Vector2.new(0, 1)
          nameGui.AlwaysOnTop = true
          nameGui.MaxDistance = 1000
          nameGui.Name = "Name"

          local text = Instance.new("TextLabel", nameGui)
          text.Text = "SCP-610 [" .. player.Name .. "]"
          text.TextColor3 = color
          text.TextTransparency = 0.25
          text.BackgroundTransparency = 1
          text.TextScaled = true
          text.Size = UDim2.new(1, 0, 1, 0)
          text.Font = Enum.Font.GothamSemibold
          text.Name = "Text"

          createTracer(torso, color, "SCP-610")
          update610Legend()
     end

     local function watchPlayer(player)
          local function onCharacter(char)
               removeESP(player)

               local torso = char:FindFirstChild("Torso")
               if not torso then
                    local added = char.ChildAdded:Wait()
                    while added.Name ~= "Torso" do
                         added = char.ChildAdded:Wait()
                    end
                    torso = added
               end

               if not torso then return end

               torso.Changed:Connect(function()
                    if is610(player) then addESP(player) else removeESP(player) end
               end)

               char.ChildAdded:Connect(function()
                    if is610(player) then addESP(player) else removeESP(player) end
               end)

               char.ChildRemoved:Connect(function()
                    if is610(player) then addESP(player) else removeESP(player) end
               end)

               if is610(player) then
                    addESP(player)
               end
          end

          if player.Character then
               onCharacter(player.Character)
          end
          player.CharacterAdded:Connect(onCharacter)
          player.CharacterRemoving:Connect(function()
               removeESP(player)
          end)
     end

     for _, player in ipairs(Players:GetPlayers()) do
          watchPlayer(player)
     end

     Players.PlayerAdded:Connect(function(player)
          watchPlayer(player)
     end)

     Players.PlayerRemoving:Connect(function(player)
          removeESP(player)
     end)

     update610Legend()
end
local function setup0492()
     local Players = game:GetService("Players")
     local color = colors["SCP-049-2"]
     local tracked = {}

     local function is0492(player)
          local char = player.Character
          if not char then return false end
          local torso = char:FindFirstChild("Torso")
          if not torso then return false end
          local hasParticle = torso:FindFirstChildOfClass("ParticleEmitter") ~= nil
          local hasSound = torso:FindFirstChildOfClass("Sound") ~= nil
          return hasParticle and hasSound
     end

     local function update0492Legend()
          local count = 0
          for _ in pairs(tracked) do count = count + 1 end
          if legendLabels["SCP-049-2"] then
               if count == 0 then
                    legendLabels["SCP-049-2"].Text = "SCP-049-2 (none active)"
                    legendLabels["SCP-049-2"].TextColor3 = Color3.fromRGB(100, 100, 100)
               else
                    legendLabels["SCP-049-2"].Text = "SCP-049-2 (" .. count .. " active)"
                    legendLabels["SCP-049-2"].TextColor3 = color
               end
          end
     end

     local function removeESP(player)
          if not tracked[player.Name] then return end
          local torso = tracked[player.Name]
          tracked[player.Name] = nil

          local esp = torso:FindFirstChild("Item-ESP")
          if esp then esp:Destroy() end
          local nameGui = torso:FindFirstChild("Name")
          if nameGui then nameGui:Destroy() end

          local uid = torso:GetDebugId()
          if tracerLines[uid] then
               tracerLines[uid].Line.Visible = false
               tracerLines[uid].Outline.Visible = false
               tracerLines[uid] = nil
          end

          update0492Legend()
     end

     local function addESP(player)
          if tracked[player.Name] then return end
          local char = player.Character
          if not char then return end
          local torso = char:FindFirstChild("Torso")
          if not torso then return end

          tracked[player.Name] = torso

          local partGui = Instance.new("BillboardGui", torso)
          partGui.Size = UDim2.new(espSize, 0, espSize, 0)
          partGui.AlwaysOnTop = true
          partGui.MaxDistance = 1000
          partGui.Name = "Item-ESP"

          local frame = Instance.new("Frame", partGui)
          frame.BackgroundColor3 = color
          frame.BackgroundTransparency = 0.75
          frame.Size = UDim2.new(2, 0, 2, 0)
          frame.BorderSizePixel = 0

          local nameGui = Instance.new("BillboardGui", torso)
          nameGui.Size = UDim2.new(6, 0, 3, 0)
          nameGui.SizeOffset = Vector2.new(0, 1)
          nameGui.AlwaysOnTop = true
          nameGui.MaxDistance = 1000
          nameGui.Name = "Name"

          local text = Instance.new("TextLabel", nameGui)
          text.Text = "SCP-049-2 [" .. player.Name .. "]"
          text.TextColor3 = color
          text.TextTransparency = 0.25
          text.BackgroundTransparency = 1
          text.TextScaled = true
          text.Size = UDim2.new(1, 0, 1, 0)
          text.Font = Enum.Font.GothamSemibold
          text.Name = "Text"

          createTracer(torso, color, "SCP-049-2")
          update0492Legend()
     end

     local function watchPlayer(player)
          local function onCharacter(char)
               removeESP(player)

               local torso = char:FindFirstChild("Torso")
               if not torso then
                    local added = char.ChildAdded:Wait()
                    while added.Name ~= "Torso" do
                         added = char.ChildAdded:Wait()
                    end
                    torso = added
               end

               if not torso then return end

               -- watch torso children for particle and sound appearing/disappearing
               torso.ChildAdded:Connect(function()
                    if is0492(player) then addESP(player) end
               end)

               torso.ChildRemoved:Connect(function()
                    if not is0492(player) then removeESP(player) end
               end)

               if is0492(player) then
                    addESP(player)
               end
          end

          if player.Character then
               onCharacter(player.Character)
          end
          player.CharacterAdded:Connect(onCharacter)
          player.CharacterRemoving:Connect(function()
               removeESP(player)
          end)
     end

     for _, player in ipairs(Players:GetPlayers()) do
          watchPlayer(player)
     end

     Players.PlayerAdded:Connect(function(player)
          watchPlayer(player)
     end)

     Players.PlayerRemoving:Connect(function(player)
          removeESP(player)
     end)

     update0492Legend()
end
local function createSettingsMenu()
     if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Settings") then return end

     local screenGui = Instance.new("ScreenGui")
     screenGui.Name = "ESP-Settings"
     screenGui.ResetOnSpawn = false
     screenGui.Parent = game.Players.LocalPlayer.PlayerGui
     screenGui.Enabled = false

     local frame = Instance.new("Frame", screenGui)
     frame.Size = UDim2.new(0, 180, 0, 90)
     frame.Position = UDim2.new(0, 200, 1, -110)
     frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
     frame.BackgroundTransparency = 0.3
     frame.BorderSizePixel = 0

     local corner = Instance.new("UICorner", frame)
     corner.CornerRadius = UDim.new(0, 8)

     local padding = Instance.new("UIPadding", frame)
     padding.PaddingLeft = UDim.new(0, 8)
     padding.PaddingTop = UDim.new(0, 8)
     padding.PaddingRight = UDim.new(0, 8)

     local title = Instance.new("TextLabel", frame)
     title.Size = UDim2.new(1, 0, 0, 16)
     title.Position = UDim2.new(0, 0, 0, 0)
     title.BackgroundTransparency = 1
     title.Text = "ESP Settings"
     title.TextColor3 = Color3.fromRGB(200, 200, 200)
     title.TextSize = 12
     title.Font = Enum.Font.GothamSemibold
     title.TextXAlignment = Enum.TextXAlignment.Left

     local sizeLabel = Instance.new("TextLabel", frame)
     sizeLabel.Size = UDim2.new(1, 0, 0, 14)
     sizeLabel.Position = UDim2.new(0, 0, 0, 20)
     sizeLabel.BackgroundTransparency = 1
     sizeLabel.Text = "ESP Size: 2.0"
     sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
     sizeLabel.TextSize = 11
     sizeLabel.Font = Enum.Font.GothamSemibold
     sizeLabel.TextXAlignment = Enum.TextXAlignment.Left

     local sizeTrack = Instance.new("Frame", frame)
     sizeTrack.Size = UDim2.new(1, -8, 0, 8)
     sizeTrack.Position = UDim2.new(0, 0, 0, 36)
     sizeTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
     sizeTrack.BorderSizePixel = 0
     local sizeTrackCorner = Instance.new("UICorner", sizeTrack)
     sizeTrackCorner.CornerRadius = UDim.new(1, 0)

     local sizeThumb = Instance.new("Frame", sizeTrack)
     sizeThumb.Size = UDim2.new(0, 12, 0, 12)
     sizeThumb.Position = UDim2.new(0.08, -6, 0.5, -6)
     sizeThumb.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
     sizeThumb.BorderSizePixel = 0
     local sizeThumbCorner = Instance.new("UICorner", sizeThumb)
     sizeThumbCorner.CornerRadius = UDim.new(1, 0)

     local sizeButton = Instance.new("TextButton", sizeTrack)
     sizeButton.Size = UDim2.new(1, 0, 1, 0)
     sizeButton.BackgroundTransparency = 1
     sizeButton.Text = ""

     local thickLabel = Instance.new("TextLabel", frame)
     thickLabel.Size = UDim2.new(1, 0, 0, 14)
     thickLabel.Position = UDim2.new(0, 0, 0, 50)
     thickLabel.BackgroundTransparency = 1
     thickLabel.Text = "Line Thickness: 1.5"
     thickLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
     thickLabel.TextSize = 11
     thickLabel.Font = Enum.Font.GothamSemibold
     thickLabel.TextXAlignment = Enum.TextXAlignment.Left

     local thickTrack = Instance.new("Frame", frame)
     thickTrack.Size = UDim2.new(1, -8, 0, 8)
     thickTrack.Position = UDim2.new(0, 0, 0, 66)
     thickTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
     thickTrack.BorderSizePixel = 0
     local thickTrackCorner = Instance.new("UICorner", thickTrack)
     thickTrackCorner.CornerRadius = UDim.new(1, 0)

     local thickThumb = Instance.new("Frame", thickTrack)
     thickThumb.Size = UDim2.new(0, 12, 0, 12)
     thickThumb.Position = UDim2.new(0.1, -6, 0.5, -6)
     thickThumb.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
     thickThumb.BorderSizePixel = 0
     local thickThumbCorner = Instance.new("UICorner", thickThumb)
     thickThumbCorner.CornerRadius = UDim.new(1, 0)

     local thickButton = Instance.new("TextButton", thickTrack)
     thickButton.Size = UDim2.new(1, 0, 1, 0)
     thickButton.BackgroundTransparency = 1
     thickButton.Text = ""

     local function makeSlider(track, thumb, button, minVal, maxVal, onChanged)
          local dragging = false
          local function update(inputX)
               local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
               local value = math.floor((minVal + (maxVal - minVal) * rel) * 10) / 10
               thumb.Position = UDim2.new(rel, -6, 0.5, -6)
               onChanged(value)
          end
          button.MouseButton1Down:Connect(function() dragging = true end)
          UserInputService.InputChanged:Connect(function(input)
               if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input.Position.X)
               end
          end)
          UserInputService.InputEnded:Connect(function(input)
               if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
               end
          end)
     end

     makeSlider(sizeTrack, sizeThumb, sizeButton, 0.5, 20, function(val)
          espSize = val
          sizeLabel.Text = "ESP Size: " .. tostring(val)
          for _, sector in ipairs({s2, s3, s4}) do
               for _, obj in ipairs(sector:GetDescendants()) do
                    if obj:IsA("BillboardGui") and obj.Name == "Item-ESP" then
                         local nameGui = obj.Parent:FindFirstChild("Name")
                         local textLabel = nameGui and nameGui:FindFirstChild("Text")
                         if textLabel and not textLabel.Text:find("SCP-1155") then
                              obj.Size = UDim2.new(val, 0, val, 0)
                         end
                    end
               end
          end
     end)

     makeSlider(thickTrack, thickThumb, thickButton, 0.5, 5, function(val)
          tracerThickness = val
          thickLabel.Text = "Line Thickness: " .. tostring(val)
          for _, t in pairs(tracerLines) do
               if t.LegendKey ~= "SCP-1155" then
                    t.Line.Thickness = val
                    t.Outline.Thickness = val + 1.5
               end
          end
     end)

     return screenGui
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
                    t.Line.Visible = false
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

createLegend()
createSettingsMenu()
setup1155()
setup914X()
setup610()
setup0492()

tryAddUi(function() return s4["SCP-058"].Torso end,                         "SCP-058")
tryAddUi(function() return s4["SCP-1350"].Main end,                         "SCP-1350")
tryAddUi(function() return s4["SCP-352-2"].HumanoidRootPart end,            "SCP-352-2")
tryAddUi(function() return s3["SCP-017"].HumanoidRootPart end,              "SCP-017")
tryAddUi(function() return s3["SCP-049"].HumanoidRootPart end,              "SCP-049")
tryAddUi(function() return s3["SCP-280"].HumanoidRootPart end,              "SCP-280")
tryAddUi(function() return s3["SCP-457"].HumanoidRootPart end,              "SCP-457")
tryAddUi(function() return s3["SCP-966"]["SCP-966-1"].HumanoidRootPart end, "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-2"].HumanoidRootPart end, "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-3"].HumanoidRootPart end, "SCP-966")
tryAddUi(function() return s3["SCP-966"]["SCP-966-4"].HumanoidRootPart end, "SCP-966")
tryAddUi(function() return s2["SCP-173"].HumanoidRootPart end,              "SCP-173")

UserInputService.InputBegan:Connect(function(input)
     if input.KeyCode == Enum.KeyCode.F5 then
          hidden = not hidden

          local legend = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Legend")
          if legend then legend.Enabled = not hidden end

          local settings = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Settings")
          if settings and hidden then settings.Enabled = false end

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

     elseif input.KeyCode == Enum.KeyCode.F8 then
          if hidden then return end
          local settings = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Settings")
          if settings then
               settings.Enabled = not settings.Enabled
          end
     end
end)
