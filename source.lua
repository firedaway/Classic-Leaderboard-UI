repeat task.wait() until game:IsLoaded()

-- !! Put your own teams here. If you don't want to sort teams, delete lines 3-6 and 1162-1172 !!
local homeTeamName = "Defenders"
local awayTeamName = "Raiders"
local spectatorTeamName = "Spectators"

local playersService = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local teamsService = game:GetService("Teams")
local userInputService = game:GetService("UserInputService")

local localPlr = playersService.LocalPlayer
local leaderboard = script.Parent

local thinChars = "[^%[iIl\%.,']"
local minimumContainerSize = UDim2.new(0, 165, 0.5, 0)

local plrEntries = {}
local gameStats = {}
local teamEntries = {}

local isShowingNeutralFrame = false
local isExpanding = false
local isPlrListExpanded = false

local lastSelectedFrame = nil
local lastSelectedPlayer = nil
local localPlrEntry = nil
local neutralTeam = nil
local popupFrame = nil
local selectedEntryMovedCn = nil
local statNameFrame = nil
local updateStatFrames = nil

local lastMaximumScrollSize = 0
local statAddId = 0
local teamAddId = 0

local scaleX = 1
local plrEntrySizeY = 20
local teamEntrySizeY = 20
local nameEntrySizeX = 165
local statEntrySizeX = 60

local entryPad = 1
local maxLeaderstats = 4
local maxStringLength = 10

local backgroundTransparency = 0.7
local textStrokeTransparency = 0.75
local textColor = Color3.fromRGB(255, 255, 255)
local textStrokeColor = Color3.fromRGB(34, 34, 34)
local tweenTime = 0.15

local expandIcon = "rbxasset://textures/ui/expandPlayerList.png"
local placeOwnerIcon = "rbxasset://textures/ui/icon_placeowner.png"
local premiumIcon = "rbxasset://textures/ui/PlayerList/PremiumIcon.png"

local clamp = function(val, min, max)
	if val < min then
		val = min
	elseif val > max then
		val = max
	end
	
	return val
end

local stringWidth = function(str)
	return string.len(str) - math.floor(string.len(string.gsub(str, thinChars, "")) / 2)
end

local getMembershipIcon = function(plr)
	local userId = tostring(plr.UserId)
	local membershipType = plr.MembershipType
	
	if plr.UserId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
		return placeOwnerIcon
	elseif membershipType == Enum.MembershipType.Premium then
		return premiumIcon
	elseif membershipType == Enum.MembershipType.None then
		return nil
	else
		warn("PlayerList: Unknown value for MembershipType " .. tostring(membershipType))
	end
end

local isValidStat = function(obj)
	return (obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") or obj:IsA("DoubleConstrainedValue") or obj:IsA("IntConstrainedValue"))
end

local sortPlrEntries = function(a, b)
	if a.PrimaryStat == b.PrimaryStat then
		return a.Player.Name:upper() < b.Player.Name:upper()
	end
	
	if not a.PrimaryStat then
		return false
	end
	
	if not b.PrimaryStat then
		return true
	end
	
	return a.PrimaryStat > b.PrimaryStat
end

local sortLeaderstats = function(a, b)
	if a.IsPrimary ~= b.IsPrimary then
		return a.IsPrimary
	end
	
	if a.Priority == b.Priority then
		return a.AddId < b.AddId
	end
	
	return a.Priority < b.Priority
end

local sortTeams = function(a, b)
	if a.TeamScore == b.TeamScore then
		return a.Id < b.Id
	end
	
	if not a.TeamScore then
		return false
	end
	
	if not b.TeamScore then
		return true
	end
	
	return a.TeamScore < b.TeamScore
end

local container = Instance.new("Frame")
container.Name = "container"
container.Position = UDim2.new(1, -167, 0, 2)
container.Size = minimumContainerSize
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = leaderboard

local headerFrame = Instance.new("Frame")
headerFrame.Name = "header"
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.Size = UDim2.new(1, 0, 0, 40)
headerFrame.BackgroundTransparency = backgroundTransparency
headerFrame.BackgroundColor3 = Color3.new()
headerFrame.BorderSizePixel = 0
headerFrame.Active = true
headerFrame.ClipsDescendants = true
headerFrame.Parent = container

local headerName = Instance.new("TextLabel")
headerName.Name = "headerName"
headerName.Size = UDim2.new(1, 0, 0.5, 0)
headerName.Position = UDim2.new(-0.02, 0, 0.245, 0)
headerName.BackgroundTransparency = 1
headerName.Font = Enum.Font.SourceSansBold
headerName.FontSize = Enum.FontSize.Size18
headerName.TextColor3 = textColor
headerName.TextStrokeTransparency = textStrokeTransparency
headerName.TextStrokeColor3 = textStrokeColor
headerName.TextXAlignment = Enum.TextXAlignment.Right
headerName.Text = localPlr.Name
headerName.Parent = headerFrame

local headerScore = Instance.new("TextLabel")
headerScore.Name = "headerScore"
headerScore.Size = UDim2.new(1, 0, 0.5, 0)
headerScore.Position = UDim2.new(-0.02, 0, 0.495, 0)
headerScore.BackgroundTransparency = 1
headerScore.Font = Enum.Font.SourceSansBold
headerScore.FontSize = Enum.FontSize.Size18
headerScore.TextColor3 = textColor
headerScore.TextStrokeTransparency = textStrokeTransparency
headerScore.TextStrokeColor3 = textStrokeColor
headerScore.TextXAlignment = Enum.TextXAlignment.Right
headerScore.Text = ""
headerScore.Parent = headerFrame

local scrollList = Instance.new("ScrollingFrame")
scrollList.Name = "scrollList"
scrollList.Size = UDim2.new(1, -1, 0, 0)
scrollList.Position = UDim2.new(0, 0, 0.1, 1)
scrollList.BackgroundTransparency = 1
scrollList.BackgroundColor3 = Color3.fromRGB()
scrollList.BorderSizePixel = 0
scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollList.ScrollBarThickness = 6
scrollList.BottomImage = "rbxasset://textures/ui/scroll-bottom.png"
scrollList.MidImage = "rbxasset://textures/ui/scroll-middle.png"
scrollList.TopImage = "rbxasset://textures/ui/scroll-top.png"
scrollList.Parent = container

local expandFrame = Instance.new("Frame")
expandFrame.Name = "expandFrame"
expandFrame.Size = UDim2.new(1, 0, 0, 22)
expandFrame.Position = UDim2.new(0, 0, 0, 0)
expandFrame.BackgroundTransparency = 1
expandFrame.Active = true
expandFrame.Parent = container

local expandImage = Instance.new("ImageLabel")
expandImage.Name = "expandImage"
expandImage.Size = UDim2.new(0, 27, 0, expandFrame.Size.Y.Offset / 2)
expandImage.Position = UDim2.new(0.5, -expandImage.Size.X.Offset / 2, 0, 0)
expandImage.BackgroundTransparency = 1
expandImage.Image = expandIcon
expandImage.Parent = expandFrame

local popupClipFrame = Instance.new("Frame")
popupClipFrame.Name = "popupClipFrame"
popupClipFrame.Size = UDim2.new(0, 150, 1.5, 0)
popupClipFrame.Position = UDim2.new(0, -151, 0, 2)
popupClipFrame.BackgroundTransparency = 1
popupClipFrame.ClipsDescendants = true
popupClipFrame.Parent = container

local createEntryFrame = function(name, sizeYOffset)
	local containerFrame = Instance.new("Frame")
	containerFrame.Name = name
	containerFrame.Position = UDim2.new(0, 0, 0, 0)
	containerFrame.Size = UDim2.new(1, 0, 0, sizeYOffset)
	containerFrame.BackgroundTransparency = 1
	
	local nameFrame = Instance.new("TextButton")
	nameFrame.Name = "backgroundFrame"
	nameFrame.Position = UDim2.new(0, 0, 0, 0)
	nameFrame.Size = UDim2.new(0, nameEntrySizeX * scaleX, 0, sizeYOffset)
	nameFrame.BackgroundTransparency = backgroundTransparency
	nameFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameFrame.BorderSizePixel = 0
	nameFrame.ClipsDescendants = true
	nameFrame.AutoButtonColor = false
	nameFrame.Text = ""
	nameFrame.Parent = containerFrame
	
	return containerFrame, nameFrame
end

local createEntryNameText = function(name, text, sizeXOffset, posXOffset)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = name
	nameLabel.Size = UDim2.new(-0.01, sizeXOffset, 0.5, 0)
	nameLabel.Position = UDim2.new(0.01, posXOffset, 0.245, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.FontSize = Enum.FontSize.Size14
	nameLabel.TextColor3 = textColor
	nameLabel.TextStrokeTransparency = textStrokeTransparency
	nameLabel.TextStrokeColor3 = textStrokeColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = text

	return nameLabel
end

local createStatFrame = function(offset, parent, name)
	local statFrame = Instance.new("Frame")
	statFrame.Name = name
	statFrame.Size = UDim2.new(0, statEntrySizeX * scaleX, 1, 0)
	statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
	statFrame.BackgroundTransparency = backgroundTransparency
	statFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	statFrame.BorderSizePixel = 0
	statFrame.Parent = parent

	return statFrame
end

local createStatText = function(parent, text)
	local statText = Instance.new("TextLabel")
	statText.Name = "statText"
	statText.Size = UDim2.new(1, 0, 1, 0)
	statText.Position = UDim2.new(0, 0, 0, 0)
	statText.BackgroundTransparency = 1
	statText.Font = Enum.Font.SourceSans
	statText.FontSize = Enum.FontSize.Size14
	statText.TextColor3 = textColor
	statText.TextStrokeColor3 = textStrokeColor
	statText.TextStrokeTransparency = textStrokeTransparency
	statText.Text = text
	statText.Active = true
	statText.Parent = parent

	return statText
end

local createImageIcon = function(image, name, xOffset, parent)
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = name
	imageLabel.Size = UDim2.new(0, 16, 0, 16)
	imageLabel.Position = UDim2.new(0.01, xOffset, 0.5, -imageLabel.Size.Y.Offset / 2)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = image
	imageLabel.BorderSizePixel = 0
	imageLabel.Parent = parent

	return imageLabel
end

local getScoreValue = function(statObj)
	if statObj:IsA("DoubleConstrainedValue") or statObj:IsA("IntConstrainedValue") then
		return statObj.ConstrainedValue
	elseif statObj:IsA("BoolValue") then
		if statObj.Value then
			return 1
		else
			return 0
		end
	else
		return statObj.Value
	end
end

local formatStatString = function(text)
	local maxLength = maxStringLength * scaleX
	
	if stringWidth(text) <= maxLength then
		return text
	else
		return string.sub(text, 1, maxLength - 3) .. "..."
	end
end

local lastExpandPos = scrollList.Size.Y.Offset

local setExpandFramePos = function()
	local canvasOffset = scrollList.AbsolutePosition.Y + scrollList.CanvasSize.Y.Offset
	local scrollListOffset = scrollList.AbsolutePosition.Y + scrollList.AbsoluteSize.Y
	local newPos = math.min(canvasOffset, scrollListOffset)
	
	expandFrame.Position = UDim2.new(0, 0, 0, newPos - container.AbsolutePosition.Y + 2)
end

local setScrollListSize = function()
	local teamSize = #teamEntries * teamEntrySizeY
	local plrSize = #plrEntries * plrEntrySizeY
	local spacing = #plrEntries * entryPad + #teamEntries * entryPad
	local canvasSize = teamSize + plrSize + spacing + (#gameStats > 0 and plrEntrySizeY or 0)

	if #teamEntries > 0 and neutralTeam and isShowingNeutralFrame then
		canvasSize = canvasSize + teamEntrySizeY + entryPad
	end

	scrollList.CanvasSize = UDim2.new(0, 0, 0, canvasSize)

	local newScrollListSize = math.min(canvasSize, container.AbsoluteSize.Y - headerFrame.AbsoluteSize.Y)
	
	if scrollList.Size.Y.Offset == lastMaximumScrollSize and not isExpanding then
		scrollList.Size = UDim2.new(1, 0, 0, newScrollListSize)
	end

	lastMaximumScrollSize = newScrollListSize

	setExpandFramePos()

	lastExpandPos = scrollList.Size.Y.Offset
end

local setPlrEntryPos = function()
	local pos = #gameStats > 0 and plrEntrySizeY + 1 or 0
	
	for i = 1, #plrEntries do
		plrEntries[i].Frame.Position = UDim2.new(0, 0, 0, pos)
		pos = pos + plrEntrySizeY + 1
	end
end

local setTeamEntryPos = function()
	local teamsFound = {}
	
	for _, teamEntry in pairs(teamEntries) do
		local team = teamEntry.Team
		teamsFound[tostring(team.TeamColor)] = {}
	end
	
	if neutralTeam then
		teamsFound.Neutral = {}
	end

	for _, plrEntry in pairs(plrEntries) do
		local plr = plrEntry.Player
		
		if plr.Neutral then
			table.insert(teamsFound.Neutral, plrEntry)
		elseif teamsFound[tostring(plr.TeamColor)] then
			table.insert(teamsFound[tostring(plr.TeamColor)], plrEntry)
		else
			table.insert(teamsFound.Neutral, plrEntry)
		end
	end

	local pos = #gameStats > 0 and plrEntrySizeY + 1 or 0
	
	for _, teamEntry in pairs(teamEntries) do
		local team = teamEntry.Team
		
		teamEntry.Frame.Position = UDim2.new(0, 0, 0, pos)
		pos = pos + teamEntrySizeY + 1
		
		local playersFound = teamsFound[tostring(team.TeamColor)]
		
		for _, plrEntry in pairs(playersFound) do
			plrEntry.Frame.Position = UDim2.new(0, 0, 0, pos)
			pos = pos + plrEntrySizeY + 1
		end
	end
	
	if neutralTeam then
		neutralTeam.Frame.Position = UDim2.new(0, 0, 0, pos)
		pos = pos + teamEntrySizeY + 1
		
		if #teamsFound.Neutral > 0 then
			isShowingNeutralFrame = true
			local playersFound = teamsFound.Neutral
			
			for _, plrEntry in pairs(playersFound) do
				plrEntry.Frame.Position = UDim2.new(0, 0, 0, pos)
				pos = pos + plrEntrySizeY + 1
			end
		else
			isShowingNeutralFrame = false
		end
	end
end

local setEntryPos = function()
	table.sort(plrEntries, sortPlrEntries)
	
	if #teamEntries > 0 then
		setTeamEntryPos()
	else
		setPlrEntryPos()
	end
end

local createPopupFrame = function(buttons)
	local newFrame = Instance.new("Frame")
	newFrame.Name = "popupFrame"
	newFrame.Size = UDim2.new(1, 0, 0, (plrEntrySizeY * #buttons) + (#buttons - 1))
	newFrame.Position = UDim2.new(1, 1, 0, 0)
	newFrame.BackgroundTransparency = 1
	newFrame.Parent = popupClipFrame
	
	for i, button in pairs(buttons) do
		local textButton = Instance.new("TextButton")
		textButton.Name = button.name
		textButton.Size = UDim2.new(1, 0, 0, plrEntrySizeY)
		textButton.Position = UDim2.new(0, 0, 0, plrEntrySizeY * (i - 1) + (i - 1))
		textButton.BackgroundTransparency = backgroundTransparency
		textButton.BackgroundColor3 = Color3.new(0, 0, 0)
		textButton.BorderSizePixel = 0
		textButton.Text = button.text
		textButton.Font = Enum.Font.SourceSans
		textButton.FontSize = Enum.FontSize.Size14
		textButton.TextColor3 = textColor
		textButton.TextStrokeTransparency = textStrokeTransparency
		textButton.TextStrokeColor3 = textStrokeColor
		textButton.AutoButtonColor = true
		textButton.Parent = newFrame
		
		textButton.MouseButton1Click:Connect(button.onPress)
	end
	
	return newFrame
end

local hidePopup = function()
	if popupFrame then
		popupFrame:TweenPosition(UDim2.new(1, 1, 0, popupFrame.Position.Y.Offset), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, tweenTime, true, function() popupFrame:Destroy() popupFrame = nil if selectedEntryMovedCn then selectedEntryMovedCn:Disconnect() selectedEntryMovedCn = nil end end)
	end
	
	if lastSelectedFrame then
		for _, childFrame in pairs(lastSelectedFrame:GetChildren()) do
			if childFrame:IsA("TextButton") or childFrame:IsA("Frame") then
				childFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			end
		end
	end
	
	scrollList.ScrollingEnabled = true
	lastSelectedFrame = nil
	lastSelectedPlr = nil
end

local onFriendButtonPressed = function()
	if lastSelectedPlr then
		local friendStatus = localPlr:IsFriendsWith(lastSelectedPlr.UserId)
		
		if friendStatus then
			starterGui:SetCore("PromptUnfriend", lastSelectedPlr)
		elseif not friendStatus then
			starterGui:SetCore("PromptSendFriendRequest", lastSelectedPlr)
		end
		
		hidePopup()
	end
end

local onDeclineFriendButtonPressed = function()
	if lastSelectedPlr then
		starterGui:SetCore("PromptUnfriend", lastSelectedPlr)
	end
	
	hidePopup()
end

local onBlockButtonPressed = function()
	if lastSelectedPlr then
		local blockedUserIds = starterGui:GetCore("GetBlockedUserIds")
		
		if table.find(blockedUserIds, lastSelectedPlr.UserId) then
			starterGui:SetCore("PromptUnblockPlayer", lastSelectedPlr)
		else
			starterGui:SetCore("PromptBlockPlayer", lastSelectedPlr)
		end
		
		hidePopup()
	end
end

local showPopup = function(selectedFrame, selectedPlr)
	local buttons = {}
	
	local friendStatus = localPlr:IsFriendsWith(selectedPlr.UserId)
	local friendText = ""
	local canDeclineFriend = false
	
	if friendStatus == true then
		friendText = "Unfriend Player"
	elseif friendStatus == false then
		friendText = "Send Friend Request"
	end
	
	local blockedUserIds = starterGui:GetCore("GetBlockedUserIds")
	local blockText = ""
	
	if table.find(blockedUserIds, lastSelectedPlr.UserId) then
		blockText = "Unblock Player"
	else
		blockText = "Block Player"
	end
	
	table.insert(buttons, {
		name = "FriendButton";
		text = friendText;
		onPress = onFriendButtonPressed;
	})
	
	if canDeclineFriend then
		table.insert(buttons, {
			name = "DeclineFriend";
			text = "Decline Friend Request";
			onPress = onDeclineFriendButtonPressed;
		})
	end
	
	table.insert(buttons, {
		name = "BlockButton";
		text = blockText;
		onPress = onBlockButtonPressed;
	})
	
	if popupFrame then
		popupFrame:Destroy()
		
		if selectedEntryMovedCn then
			selectedEntryMovedCn:Disconnect()
			selectedEntryMovedCn = nil
		end
	end
	
	popupFrame = createPopupFrame(buttons)
	popupFrame.Position = UDim2.new(1, 1, 0, selectedFrame.Position.Y.Offset - scrollList.CanvasPosition.Y + 39)
	popupFrame:TweenPosition(UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - scrollList.CanvasPosition.Y + 39), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, tweenTime, true)
	
	selectedEntryMovedCn = selectedFrame.Changed:Connect(function(prop)
		if prop == "Position" then
			popupFrame.Position = UDim2.new(0, 0, 0, selectedFrame.Position.Y.Offset - scrollList.CanvasPosition.Y + 39)
		end
	end)
end

local onEntryFrameSelected = function(selectedFrame, selectedPlr)
	if selectedPlr ~= localPlr and selectedPlr.UserId > 1 and localPlr.UserId > 1 then
		if lastSelectedFrame ~= selectedFrame then
			if lastSelectedFrame then
				for _, childFrame in pairs(lastSelectedFrame:GetChildren()) do
					if childFrame:IsA("TextButton") or childFrame:IsA("Frame") then
						childFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					end
				end
			end
			
			lastSelectedFrame = selectedFrame
			lastSelectedPlr = selectedPlr
			
			for _, childFrame in pairs(selectedFrame:GetChildren()) do
				if childFrame:IsA("TextButton") or childFrame:IsA("Frame") then
					childFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
				end
			end
			
			scrollList.ScrollingEnabled = false
			showPopup(selectedFrame, selectedPlr)
		else
			hidePopup()
			lastSelectedFrame = nil
			lastSelectedPlr = nil
		end
	end
end

local updateTeamScores = function()
	local teamScores = {}
	
	for _, plrEntry in pairs(plrEntries) do
		local plr = plrEntry.Player
		local leaderstats = plr:FindFirstChild("leaderstats")
		local team = plr.Neutral and "Neutral" or tostring(plr.TeamColor)
		local isInvalidColor = true
		
		if team ~= "Neutral" then
			for _, teamEntry in pairs(teamEntries) do
				local color = teamEntry.Team.TeamColor
				
				if team == tostring(color) then
					isInvalidColor = false
					break
				end
			end
		end 
		
		if isInvalidColor then
			team = "Neutral"
		end
		
		if not teamScores[team] then
			teamScores[team] = {}
		end
		
		if leaderstats then
			for _, stat in pairs(gameStats) do
				local statObj = leaderstats:FindFirstChild(stat.Name)
				
				if statObj and not statObj:IsA("StringValue") then
					if not teamScores[team][stat.Name] then
						teamScores[team][stat.Name] = 0
					end
					teamScores[team][stat.Name] = teamScores[team][stat.Name] + getScoreValue(statObj)
				end
			end
		end
	end

	for _, teamEntry in pairs(teamEntries) do
		local team = teamEntry.Team
		local frame = teamEntry.Frame
		local color = tostring(team.TeamColor)
		local stats = teamScores[color]
		
		if stats then
			for statName, statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				
				if statFrame then
					local statText = statFrame:FindFirstChild("statText")
					
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		else
			for _, childFrame in pairs(frame:GetChildren()) do
				local statText = childFrame:FindFirstChild("statText")
				
				if statText then
					statText.Text = ""
				end
			end
		end
	end
	
	if neutralTeam then
		local frame = neutralTeam.Frame
		local stats = teamScores["Neutral"]
		
		if stats then
			for statName, statValue in pairs(stats) do
				local statFrame = frame:FindFirstChild(statName)
				
				if statFrame then
					local statText = statFrame:FindFirstChild("statText")
					
					if statText then
						statText.Text = formatStatString(tostring(statValue))
					end
				end
			end
		end
	end
end

local updateHeaderScore = function(statName)
	if #gameStats > 0 then
		if statName == gameStats[1].Name then
			local leaderstats = localPlr:FindFirstChild("leaderstats")
			
			if leaderstats then
				local statObj = leaderstats:FindFirstChild(statName)
				
				if statObj then
					if headerScore.Text == "" then
						headerName.Position = UDim2.new(-0.02, 0, 0.005, 0)
					end
					
					local score = getScoreValue(statObj)
					headerScore.Text = tostring(score)
				end
			end
		end
	end
end

local updateTeamEntry = function(entry)
	local frame = entry.Frame
	local team = entry.Team
	local color = team.TeamColor.Color
	local offset = nameEntrySizeX * scaleX
	
	for _, stat in pairs(gameStats) do
		local statFrame = frame:FindFirstChild(stat.Name)
		
		if not statFrame then
			statFrame = createStatFrame(offset, frame, stat.Name)
			statFrame.BackgroundColor3 = color
			createStatText(statFrame, "")
		end
		
		statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
		offset = offset + statFrame.Size.X.Offset + 1
	end
end

local updatePrimaryStats = function(statName)
	for _, entry in pairs(plrEntries) do
		local plr = entry.Player
		local leaderstats = plr:FindFirstChild("leaderstats")
		
		if leaderstats then
			local statObj = leaderstats:FindFirstChild(statName)
			
			if statObj then
				local scoreValue = getScoreValue(statObj)
				entry.PrimaryStat = scoreValue
			end
		end
	end
end

local initializeStatText = function(stat, statObj, entry, statFrame)
	local plr = entry.Player
	local statValue = getScoreValue(statObj)
	
	if statObj.Name == gameStats[1].Name then
		entry.PrimaryStat = statValue
	end
	
	local statText = createStatText(statFrame, formatStatString(tostring(statValue)))
	
	statObj.Changed:Connect(function(newValue)
		local scoreValue = getScoreValue(statObj)
		statText.Text = formatStatString(tostring(scoreValue))
		
		if statObj.Name == gameStats[1].Name then
			entry.PrimaryStat = scoreValue
		end
		
		updateTeamScores()
		setEntryPos()
		
		if plr == localPlr then
			updateHeaderScore(statObj.Name)
		end
	end)
	
	statObj.ChildAdded:Connect(function(child)
		if child.Name == "IsPrimary" then
			stat.IsPrimary = true
			
			updatePrimaryStats(stat.Name)
			
			if updateStatFrames then
				updateStatFrames()
			end
			
			updateHeaderScore(statObj.Name)
		end
	end)
	
	if plr == localPlr then
		updateHeaderScore(statObj.Name)
	end
end

updateStatFrames = function()
	table.sort(gameStats, sortLeaderstats)
	
	if statNameFrame then
		local offset = nameEntrySizeX * scaleX
		
		for _, stat in pairs(gameStats) do
			local statFrame = statNameFrame:FindFirstChild(stat.Name)
			
			if not statFrame then
				statFrame = createStatFrame(offset, statNameFrame, stat.Name)
				createStatText(statFrame, formatStatString(stat.Name))
			end
			
			statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
			offset = offset + statFrame.Size.X.Offset + 1
		end
	end
	
	if #teamEntries > 0 then
		for _, entry in pairs(teamEntries) do
			updateTeamEntry(entry)
		end
		
		if neutralTeam then
			updateTeamEntry(neutralTeam)
		end
	end
	
	for _, entry in pairs(plrEntries) do
		local plr = entry.Player
		local mainFrame = entry.Frame
		local offset = nameEntrySizeX * scaleX
		local leaderstats = plr:FindFirstChild("leaderstats")
		
		if leaderstats then
			for _, stat in pairs(gameStats) do
				local statObj = leaderstats:FindFirstChild(stat.Name)
				local statFrame = mainFrame:FindFirstChild(stat.Name)
				
				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
					
					if statObj then
						initializeStatText(stat, statObj, entry, statFrame)
					end
				elseif statObj then
					local statText = statFrame:FindFirstChild("statText")
					
					if not statText then
						initializeStatText(stat, statObj, entry, statFrame)
					end
				end
				
				statFrame.Position = UDim2.new(0, offset + 1, 0, 0)
				offset = offset + statFrame.Size.X.Offset + 1
			end
		else
			for _, stat in pairs(gameStats) do
				local statFrame = mainFrame:FindFirstChild(stat.Name)
				
				if not statFrame then
					statFrame = createStatFrame(offset, mainFrame, stat.Name)
				end
				
				offset = offset + statFrame.Size.X.Offset + 1
			end
		end
		
		container.Position = isPlrListExpanded and UDim2.new(0.5, -offset / 2, 0.15, 0) or UDim2.new(1, -offset - 2, 0, 2)
		container.Size = UDim2.new(0, offset, 0.5, 0)
		
		local newMinimumContainerOffset = isPlrListExpanded and offset / 2 or offset
		minimumContainerSize = UDim2.new(0, newMinimumContainerOffset, 0.5, 0)
	end
	
	updateTeamScores()
	setEntryPos()
end

local createStatNameFrame = function()
	statNameFrame = Instance.new("Frame")
	statNameFrame.Name = "statNameFrame"
	statNameFrame.Position = UDim2.new(0, 0, 0, 0)
	statNameFrame.Size = UDim2.new(1, 0, 0, plrEntrySizeY)
	statNameFrame.BackgroundTransparency = 1
	statNameFrame.Parent = scrollList

	local blankFrame = Instance.new("Frame")
	blankFrame.Name = "players"
	blankFrame.Position = UDim2.new(0, 0, 0, 0)
	blankFrame.Size = UDim2.new(0, nameEntrySizeX * scaleX, 0, plrEntrySizeY)
	blankFrame.BackgroundTransparency = backgroundTransparency
	blankFrame.BackgroundColor3 = Color3.new(0, 0, 0, 0)
	blankFrame.BorderSizePixel = 0
	blankFrame.Parent = statNameFrame

	local NameText = createEntryNameText("playerNames", "players", blankFrame.Size.X.Offset - 2, 2)
	NameText.Parent = blankFrame
end

local addNewStats = function(leaderstats)
	for i, stat in pairs(leaderstats:GetChildren()) do
		if isValidStat(stat) and #gameStats < maxLeaderstats then
			local gameHasStat = false
			
			for _, gameStat in pairs(gameStats) do
				if stat.Name == gameStat.Name then
					gameHasStat = true
					break
				end
			end

			if not gameHasStat then
				local newStat = {}
				newStat.Name = stat.Name
				newStat.Priority = 0
				
				local priority = stat:FindFirstChild("Priority")
				
				if priority then 
					newStat.Priority = priority 
				end
				
				newStat.IsPrimary = false
				
				local isPrimary = stat:FindFirstChild("IsPrimary")
				
				if isPrimary then
					newStat.IsPrimary = true
				end
				
				newStat.AddId = statAddId
				statAddId += 1
				
				table.insert(gameStats, newStat)
				table.sort(gameStats, sortLeaderstats)
				
				if #gameStats == 1 then
					createStatNameFrame()
					setScrollListSize()
					setEntryPos()
				end
			end
		end
	end
end

local removeStatFrameFromEntry = function(stat, frame)
	local statFrame = frame:FindFirstChild(stat.Name)
	
	if statFrame then
		statFrame:Destroy()
	end
end

local doesStatExist = function(stat)
	local doesExist = false
	
	for _, entry in pairs(plrEntries) do
		local plr = entry.Player
		
		if plr then
			local leaderstats = plr:FindFirstChild("leaderstats")
			
			if leaderstats and leaderstats:FindFirstChild(stat.Name) then
				doesExist = true
				break
			end
		end
	end

	return doesExist
end

local onStatRemoved = function(oldStat, entry)
	if isValidStat(oldStat) then
		removeStatFrameFromEntry(oldStat, entry.Frame)
		local StatExists = doesStatExist(oldStat)
		
		if not StatExists then
			for _, plrEntry in pairs(plrEntries) do
				removeStatFrameFromEntry(oldStat, plrEntry.Frame)
			end

			for _, teamEntry in pairs(teamEntries) do
				removeStatFrameFromEntry(oldStat, teamEntry.Frame)
			end

			local toRemove = nil
			
			for i, stat in pairs(gameStats) do
				if stat.Name == oldStat.Name then
					toRemove = i
					break
				end
			end
			
			if toRemove then
				removeStatFrameFromEntry(oldStat, statNameFrame)
				table.remove(gameStats, toRemove)
				table.sort(gameStats, sortLeaderstats)
			end
		end
		
		if #gameStats == 0 then
			if statNameFrame then 
				statNameFrame:Destroy() 
			end
			
			setEntryPos()
			setScrollListSize()
			
			headerScore.Text = ""
			headerName.Position = UDim2.new(-0.02, 0, 0.245, 0)
		else
			local leaderstats = localPlr:FindFirstChild("leaderstats")
			
			if leaderstats then
				local newPrimaryStat = leaderstats:FindFirstChild(gameStats[1].Name)
				
				if newPrimaryStat then
					updateHeaderScore(newPrimaryStat.Name)
				end
			end
		end
		updateStatFrames()
	end
end

local onStatAdded = function(leaderstats, entry)
	leaderstats.ChildAdded:Connect(function(newStat)
		if isValidStat(newStat) then
			addNewStats(newStat.Parent)
			updateStatFrames()
		end
	end)
	
	leaderstats.ChildRemoved:Connect(function(child)
		onStatRemoved(child, entry)
	end)
	
	addNewStats(leaderstats)
	updateStatFrames()
end

local setLeaderstats = function(entry)
	local plr = entry.Player
	local leaderstats = plr:FindFirstChild("leaderstats")

	if leaderstats then
		onStatAdded(leaderstats, entry)
	end

	local function onPlrChildChanged(property, child)
		if property == "Name" and child.Name == "leaderstats" then
			onStatAdded(child, entry)
		end
	end

	plr.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			onStatAdded(child, entry)
		end
		
		child.Changed:Connect(function(property)
			onPlrChildChanged(property, child) 
		end)
	end)
	
	for _, child in pairs(plr:GetChildren()) do
		child.Changed:Connect(function(property)
			onPlrChildChanged(property, child)
		end)
	end

	plr.ChildRemoved:Connect(function(child)
		if child.Name == "leaderstats" then
			for i, stat in pairs(child:GetChildren()) do
				onStatRemoved(stat, entry)
			end
			
			updateStatFrames()
			
			if plr == localPlr then
				headerScore.Text = ""
				headerName.Position = UDim2.new(-0.02, 0, 0.245, 0)
			end
		end
	end)
end

local createPlrEntry = function(plr)
	local plrEntry = {}
	local plrName = plr.Name

	local containerFrame, entryFrame = createEntryFrame(plrName, plrEntrySizeY)
	entryFrame.Active = true
	
	local function localEntrySelected()
		onEntryFrameSelected(containerFrame, plr)
	end
	
	entryFrame.MouseButton1Click:Connect(localEntrySelected)

	local currentXOffset = 1
	
	local membershipIconImage = getMembershipIcon(plr)
	local membershipIcon = nil
	
	if membershipIconImage then
		membershipIcon = createImageIcon(membershipIconImage, "membershipIcon", currentXOffset, entryFrame)
		currentXOffset = currentXOffset + membershipIcon.Size.X.Offset + 2
	else
		currentXOffset = currentXOffset + 18
	end

	task.spawn(function()
		local success, result = pcall(function()
			return plr:GetRankInGroup(game.CreatorId) == 255
		end)
		
		if success then
			if game.CreatorType == Enum.CreatorType.Group and result then
				membershipIconImage = placeOwnerIcon
				
				if not membershipIcon then
					membershipIcon = createImageIcon(membershipIconImage, "membershipIcon", 1, entryFrame)
				else
					membershipIcon.Image = membershipIconImage
				end
			end
		else
			print("PlayerList: GetRankInGroup failed because ", result)
		end
	end)

	local plrNameXSize = entryFrame.Size.X.Offset - currentXOffset
	local plrName = createEntryNameText("playerName", plrName, plrNameXSize, currentXOffset)
	plrName.Parent = entryFrame
    plrEntry.Player = plr
	plrEntry.Frame = containerFrame

	return plrEntry
end

local createTeamEntry = function(team)
	local teamEntry = {}
	teamEntry.Team = team
	teamEntry.TeamScore = 0

	if team.Name == homeTeamName then
		teamEntry.TeamScore = 1
	end

	if team.Name == awayTeamName then
		teamEntry.TeamScore = 2
	end

	if team.Name == spectatorTeamName then
		teamEntry.TeamScore = 3
	end

	local containerFrame, entryFrame = createEntryFrame(team.Name, teamEntrySizeY)
	entryFrame.BackgroundColor3 = team.TeamColor.Color

	local teamName = createEntryNameText("teamName", team.Name, entryFrame.AbsoluteSize.X, 1)
	teamName.Parent = entryFrame

	teamEntry.Frame = containerFrame

	team.Changed:Connect(function(property)
		if property == "Name" then
			teamName.Text = team.Name
		elseif property == "TeamColor" then
			for _, childFrame in pairs(containerFrame:GetChildren()) do
				if childFrame:IsA("Frame") then
					childFrame.BackgroundColor3 = team.TeamColor.Color
				end
			end
		end
	end)

	return teamEntry
end

local createNeutralTeam = function()
	if not neutralTeam then
		local team = Instance.new("Team")
		team.Name = "Neutral"
		team.TeamColor = BrickColor.new("Dark grey")
		
		neutralTeam = createTeamEntry(team)
		neutralTeam.Frame.Parent = scrollList
	end
end

local insertPlrEntry = function(plr)
	local entry = createPlrEntry(plr)
	
	if plr == localPlr then
		localPlrEntry = entry.Frame
	end
	
	setLeaderstats(entry)
	
	table.insert(plrEntries, entry)
	
	setScrollListSize()
	updateStatFrames()
	
	entry.Frame.Parent = scrollList

	plr.Changed:connect(function(property)
		if #teamEntries > 0 and (property == "Neutral" or property == "TeamColor") then
			setTeamEntryPos()
			updateTeamScores()
			setEntryPos()
			setScrollListSize()
		end
	end)
end

local removePlrEntry = function(plr)
	for i = 1, #plrEntries do
		if plrEntries[i].Player == plr then
			plrEntries[i].Frame:Destroy()
			table.remove(plrEntries, i)
			break
		end
	end
	
	setEntryPos()
	setScrollListSize()
end

local onTeamAdded = function(team)
	for i = 1, #teamEntries do
		if teamEntries[i].Team.TeamColor == team.TeamColor then
			teamEntries[i].Frame:Destroy()
			table.remove(teamEntries, i)
			break
		end
	end
	
	local entry = createTeamEntry(team)
	entry.Id = teamAddId
	teamAddId = teamAddId + 1
	
	if not neutralTeam then
		createNeutralTeam()
	end
	
	table.insert(teamEntries, entry)
	table.sort(teamEntries, sortTeams)
	
	setTeamEntryPos()
	updateStatFrames()
	setScrollListSize()
	
	entry.Frame.Parent = scrollList
end

local onTeamRemoved = function(removedTeam)
	for i = 1, #teamEntries do
		local team = teamEntries[i].Team
		
		if team.Name == removedTeam.Name then
			teamEntries[i].Frame:Destroy()
			table.remove(teamEntries, i)
			break
		end
	end
	
	if #teamEntries == 0 then
		if neutralTeam then
			neutralTeam.Frame:Destroy()
			neutralTeam.Team:Destroy()
			neutralTeam = nil
			isShowingNeutralFrame = false
		end
	end
	
	setEntryPos()
	updateStatFrames()
	setScrollListSize()
end

local clampCanvasPos = function()
	local maximumCanvasPos = scrollList.CanvasSize.Y.Offset - scrollList.Size.Y.Offset
	
	if maximumCanvasPos >= 0 and scrollList.CanvasPosition.Y > maximumCanvasPos then
		scrollList.CanvasPosition = Vector2.new(0, maximumCanvasPos)
	end
end

local resizeExpandedFrame = function(containerFrame, scale, name, func)
	local offset = 0
	local nameFrame = containerFrame:FindFirstChild(name)
	
	if nameFrame then
		nameFrame.Size = UDim2.new(0, nameFrame.Size.X.Offset * scale, 1, 0)
		nameFrame.Position = UDim2.new(0, offset, 0, 0)
		offset = offset + nameFrame.Size.X.Offset + 1
	end
	
	for _, stat in pairs(gameStats) do
		local subFrame = containerFrame:FindFirstChild(stat.Name)
		
		if subFrame then
			subFrame.Size = UDim2.new(0, subFrame.Size.X.Offset * scale, 1, 0)
			subFrame.Position = UDim2.new(0, offset, 0, 0)
			offset = offset + subFrame.Size.X.Offset + 1
			
			if func then
				func(subFrame, stat.Name)
			end
		end
	end
end

local expandPlrList = function(endPos, subFrameScale)
	local ContainerOffset = 5 * (scaleX - 1)
	
	container:TweenSizeAndPosition(UDim2.new(0, minimumContainerSize.X.Offset * scaleX - ContainerOffset, 0.5, 0), endPos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, tweenTime, true)

	if statNameFrame then
		resizeExpandedFrame(statNameFrame, subFrameScale, "Players")
		
		for _, stat in pairs(gameStats) do
			local subFrame = statNameFrame:FindFirstChild(stat.Name)
			
			if subFrame then
				local statText = subFrame:FindFirstChild("statText")
				
				if statText then
					statText.Text = formatStatString(stat.Name)
				end
			end
		end
	end
	
	for _, entry in pairs(plrEntries) do
		local plr = entry.Player
		local leaderstats = plr:FindFirstChild("leaderstats")
		
		local function setScore(subFrame, statName)
			if leaderstats then
				local statObj = leaderstats:FindFirstChild(statName)
				local statText = subFrame:FindFirstChild("statText")
				
				if statObj and statText then
					local score = getScoreValue(statObj)
					statText.Text = formatStatString(tostring(score))
				end
			end
		end
		
		resizeExpandedFrame(entry.Frame, subFrameScale, "backgroundFrame", setScore)
	end
	
	for _, entry in pairs(teamEntries) do
		resizeExpandedFrame(entry.Frame, subFrameScale, "backgroundFrame")
	end
	
	if neutralTeam then
		resizeExpandedFrame(neutralTeam.Frame, subFrameScale, "backgroundFrame")
	end
	
	updateTeamScores()
end

local resizePlrList = function()
	setScrollListSize()
	scrollList.Position = UDim2.new(0, 0, 0, headerFrame.AbsoluteSize.Y + 1)
	clampCanvasPos()
end

leaderboard.Changed:Connect(function(property)
	if property == "AbsoluteSize" then
		task.spawn(function()
			resizePlrList()
		end)
	end
end)

local expandInputObject = nil
local lastExpandInputPos = nil
local expandOffset = nil

expandFrame.InputBegan:connect(function(inputObject)
	if lastSelectedFrame then
		return
	end
	
	local inputType = inputObject.UserInputType
	local inputState = inputObject.UserInputState
	
	if (inputType == Enum.UserInputType.Touch and inputState == Enum.UserInputState.Begin) or inputType == Enum.UserInputType.MouseButton1 then
		isExpanding = true
		expandInputObject = inputObject
		lastExpandInputPos = inputObject.Position.Y
		expandOffset = inputObject.Position.Y - (scrollList.AbsolutePosition.Y + scrollList.AbsoluteSize.Y)
	end
end)

userInputService.InputChanged:Connect(function(inputObject)
	if inputObject == expandInputObject or (expandInputObject and inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
		local minExpand = scrollList.AbsolutePosition.Y + expandOffset
		local maxExpand = minExpand + lastMaximumScrollSize
		local currentPos = clamp(inputObject.Position.Y, minExpand, maxExpand)
		local delta = lastExpandInputPos - currentPos
		local newPos = clamp(scrollList.Size.Y.Offset - delta, 0, container.AbsoluteSize.Y - headerFrame.AbsoluteSize.Y)
		
		scrollList.Size = UDim2.new(1, 0, 0, newPos)

		clampCanvasPos()
		setExpandFramePos()
		
		lastExpandInputPos = currentPos
	end
end)

userInputService.InputEnded:Connect(function(inputObject)
	if inputObject == expandInputObject then
		expandInputObject = nil
		lastExpandInputPos = nil
		lastExpandPos = scrollList.Size.Y.Offset
		isExpanding = false
	end
end)

userInputService.InputBegan:Connect(function(inputObject, isProcessed)
	if isProcessed then
		return
	end
	
	local inputType = inputObject.UserInputType
	
	if (inputType == Enum.UserInputType.Touch and inputObject.UserInputState == Enum.UserInputState.Begin) or inputType == Enum.UserInputType.MouseButton1 then
		if lastSelectedFrame then
			hidePopup()
		end
	end
	
	if inputObject.KeyCode == Enum.KeyCode.Tab then
		container.Visible = not container.Visible
	end
end)

playersService.ChildAdded:Connect(function(child)
	if child:IsA("Player") then
		insertPlrEntry(child)
	end
end)

for _, plr in pairs(playersService:GetPlayers()) do
	insertPlrEntry(plr)
end

playersService.ChildRemoved:Connect(function(child)
	if child:IsA("Player") then
		if lastSelectedPlr and child == lastSelectedPlr then
			hidePopup()
		end
		
		removePlrEntry(child)
	end
end)

local initializeTeams = function(foundTeams)
	for _, team in pairs(foundTeams:GetTeams()) do
		onTeamAdded(team)
	end

	foundTeams.ChildAdded:Connect(function(team)
		if team:IsA("Team") then
			onTeamAdded(team)
		end
	end)

	foundTeams.ChildRemoved:Connect(function(team)
		if team:IsA("Team") then
			onTeamRemoved(team)
		end
	end)
end

if teamsService then
	initializeTeams(teamsService)
end

game.ChildAdded:Connect(function(child)
	if child:IsA("Teams") then
		initializeTeams(child)
	end
end)

starterGui:SetCoreGuiEnabled("PlayerList", false)
resizePlrList()
container.Visible = true
