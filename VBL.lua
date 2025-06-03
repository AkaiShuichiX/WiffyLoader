-- Wiffy Hub - Volleyball Legends
-- Created using Rayfield UI Library

-- Load the Rayfield library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- Local variables
local Window = nil
local MainTab = nil
local HitboxSection = nil
local HitboxToggle = nil
local HitboxSizeSlider = nil
local HitboxTransparencySlider = nil
local PlayerHitboxSection = nil
local PlayerHitboxShowToggle = nil
local PlayerHitboxTransparencySlider = nil
local CharacterRotationSection = nil
local CharacterRotationToggle = nil
local AnimationRemovalSection = nil
local AnimationRemovalToggle = nil
local JumpPowerSection = nil
local JumpPowerSlider = nil
local PlayerDirectionSection = nil
local PlayerDirectionToggle = nil
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Create the main window
Window = Rayfield:CreateWindow({
   Name = "Wiffy Hub - Volleyball Legends",
   LoadingTitle = "Wiffy Hub",
   LoadingSubtitle = "by Wiffy",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Creates a custom folder for your hub/game
      FileName = "WiffyHub_VolleyballLegends"
   },
   Discord = {
      Enabled = false,
      Invite = "", -- Discord invite code
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Wiffy Hub",
      Subtitle = "Volleyball Legends",
      Note = "Key: Dick",
      FileName = "WiffyKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Dick"}
   }
})

-- Create main tab
MainTab = Window:CreateTab("Main")

-- Global variables for hitbox management
_G.HitboxEnabled = false
_G.HitboxSize = 1
_G.HitboxTransparency = 0.5 -- Changed from TransparencyValue to HitboxTransparency
_G.OriginalSizes = {}
_G.OriginalTransparency = {}
_G.OriginalHitboxParts = {}
_G.CustomHitboxParts = {}

-- Global variables for player hitbox show
_G.PlayerHitboxShowEnabled = false
_G.PlayerHitboxTransparency = 0.5

-- Global variable for animation removal
_G.RemoveAnimationsEnabled = false

-- Global variable for JumpPower
_G.JumpPowerMultiplier = 1

-- Global variable for Player Direction Visualization
_G.PlayerDirectionEnabled = false
_G.DirectionLines = {}

-- Function declarations
local function isShiftLockEnabled() 
    return UserGameSettings.RotationType == Enum.RotationType.CameraRelative 
end 

-- Function to create or update a custom hitbox part in the model
function createOrUpdateHitboxPart(ballName, originalPart)
   -- Check if we already have a custom hitbox for this ball
   local customHitbox = _G.CustomHitboxParts[ballName]
   
   -- If not, create a new one
   if not customHitbox or not customHitbox.Parent then
      -- Create a new hitbox part
      customHitbox = Instance.new("Part")
      customHitbox.Name = "CustomHitbox"
      customHitbox.Anchored = true
      customHitbox.CanCollide = false -- Changed to false so players can walk through
      customHitbox.CanTouch = true
      customHitbox.CanQuery = true
      customHitbox.Shape = Enum.PartType.Ball
      customHitbox.Material = Enum.Material.SmoothPlastic
      customHitbox.Color = Color3.fromRGB(255, 0, 0) -- Red color
      
      -- Make the original part non-collidable
      originalPart.CanCollide = false
      
      -- Store the custom hitbox
      _G.CustomHitboxParts[ballName] = customHitbox
      
      -- Parent to the same model as the original part
      customHitbox.Parent = originalPart.Parent
   end
   
   -- Update the custom hitbox properties
   customHitbox.Size = _G.OriginalSizes[ballName] * _G.HitboxSize
   customHitbox.Position = originalPart.Position
   customHitbox.Transparency = _G.HitboxTransparency -- Use hitbox-specific transparency
   customHitbox.Color = Color3.fromRGB(255, 0, 0) -- Ensure it stays red
   
   -- Make sure the part is visible through walls if transparency is set
   if _G.HitboxTransparency > 0 then
      customHitbox.LocalTransparencyModifier = _G.HitboxTransparency
   end
   
   return customHitbox
end

-- Function to modify hitbox size and transparency using custom hitbox part
function modifyHitboxSize(ballName, hitboxPart)
   -- Store original size and transparency if not already stored
   if not _G.OriginalSizes[ballName] then
      _G.OriginalSizes[ballName] = hitboxPart.Size
      _G.OriginalTransparency[ballName] = hitboxPart.Transparency
   end
   
   -- Create or update the custom hitbox part
   createOrUpdateHitboxPart(ballName, hitboxPart)
end

-- Function to reset all hitboxes to original size and transparency
function resetAllHitboxes()
   -- Remove all custom hitbox parts
   for ballName, customHitbox in pairs(_G.CustomHitboxParts) do
      if customHitbox and customHitbox.Parent then
         customHitbox:Destroy()
      end
   end
   
   -- Restore original parts' properties
   for ballName, originalSize in pairs(_G.OriginalSizes) do
      local hitboxPart = _G.OriginalHitboxParts[ballName]
      if hitboxPart and hitboxPart.Parent then
         hitboxPart.Size = originalSize
         hitboxPart.Transparency = _G.OriginalTransparency[ballName] or 0
         hitboxPart.LocalTransparencyModifier = 0
         hitboxPart.CanCollide = true -- Restore collision
      end
   end
   
   -- Clear stored data
   _G.OriginalSizes = {}
   _G.OriginalTransparency = {}
   _G.OriginalHitboxParts = {}
   _G.CustomHitboxParts = {}
end

-- Add a section for Hitbox modification
HitboxSection = MainTab:CreateSection("Hitbox Modification")

-- Add a toggle for hitbox modification
HitboxToggle = MainTab:CreateToggle({
   Name = "Hitbox Modification",
   Info = "Enables/Disables hitbox modification for all CLIENT_BALL models",
   CurrentValue = false,
   Flag = "HitboxToggle",
   Callback = function(Value)
      _G.HitboxEnabled = Value
      
      if Value then
         -- Start the hitbox modification loop
         spawn(function()
            while _G.HitboxEnabled do
               -- Find all CLIENT_BALL models and modify their hitboxes
               for _, obj in pairs(workspace:GetChildren()) do
                  if typeof(obj) == "Instance" and obj:IsA("Model") and string.find(obj.Name, "^CLIENT_BALL") then
                     -- Try to find the hitbox part in the model
                     local hitboxPart = nil
                     
                     -- First check if there's a part named "Hitbox"
                     hitboxPart = obj:FindFirstChild("Hitbox")
                     
                     -- If not, look for the primary part
                     if not hitboxPart and obj.PrimaryPart then
                        hitboxPart = obj.PrimaryPart
                     end
                     
                     -- If still not found, try to find any part that might be the ball
                     if not hitboxPart then
                        for _, part in pairs(obj:GetDescendants()) do
                           if part:IsA("BasePart") and (part.Name:lower():find("ball") or part.Shape == Enum.PartType.Ball) then
                              hitboxPart = part
                              break
                           end
                        end
                     end
                     
                     -- If still not found, just use the first BasePart
                     if not hitboxPart then
                        hitboxPart = obj:FindFirstChildWhichIsA("BasePart")
                     end
                     
                     -- Apply hitbox modification if we found a part
                     if hitboxPart then
                        -- Store reference to original hitbox part if not already stored
                        if not _G.OriginalHitboxParts[obj.Name] then
                           _G.OriginalHitboxParts[obj.Name] = hitboxPart
                           _G.OriginalSizes[obj.Name] = hitboxPart.Size
                           _G.OriginalTransparency[obj.Name] = hitboxPart.Transparency
                        end
                        
                        -- Create or update custom hitbox part
                        modifyHitboxSize(obj.Name, hitboxPart)
                     end
                  end
               end
               
               -- Wait before next update
               wait(0.1)
            end
            
            -- Reset all hitboxes to original size and transparency
            resetAllHitboxes()
         end)
      else
         -- Reset all hitboxes when disabled
         resetAllHitboxes()
      end
   end,
})

-- Add a slider for hitbox size
HitboxSizeSlider = MainTab:CreateSlider({
   Name = "Hitbox Size Multiplier",
   Info = "Adjusts the size of all CLIENT_BALL hitboxes",
   Range = {0.1, 30},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "HitboxSizeSlider",
   Callback = function(Value)
      _G.HitboxSize = Value
   end,
})

-- Add a slider for hitbox transparency
HitboxTransparencySlider = MainTab:CreateSlider({
   Name = "Hitbox Transparency",
   Info = "Adjusts the transparency of custom hitbox parts",
   Range = {0, 1},
   Increment = 0.1,
   Suffix = "",
   CurrentValue = 0.5,
   Flag = "HitboxTransparencySlider",
   Callback = function(Value)
      _G.HitboxTransparency = Value
   end,
})

-- Add a section for PlayerHitboxShow
PlayerHitboxSection = MainTab:CreateSection("Player Hitbox Show")

-- Add a toggle for player hitbox show
PlayerHitboxShowToggle = MainTab:CreateToggle({
   Name = "Show PlayerHitbox",
   Info = "Makes workspace.Part visible and warps it to CLIENT_BALL models",
   CurrentValue = false,
   Flag = "PlayerHitboxShowToggle",
   Callback = function(Value)
      _G.PlayerHitboxShowEnabled = Value
      
      if Value then
         -- Start the player hitbox show loop
         spawn(function()
            while _G.PlayerHitboxShowEnabled do
               -- Find only workspace.Part (direct child of workspace)
               local workspacePart = workspace:FindFirstChild("Part")
               if workspacePart and workspacePart:IsA("BasePart") then
                  -- Apply transparency setting
                  workspacePart.Transparency = _G.PlayerHitboxTransparency
                  
                  -- Find CLIENT_BALL model to warp to
                  for _, obj in pairs(workspace:GetChildren()) do
                     if typeof(obj) == "Instance" and obj:IsA("Model") and string.find(obj.Name, "^CLIENT_BALL") then
                        -- Try to find the hitbox part in the model
                        local hitboxPart = nil
                        
                        -- First check if there's a part named "Hitbox"
                        hitboxPart = obj:FindFirstChild("Hitbox")
                        
                        -- If not, look for the primary part
                        if not hitboxPart and obj.PrimaryPart then
                           hitboxPart = obj.PrimaryPart
                        end
                        
                        -- If still not found, try to find any part that might be the ball
                        if not hitboxPart then
                           for _, part in pairs(obj:GetDescendants()) do
                              if part:IsA("BasePart") and (part.Name:lower():find("ball") or part.Shape == Enum.PartType.Ball) then
                                 hitboxPart = part
                                 break
                              end
                           end
                        end
                        
                        -- If we found a hitbox part, warp the workspace.Part to it
                        if hitboxPart then
                           workspacePart.CFrame = hitboxPart.CFrame
                           break -- Warp to the first CLIENT_BALL found
                        end
                     end
                  end
               end
               
               -- Wait before next update (0.5 seconds as requested)
               wait(0.5)
            end
         end)
      end
   end,
})

-- Add a slider for player hitbox transparency
PlayerHitboxTransparencySlider = MainTab:CreateSlider({
   Name = "PlayerHitbox Transparency",
   Range = {0, 1},
   Increment = 0.1,
   Suffix = "",
   CurrentValue = 0.5,
   Flag = "PlayerHitboxTransparencySlider",
   Callback = function(Value)
      _G.PlayerHitboxTransparency = Value
   end,
})

-- Add a section for Character Rotation
CharacterRotationSection = MainTab:CreateSection("Force ShiftLock")

-- Add a toggle for character rotation
CharacterRotationToggle = MainTab:CreateToggle({
   Name = "Force ShiftLock",
   Info = "Makes your character face the direction your camera is looking when ShiftLock is enabled",
   CurrentValue = false,
   Flag = "CharacterRotationToggle",
   Callback = function(Value)
      if Value then
         -- Connect the rotation function
         _G.CharacterRotationConnection = RunService.RenderStepped:Connect(function() 
            if isShiftLockEnabled() then 
                local character = player.Character 
                if character and character:FindFirstChild("HumanoidRootPart") then 
                    local hrp = character.HumanoidRootPart 
                    local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit 
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look) 
                end 
            end 
         end)
      else
         -- Disconnect the rotation function if it exists
         if _G.CharacterRotationConnection then
            _G.CharacterRotationConnection:Disconnect()
            _G.CharacterRotationConnection = nil
         end
      end
   end,
})

-- Add a section for Animation Removal
AnimationRemovalSection = MainTab:CreateSection("Animation Removal")

-- Add a toggle for animation removal
AnimationRemovalToggle = MainTab:CreateToggle({
   Name = "Remove All Animations",
   Info = "Continuously removes all animations from your character every 0.1 seconds",
   CurrentValue = false,
   Flag = "AnimationRemovalToggle",
   Callback = function(Value)
      _G.RemoveAnimationsEnabled = Value
      
      if Value then
         -- Start the animation removal loop
         spawn(function()
            while _G.RemoveAnimationsEnabled do
               -- Get the local player and character
               local player = game.Players.LocalPlayer
               if player and player.Character then
                  local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                  if humanoid then
                     -- Get the animator if it exists
                     local animator = humanoid:FindFirstChildOfClass("Animator")
                     if animator then
                        -- Stop all playing animations
                        for _, animTrack in pairs(animator:GetPlayingAnimationTracks()) do
                           animTrack:Stop()
                        end
                     end
                  end
               end
               
               -- Wait before next removal (0.1 seconds as requested)
               wait(0.1)
            end
         end)
      end
   end,
})

-- Add a section for JumpPower
JumpPowerSection = MainTab:CreateSection("Jump Power")

-- Add a slider for JumpPower
JumpPowerSlider = MainTab:CreateSlider({
   Name = "Jump Power Multiplier",
   Info = "Adjusts your character's jump power",
   Range = {0, 5},
   Increment = 0.05,
   Suffix = "x",
   CurrentValue = player:GetAttribute("GameJumpPowerMultiplier") or 1,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
      _G.JumpPowerMultiplier = Value
      local player = game:GetService("Players").LocalPlayer
      if player then
         player:SetAttribute("GameJumpPowerMultiplier", Value)
      end
   end,
})

-- Add a section for Player Direction Visualization
PlayerDirectionSection = MainTab:CreateSection("Enemy Direction Visualization")

PlayerDirectionToggle = MainTab:CreateToggle({
   Name = "Show Enemy Direction",
   Info = "Creates a colored line in front of enemy players to show where they are looking",
   CurrentValue = false,
   Flag = "PlayerDirectionToggle",
   Callback = function(Value)
      _G.PlayerDirectionEnabled = Value
      
      -- Clean up existing direction lines
      for _, line in pairs(_G.DirectionLines) do
         if line and line.Parent then
            line:Destroy()
         end
      end
      _G.DirectionLines = {}
      
      if Value then
         -- Start the enemy direction visualization loop
         spawn(function()
            while _G.PlayerDirectionEnabled do
               -- Remove lines for players who left
               for playerName, line in pairs(_G.DirectionLines) do
                  local playerStillExists = false
                  for _, p in pairs(Players:GetPlayers()) do
                     if p.Name == playerName and p ~= player then
                        playerStillExists = true
                        break
                     end
                  end
                  
                  if not playerStillExists and line and line.Parent then
                     line:Destroy()
                     _G.DirectionLines[playerName] = nil
                  end
               end
               
               -- Create or update direction lines for enemy players only
               for _, p in pairs(Players:GetPlayers()) do
                  -- Skip local player and only show opposite team players
                  if p ~= player then
                     local character = p.Character
                     local localCharacter = player.Character
                     
                     if character and character:FindFirstChild("Head") and localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
                        local head = character.Head
                        local localPosition = localCharacter.HumanoidRootPart.Position
                        local enemyPosition = character.HumanoidRootPart and character.HumanoidRootPart.Position
                        
                        -- Check if enemy is on opposite side (simple distance-based check)
                        if enemyPosition and (localPosition - enemyPosition).Magnitude > 10 then
                           -- Create line if it doesn't exist
                           if not _G.DirectionLines[p.Name] or not _G.DirectionLines[p.Name].Parent then
                              local line = Instance.new("Part")
                              line.Name = "EnemyDirectionLine_" .. p.Name
                              line.Anchored = false
                              line.CanCollide = false
                              line.Material = Enum.Material.Neon
                              
                              -- Determine team color based on player's team
                              local teamColor = Color3.fromRGB(255, 0, 0) -- Default red
                              if p.Team then
                                 teamColor = p.Team.TeamColor.Color
                              elseif p:FindFirstChild("TeamColor") then
                                 teamColor = p.TeamColor.Value
                              elseif character:FindFirstChild("Body Colors") then
                                 -- Use torso color as team indicator
                                 teamColor = character["Body Colors"].TorsoColor3
                              end
                              
                              line.Color = teamColor
                              -- Use global direction line length variable
                              local lineLength = _G.DirectionLineLength or 20
                              line.Size = Vector3.new(0.15, 0.15, lineLength)
                              line.Transparency = 0.15
                              
                              -- Parent directly to character
                              line.Parent = character
                              
                              -- Position the line based on its length
                              line.CFrame = head.CFrame * CFrame.new(0, 0, -lineLength/2)
                              
                              -- Create WeldConstraint to attach line to head
                              local weld = Instance.new("WeldConstraint")
                              weld.Part0 = head
                              weld.Part1 = line
                              weld.Parent = line
                              
                              _G.DirectionLines[p.Name] = line
                           end
                        else
                           -- Remove line if player is too close (same team)
                           if _G.DirectionLines[p.Name] and _G.DirectionLines[p.Name].Parent then
                              _G.DirectionLines[p.Name]:Destroy()
                              _G.DirectionLines[p.Name] = nil
                           end
                        end
                     end
                  end
               end
               
               -- Wait before next update
               wait(0.3)
            end
         end)
      end
   end,
})

-- Add slider for direction line length
DirectionLengthSlider = MainTab:CreateSlider({
   Name = "Direction Line Length",
   Info = "Adjust the length of enemy direction lines",
   Range = {5, 50},
   Increment = 1,
   CurrentValue = 20,
   Flag = "DirectionLengthSlider",
   Callback = function(Value)
      _G.DirectionLineLength = Value
      
      -- Update existing lines
      for playerName, line in pairs(_G.DirectionLines) do
         if line and line.Parent then
            line.Size = Vector3.new(0.15, 0.15, Value)
            -- Adjust position based on new length
            local character = line.Parent
            if character and character:FindFirstChild("Head") then
               line.CFrame = character.Head.CFrame * CFrame.new(0, 0, -Value/2)
            end
         end
      end
      
      -- Restart the direction visualization if it's currently enabled
      if _G.PlayerDirectionEnabled then
         -- Clean up existing lines
         for _, line in pairs(_G.DirectionLines) do
            if line and line.Parent then
               line:Destroy()
            end
         end
         _G.DirectionLines = {}
         
         -- Restart the toggle functionality
         _G.PlayerDirectionEnabled = false
         wait(0.1) -- Small delay to ensure cleanup
         _G.PlayerDirectionEnabled = true
         
         -- Restart the enemy direction visualization loop
         spawn(function()
            while _G.PlayerDirectionEnabled do
               -- Remove lines for players who left
               for playerName, line in pairs(_G.DirectionLines) do
                  local playerStillExists = false
                  for _, p in pairs(Players:GetPlayers()) do
                     if p.Name == playerName and p ~= player then
                        playerStillExists = true
                        break
                     end
                  end
                  
                  if not playerStillExists and line and line.Parent then
                     line:Destroy()
                     _G.DirectionLines[playerName] = nil
                  end
               end
               
               -- Create or update direction lines for enemy players only
               for _, p in pairs(Players:GetPlayers()) do
                  -- Skip local player and only show opposite team players
                  if p ~= player then
                     local character = p.Character
                     local localCharacter = player.Character
                     
                     if character and character:FindFirstChild("Head") and localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
                        local head = character.Head
                        local localPosition = localCharacter.HumanoidRootPart.Position
                        local enemyPosition = character.HumanoidRootPart and character.HumanoidRootPart.Position
                        
                        -- Check if enemy is on opposite side (simple distance-based check)
                        if enemyPosition and (localPosition - enemyPosition).Magnitude > 10 then
                           -- Create line if it doesn't exist
                           if not _G.DirectionLines[p.Name] or not _G.DirectionLines[p.Name].Parent then
                              local line = Instance.new("Part")
                              line.Name = "EnemyDirectionLine_" .. p.Name
                              line.Anchored = false
                              line.CanCollide = false
                              line.Material = Enum.Material.Neon
                              
                              -- Determine team color based on player's team
                              local teamColor = Color3.fromRGB(255, 0, 0) -- Default red
                              if p.Team then
                                 teamColor = p.Team.TeamColor.Color
                              elseif p:FindFirstChild("TeamColor") then
                                 teamColor = p.TeamColor.Value
                              elseif character:FindFirstChild("Body Colors") then
                                 -- Use torso color as team indicator
                                 teamColor = character["Body Colors"].TorsoColor3
                              end
                              
                              line.Color = teamColor
                              -- Use updated direction line length
                              local lineLength = _G.DirectionLineLength or 20
                              line.Size = Vector3.new(0.15, 0.15, lineLength)
                              line.Transparency = 0.15
                              
                              -- Parent directly to character
                              line.Parent = character
                              
                              -- Position the line based on its length
                              line.CFrame = head.CFrame * CFrame.new(0, 0, -lineLength/2)
                              
                              -- Create WeldConstraint to attach line to head
                              local weld = Instance.new("WeldConstraint")
                              weld.Part0 = head
                              weld.Part1 = line
                              weld.Parent = line
                              
                              _G.DirectionLines[p.Name] = line
                           end
                        else
                           -- Remove line if player is too close (same team)
                           if _G.DirectionLines[p.Name] and _G.DirectionLines[p.Name].Parent then
                              _G.DirectionLines[p.Name]:Destroy()
                              _G.DirectionLines[p.Name] = nil
                           end
                        end
                     end
                  end
               end
               
               -- Wait before next update
               wait(0.3)
            end
         end)
      end
   end,
})

-- Add a paragraph with credits
MainTab:CreateParagraph({Title = "Credits", Content = "Wiffy Hub created by Wiffy\nUI Library: Rayfield"})

-- Load saved configuration
Rayfield:LoadConfiguration()
