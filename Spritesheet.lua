-- This is a class that allows you to play videos and GIFs using spritesheets. 
-- Since Roblox does not have animated images, I created my own solution.

local SpriteSheet = {}
SpriteSheet.__index = SpriteSheet
SpriteSheet.ClassName = "SpriteSheet"

function SpriteSheet.calculateRows(GIF_Data)
	return math.ceil(GIF_Data.frames/GIF_Data.columns)
end

function SpriteSheet.calculateFrames(rows, columns, finalPanel)
	local frames = {}

	for row = 0,rows-1 do
		for column = 0,columns-1 do
			frames[#frames + 1] = UDim2.new(-column, 0, -row,0)
			if #frames == finalPanel then
				break
			end
		end
	end

	return frames
end

function SpriteSheet.new(image, gifData)
	local self = setmetatable({}, SpriteSheet)
	self._gifData = gifData
	self._image = image
	self._rows = SpriteSheet.calculateRows(self._gifData)
	self._isPaused = false
	self._isStopped = false
	self._isPlaying = false
	
	self._completedEvent = Instance.new("BindableEvent")
	self.Completed = self._completedEvent.Event
	
	self._stoppedEvent = Instance.new("BindableEvent")
	self.Stopped = self._stoppedEvent.Event
	
	self._pausedEvent = Instance.new("BindableEvent")
	self.Paused = self._pausedEvent.Event
	
	
	return self
end

function SpriteSheet:IsPlaying()
	return self._isPlaying and not self._isPaused and not self._isStopped
end

function SpriteSheet:JumpTo(frameNumber)
	local frames = SpriteSheet.calculateFrames(self._rows, self._gifData.columns, self._gifData.frames)
	self._image.Position = frames[frameNumber]
end

function SpriteSheet:Play()
	if self._isPaused then
		self._isPaused = false
		self._isPlaying = true
		return
	end
	
	self._isPlaying = true
	self._image.Image = self._gifData.image
	self._image.Size = UDim2.new(self._gifData.columns, 0, self._rows, 0)

	local i = 0
	local frames = SpriteSheet.calculateFrames(self._rows, self._gifData.columns, self._gifData.frames)

	coroutine.wrap(function()
		while true do
			if self._isPaused then
				self._isPlaying = false
				
				repeat
					wait()
				until not self._isPaused
				
				self._isPaused = false
				self._isStopped = false
			end
			
			if self._isStopped then
				self._isPaused = false
				self._isStopped = false
				
				break
			end
			
			if i == self._gifData.frames and not self._gifData.looped then
				break
			end
			
			
			i = (i % self._gifData.frames) + 1
			self._image.Position = frames[i]
			wait(self._gifData.timePerFrame)
		end
		
		self._isPlaying = false
		self._completedEvent:Fire()
	end)()
end

function SpriteSheet:Pause()
	self._isPaused = true
	self._isPlaying = false
	self._pausedEvent:Fire()
end

function SpriteSheet:Stop()
	self._isStopped = true
	self._stoppedEvent:Fire()
end

return SpriteSheet
