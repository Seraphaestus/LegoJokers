local mod = SMODS.current_mod
SMODS.Atlas{ key = "jokers", path = "jokers.png", px = 71, py = 95 }
SMODS.Atlas{ key = "consumables", path = "consumables.png", px = 71, py = 95 }
SMODS.Atlas{ key = "decks", path = "decks.png", px = 71, py = 95 }
SMODS.Atlas{ key = "modicon", path = "icon.png", px = 32, py = 32 }

SMODS.current_mod.config_tab = function()
    local makemake_display = CardArea(0,0, G.CARD_W, G.CARD_H, 
        {card_limit = 1, type = 'title', highlight_limit = 0, lr_padding = 0})
    
    local makemake = Card(0,0, G.CARD_W, G.CARD_H, nil, G.P_CENTERS['c_' .. mod.prefix .. '_makemake'])
    makemake.no_ui = true
    makemake_display:emplace(makemake)

    return {n=G.UIT.ROOT, config={ align = "cm", padding = 0.05, colour = G.C.CLEAR }, nodes = {
        {n=G.UIT.R, config={ align = "cm", padding = 0.03 }, nodes = {
            create_option_cycle({ label = "Planet for My Own Creation", options = mod.config.moc_planet.options,
                current_option = mod.config.moc_planet.value,
                opt_callback = 'amaryllis_lego_makemake_changed',
                w = 3.5,
            }),
            {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                {n=G.UIT.O, config={align = "cm", object = makemake_display}},
                {n=G.UIT.R, config={minw = 1}}
            }}
        }}
    }}
end

G.FUNCS.amaryllis_lego_makemake_changed = function(args)
    if args and args.cycle_config and args.cycle_config.current_option then
        mod.config.moc_planet.value = args.cycle_config.current_option

        G.P_CENTERS['c_' .. mod.prefix .. '_makemake'].pos.x = (mod.config.moc_planet.value - 1)
    end
end
G.FUNCS.amaryllis_lego_get_makemake_name = function()
    return mod.config.moc_planet.options[mod.config.moc_planet.value] or 'Makemake'
end

G.FUNCS.amaryllis_lego_after_scoring = function(scoring_hand)
    if not G.GAME.amaryllis_rank_last_scored then G.GAME.amaryllis_rank_last_scored = {} end

    for i = 1, #scoring_hand do
        if not SMODS.has_no_rank(scoring_hand[i]) and not scoring_hand[i].debuff then
            local npu_rank = scoring_hand[i]:get_id()
            if npu_rank then G.GAME.amaryllis_rank_last_scored[npu_rank] = G.GAME.round end
        end
    end
end

-------------------------

SMODS.Joker{ -- Classic Joker
    key = "classic_joker",

    name = "Classic Joker",
    loc_txt = {
        name = "Classic Joker",
        text = {
            [1] = "{C:attention}Face{} cards",
            [2] = "held in hand",
            [3] = "at end of round",
            [4] = "become {C:diamonds}#1#{}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { localize('Diamonds', 'suits_plural') }}
    end,

    pos = { x = 0, y = 0 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.end_of_round and 
           context.cardarea == G.hand and context.individual and not context.repetition and 
           context.other_card:is_face() and not context.other_card:is_suit('Diamonds')
        then
            local _card = context.other_card
            G.E_MANAGER:add_event(Event({func = function()
                SMODS.change_base(_card, 'Diamonds')
                _card:juice_up()
                return true
            end}))

            return {
                message = localize('k_' .. mod.prefix .. '_classic'), 
                colour = G.C.SO_2.Diamonds, 
                card = card 
            }
        end
    end,
}



SMODS.Joker{ -- Greebled Joker
    key = "greebled_joker",

    name = "Greebled Joker",
    loc_txt = {
        name = "Greebled Joker",
        text = {
            [1] = "Each scored {C:attention}2{} or {C:attention}3{}",
            [2] = "adds a retrigger to",
            [3] = "all other played cards",
        }
    },

    pos = { x = 1, y = 0 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            local this_rank = context.other_card:get_id()
            if not (this_rank == 2 or this_rank == 3) then
                
                local retriggers = 0
                for i=1, #context.scoring_hand do
                    local rank = context.scoring_hand[i]:get_id()
                    if not context.scoring_hand[i].debuff and (rank == 2 or rank == 3) then
                        retriggers = retriggers + 1
                    end
                end

                if retriggers > 0 then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = retriggers,
                        card = card
                    }
                end
            end
        end
    end,
}



SMODS.Joker{ -- AFOL
    key = "afol",

    name = "AFOL",
    loc_txt = {
        name = "AFOL",
        text = {
            [1] = "{X:mult,C:white} X#1# {} Mult if played hand",
            [2] = "has a scoring {C:attention}face{} card",
            [3] = "and a scoring {C:attention}non-face{} card",
        }
    },

    config = {
        extra = {
            Xmult = 2,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult }}
    end,

    pos = { x = 3, y = 0 }, atlas = "jokers",

    cost = 7, rarity = 1,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.joker_main then

            local has_face = false
            local has_non_face = false
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:is_face() then 
                    has_face = true
                    if has_not_face then break end
                else 
                    has_non_face = true 
                    if has_face then break end
                end
            end

            if has_face and has_non_face then
                return { xmult = card.ability.extra.Xmult }
            end
        end
    end,
}



SMODS.Joker{ -- Licensed Joker
    key = "licensed_joker",

    name = "Licensed Joker",
    loc_txt = {
        name = "Licensed Joker",
        text = {
            [1] = "Earn {C:money}$#1#{} when a {C:attention}face{}",
            [2] = "card is drawn to hand",
            [3] = "Lose {C:money}$#2#{} when a {C:attention}face{} card",
            [4] = "is played or discarded"
        }
    },

    config = {
        extra = {
            dollars_gained = 1,
            dollars_lost = 1,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.dollars_gained, card.ability.extra.dollars_lost }}
    end,

    pos = { x = 2, y = 0 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,

    calculate = function(self, card, context)
        if context.hand_drawn then
            for _, _card in ipairs(context.hand_drawn) do
                if _card:is_face() then
                    G.E_MANAGER:add_event(Event({func = (function() 
                        juice_card(card)
                        ease_dollars(card.ability.extra.dollars_gained)
                        card_eval_status_text(_card, 'dollars', card.ability.extra.dollars_gained)
                    return true end)}))
                end
            end
            return
        end


        local on_face_used = function(face_card)
            G.E_MANAGER:add_event(Event{ trigger = 'immediate', func = function()
                card:juice_up(0.7)
                return true
            end})

            ease_dollars(-card.ability.extra.dollars_lost)
            card_eval_status_text(face_card, 'dollars', -card.ability.extra.dollars_lost)
        end
        
        -- Discarded cards
        if context.discard then
            if context.other_card:is_face() then on_face_used(context.other_card) end

        -- Played cards
        elseif context.before then
            for _, _card in ipairs(context.full_hand) do
                local is_scoring = false
                for _, _scoring_card in ipairs(context.scoring_hand) do
                    if card == _scoring_card then is_scoring = true; break end
                end

                if not is_scoring and _card:is_face() then on_face_used(_card) end
            end
        end
    end,
}



SMODS.Joker{ -- NPU
    key = "nice_part_usage",

    name = "Nice Part Usage",
    loc_txt = {
        name = "Nice Part Usage",
        text = {
            [1] = "When scored, each",
            [2] = "card gives {C:mult}+#1#{} Mult",
            [3] = "per round since its",
            [4] = "{C:attention}rank{} was last scored"
        }
    },

    config = {
        extra = {
            mult_per = 1,
        }
    },

    loc_vars = function(self, info_queue, card)
        local main_end
        if G.jokers and G.jokers.cards and G.localization.descriptions.Other.amaryllis_lego_max_npu 
           and G.GAME.amaryllis_rank_last_scored
        then
            local ranks_in_deck = {}
            -- Iterate cards in deck for unique ranks
            for _, playing_card in ipairs(G.playing_cards) do
                if not SMODS.has_no_rank(playing_card) then
                    local _rank = playing_card:get_id()
                    ranks_in_deck[_rank] = playing_card.base.value
                end
            end

            local best_rank = nil
            local since_played = 0

            local effective_round = G.GAME.round
            if not (G.GAME.blind and G.GAME.blind.in_blind) then effective_round = effective_round + 1 end

            -- Iterate ranks in deck to find the highest value rank which has scored the longest time ago
            for _rank, _ in pairs(ranks_in_deck) do
                local _since_played = effective_round - (G.GAME.amaryllis_rank_last_scored[_rank] or 1)
                if _since_played > since_played then
                    best_rank = _rank
                    since_played = _since_played
                
                elseif _since_played == since_played and _rank > (best_rank or 0) then
                    best_rank = _rank
                end
            end

            if best_rank and since_played > 0 then
                main_end = {}
                localize{type = "other", key = "amaryllis_lego_max_npu", nodes = main_end, vars = { 
                    localize(ranks_in_deck[best_rank], 'ranks'), card.ability.extra.mult_per * since_played 
                }}
                main_end = main_end[1]
            end
        end
        return { main_end = main_end, vars = { card.ability.extra.mult_per }}
    end,

    pos = { x = 4, y = 0 }, atlas = "jokers",

    cost = 5, rarity = 1,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and G.GAME.amaryllis_rank_last_scored and G.GAME.round > 1 then
            if SMODS.has_no_rank(context.other_card) or context.other_card.debuff then return end
            local rank = context.other_card:get_id()
            local since_played = G.GAME.round - (G.GAME.amaryllis_rank_last_scored[rank] or 1)
            if since_played > 0 then
                return { mult = card.ability.extra.mult_per * since_played, card = card }
            end
        end
    end,
}



SMODS.Joker{ -- Sticker Sheet
    key = "sticker_sheet",

    name = "Sticker Sheet",
    loc_txt = {
        name = "Sticker Sheet",
        text = {
            [1] = "Sell this card to",
            [2] = "create a {C:red}Rare{} {C:attention}Joker{}",
            [3] = "with a random {C:attention}Sticker{}",
            [4] = "{C:inactive}(Must have room)",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = { key = 'eternal', set = 'Other' }
        info_queue[#info_queue + 1] = { key = 'perishable', set = 'Other', vars = { G.GAME.perishable_rounds or 1, G.GAME.perishable_rounds or 1 } }
        info_queue[#info_queue + 1] = { key = 'rental', set = 'Other', vars = { G.GAME.rental_rate or 1 } }
    end,

    pos = { x = 0, y = 1 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,


    calculate = function(self, card, context)
        if context.selling_self then
            if #G.jokers.cards > G.jokers.config.card_limit then
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_no_room_ex')})
                return
            end

            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, { message = localize('k_plus_joker'), colour = G.C.RED })
            
            local new_card = create_card('Joker', G.jokers, nil, 1, nil, nil, nil, 'sticker') -- rare threshold = 0.95
            
            -- Add sticker
            local sticker_chance = pseudorandom('sticker_poll')
            if sticker_chance < 0.3333 and new_card.config.center.eternal_compat then
                new_card:set_eternal(true)
            elseif sticker_chance < 0.6666 and new_card.config.center.perishable_compat then
                new_card:set_perishable(true)
            else
                new_card:set_rental(true)
            end
            
            new_card:add_to_deck()
            G.jokers:emplace(new_card)
        end
    end,
}



SMODS.Joker{ -- UCS Joker
    key = "ultimate_collectors_joker",

    name = "Ultimate Collector's Joker",
    loc_txt = {
        name = "Ultimate Collector's Joker",
        text = {
            [1] = "This Joker gains {C:chips}+#1#{} Chips",
            [2] = "each time you obtain a",
            [3] = "{C:red}Rare{} or {C:green}Uncommon{} Joker",
            [4] ="{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        }
    },

    config = {
        extra = {
            chips = 0,
            chips_gain = 18,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.chips_gain, card.ability.extra.chips }}
    end,

    pos = { x = 1, y = 1 }, atlas = "jokers",

    cost = 6, rarity = 1,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.card_added and context.card.ability.set == 'Joker' and not context.blueprint
            and not context.card:is_rarity("Common")
        then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chips_gain
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                card = card
            }
        
        elseif context.joker_main and context.cardarea == G.jokers then
            return {
                chips = card.ability.extra.chips,
                card = card
            }
        end
    end,
}



-- My Own Creation
assert(SMODS.load_file("src/my_own_creation.lua"))()



SMODS.Joker{ -- Illegal Technique
    key = "illegal_technique",

    name = "Illegal Technique",
    loc_txt = {
        name = "Illegal Technique",
        text = {
            [1] = "{C:green}#1# in #2#{} cards are",
            [2] = "temporarily {C:red}debuffed{} each round",
            [3] = "All debuffed cards in scoring",
            [4] = "hand gain a random {C:attention}Enhancement{}",
        }
    },

    config = {
        extra = {
            chance = 7,
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.chance }}
    end,

    pos = { x = 3, y = 1 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.setting_blind then
            local debuff_key = mod.prefix .. '_illegal_technique'
            for _, playing_card in ipairs(G.playing_cards) do
                if not playing_card.debuff and pseudorandom(debuff_key) < G.GAME.probabilities.normal / card.ability.extra.chance then
                    SMODS.debuff_card(playing_card, true, debuff_key)
                end
            end

        elseif context.end_of_round and context.main_eval and not context.blueprint then
            local debuff_key = mod.prefix .. '_illegal_technique'
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card.ability.debuff_sources and playing_card.ability.debuff_sources[debuff_key] then
                    SMODS.debuff_card(playing_card, false, debuff_key)
                end
            end

        elseif context.before and context.cardarea == G.jokers and not context.blueprint then
            local debuffed = {}
            for _, _card in ipairs(context.scoring_hand) do
                if _card.debuff then
                    debuffed[#debuffed+1] = _card
                    
                    G.E_MANAGER:add_event(Event({func = function()
                        local enhancement = SMODS.poll_enhancement{ key = (mod.prefix .. '_illegal_technique_enhancement'), guaranteed = true }
                        _card:set_ability(enhancement)
                        _card.debuff = true

                        _card:juice_up()
                        return true
                    end}))
                end
            end
            if #debuffed > 0 then
                return {
                    message = localize('k_' .. mod.prefix .. '_illegal'),
                    colour = HEX("D4FC5A"),
                    card = card 
                }
            end
        end
    end,
}



SMODS.Joker{ -- Convention Badge
    key = "convention_badge",

    name = "Convention Badge",
    loc_txt = {
        name = "Convention Badge",
        text = {
            [1] = "This Joker gains {X:mult,C:white} X#1# {} Mult when",
            [2] = "an unplayed {C:attention}poker hand{} is played",
            [3] = "Only gives Mult when",
            [4] = "{C:attention}#3#{} is played",
            [5] ="{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        }
    },

    config = {
        extra = {
            Xmult = 1,
            Xmult_gain = 0.5,
            last_seen_hand = nil
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult_gain, card.ability.extra.Xmult,
                card.ability.extra.last_seen_hand
                    and localize(card.ability.extra.last_seen_hand, 'poker_hands')
                    or localize('k_amaryllis_lego_last_unique_poker_hand')
        }}
    end,

    pos = { x = 4, y = 1 }, atlas = "jokers",
    pixel_size = { w = 71, h = 83 },

    cost = 7, rarity = 3,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.before and context.cardarea == G.jokers and not context.blueprint then
            -- Called after the current scoring hand has incremented the count => 1 instead of 0
            local has_seen_hand = (G.GAME.hands[context.scoring_name].played or 0) > 1
            
            if not has_seen_hand then
                card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain 
                card.ability.extra.last_seen_hand = context.scoring_name
                
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {
                    message = localize('k_' .. mod.prefix .. '_fresh_poker_hand')
                })
            end

        elseif context.joker_main and context.cardarea == G.jokers and card.ability.extra.last_seen_hand then
            if context.scoring_name == card.ability.extra.last_seen_hand then
                return {
                    xmult = card.ability.extra.Xmult,
                    card = card 
                }
            else
                return { 
                    message = localize('k_' .. mod.prefix .. '_stale_poker_hand'), 
                    card = card 
                }
            end
        end
    end,
}



SMODS.Joker{ -- Frog
    key = "frog",

    name = "Frog",
    loc_txt = {
        name = "Frog",
        text = {
            [1] = "{X:mult,C:white} X#1# {} Mult",
            [2] = "{C:red}Must play a{} {C:attention}#2#{}",
        }
    },

    config = {
        extra = {
            Xmult = 4,
            rank = 4,
            variants = 6
        }
    },

    loc_vars = function(self, info_queue, card)
        return {vars = { card.ability.extra.Xmult, card.ability.extra.rank }}
    end,

    pos = { x = 0, y = 2 }, atlas = "jokers",

    cost = 8, rarity = 3,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,


    set_ability = function(self, card, initial, delay_sprites)
        if not card.ability.extra.variant and G.playing_cards then
            card.ability.extra.variant = pseudorandom('amaryllis_frog', 0, card.ability.extra.variants - 1)
            self:set_sprites(card)
        end
    end,

    set_sprites = function(self, card, front)
        if card.ability and card.ability.extra.variant then
            local sprite_pos = { x = 0, y = 2 + card.ability.extra.variant }
            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,


    calculate = function(self, card, context)
        if (context.debuff_hand and not context.blueprint) or 
           (context.joker_main and context.cardarea == G.jokers)
        then
            local has_rank = false
            for _, _card in ipairs(context.full_hand) do
                if _card:get_id() == card.ability.extra.rank then
                    has_rank = true
                    break
                end
            end

            if context.debuff_hand then
                if not has_rank then 
                    if not context.check then
                        card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {
                            message = localize('k_' .. mod.prefix .. '_frog'), colour = G.C.PURPLE, instant = true, delay = 1.5 })
                    end
                    return {
                        debuff = true,
                        debuff_text = localize('k_' .. mod.prefix .. '_no_frog'),
                        debuff_source = card
                    }
                end
                return
            end

            if has_rank then return { xmult = card.ability.extra.Xmult } end
        end
    end,
}



SMODS.Joker{ -- SNOT Brick
    key = "snot_brick",

    name = "SNOT Brick",
    loc_txt = {
        name = "SNOT Brick",
        text = {
            [1] = "All {C:attention}9s{} are considered {C:attention}6s{}",
            [2] = "All {C:attention}5s{} are considered {C:attention}2s{}"
        }
    },

    config = {
        extra = {
            variants = 3
        }
    },

    pos = { x = 1, y = 2 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    set_ability = function(self, card, initial, delay_sprites)
        if not card.ability.extra.variant and G.playing_cards then
            card.ability.extra.variant = pseudorandom('amaryllis_snot_brick', 0, card.ability.extra.variants - 1)
            self:set_sprites(card)
        end
    end,

    set_sprites = function(self, card, front)
        if card.ability and card.ability.extra.variant then
            local sprite_pos = { x = 1, y = 2 + card.ability.extra.variant }
            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,
}



SMODS.Joker{ -- BURP
    key = "big_ugly_rock_piece",

    name = "Big Ugly Rock Piece",
    loc_txt = {
        name = "Big Ugly Rock Piece",
        text = {
            [1] = "Adds one {C:attention}Stone{} Card",
            [2] = "into drawn cards",
            [3] = "At end of round, destroy",
            [4] = "all {C:attention}Stone{} Cards in deck"
        }
    },

    config = {
        extra = {
            variants = 3,
        }
    },

    pos = { x = 2, y = 2 }, atlas = "jokers",

    cost = 6, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    set_ability = function(self, card, initial, delay_sprites)
        if not card.ability.extra.variant and G.playing_cards then
            card.ability.extra.variant = pseudorandom('amaryllis_big_ugly_rock_piece', 0, card.ability.extra.variants - 1)
            self:set_sprites(card)
        end
    end,

    set_sprites = function(self, card, front)
        if card.ability and card.ability.extra.variant then
            local sprite_pos = { x = 2, y = 2 + card.ability.extra.variant }
            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,


    calculate = function(self, card, context)
        if context.drawing_cards and G.GAME.facing_blind and context.amount > 1 then
            -- Add 1 Stone Card to draw
            G.playing_card = (G.playing_card and G.playing_card + 1) or 1

            local front = pseudorandom_element(G.P_CARDS, pseudoseed('amaryllis_lego_burp'))
            local _card = Card(G.play.T.x + G.play.T.w/2, G.play.T.y, G.CARD_W, G.CARD_H, front, G.P_CENTERS.m_stone, {playing_card = G.playing_card})
            _card:add_to_deck()
            G.deck.config.card_limit = G.deck.config.card_limit + 1
            table.insert(G.playing_cards, _card)
            G.hand:emplace(_card)

            play_sound('tarot2')
            card:juice_up(0.3, 0.5)

            playing_card_joker_effects({_card})

            -- Reduce draw size by 1 so the added Stone Card effectively replaces one of them
            return { cards_to_draw = context.amount - 1 }
            
        elseif context.round_eval and not context.blueprint then
            -- Destroy all Stone Cards in deck
            local destroyed_cards = {}
            for _, playing_card in ipairs(G.deck.cards) do
                if playing_card.playing_card and SMODS.has_enhancement(playing_card, 'm_stone') then
                    destroyed_cards[#destroyed_cards + 1] = playing_card
                end
            end

            if #destroyed_cards > 0 then
                card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {
                    message = localize('k_' .. mod.prefix .. '_burp_gone'), colour = G.C.SECONDARY_SET.Enhanced})

                SMODS.destroy_cards(destroyed_cards)
            end
        end
    end,
}



SMODS.Joker{ -- Cheese Slope
    key = "cheese_slope",

    name = "Cheese Slope",
    loc_txt = {
        name = "Cheese Slope",
        text = {
            [1] = "Earn {C:money}$#1#{} at end of round,",
            [2] = "reduces by {C:money}$#2#{} for each",
            [3] = "other {C:attention}Joker{} you have",
            [4] ="{C:inactive}(Currently {C:money}$#3#{C:inactive})",
        }
    },

    config = {
        extra = {
            starting_dollars = 12,
            dollars_lost = 3,
            consumed_at = 5, -- Just for reference in in_pool check
        }
    },

    loc_vars = function(self, info_queue, card)
        local key = self.key
        local value = self:get_cheese_slope_value(card)
        if value <= 0 then key = key .. '_unobtainable' end
        return { key = key, vars = { card.ability.extra.starting_dollars, card.ability.extra.dollars_lost, value }}
    end,

    pos = { x = 3, y = 2 }, atlas = "jokers",

    cost = 4, rarity = 2,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,


    get_cheese_slope_value = function(self, card)
        local joker_count = (G.jokers and #G.jokers.cards) or 0
        if card and card.area and card.area == G.jokers then joker_count = joker_count - 1 end
        return card.ability.extra.starting_dollars - joker_count * card.ability.extra.dollars_lost
    end,

    calculate = function(self, card, context)
        if context.blueprint then return end

        if context.card_added then
            -- Delay so #G.joker.cards returns the new value
            G.E_MANAGER:add_event(Event{func = function()
                if self:get_cheese_slope_value(card) <= 0 then
                    SMODS.destroy_cards(card, nil, nil, true)
                    
                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                        message = localize('k_' .. mod.prefix .. '_cheese_gone'),
                        colour = G.C.GOLD
                    })
                end
                return true
            end})

        elseif context.end_of_round and context.main_eval then
            if self:get_cheese_slope_value(card) <= 0 then
                SMODS.destroy_cards(card, nil, nil, true)

                return {
                    message = localize('k_' .. mod.prefix .. '_cheese_gone'),
                    colour = G.C.GOLD
                }
            end
        end
    end,

    calc_dollar_bonus = function(self, card)
        return self:get_cheese_slope_value(card)
    end,

    in_pool = function(self, args)
        -- Prevent Cheese Slope from showing up if we have 4+ Jokers, 
        -- and picking it up would immediately cause it to be consumed
        local joker_count = (G.jokers and #G.jokers.cards) or 0
        return joker_count + 1 < self.config.extra.consumed_at
    end,
}




SMODS.Joker{ -- Brick Separator
    key = "brick_separator",

    name = "Brick Separator",
    loc_txt = {
        name = "Brick Separator",
        text = {
            [1] = "If {C:attention}first hand{} of round has",
            [2] = "only {C:attention}1{} card, split it into",
            [3] = "{C:attention}2{} cards with {C:attention}half{} its rank"
        }
    },

    config = {
        extra = {
            variants = 3
        }
    },

    pos = { x = 4, y = 2 }, atlas = "jokers",

    cost = 8, rarity = 2,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    set_ability = function(self, card, initial, delay_sprites)
        if not card.ability.extra.variant and G.playing_cards then
            card.ability.extra.variant = pseudorandom('amaryllis_brick_separator', 0, card.ability.extra.variants - 1)
            self:set_sprites(card)
        end
    end,

    set_sprites = function(self, card, front)
        if card.ability and card.ability.extra.variant then
            local sprite_pos = { x = 4, y = 2 + card.ability.extra.variant }
            if sprite_pos ~= card.children.center.sprite_pos then
                card.children.center:set_sprite_pos(sprite_pos)
            end
        end
    end,


    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            local eval = function() return G.GAME.current_round.hands_played == 0 end
            juice_card_until(card, eval, true)
        
        elseif context.destroying_card and not context.blueprint and
            G.GAME.current_round.hands_played == 0 and #context.full_hand == 1
            and not context.full_hand[1].split_by_brick_separator
        then
            local ranks_by_nominal = { 'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Ace' }
            local half_value = math.floor(context.full_hand[1].base.nominal / 2)
            if half_value < 1 then half_value = 1 end
            if half_value > 11 then half_value = 11 end
            local new_rank = ranks_by_nominal[half_value]

            G.E_MANAGER:add_event(Event({func = function()
                for i = 1, 2 do
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(context.full_hand[1], nil, nil, G.playing_card)
                    SMODS.change_base(_card, nil, new_rank)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    _card.states.visible = nil
                     _card:start_materialize()
                end
                return true
            end }))

            context.full_hand[1].split_by_brick_separator = true

            card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {
                message = localize('k_amaryllis_lego_split'), colour = G.C.CHIPS
            })
            return true
        end
    end,
}



-- Rainbow Deck
SMODS.Back{
    key = "rainbow",

    name = "Rainbow Deck",
    loc_txt = {      
        name = "Rainbow Deck",      
        text = {
            "Start run with",
            "an additional {C:attention}13{}",
            "{C:spades}Wi{C:hearts}ld{} {C:clubs}Car{C:diamonds}ds{} in deck",
        }
    },

    pos = { x = 0, y = 0 },
    unlocked = true, atlas = "decks",

    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                local suits = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }
                local ranks = { 'Ace', 'King', 'Queen', 'Jack', '10', '9', '8', '7', '6', '5', '4', '3', '2' }

                local suit = pseudorandom_element(suits, pseudoseed('rainbow_wild_suit'))
                for _, rank in ipairs(ranks) do
                    SMODS.add_card { set = "Base", rank = rank, suit = suit, enhancement = "m_wild", area = G.deck }
                end
                return true
            end
        }))
    end,
}