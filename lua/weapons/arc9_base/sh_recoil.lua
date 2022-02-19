function SWEP:ThinkRecoil()
    if (self:GetLastRecoilTime() + self:GetProcessedValue("RecoilResetTime")) < CurTime() then
        local rec = self:GetRecoilAmount()

        rec = rec - (FrameTime() * self:GetProcessedValue("RecoilDissipationRate"))

        self:SetRecoilAmount(math.max(rec, 0))
    end

    local ru = self:GetRecoilUp()
    local rs = self:GetRecoilSide()

    if math.abs(ru) > 0 or math.abs(rs) > 0 then
        local new_ru = ru - (FrameTime() * self:GetRecoilUp() * self:GetProcessedValue("RecoilDissipationRate"))
        local new_rs = rs - (FrameTime() * self:GetRecoilSide() * self:GetProcessedValue("RecoilDissipationRate"))

        self:SetRecoilUp(new_ru)
        self:SetRecoilSide(new_rs)
    end

    self:ThinkVisualRecoil()
end

SWEP.RecoilPatternCache = {}

function SWEP:ApplyRecoil()
    local rec = self:GetRecoilAmount()

    local rps = 1

    if IsFirstTimePredicted() then
        rec = rec + rps
    end

    local delay = 60 / self:GetProcessedValue("RPM")

    local recoilup = 1
    local recoilside = 0

    local seed = self:GetProcessedValue("RecoilSeed") or self:GetClass()
    local shot = math.floor(self:GetRecoilAmount()) + 1

    if isstring(seed) then
        local numseed = 0

        for _, i in ipairs(string.ToTable(seed)) do
            numseed = numseed + string.byte(i)
        end

        numseed = numseed % 16777216

        seed = numseed
    end

    seed = seed + shot

    local dir = 0

    if self:GetProcessedValue("RecoilLookupTable") then
        dir = self:PatternWithRunOff(self:GetProcessedValue("RecoilLookupTable"), self:GetProcessedValue("RecoilLookupTableOverrun") or self:GetProcessedValue("RecoilLookupTable"), shot)
    else
        if self.RecoilPatternCache[shot] then
            dir = self.RecoilPatternCache[shot]
        else
            self.RecoilPatternCache[1] = 0
            if self.RecoilPatternCache[shot - 1] then
                dir = self.RecoilPatternCache[shot - 1]
                math.randomseed(seed)
                local drift = self:GetValue("RecoilPatternDrift")
                dir = dir + math.Rand(-drift, drift)
                math.randomseed(CurTime() + self:EntIndex())
                self.RecoilPatternCache[shot] = dir
            else
                dir = 0
            end
        end
    end

    dir = self:RunHook("Hook_ModifyRecoilDir", dir) or dir

    dir = dir - 90

    dir = math.rad(dir)

    recoilup = math.sin(dir)
    recoilside = math.cos(dir)

    local randomrecoilup = util.SharedRandom("arc9_recoil_up_r", -1, 1)
    local randomrecoilside = util.SharedRandom("arc9_recoil_side_r", -1, 1)

    recoilup = recoilup * self:GetProcessedValue("RecoilUp")
    recoilside = recoilside * self:GetProcessedValue("RecoilSide")

    randomrecoilup = randomrecoilup * self:GetProcessedValue("RecoilRandomUp")
    randomrecoilside = randomrecoilside * self:GetProcessedValue("RecoilRandomSide")

    recoilup = recoilup + randomrecoilup
    recoilside = recoilside + randomrecoilside

    recoilup = recoilup * self:GetProcessedValue("Recoil")
    recoilside = recoilside * self:GetProcessedValue("Recoil")

    self:SetRecoilUp(recoilup)
    self:SetRecoilSide(recoilside)

    -- self:SetRecoilDirection(-90)
    self:SetRecoilAmount(rec)

    self:SetLastRecoilTime(CurTime() + (delay * 2))

    -- local vis_kick = self:GetProcessedValue("RecoilKick")
    -- local vis_shake = 0

    -- vis_kick = vis_kick * rps
    -- vis_shake = vis_kick * rps

    -- local vis_kick_v = vis_kick * 0.5
    -- local vis_kick_h = vis_kick * util.SharedRandom("ARC9_vis_kick_h", -1, 1)
    -- vis_shake = vis_shake * util.SharedRandom("ARC9_vis_kick_shake", -1, 1)

    -- self:GetOwner():SetViewPunchAngles(Angle(vis_kick_v, vis_kick_h, vis_shake))

    -- self:GetOwner():SetFOV(self:GetOwner():GetFOV() * 0.99, 0)
    -- self:GetOwner():SetFOV(0, 60 / (self:GetProcessedValue("RPM")))
end

SWEP.VisualRecoilPos = Vector(0, 0, 0)
SWEP.VisualRecoilAng = Angle(0, 0, 0)

function SWEP:ThinkVisualRecoil()
    if game.SinglePlayer() and SERVER then self:CallOnClient("ThinkVisualRecoil") end

    -- self.VisualRecoilPos = LerpVector(2 * FrameTime(), self.VisualRecoilPos, Vector(0, 0, 0))
    -- self.VisualRecoilAng = LerpAngle(2.5 * FrameTime(), self.VisualRecoilAng, Angle(0, 0, 0))

    local ds = 0.1 / (self.VisualRecoilPos:Length() / 2)
    -- local dr = 0.4 / (self.VisualRecoilAng.p + self.VisualRecoilAng.y + self.VisualRecoilAng.r)

    self.VisualRecoilPos.x = math.Approach(self.VisualRecoilPos.x, 0, FrameTime() / ds)
    self.VisualRecoilPos.y = math.Approach(self.VisualRecoilPos.y, 0, FrameTime() / ds)
    self.VisualRecoilPos.z = math.Approach(self.VisualRecoilPos.z, 0, FrameTime() / ds)

    -- self.VisualRecoilAng.p = math.Approach(self.VisualRecoilAng.p, 0, FrameTime() / dr)
    -- self.VisualRecoilAng.y = math.Approach(self.VisualRecoilAng.y, 0, FrameTime() / dr)
    -- self.VisualRecoilAng.r = math.Approach(self.VisualRecoilAng.r, 0, FrameTime() / dr)
end

function SWEP:DoVisualRecoil()
    if game.SinglePlayer() then self:CallOnClient("DoVisualRecoil") end

    if IsFirstTimePredicted() or game.SinglePlayer() then
        local mult = self:GetProcessedValue("VisualRecoilMult")
        local sd = math.max(self:GetSightDelta(), self:GetBipodAmount())

        local up = self:GetProcessedValue("VisualRecoilUp") * mult
        local side = self:GetProcessedValue("VisualRecoilSide") * math.Rand(-1, 1) * mult
        local roll = self:GetProcessedValue("VisualRecoilRoll") * math.Rand(-1, 1) * 2 * mult
        local punch = self:GetProcessedValue("VisualRecoilPunch") * Lerp(sd, 1, 0.5) * mult

        self.VisualRecoilPos = self.VisualRecoilPos + Vector(side, -punch, up)
        -- self.VisualRecoilAng = self.VisualRecoilAng + Angle(2.5 * mult * Lerp(sd, 1, 0), 0, roll)

        if self:GetSightAmount() > 0 then
            self.VisualRecoilPos.x = math.Clamp(self.VisualRecoilPos.x, -0.1, 0.1)
            self.VisualRecoilPos.y = math.Clamp(self.VisualRecoilPos.y, -0.1, 0)
            self.VisualRecoilPos.z = math.Clamp(self.VisualRecoilPos.z, 0, 0.25)
        end
    end
end

function SWEP:GetViewModelRecoil(pos, ang)
    if !self:GetProcessedValue("UseVisualRecoil") then return pos, ang end

    local v = Vector(0, 0, 0)
    local vrc = self:GetProcessedValue("VisualRecoilCenter")

    v = v + (vrc.x * ang:Right())
    v = v + (vrc.y * ang:Forward())
    v = v + (vrc.z * ang:Up())

    ang:RotateAroundAxis(ang:Right(), self.VisualRecoilAng.p)
    ang:RotateAroundAxis(ang:Forward(), self.VisualRecoilAng.r)

    v = v + ang:Right() * self.VisualRecoilPos.x
    v = v + ang:Forward() * self.VisualRecoilPos.y
    v = v + ang:Up() * self.VisualRecoilPos.z

    v:Rotate(self.VisualRecoilAng)

    v = v - (vrc.x * ang:Right())
    v = v - (vrc.y * ang:Forward())
    v = v - (vrc.z * ang:Up())

    pos = pos + v

    return pos, ang
end