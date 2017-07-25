model:CreateWeightlist( 
    "Arm_Left",
    {
        { "Root_0", 0 },
            { "thigh_R", 0 },
            { "thigh_L", 0 },
            { "Spine_0", 0 },
                { "Spine_1", 1 },
                    { "clavicle_L", 1 },
                    { "clavicle_R", 0 },
    }
)

model:CreateWeightlist( 
    "Arm_Right",
    {
        { "Root_0", 0 },
            { "thigh_R", 0 },
            { "thigh_L", 0 },
            { "Spine_0", 0 },
                { "Spine_1", 1 },
                    { "clavicle_L", 0 },
                    { "clavicle_R", 1 },
    }
)


model:CreateSequence(
{
    name = "Orb_Spawn_Left",
    sequences = {
        { "orb_spawn_lf" }
    },
    fadeInTime = 0.2,
    fadeOutTime = 0.2,
    hidden = false,
    weightlist = "Arm_Left",
    activities = {
        { name = "ACT_DOTA_OVERRIDE_ABILITY_1", weight = 1 }
    },
    fps = 30
} )

model:CreateSequence(
{
    name = "Orb_Spawn_Right",
    sequences = {
        { "orb_spawn_rt" }
    },
    fadeInTime = 0.2,
    fadeOutTime = 0.2,
    hidden = false,
    weightlist = "Arm_Right",
    activities = {
        { name = "ACT_DOTA_OVERRIDE_ABILITY_2", weight = 1 }
    },
    fps = 30
} )







--[[
model:CreateSequence(
{
    name = "Orb_Spawn_Left",
    framerangesequence = "orb_spawn_lf",
    cmds = {
      { cmd = "sequence", sequence = "orb_spawn_lf", dst = 1 },
      { cmd = "sequence", sequence = "idle", frame = 0, dst = 2 },
      { cmd = "subtract", dst = 1, src = 2 },
      { cmd = "add", dst = 0, src = 1 }
    },
    fadeInTime = 0.2,
    fadeOutTime = 0.2,
    hidden = false,
    delta = true,
    activities = {
        { name = "ACT_DOTA_OVERRIDE_ABILITY_1", weight = 1 }
    },
    fps = 30
} )

model:CreateSequence(
{
    name = "Orb_Spawn_Right",
    framerangesequence = "orb_spawn_rt",
    cmds = {
      { cmd = "sequence", sequence = "orb_spawn_rt", dst = 1 },
      { cmd = "sequence", sequence = "idle", frame = 0, dst = 2 },
      { cmd = "subtract", dst = 1, src = 2 },
      { cmd = "add", dst = 0, src = 1 }
    },
    fadeInTime = 0.2,
    fadeOutTime = 0.2,
    hidden = false,
    delta = true,
    activities = {
        { name = "ACT_DOTA_OVERRIDE_ABILITY_2", weight = 1 }
    },
    fps = 30
} )
]]