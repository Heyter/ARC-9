SWEP.MaxLeanOffset = 16
SWEP.MaxLeanAngle = 15

SWEP.LastLeanAmountSERVER = 0

function SWEP:ThinkLean()
    if !GetConVar("arc9_lean"):GetBool() or !self:GetProcessedValue("CanLean") then
        self:SetLeanAmount(0)
        return
    end

    local leanstate = self:GetLeanState()

    if !(self:GetOwner():KeyDown(IN_SPEED) and (self:GetOwner():KeyDown(IN_FORWARD) or self:GetOwner():KeyDown(IN_BACK) or self:GetOwner():KeyDown(IN_MOVELEFT) or self:GetOwner():KeyDown(IN_MOVERIGHT))) then
        if self:GetOwner():GetInfoNum("arc9_togglelean", 0) >= 1 then
            if leanstate == -1 then
                if self:GetOwner():KeyPressed(IN_ALT1) then
                    leanstate = 0
                elseif self:GetOwner():KeyPressed(IN_ALT2) then
                    leanstate = 1
                end
            elseif leanstate == 1 then
                if self:GetOwner():KeyPressed(IN_ALT2) then
                    leanstate = 0
                elseif self:GetOwner():KeyPressed(IN_ALT1) then
                    leanstate = -1
                end
            else
                if self:GetOwner():KeyPressed(IN_ALT1) then
                    leanstate = -1
                elseif self:GetOwner():KeyPressed(IN_ALT2) then
                    leanstate = 1
                end
            end
        else
            if self:GetOwner():KeyDown(IN_ALT1) then
                leanstate = -1
            elseif self:GetOwner():KeyDown(IN_ALT2) then
                leanstate = 1
            else
                leanstate = 0
            end
        end
    else
        leanstate = 0
    end

    self:SetLeanState(leanstate)

    local maxleanfrac = 1

    if leanstate != 0 then
        local tr = util.TraceHull({
            start = self:GetOwner():EyePos(),
            endpos = self:GetOwner():EyePos() + self:GetOwner():EyeAngles():Right() * (self.MaxLeanOffset - 2) * leanstate,
            filter = self:GetOwner(),
            maxs = Vector(1, 1, 1) * 4,
            mins = Vector(-1, -1, -1) * 4,
        })

        if tr.Hit then
            maxleanfrac = tr.Fraction * 0.5
        end
    end

    local amt = self:GetLeanAmount()
    local tgt = leanstate

    if maxleanfrac < 1 then
        tgt = 0
    end

    amt = math.Approach(amt, tgt, FrameTime() * 7)
    amt = math.Clamp(amt, -maxleanfrac, maxleanfrac)

    self:SetLeanAmount(amt)

    if amt != 0 then
        self:GetOwner():SetCollisionBounds(Vector(-32, -32, 0), Vector(32, 32, 64))
    end

    local force = SERVER and (math.abs(amt) == 1 or math.abs(amt) == 0) and self.LastLeanAmountSERVER != amt

    self:DoPlayerModelLean(false, force)

    self.LastLeanAmountSERVER = amt
end

function SWEP:GetLeanDelta()
    return math.ease.InSine(self:GetLeanAmount()) * (self:GetLeanAmount() > 0 and 1 or -1)
end

function SWEP:GetLeanOffset()
    local amt = self:GetLeanDelta()

    return amt * self.MaxLeanOffset
end

function SWEP:DoCameraLean(pos, ang)
    local amt = self:GetLeanDelta()

    if amt == 0 then return pos, ang end

    local newpos = pos + self:GetOwner():EyeAngles():Right() * self:GetLeanOffset()

    ang:RotateAroundAxis(ang:Forward(), amt * self.MaxLeanAngle)

    return newpos, ang
end

function SWEP:DoWeaponLean(pos, ang)
    local amt = self:GetLeanDelta()

    if amt == 0 then return pos, ang end

    local newpos = pos + self:GetOwner():EyeAngles():Right() * self:GetLeanOffset()

    return newpos, ang
end

local leanbone = "ValveBiped.Bip01_Spine1"

local leanang_left = Angle(3.6, 2.65, 1.2)
local leanang_right = Angle(3, 2.2, 1)

function SWEP:DoPlayerModelLean(cancel, forceupdate)
    local amt = self:GetLeanDelta()

    if cancel then amt = 0 end

    local bone = self:GetOwner():LookupBone(leanbone)

    if !bone then return end

    self:GetOwner():ManipulateBoneAngles(bone, (amt < 0 and leanang_left or leanang_right) * amt * self.MaxLeanAngle, game.SinglePlayer() or cancel or forceupdate)
end