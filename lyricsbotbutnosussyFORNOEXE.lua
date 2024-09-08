local songName, plr
local debounce = false
shared.stopped = false

local function sendMessage(text)
	game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, "All")
end

game:GetService('ReplicatedStorage').DefaultChatSystemChatEvents:WaitForChild('OnMessageDoneFiltering').OnClientEvent:Connect(function(msgdata)
	local playerService = game:GetService('Players')
	local localPlayer = playerService.LocalPlayer

	if plr and (msgdata.FromSpeaker == plr or msgdata.FromSpeaker == localPlayer.Name) then
		if string.lower(msgdata.Message) == ';stop' then
			shared.stopped = true
			debounce = true
			task.wait(3)
			debounce = false
		end
	end

	if debounce or not string.match(msgdata.Message, ';lyrics ') or string.gsub(msgdata.Message, ';lyrics', '') == '' or playerService[msgdata.FromSpeaker] == localPlayer then
		return
	end

	debounce = true
	local speaker = msgdata.FromSpeaker
	local msg = string.lower(msgdata.Message):gsub('>lyrics ', ''):gsub('"', ''):gsub(' by ', '/')
	local speakerDisplay = playerService[speaker].DisplayName
	plr = playerService[speaker].Name
	songName = string.gsub(msg, " ", ""):lower()

	local response
	local success, errorMsg = pcall(function()
		response = game.HttpService:RequestAsync({
			Url = "https://lyrist.vercel.app/api/" .. songName,
			Method = "GET",
		})
	end)

	if not success then
		sendMessage('Unexpected error, please retry')
		task.wait(3)
		debounce = false
		return
	end

	local lyricsData = game:GetService('HttpService'):JSONDecode(response.Body)
	if lyricsData.error and lyricsData.error == "Lyrics Not found" then
		sendMessage('Lyrics were not found')
		task.wait(3)
		debounce = false
		return
	end

	local lyricsTable = {}
	for line in string.gmatch(lyricsData.lyrics, "[^\n]+") do
		table.insert(lyricsTable, line)
	end

	sendMessage('Fetched lyrics')
	task.wait(2)
	sendMessage('Playing song requested by ' .. speakerDisplay .. '. They can stop it by saying ";stop"')
	task.wait(3)

	for _, line in ipairs(lyricsTable) do
		if shared.stopped then
			shared.stopped = false
			break
		end
		sendMessage('🎙️ | ' .. line)
		task.wait(4.7)
	end

	task.wait(3)
	debounce = false
	sendMessage('Ended. You can request songs again.')
end)

task.spawn(function()
	while task.wait(60) do
		if not debounce then
			sendMessage('I am a lyrics bot! Type ";lyrics [SongName]" and I will sing the song for you!')
			task.wait(2)
			if not debounce then
				sendMessage('You can also do ";lyrics [SongName by Author]"')
			end
		end
	end
end)

sendMessage('I am a lyrics bot! Type ";lyrics [SongName]" and I will sing the song for you!')
task.wait(2)
sendMessage('You can also do ";lyrics [SongName by Author]"')
