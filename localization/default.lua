return {
    misc = {
        dictionary = {
            k_amaryllis_lego_classic = "Classic!",
            k_amaryllis_lego_illegal = "Illegal",
            k_amaryllis_lego_fresh_poker_hand = "Fresh!",
            k_amaryllis_lego_stale_poker_hand = "Seen it!",
            k_amaryllis_lego_last_unique_poker_hand = "the last such hand",
            k_amaryllis_lego_burp_gone = "Cleared!",
            k_amaryllis_lego_cheese_gone = "Eaten!",
            k_amaryllis_lego_frog = "Ribbit",
            k_amaryllis_lego_no_frog = "Must play a 4",
            k_amaryllis_lego_split = "Split!",

            k_amaryllis_lego_unknown_value = "???",
            k_amaryllis_lego_moon_q = "Moon?",

            amaryllis_lego_suits_adj_Spades = "Spade",
            amaryllis_lego_suits_adj_Hearts = "Hearts",
            amaryllis_lego_suits_adj_Clubs = "Clubs",
            amaryllis_lego_suits_adj_Diamonds = "Diamond",
        },

        v_dictionary = {
            -- Special rank nicknames
            amaryllis_lego_Ace = "Rockets",
            amaryllis_lego_King = "Cowboys",
            amaryllis_lego_Queen = "Ladies",
            amaryllis_lego_Jack = "Fishhooks",
            amaryllis_lego_10 = "Dimes",
            amaryllis_lego_9 = "Balloons",
            amaryllis_lego_8 = "Snowmen",
            amaryllis_lego_7 = "Scythes",
            amaryllis_lego_6 = "Kicks",
            amaryllis_lego_5 = "Nickels",
            amaryllis_lego_4 = "Sailboats",
            amaryllis_lego_3 = "Treys",
            amaryllis_lego_2 = "Deuces",
            
            -- OAK hands
            amaryllis_lego_high = "#1# High",
            amaryllis_lego_oak_2 = "Double #1#s",
            amaryllis_lego_oak_3 = "Triple #1#s",
            amaryllis_lego_oak_4 = "Four #1#s",
            amaryllis_lego_oak_5 = "Five #1#s",

            amaryllis_lego_special_oak_2 = "Pocket #1#",
            amaryllis_lego_special_oak_3 = "Triple #1#",
            amaryllis_lego_special_oak_4 = "Four #1#",
            amaryllis_lego_special_oak_5 = "Five #1#",

            amaryllis_lego_flush_2 = "Double #2# #1#s",
            amaryllis_lego_flush_3 = "Triple #2# #1#s",
            amaryllis_lego_flush_4 = "Four #2# #1#s",
            amaryllis_lego_flush_5 = "Five #2# #1#s",

            -- Mixed ranks
            amaryllis_lego_two_pair = "Twice #1#s & #2#s",
            amaryllis_lego_full_house = "Full #1#s & #2#s",

            amaryllis_lego_flush_two_pair = "Twice #3# #1#s & #2#s",
            amaryllis_lego_flush_house = "Full #3# #1#s & #2#s",

            -- Straights
            amaryllis_lego_straight = "#1#-#2# Straight",
            amaryllis_lego_straight_flush = "#1#-#2# Straight #3#",
            
            -- Flush
            amaryllis_lego_flush = "#1# Flush",
            amaryllis_lego_flush_generic = "#1# #2#",

            -- Special specific hands
            amaryllis_lego_broadway = "Broadway",
            amaryllis_lego_royale = "Royale",
            amaryllis_lego_wheel = "Wheel",
            amaryllis_lego_muskateers = "Muskateers",
            amaryllis_lego_horsemen = "Four Horsemen",
            amaryllis_lego_forest = "Forest",
            amaryllis_lego_jackpot = "Jackpot",
            amaryllis_lego_devils_hand = "Devil's Hand",
            amaryllis_lego_devils_flush = "Devil's #1#",
            amaryllis_lego_dead_mans_hand = "Dead Man's Hand",
            amaryllis_lego_dead_mans_flush = "Dead Man's #1#",
            amaryllis_lego_dolly = "Dolly",

            amaryllis_lego_moc_desc_1 = "#1#",
            amaryllis_lego_moc_desc_2 = "aka #1#",
        },

        poker_hands = {
            amaryllis_lego_moc = "My Own Creation"
        },

        poker_hand_descriptions = {
            amaryllis_lego_moc = { " A custom created poker hand " }
        },
    },
    descriptions = {
        Joker = {
            j_amaryllis_lego_my_own_creation_set = {
                name = "My Own Creation",
                text = {
                    "Allows {C:planet}#1#{} to appear",
                    "{S:0.8,C:inactive}(Custom poker hand will still be",
                    "{S:0.8,C:inactive}playable if this Joker is removed)"
                }
            },

            j_amaryllis_lego_cheese_slope_unobtainable={
                name = "Cheese Slope",
                text={
                    "Earn {C:money}$#1#{} at end of round,",
                    "reduces by {C:money}$#2#{} for each",
                    "other {C:attention}Joker{} you have",
                    "{C:inactive}(Currently unobtainable)",
                }
            }
        },
        Planet = {
            ['c_amaryllis_lego_Makemake'] = { name = "Makemake", text = {} },
            ['c_amaryllis_lego_Planet Duplo'] = { name = "Planet Duplo", text = {} },
            ['c_amaryllis_lego_LEGO Death Star'] = { name = "LEGO Death Star", text = {} },
        },
        Other = {
            amaryllis_lego_max_npu={
                name="n", text={ "{C:inactive}(Max: {C:attention}#1#{C:inactive} for {C:mult}+#2#{C:inactive} Mult){}" },
            },

            amaryllis_lego_makemake_unset={
                name="n", text={
                    "{S:0.8,C:inactive}2X values of",
                    "{S:0.8,C:inactive}base poker hand",
                },
            },
            
            amaryllis_lego_creating_moc={
                name="n", text={ "{C:inactive}(Selected creates: {C:attention}#1#{C:inactive}){}" },
            },
            amaryllis_lego_creating_moc_aka={
                name="n", text={ "{C:inactive}(Selected creates: {C:attention}#1#{C:inactive} aka {C:attention}#2#{C:inactive}){}" },
            },
            amaryllis_lego_invalid_moc={
                name="n", text={ "{C:inactive}({C:attention}Invalid hand{C:inactive} selected){}" },
            },
            amaryllis_lego_moc_incompatible_shortcut={
                name="n", text={ "{B:red,C:white} Incompatible with Shortcut {}" },
            },
            amaryllis_lego_moc_incompatible_four_fingers={
                name="n", text={ "{B:red,C:white} Incompatible with Four Fingers {}" },
            },
            amaryllis_lego_moc_hand={
                name="n", text={ "{C:inactive}({C:attention}#1#{C:inactive}){}" },
            },
            amaryllis_lego_moc_hand_aka={
                name="n", text={ "{C:inactive}({C:attention}#1#{C:inactive} aka {C:attention}#2#{C:inactive}){}" },
            },
        }
    },
}