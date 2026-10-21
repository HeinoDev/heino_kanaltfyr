return {
    HouseRobbery = {
        -- PedModel: the ped's model name.
        -- All models with previews: https://docs.fivem.net/docs/game-references/ped-models/
        PedModel = 'A_M_M_TrampBeac_01',
        -- Scenario: the idle animation the ped loops. Set to nil for none.
        -- Full scenario list: https://wiki.rage.mp/index.php?title=Scenarios
        -- Common choices:
        --   WORLD_HUMAN_SMOKING          smoking a cigarette
        --   WORLD_HUMAN_STAND_IMPATIENT  standing around, checking surroundings
        --   WORLD_HUMAN_STAND_MOBILE     looking at a phone
        --   WORLD_HUMAN_DRUG_DEALER      shady dealer stance
        --   WORLD_HUMAN_AA_COFFEE        drinking coffee
        --   WORLD_HUMAN_LEANING          leaning against a wall
        --   WORLD_HUMAN_GUARD_STAND      standing guard
        --   WORLD_HUMAN_CLIPBOARD        writing on a clipboard
        --   WORLD_HUMAN_BUM_STANDING     standing like a homeless person
        Scenario = 'WORLD_HUMAN_SMOKING',
        Coords = vec4(1391.08, -1508.34, 58.43, 30.0),
        Target = {
            Label = 'Snak med kanal-fyren',
            Icon = 'fa-solid fa-sack-dollar',
        },
        Blip = nil,
    },
}
