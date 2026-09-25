local mod = SMODS.current_mod

local vanilla_hands = { 'Flush Five', 'Flush House', 'Five of a Kind', 'Straight Flush', 'Four of a Kind', 'Full House', 'Flush', 'Straight', 'Three of a Kind', 'Two Pair', 'Pair', 'High Card' }
local max_ranks = {
    ['Flush Five'] = 1,
    ['Flush House'] = 2,
    ['Five of a Kind'] = 1,
    ['Straight Flush'] = 5,
    ['Four of a Kind'] = 1,
    ['Full House'] = 2,
    ['Flush'] = 5,
    ['Straight'] = 5,
    ['Three of a Kind'] = 1,
    ['Two Pair'] = 2,
    ['Pair'] = 1,
    ['High Card'] = 1,
}
local sort_ranks = {
    ['Ace'] = 14,
    ['King'] = 13,
    ['Queen'] = 12,
    ['Jack'] = 11,
    ['10'] = 10,
    ['9'] = 9,
    ['8'] = 8,
    ['7'] = 7,
    ['6'] = 6,
    ['5'] = 5,
    ['4'] = 4,
    ['3'] = 3,
    ['2'] = 2,
}

local ignore_moc_hand = false
function calculate_moc_hand(hand, preview_only)
    -- Calculate base hand
    ignore_moc_hand = true
    local base_poker_hands = evaluate_poker_hand(hand)
    ignore_moc_hand = false

    local base_hand
    local scoring_hand = {}

    for i = 1, #vanilla_hands do
        if next(base_poker_hands[vanilla_hands[i]]) then
            base_hand = vanilla_hands[i]
            scoring_hand = base_poker_hands[vanilla_hands[i]][1]
            break
        end
    end
    if not base_hand then return end

    local incompat = get_moc_incompatibility(base_hand, scoring_hand)
    if incompat then return { incompatible = incompat } end

    local ranks = nil
    local ranks_count = 0
    local ignore_ranks = (base_hand == 'Flush')
    if not ignore_ranks then
        ranks = {}
        for _, playing_card in ipairs(scoring_hand) do
            if not SMODS.has_no_rank(playing_card) then
                local rank = playing_card.base.value
                if not ranks[rank] then ranks_count = ranks_count + 1 end
                ranks[rank] = (ranks[rank] or 0) + 1
            end
        end
        if not next(ranks) then return end

        -- Filter ranks to max expected number for its hand type, to account for Splash effects adding nonsense cards to scoring_hand
        local max_ranks_count = max_ranks[base_hand]
        while ranks_count > (max_ranks_count or 5) do
            -- Find the rank with the lowest amount and lowest sort value
            local worst_rank = nil
            local worst_rank_count = 1000000
            local worst_rank_sort = 1000000
            for rank, count in pairs(ranks) do
                local sort = (sort_ranks[rank] or 0)
                if count < worst_rank_count or (count == worst_rank_count and sort < worst_rank_sort) then
                    worst_rank = rank
                    worst_rank_count = count
                    worst_rank_sort = sort
                end
            end
            if worst_rank then
                ranks[worst_rank] = nil
                ranks_count = ranks_count - 1
            else break end
        end
    end

    local suit = nil
    if #scoring_hand > 1 then
        local all_wild = true
        for _, playing_card in ipairs(scoring_hand) do
            if not SMODS.has_any_suit(playing_card) then
                all_wild = false
                if not SMODS.has_no_suit(playing_card) then
                    -- Initialize flush suit to first suit found
                    if not suit then
                        suit = playing_card.base.suit
                    -- If multiple suits, cancel the flush
                    elseif suit ~= playing_card.base.suit then
                        suit = nil
                        break
                    end
                end
            end
        end
        if all_wild then suit = 'Hearts' end
    end

    -- Update Poker Hand base/Planet chips/mult values
    -- Base amounts + 3 base level-ups
    G.GAME.hands[mod.prefix .. '_moc'].mult = G.GAME.hands[base_hand].mult + 3 * G.GAME.hands[base_hand].l_mult
    G.GAME.hands[mod.prefix .. '_moc'].chips = G.GAME.hands[base_hand].chips + 3 * G.GAME.hands[base_hand].l_chips
    -- 2x level-up amount
    G.GAME.hands[mod.prefix .. '_moc'].l_mult = G.GAME.hands[base_hand].l_mult * 2
    G.GAME.hands[mod.prefix .. '_moc'].l_chips = G.GAME.hands[base_hand].l_chips * 2

    -- Update example hand
    if not preview_only then
        local example = {}
        for i = 1, 5 do
            if i <= #hand then
                -- Set to played hand
                local card_name = hand[i].base.name
                local card_key = nil
                for key, _card in pairs(G.P_CARDS) do
                    if card_name == _card.name then card_key = key; break end
                end
                if card_key then
                    local is_scoring = false
                    for _, scoring_card in ipairs(scoring_hand) do
                        if hand[i] == scoring_card then is_scoring = true; break end
                        end
                    example[#example + 1] = { card_key, is_scoring }
                end
            else
                -- Fill with filler
                example[#example + 1] = G.GAME.hands['High Card'].example[i]
            end
        end
        G.GAME.hands[mod.prefix .. '_moc'].example = example
    end

    return {
        base = base_hand,
        ranks = ranks,
        suit = suit
    }
end

function get_moc_incompatibility(base_hand, played_hand)
    if base_hand:sub(1, 8) == 'Straight' then
        if #played_hand < 5 then return 'incompatible_four_fingers' end

        -- Check if it's a continuous straight
        local ranks = {}
        for _, _card in ipairs(played_hand) do
            if not SMODS.has_no_rank(_card) then ranks[#ranks + 1] = _card:get_id() end
        end
        if #ranks < 5 then return 'incompatible_four_fingers' end
        table.sort(ranks)

        -- Exempt special Wheel straight where Ace acts as a 1
        local is_wheel = (ranks[1] == 2 and ranks[2] == 3 and ranks[3] == 4 and ranks[4] == 5 and ranks[5] == 14)
        
        if not is_wheel then
            for i = 1, #ranks - 1 do
                if ranks[i + 1] - ranks[i] > 1 then return 'incompatible_shortcut' end
            end
        end
    
    elseif base_hand:sub(1, 5) == 'Flush' then
        if #played_hand < 5 then return 'incompatible_four_fingers' end
    end
end

function localize_moc_hand(poker_hand, force_plain)
    if not poker_hand or poker_hand.incompatible then return end

    local localize_hand = function(key, vars)
        return localize({type = 'variable', key = mod.prefix .. '_' .. key, vars = vars})
    end

    local suit, suit_adj
    if poker_hand.suit then 
        suit = localize(poker_hand.suit, 'suits_plural')
        suit_adj = localize(mod.prefix .. '_suits_adj_' .. poker_hand.suit) 
    end

    local name -- Now only used for special hand names like Broadway, Wheel
    if poker_hand.ranks then
        local indexed_ranks = {}
        for rank, _ in pairs(poker_hand.ranks) do
            indexed_ranks[#indexed_ranks + 1] = rank
        end

        local has = function(rank, count) return (poker_hand.ranks[rank] or 0) >= (count or 1) end
        local exactly = function(rank, count) return (poker_hand.ranks[rank] or 0) == (count or 1) end
        local straight = function(rank1, rank2, rank3, rank4, rank5) return poker_hand.ranks[rank1] and poker_hand.ranks[rank2] and poker_hand.ranks[rank3] and poker_hand.ranks[rank4] and poker_hand.ranks[rank5] end
       
        -- Special hand nicknames
        if not force_plain then
            if (has('Ace', 2) and has('8', 2)) or (has('Jack', 2) and (has('10', 2) or has('7', 2))) then
                if suit then return localize_hand('dead_mans_flush', { suit }) end
                return localize_hand('dead_mans_hand')
            
            elseif (has('9', 2) and has('5', 2)) or straight('9', '8', '7', '6', '5') then
                name = localize_hand('dolly')
            
            elseif #indexed_ranks == 1 and (exactly('Ace', 3) or exactly('Ace', 4)) then
                name = localize_hand('muskateers')
            
            elseif #indexed_ranks == 1 and exactly('King', 4) then
                name = localize_hand('horsemen')
            
            elseif #indexed_ranks == 1 and has('3', 3) then
                name = localize_hand('forest')
            
            elseif #indexed_ranks == 1 and has('7', 3) then
                name = localize_hand('jackpot')
            
            elseif exactly('6', 3) then
                if suit then return localize_hand('devils_flush', { suit }) end
                return localize_hand('devils_hand')
            
            elseif straight('Ace', 'King', 'Queen', 'Jack', '10') then
                name = localize_hand(poker_hand.suit and 'royale' or 'broadway')
            
            elseif straight('Ace', '2', '3', '4', '5') then
                name = localize_hand('wheel')
            end
        end

        if not name then
            if poker_hand.base == 'Two Pair' and #indexed_ranks >= 2 then
                -- Two Pair
                local rank_1 = localize(indexed_ranks[1], 'ranks')
                local rank_2 = localize(indexed_ranks[2], 'ranks')
                if suit then return localize_hand('flush_two_pair', { rank_1, rank_2, suit_adj })
                else return localize_hand('two_pair', { rank_1, rank_2 }) end
            
            elseif poker_hand.base:sub(-5) == 'House' and #indexed_ranks >= 2 then
                -- Full House
                local rank_1 = localize(indexed_ranks[1], 'ranks')
                local rank_2 = localize(indexed_ranks[2], 'ranks')
                if suit then return localize_hand('flush_house', { rank_1, rank_2, suit_adj })
                else return localize_hand('full_house', { rank_1, rank_2 }) end
            
            elseif poker_hand.base:sub(1, 8) == 'Straight' and #indexed_ranks >= 5 then
                -- Straight
                local lowest_rank = nil; local lowest_rank_value = 1000000
                local highest_rank = nil; local highest_rank_value = -1000000
                for _, rank in ipairs(indexed_ranks) do
                    local value = sort_ranks[rank]
                    if rank == 'Ace' and indexed_ranks['2'] then value = 1 end
                    if value < lowest_rank_value then
                        lowest_rank = rank
                        lowest_rank_value = value
                    end
                    if value > highest_rank_value then
                        highest_rank = rank
                        highest_rank_value = value
                    end
                end

                local ascending_order = highest_rank_value <= 10 and not (highest_rank == '9' and lowest_rank == '5')
                if highest_rank == 'Ace' and lowest_rank == '2' then lowest_rank = '5' end -- Handle special Wheel straight where Ace acts as a 1
                local rank_1 = ascending_order and localize(lowest_rank, 'ranks') or localize(highest_rank, 'ranks')
                local rank_2 = ascending_order and localize(highest_rank, 'ranks') or localize(lowest_rank, 'ranks')
                if suit then return localize_hand('straight_flush', { rank_1, rank_2, suit })
                else return localize_hand('straight', { rank_1, rank_2 }) end
            
            elseif #indexed_ranks == 1 then
                -- 2-5 OAKs
                local count = poker_hand.ranks[indexed_ranks[1]]
                for n = 5, 2, -1 do
                    if count >= n then
                        if suit then return localize_hand('flush_' .. n, { localize(indexed_ranks[1], 'ranks'), suit_adj }) end
                        if force_plain then return localize_hand('oak_' .. n, { localize(indexed_ranks[1], 'ranks') }) end
                        return localize_hand('special_oak_' .. n, { localize_hand('' .. indexed_ranks[1]) })
                    end
                end

                -- High Card
                return localize_hand('high', { localize(indexed_ranks[1], 'ranks') })
            end
        end
    end

    -- Apply suit modifier e.g. 'Clubs Straight', 'Clubs Twice 10s and 2s'
    if suit then
        if name then return localize_hand('flush_generic', { suit, name }) end
        
        -- Pure Flush
        return localize_hand('flush', { suit })
    end

    if name then return name end
    return 'ERROR'
end

function localize_moc_hand_description(poker_hand)
    local plain_hand_name = localize_moc_hand(poker_hand, true)
    if not plain_hand_name then return G.localization.misc.poker_hand_descriptions['amaryllis_lego_moc'] or 'ERROR' end
    
    local fancy_hand_name = localize_moc_hand(poker_hand)
    local line1 = localize{type = "variable", key = mod.prefix .. "_moc_desc_1", vars = { fancy_hand_name }} or 'ERROR'
    if fancy_hand_name == plain_hand_name then return { line1 } end

    local line2 = localize{type = "variable", key = mod.prefix .. "_moc_desc_2", vars = { plain_hand_name }} or 'ERROR'
    return { line1, line2 }
end

SMODS.Joker{ -- MOC
    key = "my_own_creation",

    name = "My Own Creation",
    loc_txt = {
        name = "My Own Creation",
        text = {
            [1] = "The next valid scoring hand",
            [2] = "becomes a {C:attention}new poker hand{}",
            [3] = "with its own {C:planet}Planet{} card"
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS['c_' .. mod.prefix .. '_makemake']

        local key = self.key
        local vars = {}
        local main_end
        if G.jokers and G.jokers.cards then
            -- Give feedback when creating the hand
            if G.hand.highlighted and #G.hand.highlighted > 0 
               and not G.GAME.amaryllis_lego_moc_hand and G.localization.descriptions.Other.amaryllis_lego_creating_moc
            then
                main_end = {}

                local poker_hand = calculate_moc_hand(G.hand.highlighted, true)

                -- Display incompatibilities
                if not poker_hand then
                    localize{type = "other", key = mod.prefix .. "_invalid_moc", nodes = main_end}
                
                elseif poker_hand.incompatible then
                    localize{type = "other", key = mod.prefix .. '_moc_' .. poker_hand.incompatible, nodes = main_end}

                else
                    -- Display hand for selected cards
                        local plain_hand_name = localize_moc_hand(poker_hand, true)
                        if not plain_hand_name then
                            localize{type = "other", key = mod.prefix .. "_invalid_moc", nodes = main_end}
                        else
                            local fancy_hand_name = localize_moc_hand(poker_hand)
                            if fancy_hand_name ~= plain_hand_name then
                                localize{type = "other", key = mod.prefix .. "_creating_moc_aka", nodes = main_end, vars = { fancy_hand_name, plain_hand_name }}
                            else
                                localize{type = "other", key = mod.prefix .. "_creating_moc", nodes = main_end, vars = { plain_hand_name }}
                            end
                        end
                end
                main_end = main_end[1]
            
            -- Add reminder of what hand was created
            elseif G.GAME.amaryllis_lego_moc_hand then
                main_end = {}

                local fancy_hand_name = localize_moc_hand(G.GAME.amaryllis_lego_moc_hand)
                local plain_hand_name = localize_moc_hand(G.GAME.amaryllis_lego_moc_hand, true)

                if fancy_hand_name ~= plain_hand_name then
                    localize{type = "other", key = mod.prefix .. "_moc_hand_aka", nodes = main_end, vars = { fancy_hand_name, plain_hand_name }}
                else
                    localize{type = "other", key = mod.prefix .. "_moc_hand", nodes = main_end, vars = { plain_hand_name }}
                end
                
                main_end = main_end[1]

                -- Change the Joker's description to reflect that the hand has already been created
                key = key .. '_set'
                vars[#vars + 1] = localize{type = 'name_text', set = 'Planet', key = 'c_' .. mod.prefix .. '_makemake'}
            end
        end
        return { key = key, main_end = main_end, vars = vars }
    end,

    pos = { x = 2, y = 1 }, atlas = "jokers",

    cost = 7, rarity = 3,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,


    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            local eval = function() return G.GAME.amaryllis_lego_moc_hand == nil end
            juice_card_until(card, eval, true)

        elseif context.press_play and not context.blueprint and not G.GAME.amaryllis_lego_moc_hand then
            -- Create poker hand from scored hand
            local poker_hand = calculate_moc_hand(G.hand.highlighted)
            if poker_hand and not poker_hand.incompatible then G.GAME.amaryllis_lego_moc_hand = poker_hand end
        end
    end,
}

local am_test = 0

-- MOC hand
SMODS.PokerHand{
    key = "moc",

    visible = false,
    above_hand = "Flush Five",
    order_offset = 1, -- fixes some issue with not actually ordering above a Flush Five, potentially float precision?

    example = {}, -- necessary for validation even though we don't use it

    mult = 0,
    chips = 0,

    l_mult = 0,
    l_chips = 0,

    evaluate = function(parts, hand)
        if ignore_moc_hand == true then return {} end

        -- If ready to create hand, consider all selected hands a valid MOC hand so that it displays a preview
        if not G.GAME.amaryllis_lego_moc_hand then
            if G.hand.highlighted and #G.hand.highlighted > 0 and
               next(SMODS.find_card('j_' .. mod.prefix .. '_my_own_creation')) 
            then
                local poker_hand = calculate_moc_hand(G.hand.highlighted, true)
                if poker_hand and not poker_hand.incompatible then return { hand } end
            end
            return {}
        end

        local poker_hand = G.GAME.amaryllis_lego_moc_hand
        if not poker_hand then return {} end
        if not poker_hand.suit and not poker_hand.ranks then return {} end

        local scoring_cards
        if poker_hand.ranks then
            -- Copy hand's required rank counts
            local rank_counts = {}
            for rank, count in pairs(poker_hand.ranks) do
                rank_counts[rank] = count
            end

            -- For each card, decrement its rank's count, if positive, and track the card
            scoring_cards = {}
            for i = 1, #hand do
                if not SMODS.has_no_rank(hand[i]) then
                    local rank = hand[i].base.value
                    if (rank_counts[rank] or 0) > 0 then
                        -- Validate flush if specified
                        local is_valid_suit = (not poker_hand.suit) or hand[i]:is_suit(poker_hand.suit, nil, true)
                        if is_valid_suit then
                            -- Add to scoring cards
                            rank_counts[rank] = rank_counts[rank] - 1
                            scoring_cards[#scoring_cards + 1] = hand[i]
                        end
                    end
                end
            end

            -- Validate that enough ranks are present
            for rank, count in pairs(rank_counts) do
                if count > 0 then return {} end
            end
        else
            -- No ranks, i.e. a 5-card pure 'Flush'
            if #hand < 5 then return {} end
            -- Take whole hand as scoring
            scoring_cards = SMODS.shallow_copy(hand)
            -- Validate flush
            for i = 1, #scoring_cards do
                if not scoring_cards[i]:is_suit(poker_hand.suit, nil, true) then return {} end
            end
        end

        return {scoring_cards}
    end,

    -- Despite default output being a loc key, will fallback to using it as plaintext if localization fails, hence we can localize in advance for combinations
    modify_display_text = function(self, cards, scoring_hand)
        if not G.GAME.amaryllis_lego_moc_hand and next(SMODS.find_card('j_' .. mod.prefix .. '_my_own_creation')) then 
            return localize_moc_hand(calculate_moc_hand(cards, true))
        
        elseif G.GAME.amaryllis_lego_moc_hand then 
            return localize_moc_hand(G.GAME.amaryllis_lego_moc_hand)
        end
    end,

}

-- MOC Planet Card (Makemake)
SMODS.Consumable{
    key = "makemake",

    set = 'Planet',

    name = 'Makemake',
    loc_txt = {
        name = "Makemake",
        text = {
            [1] = "{S:0.8}({S:0.8,V:1}lvl.#1#{S:0.8}){} Level up",
            [2] = "{C:attention}#2#",
            [3] = "{C:mult}+#3#{} Mult and",
            [4] = "{C:chips}+#4#{} chips",
        }
    },

    config = {
        hand_type = mod.prefix .. '_moc',
        softlock = true,
    },

    loc_vars = function(self, info_queue, card)
        local hand_set = (G.GAME.amaryllis_lego_moc_hand ~= nil)
        local main_end
        if not hand_set then
            main_end = {}
            localize{type = "other", key = mod.prefix .. "_makemake_unset", nodes = main_end }
            
            for i = 1, #main_end do 
                main_end[i] = { n=G.UIT.R, config={align = "cm"}, nodes=main_end[i] } 
            end
            main_end = {{n=G.UIT.C, config={align = "cm"}, nodes=main_end}}
        end

        local name_key = 'c_' .. mod.prefix .. '_' .. G.FUNCS.amaryllis_lego_get_makemake_name()

        return {
            name_key = name_key,
            vars = {
                G.GAME.hands[card.ability.hand_type].level,
                localize(card.ability.hand_type, 'poker_hands'),
                hand_set and G.GAME.hands[card.ability.hand_type].l_mult or localize('k_amaryllis_lego_unknown_value'),
                hand_set and G.GAME.hands[card.ability.hand_type].l_chips or localize('k_amaryllis_lego_unknown_value'),

                colours = { (G.GAME.hands[card.ability.hand_type].level == 1 and G.C.UI.TEXT_DARK or G.C.HAND_LEVELS[math.min(7, G.GAME.hands[card.ability.hand_type].level)]) }
            },
            main_end = main_end
        }
    end,

    set_card_type_badge = function(self, card, badges)
        badges[#badges + 1] = create_badge(
            localize('k_' .. mod.config.moc_planet.planet_type[mod.config.moc_planet.value]),
            get_type_colour(card.config.center or card.config, card), G.C.WHITE, 1.2)
    end,

    pos = { x = (mod.config.moc_planet.value - 1), y = 0 }, atlas = "consumables",

    no_collection = true,

    in_pool = function(self, args)
        return G.GAME.amaryllis_lego_moc_hand ~= nil and next(SMODS.find_card('j_amaryllis_lego_my_own_creation'))
    end,

    can_use = function(self, card)
        return G.GAME.amaryllis_lego_moc_hand ~= nil
    end,
}