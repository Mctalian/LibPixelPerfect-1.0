---@diagnostic disable: missing-fields
local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local assert = busted.assert

function Round(x)
    if x >= 0 then
        return math.floor(x + 0.5)
    else
        return math.ceil(x - 0.5)
    end
end

function GetPhysicalScreenSize()
    -- This function should return the physical screen size.
    -- For testing purposes, we can return a fixed size.
    -- In a real application, this would query the system for the actual screen size.
    return 1920, 1080; -- Example values for physical width and height
end

_G.UIParent = {
    GetEffectiveScale = function()
        -- This function should return the effective scale of the UIParent.
        -- For testing purposes, we can return a fixed scale.
        return 1.0; -- Example value for effective scale
    end,
};

--- These are lifted from the PixelUtil library in WoW for testing.
_G.PixelUtil = {};

function PixelUtil.GetPixelToUIUnitFactor()
    --- GetPhysicalScreenSize was added in WoW 7.1.0 (Legion).
	local physicalWidth, physicalHeight = GetPhysicalScreenSize();
	return 768.0 / physicalHeight;
end

function PixelUtil.GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
	if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
		return 0;
	end

	local uiUnitFactor = PixelUtil.GetPixelToUIUnitFactor();
	local numPixels = Round((uiUnitSize * layoutScale) / uiUnitFactor);
	local rawNumPixels = numPixels;
	if minPixels then
		if uiUnitSize < 0.0 then
			if numPixels > -minPixels then
				numPixels = -minPixels;
			end
		else
			if numPixels < minPixels then
				numPixels = minPixels;
			end
		end
	end

	return numPixels * uiUnitFactor / layoutScale;
end

-- Mock LibStub
_G.LibStub = {
    NewLibrary = function(name, version)
        return {}
    end
}

-- Mock frame for testing
local function createMockFrame()
    return {
        SetSize = function(self, width, height)
            self.width = width
            self.height = height
        end,
        SetPoint = function(self, point, relativeTo, relativePoint, offsetX, offsetY)
            self.point = point
            self.relativeTo = relativeTo
            self.relativePoint = relativePoint
            self.offsetX = offsetX
            self.offsetY = offsetY
        end,
        SetWidth = function(self, width)
            self.width = width
        end,
        SetHeight = function(self, height)
            self.height = height
        end,
        GetEffectiveScale = function(self)
            return self.scale or 1.0
        end,
        scale = 1.0
    }
end

describe("LibPixelPerfect", function()
    local LibPixelPerfect
    local ns = {}

    before_each(function()
        LibPixelPerfect = assert(loadfile("LibPixelPerfect/LibPixelPerfect.lua"))("LibPixelPerfect", ns)
    end)

    describe("SetParentFrame", function()
        it("should set a custom parent frame", function()
            local customFrame = createMockFrame()
            customFrame.scale = 0.8
            LibPixelPerfect.SetParentFrame(customFrame)
            
            -- Test that the new parent frame is used
            local result = LibPixelPerfect.PScale(100)
            local expected = PixelUtil.GetNearestPixelSize(100, 0.8)
            assert.are.equal(expected, result)
        end)
    end)

    describe("PScale", function()
        it("should scale pixel values correctly", function()
            local result = LibPixelPerfect.PScale(100)
            local expected = PixelUtil.GetNearestPixelSize(100, UIParent:GetEffectiveScale())
            assert.are.equal(expected, result)
        end)

        it("should default to 0 when no value is provided", function()
            local result = LibPixelPerfect.PScale()
            local expected = PixelUtil.GetNearestPixelSize(0, UIParent:GetEffectiveScale())
            assert.are.equal(expected, result)
        end)

        it("should handle nil values", function()
            local result = LibPixelPerfect.PScale(nil)
            local expected = PixelUtil.GetNearestPixelSize(0, UIParent:GetEffectiveScale())
            assert.are.equal(expected, result)
        end)
    end)

    describe("PSize", function()
        it("should set frame size with scaled values", function()
            local frame = createMockFrame()
            frame.scale = 0.5
            LibPixelPerfect.PSize(frame, 200, 100)
            
            local expectedWidth = LibPixelPerfect.PScale(200)
            local expectedHeight = LibPixelPerfect.PScale(100)
            
            assert.are.equal(expectedWidth, frame.width)
            assert.are.equal(expectedHeight, frame.height)
        end)

        it("should handle nil frame gracefully", function()
            assert.has_no.errors(function()
                LibPixelPerfect.PSize(nil, 200, 100)
            end)
        end)
    end)

    describe("PWidth", function()
        it("should set frame width with scaled value", function()
            local frame = createMockFrame()
            frame.scale = 1.2
            LibPixelPerfect.PWidth(frame, 300)
            
            local expectedWidth = LibPixelPerfect.PScale(300)
            assert.are.equal(expectedWidth, frame.width)
        end)
    end)

    describe("PHeight", function()
        it("should set frame height with scaled value", function()
            local frame = createMockFrame()
            frame.scale = 1.5
            LibPixelPerfect.PHeight(frame, 150)
            
            local expectedHeight = LibPixelPerfect.PScale(150)
            assert.are.equal(expectedHeight, frame.height)
        end)
    end)
end)
