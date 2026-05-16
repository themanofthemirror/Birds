if _G.BirdESP_Active then
     pcall(function() RunService:UnbindFromRenderStep("SCP_Tracers") end)
     pcall(function() RunService:UnbindFromRenderStep("SCP_Spectate") end)
     if _G.BirdESP_TracerLines then
          for _, t in pairs(_G.BirdESP_TracerLines) do
               pcall(function() t.Line:Remove() end)
               pcall(function() t.Outline:Remove() end)
          end
     end
     if _G.BirdESP_ArrowDrawings then
          for _, arrow in pairs(_G.BirdESP_ArrowDrawings) do
               pcall(function() arrow:Remove() end)
          end
     end
     pcall(function()
          for _, sector in ipairs({
               game:GetService("Workspace").Sectors.Sector2.SCPs,
               game:GetService("Workspace").Sectors.Sector3.SCPs,
               game:GetService("Workspace").Sectors.Sector4.SCPs,
          }) do
               for _, obj in ipairs(sector:GetDescendants()) do
                    if obj:IsA("BillboardGui") and (obj.Name == "Item-ESP" or obj.Name == "Name") then
                         obj:Destroy()
                    end
               end
          end
     end)
     pcall(function()
          local pg = game.Players.LocalPlayer.PlayerGui
          for _, name in ipairs({"ESP-Legend", "ESP-Settings", "ESP-Minimap", "ESP-SpectateLabel"}) do
               local gui = pg:FindFirstChild(name)
               if gui then gui:Destroy() end
          end
     end)
     -- clear player character billboards
     pcall(function()
          for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
               local char = player.Character
               if not char then continue end
               for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BillboardGui") and (obj.Name == "Item-ESP" or obj.Name == "Name") then
                         obj:Destroy()
                    end
               end
          end
     end)
end

_G.BirdESP_Active = true

--All Gloabals
local espSize = 2
local tracerThickness = 1.5
local settingsOpen = false
local spectating = false
local spectateIndex = 1
local spectateList = {}
local originalCameraType = nil
local originalCameraCFrame = nil

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
      ["SCP-999"] = Color3.fromRGB(255, 200, 0), 
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
local arrowDrawings = {}
_G.BirdESP_TracerLines = tracerLines
_G.BirdESP_ArrowDrawings = arrowDrawings

local hidden = false
local tracersEnabled = true
local active966Count = 0
local failed966Count = 0
local alertSoundEnabled = true
local alertVisualEnabled = true
local alertRadius = 60
local alertSoundId = "9120386436"

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local s2 = ws.Sectors.Sector2.SCPs
local s3 = ws.Sectors.Sector3.SCPs
local s4 = ws.Sectors.Sector4.SCPs

local containmentZones = {
     ["SCP-173"]  = {pos = Vector3.new(23.9,   405.4, 30.1),   radius = 60},
     ["SCP-017"]  = {pos = Vector3.new(98.5,   387.9, 631.9),  radius = 60},
     ["SCP-049"]  = {pos = Vector3.new(-103.9, 388.9, 448.4),  radius = 60},
     ["SCP-280"]  = {pos = Vector3.new(-277.5, 393.5, 333.4),  radius = 60},
     ["SCP-457"]  = {pos = Vector3.new(-265.4, 404.4, 263.1),  radius = 60},
     ["SCP-058"]  = {pos = Vector3.new(-2.3,   404.4, 929.1),  radius = 60},
     ["SCP-352-2"]= {pos = Vector3.new(-213.3, 390.1, 859.4),  radius = 60},
     ["SCP-1350"] = {pos = Vector3.new(-214.4, 380.1, 1009.8), radius = 60},
     ["SCP-966"]  = {pos = Vector3.new(-34.58, 391.458, 579.143), radius = 60}, -- update pos to actual 966 CZ
     ["SCP-999"]  = {pos = Vector3.new(-201.752, 402.13, 59.914), radius =60}
}

local breachedAlerts = {}  -- tracks which SCPs are currently breached
local alertCooldowns = {}  -- prevents spam
local alertSound = nil

-- create alert sound once
local function createAlertSound()
     local sound = Instance.new("Sound")
     sound.SoundId = "rbxassetid://" .. alertSoundId
     sound.Volume = 0.5
     sound.Parent = game.Players.LocalPlayer.PlayerGui
     alertSound = sound
end

local function flashLabel(legendKey, isBreached)
     local label = legendLabels[legendKey]
     if not label then return end

     if isBreached then
          breachedAlerts[legendKey] = true
          local originalColor = colors[legendKey]

          -- update legend text to show breached
          label.Text = legendKey .. " [BREACHED]"

          coroutine.wrap(function()
               local t = 0
               while breachedAlerts[legendKey] do
                    t = t + 0.05
                    local alpha = (math.sin(t * math.pi) + 1) / 2  -- smooth 0 to 1 wave
                    label.TextColor3 = originalColor:Lerp(Color3.fromRGB(255, 0, 0), alpha)
                    task.wait(0.03)
               end
               label.TextColor3 = originalColor
               label.Text = legendKey
          end)()

          if alertSoundEnabled and not alertCooldowns[legendKey] then
               alertCooldowns[legendKey] = true
               if alertSound then alertSound:Play() end
               task.delay(5, function()
                    alertCooldowns[legendKey] = nil
               end)
          end
     else
          breachedAlerts[legendKey] = nil
     end
end

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
    
     local uid = part:GetDebugId()
     

     if tracerLines[uid] then return end

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

     tracerLines[uid] = { Line = line, Outline = outline, Part = part, LegendKey = legendKey }
end



-- off screen arrows storage


local function getOrCreateArrow(uid, color)
     if not arrowDrawings[uid] then
          local arrow = Drawing.new("Triangle")
          arrow.Color = color
          arrow.Filled = true
          arrow.Transparency = 0.5
          arrow.Visible = false
          arrowDrawings[uid] = arrow
     end
     return arrowDrawings[uid]
end

RunService:BindToRenderStep("SCP_Tracers", 300, function()
     if hidden or not tracersEnabled then
          for _, t in pairs(tracerLines) do
               t.Line.Visible    = false
               t.Outline.Visible = false
          end
          for _, arrow in pairs(arrowDrawings) do
               arrow.Visible = false
          end
          return
     end

     local fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
     local vx, vy = Camera.ViewportSize.X, Camera.ViewportSize.Y
     local cx, cy = vx / 2, vy / 2
     local arrowMargin = 40  -- pixels from screen edge

     for uid, t in pairs(tracerLines) do
          local part = t.Part
          local arrow = getOrCreateArrow(uid, t.Line.Color)

          if not part or not part.Parent then
               t.Line.Visible    = false
               t.Outline.Visible = false
               arrow.Visible     = false
          else
               local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
               local distance = (Camera.CFrame.Position - part.Position).Magnitude

               -- proximity fade: closer = more opaque
               local transparency = math.clamp(1 - (distance / 200), 0.25, 0.75)
               -- proximity color fade for tracer: gets brighter when close
               local proximityAlpha = math.clamp(1 - (distance / 500), 0, 1)
               local baseColor = colors[getLegendKey(t.LegendKey)] or Color3.fromRGB(255, 255, 255)
               local proximityAlpha = math.clamp(1 - (distance / 500), 0, 1)
               local fadedColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), proximityAlpha * 0.3)

               if screenPos.Z > 0 and onScreen then
                    -- on screen: show tracer, hide arrow
                    local to = Vector2.new(
                         math.clamp(screenPos.X, 0, vx),
                         math.clamp(screenPos.Y, 0, vy)
                    )

                    t.Line.Visible      = true
                    t.Line.From         = fromPos
                    t.Line.To           = to
                    t.Line.Transparency = transparency
                    t.Line.Color        = fadedColor

                    t.Outline.Visible      = true
                    t.Outline.From         = fromPos
                    t.Outline.To           = to
                    t.Outline.Transparency = transparency - 0.15

                    arrow.Visible = false

                    -- update distance label on billboard
                    local nameGui = part:FindFirstChild("Name")
                    local textLabel = nameGui and nameGui:FindFirstChild("Text")
                    if textLabel then
                         local baseName = textLabel.Text:match("^(.-)%s*%[%d+m%]") or textLabel.Text:match("^(.-)%s*$")
                         textLabel.Text = baseName .. " [" .. math.floor(distance) .. "m]"
                    end

               else
                    -- off screen: hide tracer, show arrow pointing toward SCP
                    t.Line.Visible    = false
                    t.Outline.Visible = false

                    -- calculate direction from screen center to where SCP would be
                    local dir = Vector2.new(screenPos.X - cx, screenPos.Y - cy)
                    if screenPos.Z < 0 then dir = -dir end
                    dir = dir.Unit

                    -- clamp to screen edge with margin
                    local angle = math.atan2(dir.Y, dir.X)
                    local edgeX = cx + math.cos(angle) * (cx - arrowMargin)
                    local edgeY = cy + math.sin(angle) * (cy - arrowMargin)
                    edgeX = math.clamp(edgeX, arrowMargin, vx - arrowMargin)
                    edgeY = math.clamp(edgeY, arrowMargin, vy - arrowMargin)

                    -- draw small triangle arrow pointing in direction
                    local arrowSize = 12
                    local perpAngle = angle + math.pi / 2
                    local tipX = edgeX + math.cos(angle) * arrowSize
                    local tipY = edgeY + math.sin(angle) * arrowSize
                    local baseX1 = edgeX + math.cos(perpAngle) * (arrowSize / 2)
                    local baseY1 = edgeY + math.sin(perpAngle) * (arrowSize / 2)
                    local baseX2 = edgeX - math.cos(perpAngle) * (arrowSize / 2)
                    local baseY2 = edgeY - math.sin(perpAngle) * (arrowSize / 2)

                    arrow.PointA   = Vector2.new(tipX, tipY)
                    arrow.PointB   = Vector2.new(baseX1, baseY1)
                    arrow.PointC   = Vector2.new(baseX2, baseY2)
                    arrow.Color    = fadedColor
                    arrow.Visible  = true
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

local function watchForRespawn(getPartFunc, fallbackLegendKey)
     local function attach()
          local ok, part = pcall(getPartFunc)
          print("watchForRespawn attach:", fallbackLegendKey, "ok:", ok, "part:", part)
          if ok and part then
               local addOk, err = pcall(addUi, part)
               print("addUi result:", fallbackLegendKey, "ok:", addOk, "err:", err)
               pcall(addUi, part)

               -- watch for the part being removed then re-added
               part.AncestryChanged:Connect(function()
                    if not part.Parent then
                         -- wait a moment then try to reattach
                         task.wait(2)
                         attach()
                    end
               end)
          else
               -- part doesnt exist yet, watch the parent for it appearing
               task.wait(3)
               attach()
          end
     end

     task.spawn(attach)
end

local function setup1155()
     local uid = part
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
          local uid = torso
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
     frame.Size = UDim2.new(0, 200, 0, 220)
     frame.Position = UDim2.new(0, 200, 1, -230)
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

     -- helper to make a label
     local function makeLabel(parent, text, yPos)
          local label = Instance.new("TextLabel", parent)
          label.Size = UDim2.new(1, 0, 0, 14)
          label.Position = UDim2.new(0, 0, 0, yPos)
          label.BackgroundTransparency = 1
          label.Text = text
          label.TextColor3 = Color3.fromRGB(180, 180, 180)
          label.TextSize = 11
          label.Font = Enum.Font.GothamSemibold
          label.TextXAlignment = Enum.TextXAlignment.Left
          return label
     end

     -- helper to make a toggle button
     local function makeToggle(parent, text, yPos, initialState, onToggle)
          local btn = Instance.new("TextButton", parent)
          btn.Size = UDim2.new(1, -8, 0, 18)
          btn.Position = UDim2.new(0, 0, 0, yPos)
          btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
          btn.BorderSizePixel = 0
          btn.Text = text .. (initialState and ": ON" or ": OFF")
          btn.TextColor3 = Color3.fromRGB(255, 255, 255)
          btn.TextSize = 11
          btn.Font = Enum.Font.GothamSemibold
          local btnCorner = Instance.new("UICorner", btn)
          btnCorner.CornerRadius = UDim.new(0, 4)

          local state = initialState
          btn.MouseButton1Click:Connect(function()
               state = not state
               btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
               btn.Text = text .. (state and ": ON" or ": OFF")
               onToggle(state)
          end)
          return btn
     end

     -- helper to make a slider
     local function makeSlider(parent, yPos, minVal, maxVal, onChanged)
          local track = Instance.new("Frame", parent)
          track.Size = UDim2.new(1, -8, 0, 8)
          track.Position = UDim2.new(0, 0, 0, yPos)
          track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
          track.BorderSizePixel = 0
          local trackCorner = Instance.new("UICorner", track)
          trackCorner.CornerRadius = UDim.new(1, 0)

          local thumb = Instance.new("Frame", track)
          thumb.Size = UDim2.new(0, 12, 0, 12)
          thumb.Position = UDim2.new(0.08, -6, 0.5, -6)
          thumb.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
          thumb.BorderSizePixel = 0
          local thumbCorner = Instance.new("UICorner", thumb)
          thumbCorner.CornerRadius = UDim.new(1, 0)

          local button = Instance.new("TextButton", track)
          button.Size = UDim2.new(1, 0, 1, 0)
          button.BackgroundTransparency = 1
          button.Text = ""

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

          return track, thumb
     end

     -- ESP Size
     local sizeLabel = makeLabel(frame, "ESP Size: 2.0", 20)
     makeSlider(frame, 36, 0.5, 20, function(val)
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

     -- Line Thickness
     local thickLabel = makeLabel(frame, "Line Thickness: 1.5", 50)
     makeSlider(frame, 66, 0.5, 5, function(val)
          tracerThickness = val
          thickLabel.Text = "Line Thickness: " .. tostring(val)
          for _, t in pairs(tracerLines) do
               if t.LegendKey ~= "SCP-1155" then
                    t.Line.Thickness = val
                    t.Outline.Thickness = val + 1.5
               end
          end
     end)

     -- Alert Radius
     local radiusLabel = makeLabel(frame, "Alert Radius: 60", 80)
     makeSlider(frame, 96, 10, 300, function(val)
          alertRadius = val
          radiusLabel.Text = "Alert Radius: " .. tostring(val)
     end)

     -- Sound ID input
     local soundLabel = makeLabel(frame, "Sound ID: " .. alertSoundId, 112)
     local soundInput = Instance.new("TextBox", frame)
     soundInput.Size = UDim2.new(1, -8, 0, 18)
     soundInput.Position = UDim2.new(0, 0, 0, 126)
     soundInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
     soundInput.BorderSizePixel = 0
     soundInput.Text = alertSoundId
     soundInput.TextColor3 = Color3.fromRGB(200, 200, 200)
     soundInput.TextSize = 11
     soundInput.Font = Enum.Font.GothamSemibold
     soundInput.ClearTextOnFocus = false
     local soundInputCorner = Instance.new("UICorner", soundInput)
     soundInputCorner.CornerRadius = UDim.new(0, 4)
     soundInput.FocusLost:Connect(function()
          local newId = soundInput.Text:match("%d+")
          if newId then
               alertSoundId = newId
               soundLabel.Text = "Sound ID: " .. alertSoundId
               if alertSound then
                    alertSound.SoundId = "rbxassetid://" .. alertSoundId
               end
          end
     end)

     -- Toggles
     makeToggle(frame, "Alert Visual", 150, true, function(state)
          alertVisualEnabled = state
          if not state then
               -- clear any active alerts
               for key in pairs(breachedAlerts) do
                    breachedAlerts[key] = nil
                    if legendLabels[key] then
                         legendLabels[key].TextColor3 = colors[key]
                         legendLabels[key].Text = key
                    end
               end
          end
     end)

     makeToggle(frame, "Alert Sound", 172, true, function(state)
          alertSoundEnabled = state
     end)

     return screenGui
end

local legendOrder = {
     "SCP-017",
     "SCP-049",
     "SCP-049-2",
     "SCP-058",
     "SCP-173",
     "SCP-280",
     "SCP-352-2",
     "SCP-457",
     "SCP-610",
     "SCP-966",
     "SCP-914-X",
     "SCP-999",
     "SCP-1155",
     "SCP-1350",
}

local function createLegend()
     if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Legend") then return end

     local screenGui = Instance.new("ScreenGui")
     screenGui.Name = "ESP-Legend"
     screenGui.ResetOnSpawn = false
     screenGui.Parent = game.Players.LocalPlayer.PlayerGui

     local rowHeight = 22
     local totalRows = #legendOrder

     local frame = Instance.new("Frame", screenGui)
     frame.Size = UDim2.new(0, 180, 0, totalRows * rowHeight + 115)
     frame.Position = UDim2.new(0, 10, 1, -(totalRows * rowHeight + 125))
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
     for _, name in ipairs(legendOrder) do
          local color = colors[name]
          if not color then continue end

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
     -- keybind display at bottom of legend
     local keybindFrame = Instance.new("Frame", frame)
     keybindFrame.Size = UDim2.new(1, -8, 0, 72)
     keybindFrame.Position = UDim2.new(0, 0, 0, totalRows * rowHeight + 33)
     keybindFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
     keybindFrame.BackgroundTransparency = 0.3
     keybindFrame.BorderSizePixel = 0
     local keybindCorner = Instance.new("UICorner", keybindFrame)
     keybindCorner.CornerRadius = UDim.new(0, 6)

    local keybinds = {
     "[F5] Toggle ESP",
     "[F8] Settings",
     "[PgUp] Spectate / Next",
     "[PgDn] Spectate Prev",
     "[Del] Exit Spectate",
}

     for idx, text in ipairs(keybinds) do
          local kLabel = Instance.new("TextLabel", keybindFrame)
          kLabel.Size = UDim2.new(1, 0, 0, 14)
          kLabel.Position = UDim2.new(0, 6, 0, (idx - 1) * 16 + 2)
          kLabel.BackgroundTransparency = 1
          kLabel.Text = text
          kLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
          kLabel.TextSize = 10
          kLabel.Font = Enum.Font.GothamBold -- was GothamSemibold
          kLabel.TextXAlignment = Enum.TextXAlignment.Left
          kLabel.TextStrokeTransparency = 0.5  -- adds a dark outline around each letter
          kLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
     end
end



local function startContainmentMonitor()
     RunService.Heartbeat:Connect(function()
          if not alertVisualEnabled then return end

          local npcChecks = {
               {key = "SCP-999",   getPart = function() return s2["SCP-999"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-173",   getPart = function() return s2["SCP-173"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-017",   getPart = function() return s3["SCP-017"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-049",   getPart = function() return s3["SCP-049"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-280",   getPart = function() return s3["SCP-280"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-457",   getPart = function() return s3["SCP-457"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-058",   getPart = function() return s4["SCP-058"]:FindFirstChild("Torso") end},
               {key = "SCP-352-2", getPart = function() return s4["SCP-352-2"]:FindFirstChild("HumanoidRootPart") end},
               {key = "SCP-1350",  getPart = function() return s4["SCP-1350"]:FindFirstChild("Main") end},
          }

          for _, entry in ipairs(npcChecks) do
               local zone = containmentZones[entry.key]
               if not zone then continue end

               -- use global alertRadius unless zone has a custom override
               local radius = zone.radius or alertRadius

               local ok, part = pcall(entry.getPart)
               if not ok or not part then continue end

               local dist = (part.Position - zone.pos).Magnitude
               local isBreached = dist > radius

               if isBreached and not breachedAlerts[entry.key] then
                    flashLabel(entry.key, true)
               elseif not isBreached and breachedAlerts[entry.key] then
                    flashLabel(entry.key, false)
               end

          end

     local zone966 = containmentZones["SCP-966"]
     if zone966 then
          local instances = {"SCP-966-1", "SCP-966-2", "SCP-966-3", "SCP-966-4"}
          local anyBreached = false

          for _, name in ipairs(instances) do
               local ok, part = pcall(function()
                    return s3["SCP-966"][name]:FindFirstChild("HumanoidRootPart")
               end)
               if ok and part then
                    local dist = (part.Position - zone966.pos).Magnitude
                    if dist > zone966.radius then
                         anyBreached = true
                         break
                    end
               end
          end

          if anyBreached and not breachedAlerts["SCP-966"] then
               flashLabel("SCP-966", true)
          elseif not anyBreached and breachedAlerts["SCP-966"] then
               flashLabel("SCP-966", false)
          end
     end
     end)
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
createAlertSound()
createSettingsMenu()
setup1155()
setup914X()
setup610()
setup0492()
startContainmentMonitor()
--[[ MINIMAP TEST -- remove or comment out if not wanted
local minimapEnabled = true  -- toggle this to true to test
local minimapDots = {}

local function createMinimap()
     if not minimapEnabled then return end

     local screenGui = Instance.new("ScreenGui")
     screenGui.Name = "ESP-Minimap"
     screenGui.ResetOnSpawn = false
     screenGui.Parent = game.Players.LocalPlayer.PlayerGui

     local mapSize = 200
     local mapScale = 0.08  -- world units to minimap pixels

     local bg = Instance.new("Frame", screenGui)
     bg.Name = "MinimapBG"
     bg.Size = UDim2.new(0, mapSize, 0, mapSize)
     bg.Position = UDim2.new(1, -(mapSize + 10), 0, 10)
     bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
     bg.BackgroundTransparency = 0.3
     bg.BorderSizePixel = 0
     local bgCorner = Instance.new("UICorner", bg)
     bgCorner.CornerRadius = UDim.new(0, 8)

     -- player dot in center
     local playerDot = Instance.new("Frame", bg)
     playerDot.Name = "PlayerDot"
     playerDot.Size = UDim2.new(0, 8, 0, 8)
     playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
     playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
     playerDot.BorderSizePixel = 0
     local playerDotCorner = Instance.new("UICorner", playerDot)
     playerDotCorner.CornerRadius = UDim.new(1, 0)

     -- label
     local label = Instance.new("TextLabel", bg)
     label.Size = UDim2.new(1, 0, 0, 14)
     label.Position = UDim2.new(0, 0, 1, 2)
     label.BackgroundTransparency = 1
     label.Text = "MINIMAP (TEST)"
     label.TextColor3 = Color3.fromRGB(150, 150, 150)
     label.TextSize = 10
     label.Font = Enum.Font.GothamSemibold

     -- update loop
     RunService.RenderStepped:Connect(function()
          if hidden then
               bg.Visible = false
               return
          end
          bg.Visible = true

          local localChar = game.Players.LocalPlayer.Character
          local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
          if not localRoot then return end

          local localPos = localRoot.Position

          -- clear old dots
          for key, dot in pairs(minimapDots) do
               if not tracerLines[key] then
                    dot:Destroy()
                    minimapDots[key] = nil
               end
          end

          -- draw SCP dots
          for uid, t in pairs(tracerLines) do
               local part = t.Part
               if not part or not part.Parent then
                    if minimapDots[uid] then
                         minimapDots[uid]:Destroy()
                         minimapDots[uid] = nil
                    end
                    continue
               end

               local dot = minimapDots[uid]
               if not dot then
                    dot = Instance.new("Frame", bg)
                    dot.Size = UDim2.new(0, 6, 0, 6)
                    dot.BackgroundColor3 = t.Line.Color
                    dot.BorderSizePixel = 0
                    local dotCorner = Instance.new("UICorner", dot)
                    dotCorner.CornerRadius = UDim.new(1, 0)
                    minimapDots[uid] = dot
               end

               -- position relative to player
               local relX = (part.Position.X - localPos.X) * mapScale
               local relZ = (part.Position.Z - localPos.Z) * mapScale

               -- clamp to map bounds
               local dotX = math.clamp(mapSize / 2 + relX, 3, mapSize - 9)
               local dotZ = math.clamp(mapSize / 2 + relZ, 3, mapSize - 9)

               dot.Position = UDim2.new(0, dotX - 3, 0, dotZ - 3)
               dot.Visible = true
          end
     end)
end
createMinimap()
--]]
watchForRespawn(function() return s2["SCP-999"].HumanoidRootPart end, "SCP-999")
watchForRespawn(function() return s4["SCP-058"].Torso end,                         "SCP-058")
watchForRespawn(function() return s4["SCP-1350"].Main end,                         "SCP-1350")
watchForRespawn(function() return s4["SCP-352-2"].HumanoidRootPart end,            "SCP-352-2")
watchForRespawn(function() return s3["SCP-017"].HumanoidRootPart end,              "SCP-017")
watchForRespawn(function() return s3["SCP-049"].HumanoidRootPart end,              "SCP-049")
watchForRespawn(function() return s3["SCP-280"].HumanoidRootPart end,              "SCP-280")
watchForRespawn(function() return s3["SCP-457"].HumanoidRootPart end,              "SCP-457")
watchForRespawn(function() return s3["SCP-966"]["SCP-966-1"].HumanoidRootPart end, "SCP-966")
watchForRespawn(function() return s3["SCP-966"]["SCP-966-2"].HumanoidRootPart end, "SCP-966")
watchForRespawn(function() return s3["SCP-966"]["SCP-966-3"].HumanoidRootPart end, "SCP-966")
watchForRespawn(function() return s3["SCP-966"]["SCP-966-4"].HumanoidRootPart end, "SCP-966")
watchForRespawn(function() return s2["SCP-173"].HumanoidRootPart end,              "SCP-173")

local function buildSpectateList()
     spectateList = {}

     -- NPC SCPs
     local npcParts = {
          {key = "SCP-058",   getPart = function() return s4["SCP-058"].Torso end},
          {key = "SCP-1350",  getPart = function() return s4["SCP-1350"].Main end},
          {key = "SCP-352-2", getPart = function() return s4["SCP-352-2"].HumanoidRootPart end},
          {key = "SCP-017",   getPart = function() return s3["SCP-017"].HumanoidRootPart end},
          {key = "SCP-049",   getPart = function() return s3["SCP-049"].HumanoidRootPart end},
          {key = "SCP-280",   getPart = function() return s3["SCP-280"].HumanoidRootPart end},
          {key = "SCP-457",   getPart = function() return s3["SCP-457"].HumanoidRootPart end},
          {key = "SCP-966-1", getPart = function() return s3["SCP-966"]["SCP-966-1"].HumanoidRootPart end},
          {key = "SCP-966-2", getPart = function() return s3["SCP-966"]["SCP-966-2"].HumanoidRootPart end},
          {key = "SCP-966-3", getPart = function() return s3["SCP-966"]["SCP-966-3"].HumanoidRootPart end},
          {key = "SCP-966-4", getPart = function() return s3["SCP-966"]["SCP-966-4"].HumanoidRootPart end},
          {key = "SCP-173",   getPart = function() return s2["SCP-173"].HumanoidRootPart end},
          {key = "SCP-999",   getPart = function() return s2["SCP-999"].HumanoidRootPart end},
     }

     for _, entry in ipairs(npcParts) do
          local ok, part = pcall(entry.getPart)
          if ok and part and part.Parent then
               table.insert(spectateList, {key = entry.key, part = part})
          end
     end

     -- player SCPs: only add if they are currently transformed
     local Players = game:GetService("Players")
     for _, player in ipairs(Players:GetPlayers()) do
          local char = player.Character
          if not char then continue end
          local torso = char:FindFirstChild("Torso")
          if not torso then continue end

          -- check 914-X
          local isBlack = torso.Color == Color3.new(0, 0, 0)
          local noShirt = char:FindFirstChildOfClass("Shirt") == nil
          local noPants = char:FindFirstChildOfClass("Pants") == nil
          local noAccessory = char:FindFirstChildOfClass("Accessory") == nil
          if isBlack and noShirt and noPants and noAccessory then
               table.insert(spectateList, {key = "SCP-914-X [" .. player.Name .. "]", part = torso})
          end

          -- check 610
          local hasMorph = char:FindFirstChild("Morph") ~= nil
          local isOrange = torso.Color == Color3.fromRGB(234, 184, 146)
          if hasMorph and isOrange then
               table.insert(spectateList, {key = "SCP-610 [" .. player.Name .. "]", part = torso})
          end

          -- check 049-2
          local hasParticle = torso:FindFirstChildOfClass("ParticleEmitter") ~= nil
          local hasSound = torso:FindFirstChildOfClass("Sound") ~= nil
          if hasParticle and hasSound then
               table.insert(spectateList, {key = "SCP-049-2 [" .. player.Name .. "]", part = torso})
          end
     end
end

local spectateLabel = nil

local function createSpectateLabel()
     if spectateLabel then spectateLabel:Destroy() end
     local screenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ESP-Legend")
     if not screenGui then return end

     local label = Instance.new("ScreenGui")
     label.Name = "ESP-SpectateLabel"
     label.ResetOnSpawn = false
     label.Parent = game.Players.LocalPlayer.PlayerGui

     local frame = Instance.new("Frame", label)
     frame.Size = UDim2.new(0, 220, 0, 40)
     frame.Position = UDim2.new(0.5, -110, 0, 10)
     frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
     frame.BackgroundTransparency = 0.3
     frame.BorderSizePixel = 0
     local corner = Instance.new("UICorner", frame)
     corner.CornerRadius = UDim.new(0, 8)

     local text = Instance.new("TextLabel", frame)
     text.Name = "SpectateText"
     text.Size = UDim2.new(1, 0, 0.6, 0)
     text.Position = UDim2.new(0, 0, 0, 4)
     text.BackgroundTransparency = 1
     text.Text = "SPECTATING: "
     text.TextColor3 = Color3.fromRGB(255, 255, 255)
     text.TextSize = 13
     text.Font = Enum.Font.GothamSemibold

     local hint = Instance.new("TextLabel", frame)
     hint.Size = UDim2.new(1, 0, 0.4, 0)
     hint.Position = UDim2.new(0, 0, 0.6, 0)
     hint.BackgroundTransparency = 1
     hint.Text = "[PgUp] Next   [PgDn] Previous   [Del] Exit"
     hint.TextColor3 = Color3.fromRGB(200, 200, 200)
     hint.TextSize = 10
     hint.Font = Enum.Font.GothamBold  -- was GothamSemibold, Bold is thicker
     hint.TextStrokeTransparency = 0.5  -- adds a dark outline around each letter
     hint.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
     spectateLabel = label
     return text
end

local spectateText = nil

local function updateSpectateCamera()
     if not spectating or #spectateList == 0 then return end
     local entry = spectateList[spectateIndex]
     if not entry or not entry.part or not entry.part.Parent then
          spectateIndex = spectateIndex % #spectateList + 1
          updateSpectateCamera()
          return
     end

     -- use CameraSubject so the player can still move the camera freely
     Camera.CameraType = Enum.CameraType.Custom
     Camera.CameraSubject = entry.part

     if spectateText then
     local baseKey = entry.key:match("^(SCP%-%d+%S*)") or entry.key
     local color = colors[getLegendKey(baseKey)] or Color3.fromRGB(255, 255, 255)
     spectateText.Text = "SPECTATING: " .. entry.key
     spectateText.TextColor3 = color
     end
end

local function enterSpectate()
     buildSpectateList()
     if #spectateList == 0 then return end
     spectating = true
     spectateIndex = 1
     originalCameraType = Camera.CameraType
     originalCameraCFrame = Camera.CFrame
     spectateText = createSpectateLabel()
     updateSpectateCamera()
end

local function exitSpectate()
     spectating = false
     Camera.CameraType = originalCameraType or Enum.CameraType.Custom
     local char = game.Players.LocalPlayer.Character
     Camera.CameraSubject = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("HumanoidRootPart")) or Camera.CameraSubject
     if spectateLabel then
          spectateLabel:Destroy()
          spectateLabel = nil
          spectateText = nil
     end
end




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

     elseif input.KeyCode == Enum.KeyCode.PageUp then
          if not spectating then
               enterSpectate()
          else
               spectateIndex = spectateIndex % #spectateList + 1
               updateSpectateCamera()
          end

     elseif input.KeyCode == Enum.KeyCode.PageDown then
          if spectating then
               spectateIndex = ((spectateIndex - 2) % #spectateList) + 1
               updateSpectateCamera()
          end

     elseif input.KeyCode == Enum.KeyCode.Delete then
          if spectating then
               exitSpectate()
          end
     end
end)

