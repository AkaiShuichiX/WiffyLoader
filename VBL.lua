-- Wiffy Hub - Volleyball Legends
-- Created using Twilight UI Library
-- Load the Twilight library and addons
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/AkaiShuichiX/Twilight/refs/heads/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/AkaiShuichiX/Twilight/refs/heads/main/addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/AkaiShuichiX/Twilight/refs/heads/main/addons/SaveManager.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- Local variables
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Initialize global variables
_G.HitboxEnabled = false
_G.HitboxSize = 1
_G.HitboxTransparency = 0.5
_G.OriginalSizes = {}
_G.OriginalTransparency = {}
_G.OriginalHitboxParts = {}
_G.CustomHitboxParts = {}
_G.PlayerHitboxShowEnabled = false
_G.PlayerHitboxTransparency = 0.5
_G.RemoveAnimationsEnabled = false
_G.JumpPowerMultiplier = 1
_G.PlayerDirectionEnabled = false
_G.DirectionLines = {}

-- Create the main window
local Window = Library:CreateWindow({
    Title = "Wiffy Hub - Volleyball Legends",
    TopTabBar = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
    Width = 500,
    Height = 500,
 
    --[[Default:
         Title = "Template",
         TopTabBar = false,
         OutlineThickness = 2,
         Width = 700,
         Height = 700,
         Font = Font.fromEnum(Enum.Font.Code),
         FontSize = 16,
         SectionFontSize = 18,
         SectionTitleTransparency = 0.5,
         ElementTitleTransparency = 0.5,
         MaxDialogButtonsPerLine = 4,
         MaxDropdownItems = 8,
         Theme = nil,
         TweenTime = 0.1,
         ToggleKeybind = Enum.KeyCode.RightControl,
     ]]
})

-- Create tabs
local MainTab = Window:CreateTab("Main", "home")
local Settings = Window:CreateTab("Settings")

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
local HitboxSection = MainTab:CreateSection("Hitbox Modification")

-- Add a toggle for hitbox modification
local HitboxToggle = HitboxSection:CreateToggle("HitboxToggle", {
   Title = "Hitbox Modification",
   Description = "Enables/Disables hitbox modification for Ball",
   Default = false,
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
local HitboxSizeSlider = HitboxSection:CreateSlider("HitboxSizeSlider", {
   Title = "Hitbox Size Multiplier",
   Min = 0.1,
   Max = 30,
   Value = 1,
   Increment = 0.1,
   Suffix = "x",
   Callback = function(Value)
      _G.HitboxSize = Value
   end,
})

-- Add a slider for hitbox transparency
local HitboxTransparencySlider = HitboxSection:CreateSlider("HitboxTransparencySlider", {
   Title = "Hitbox Transparency",
   Min = 0,
   Max = 1,
   Value = 0.5,
   Increment = 0.1,
   Callback = function(Value)
      _G.HitboxTransparency = Value
   end,
})

-- Add a section for PlayerHitboxShow
local PlayerHitboxSection = MainTab:CreateSection("Player Hitbox Show")

-- Add a toggle for player hitbox show
local PlayerHitboxShowToggle = PlayerHitboxSection:CreateToggle("PlayerHitboxShowToggle", {
   Title = "Show PlayerHitbox",
   Description = "Enables/Disables showing PlayerHitbox",
   Default = false,
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
local PlayerHitboxTransparencySlider = PlayerHitboxSection:CreateSlider("PlayerHitboxTransparencySlider", {
   Title = "PlayerHitbox Transparency",
   Min = 0,
   Max = 1,
   Value = 0.5,
   Increment = 0.1,
   Callback = function(Value)
      _G.PlayerHitboxTransparency = Value
   end,
})

-- Add a section for Character Rotation
local CharacterRotationSection = MainTab:CreateSection("Force ShiftLock")

-- Add a toggle for character rotation
local CharacterRotationToggle = CharacterRotationSection:CreateToggle("CharacterRotationToggle", {
   Title = "Force ShiftLock",
   Description = "Enables/Disables force ShiftLock rotation",
   Default = false,
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
local AnimationRemovalSection = MainTab:CreateSection("Animation Removal")

-- Add a toggle for animation removal
local AnimationRemovalToggle = AnimationRemovalSection:CreateToggle("AnimationRemovalToggle", {
   Title = "Remove All Animations",
   Description = "Enables/Disables removal of all animations",
   Default = false,
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
local JumpPowerSection = MainTab:CreateSection("Jump Power")

-- Add a slider for JumpPower
local JumpPowerSlider = JumpPowerSection:CreateSlider("JumpPowerSlider", {
   Title = "Jump Power Multiplier",
   Description = "Adjusts your character's jump power",
   Min = 0,
   Max = 5,
   Value = player:GetAttribute("GameJumpPowerMultiplier") or 1,
   Increment = 0.05,
   Suffix = "x",
   Callback = function(Value)
      _G.JumpPowerMultiplier = Value
      local player = game:GetService("Players").LocalPlayer
      if player then
         player:SetAttribute("GameJumpPowerMultiplier", Value)
      end
   end,
})

-- Add a section for Player Direction Visualization
local PlayerDirectionSection = MainTab:CreateSection("Enemy Direction Visualization")

local PlayerDirectionToggle = PlayerDirectionSection:CreateToggle("PlayerDirectionToggle", {
   Title = "Show Enemy Direction",
   Description = "Enables/Disables enemy direction visualization",
   Default = false,
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
                  -- Skip local player
                  if p ~= player then
                     local character = p.Character
                     local localCharacter = player.Character
                     
                     if character and character:FindFirstChild("Head") and localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
                        local head = character.Head
                        local localPosition = localCharacter.HumanoidRootPart.Position
                        local enemyPosition = character.HumanoidRootPart and character.HumanoidRootPart.Position
                        
                        -- Check if player is on opposite team or if show same team is enabled
                        local isSameTeam = false
                        if p.Team and player.Team then
                           isSameTeam = (p.Team == player.Team)
                        elseif (localPosition - enemyPosition).Magnitude <= 10 then
                           -- Use distance as a fallback for team detection
                           isSameTeam = true
                        end
                        
                        local shouldShowLine = (_G.ShowSameTeam or not isSameTeam)
                        
                        if enemyPosition and shouldShowLine then
                           -- Create line if it doesn't exist or update existing one
                           local line = _G.DirectionLines[p.Name]
                           
                           -- Determine team color based on player's team (always update color)
                           local teamColor = Color3.fromRGB(255, 0, 0) -- Default red
                           if p.Team then
                              teamColor = p.Team.TeamColor.Color
                           elseif p:FindFirstChild("TeamColor") then
                              teamColor = p.TeamColor.Value
                           elseif character:FindFirstChild("Body Colors") then
                              -- Use torso color as team indicator
                              teamColor = character["Body Colors"].TorsoColor3
                           end
                           
                           if not line or not line.Parent then
                              -- Create new line
                              line = Instance.new("Part")
                              line.Name = "EnemyDirectionLine_" .. p.Name
                              line.Anchored = false
                              line.CanCollide = false
                              line.Material = Enum.Material.Neon
                              
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
                           
                           -- Always update color in case team changed
                           line.Color = teamColor
                        else
                           -- Remove line if player is not supposed to be shown
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

-- Add toggle for showing same team players
local SameTeamToggle = PlayerDirectionSection:CreateToggle("SameTeamToggle", {
   Title = "Show Same Team Direction",
   Default = false,
   Callback = function(Value)
      _G.ShowSameTeam = Value
      
      -- Clean up existing direction lines to force refresh
      for _, line in pairs(_G.DirectionLines) do
         if line and line.Parent then
            line:Destroy()
         end
      end
      _G.DirectionLines = {}
   end,
})

-- Add slider for direction line length
local DirectionLengthSlider = PlayerDirectionSection:CreateSlider("DirectionLengthSlider", {
   Title = "Direction Line Length",
   Min = 5,
   Max = 50,
   Value = 20,
   Increment = 1,
   Callback = function(Value)
      _G.DirectionLineLength = Value
      
      -- Update existing lines by recreating them to avoid weld conflicts
      for playerName, line in pairs(_G.DirectionLines) do
         if line and line.Parent then
            local character = line.Parent
            local head = character:FindFirstChild("Head")
            
            if head then
               -- Store the line color before destroying
               local lineColor = line.Color
               
               -- Destroy the old line
               line:Destroy()
               
               -- Create new line with updated size
               local newLine = Instance.new("Part")
               newLine.Name = "EnemyDirectionLine_" .. playerName
               newLine.Anchored = false
               newLine.CanCollide = false
               newLine.Material = Enum.Material.Neon
               newLine.Color = lineColor
               newLine.Size = Vector3.new(0.15, 0.15, Value)
               newLine.Transparency = 0.15
               
               -- Parent to character
               newLine.Parent = character
               
               -- Position the line based on new length
               newLine.CFrame = head.CFrame * CFrame.new(0, 0, -Value/2)
               
               -- Create new WeldConstraint
               local weld = Instance.new("WeldConstraint")
               weld.Part0 = head
               weld.Part1 = newLine
               weld.Parent = newLine
               
               -- Update the reference
               _G.DirectionLines[playerName] = newLine
            end
         end
      end
   end,
})

-- Create toggle keybind in settings
local MenuSec = Settings:CreateSection("Menu")
local ToggleKeypicker = MenuSec:CreateKeypicker("ToggleKeybind", {
   Title = "Toggle Keybind",
   Keybind = Library.ToggleKeybind
})

-- Create unload button
MenuSec:CreateButton("UnloadButton", {
   Title = "Unload",
   Callback = function()
      Library:Unload()
   end
})

-- Set toggle keybind and unload handler
Library.ToggleKeybind = ToggleKeypicker

-- Setup theme manager and save manager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:ApplyToTab(Settings)
SaveManager:ApplyToTab(Settings)

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
	print("Unloading UI Library")
end)
