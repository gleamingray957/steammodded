-- ----------------------------------------------
-- ------------MOD CORE API CARDS----------------
SMODS.Card = {}
SMODS.Card.SUIT_LIST = { "Hearts", "Diamonds", "Clubs", "Spades" }
SMODS.Card.SUITS = {
	["Hearts"] = {
		name = 'Hearts',
		prefix = 'H',
		suit_nominal = 0.03,
		ui_pos = { x = 0, y = 1 }
	},
	["Diamonds"] = {
		name = 'Diamonds',
		prefix = 'D',
		suit_nominal = 0.01,
		ui_pos = { x = 1, y = 1 },
	},
	["Clubs"] = {
		name = 'Clubs',
		prefix = 'C',
		suit_nominal = 0.02,
		ui_pos = { x = 2, y = 1 },
	},
	["Spades"] = {
		name = 'Spades',
		prefix = 'S',
		suit_nominal = 0.04,
		ui_pos = { x = 3, y = 1 }
	}
}
SMODS.Card.MAX_SUIT_NOMINAL = 0.04
SMODS.Card.RANKS = {
	['2'] = { value = '2', pos = { x = 0 }, id = 2, nominal = 2 },
	['3'] = { value = '3', pos = { x = 1 }, id = 3, nominal = 3 },
	['4'] = { value = '4', pos = { x = 2 }, id = 4, nominal = 4 },
	['5'] = { value = '5', pos = { x = 3 }, id = 5, nominal = 5 },
	['6'] = { value = '6', pos = { x = 4 }, id = 6, nominal = 6 },
	['7'] = { value = '7', pos = { x = 5 }, id = 7, nominal = 7 },
	['8'] = { value = '8', pos = { x = 6 }, id = 8, nominal = 8 },
	['9'] = { value = '9', pos = { x = 7 }, id = 9, nominal = 9 },
	['10'] = { suffix = 'T', value = '10', pos = { x = 8 }, id = 10, nominal = 10 },
	['Jack'] = { suffix = 'J', value = 'Jack', pos = { x = 9 }, id = 11, nominal = 10, face_nominal = 0.1 },
	['Queen'] = { suffix = 'Q', value = 'Queen', pos = { x = 10 }, id = 12, nominal = 10, face_nominal = 0.2 },
	['King'] = { suffix = 'K', value = 'King', pos = { x = 11 }, id = 13, nominal = 10, face_nominal = 0.3, },
	['Ace'] = { suffix = 'A', value = 'Ace', pos = { x = 12 }, id = 14, nominal = 11, face_nominal = 0.4 }
}
function SMODS.Card.generate_prefix()
	local possible_prefixes = { 'A', 'B', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'T', 'U', 'V',
		'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
		't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9' }
	for _, v in pairs(SMODS.Card.SUITS) do
		for i, vv in ipairs(possible_prefixes) do
			if v.prefix == vv then
				table.remove(possible_prefixes, i)
			end
		end
	end
	return possible_prefixes[1]
end

function SMODS.Card:new_suit(name, card_atlas_low_contrast, card_atlas_high_contrast, card_pos, ui_atlas_low_contrast,
							 ui_atlas_high_contrast, ui_pos, colour_low_contrast, colour_high_contrast)
	if SMODS.Card.SUITS[name] then
		sendDebugMessage('Failed to register duplicate suit:' .. name)
		return nil
	end
	local prefix = SMODS.Card.generate_prefix()
	if not prefix then
		sendDebugMessage('Too many suits! Failed to assign valid prefix to:' .. name)
	end
	SMODS.Card.MAX_SUIT_NOMINAL = SMODS.Card.MAX_SUIT_NOMINAL + 0.01
	SMODS.Card.SUITS[name] = {
		name = name,
		prefix = prefix,
		suit_nominal = SMODS.Card.MAX_SUIT_NOMINAL,
		card_atlas_low_contrast = card_atlas_low_contrast,
		card_atlas_high_contrast = card_atlas_high_contrast,
		card_pos = { y = card_pos.y },
		ui_atlas_low_contrast = ui_atlas_low_contrast,
		ui_atlas_high_contrast = ui_atlas_high_contrast,
		ui_pos = ui_pos
    }
	SMODS.Card.SUIT_LIST[#SMODS.Card.SUIT_LIST+1] = name
	colour_low_contrast = colour_low_contrast or '000000'
	colour_high_contrast = colour_high_contrast or '000000'
	if not (type(colour_low_contrast) == 'table') then colour_low_contrast = HEX(colour_low_contrast) end
	if not (type(colour_high_contrast) == 'table') then colour_high_contrast = HEX(colour_high_contrast) end
	G.C.SO_1[name] = colour_low_contrast
	G.C.SO_2[name] = colour_high_contrast
	G.C.SUITS[name] = G.C["SO_" .. (G.SETTINGS.colourblind_option and 2 or 1)][name]
	for _, v in pairs(SMODS.Card.RANKS) do
		G.P_CARDS[prefix .. '_' .. (v.suffix or v.value)] = {
			name = v.value .. ' of ' .. name,
			value = v.value,
			suit = name,
			pos = { x = v.pos.x, y = card_pos.y },
			card_atlas_low_contrast = card_atlas_low_contrast,
			card_atlas_high_contrast = card_atlas_high_contrast,
		}
	end
	G.localization.misc['suits_plural'][name] = name
	G.localization.misc['suits_singular'][name] = name
	return SMODS.Card.SUITS[name]
end

function SMODS.Card:_extend()
	function get_flush(hand)
		local ret = {}
		local four_fingers = next(find_joker('Four Fingers'))
		local suits = SMODS.Card.SUIT_LIST
		if #hand > 5 or #hand < (5 - (four_fingers and 1 or 0)) then
			return ret
		else
			for j = 1, #suits do
				local t = {}
				local suit = suits[j]
				local flush_count = 0
				for i = 1, #hand do
					if hand[i]:is_suit(suit, nil, true) then
						flush_count = flush_count + 1
						t[#t + 1] = hand[i]
					end
				end
				if flush_count >= (5 - (four_fingers and 1 or 0)) then
					table.insert(ret, t)
					return ret
				end
			end
			return {}
		end
	end

	function G.UIDEF.view_deck(unplayed_only)
		local deck_tables = {}
		remove_nils(G.playing_cards)
		G.VIEWING_DECK = true
		table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
		local suit_list = SMODS.Card.SUIT_LIST
		local SUITS = {}
		for _, v in ipairs(suit_list) do
			SUITS[v] = {}
		end
		for k, v in ipairs(G.playing_cards) do
			table.insert(SUITS[v.base.suit], v)
		end
		local num_suits = 0
		for j = 1, #suit_list do
			if SUITS[suit_list[j]][1] then num_suits = num_suits + 1 end
		end
		for j = 1, #suit_list do
			if SUITS[suit_list[j]][1] then
				local view_deck = CardArea(
					G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
					6.5 * G.CARD_W,
					((num_suits > 8) and 0.2 or (num_suits > 4) and (1 - 0.1 * num_suits) or 0.6) * G.CARD_H,
					{
						card_limit = #SUITS[suit_list[j]],
						type = 'title',
						view_deck = true,
						highlight_limit = 0,
						card_w = G.CARD_W * 0.6,
						draw_layers = { 'card' }
					})
				table.insert(deck_tables,
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0 },
						nodes = {
							{ n = G.UIT.O, config = { object = view_deck } }
						}
					}
				)

				for i = 1, #SUITS[suit_list[j]] do
					if SUITS[suit_list[j]][i] then
						local greyed, _scale = nil, 0.7
						if unplayed_only and not ((SUITS[suit_list[j]][i].area and SUITS[suit_list[j]][i].area == G.deck) or SUITS[suit_list[j]][i].ability.wheel_flipped) then
							greyed = true
						end
						local copy = copy_card(SUITS[suit_list[j]][i], nil, _scale)
						copy.greyed = greyed
						copy.T.x = view_deck.T.x + view_deck.T.w / 2
						copy.T.y = view_deck.T.y

						copy:hard_set_T()
						view_deck:emplace(copy)
					end
				end
			end
		end

		local flip_col = G.C.WHITE

		local suit_tallies = {}
		local mod_suit_tallies = {}
		for _, v in ipairs(suit_list) do
			suit_tallies[v] = 0
			mod_suit_tallies[v] = 0
		end
		local rank_tallies = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
		local mod_rank_tallies = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
		local rank_name_mapping = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K', 'A' }
		local face_tally = 0
		local mod_face_tally = 0
		local num_tally = 0
		local mod_num_tally = 0
		local ace_tally = 0
		local mod_ace_tally = 0
		local wheel_flipped = 0

		for _, v in ipairs(G.playing_cards) do
			if v.ability.name ~= 'Stone Card' and (not unplayed_only or ((v.area and v.area == G.deck) or v.ability.wheel_flipped)) then
				if v.ability.wheel_flipped and unplayed_only then wheel_flipped = wheel_flipped + 1 end
				--For the suits
				suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1
				for kk, vv in pairs(mod_suit_tallies) do
					mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
				end

				--for face cards/numbered cards/aces
				local card_id = v:get_id()
				face_tally = face_tally + ((card_id == 11 or card_id == 12 or card_id == 13) and 1 or 0)
				mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
				if card_id > 1 and card_id < 11 then
					num_tally = num_tally + 1
					if not v.debuff then mod_num_tally = mod_num_tally + 1 end
				end
				if card_id == 14 then
					ace_tally = ace_tally + 1
					if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
				end

				--ranks
				rank_tallies[card_id - 1] = rank_tallies[card_id - 1] + 1
				if not v.debuff then mod_rank_tallies[card_id - 1] = mod_rank_tallies[card_id - 1] + 1 end
			end
		end

		local modded = (face_tally ~= mod_face_tally)
		for kk, vv in pairs(mod_suit_tallies) do
			if vv ~= suit_tallies[kk] then modded = true end
		end

		if wheel_flipped > 0 then flip_col = mix_colours(G.C.FILTER, G.C.WHITE, 0.7) end

		local rank_cols = {}
		for i = 13, 1, -1 do
			local mod_delta = mod_rank_tallies[i] ~= rank_tallies[i]
			rank_cols[#rank_cols + 1] = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.07 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", r = 0.1, padding = 0.04, emboss = 0.04, minw = 0.5, colour = G.C.L_BLACK },
						nodes = {
							{ n = G.UIT.T, config = { text = rank_name_mapping[i], colour = G.C.JOKER_GREY, scale = 0.35, shadow = true } },
						}
					},
					{
						n = G.UIT.C,
						config = { align = "cr", minw = 0.4 },
						nodes = {
							mod_delta and
							{ n = G.UIT.O, config = { object = DynaText({ string = { { string = '' .. rank_tallies[i], colour = flip_col }, { string = '' .. mod_rank_tallies[i], colour = G.C.BLUE } }, colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4 }) } } or
							{ n = G.UIT.T, config = { text = rank_tallies[i] or 'NIL', colour = flip_col, scale = 0.45, shadow = true } },
						}
					}
				}
			}
		end

		local tally_ui = {
			-- base cards
			{
				n = G.UIT.R,
				config = { align = "cm", minh = 0.05, padding = 0.07 },
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = { { string = localize('k_base_cards'), colour = G.C.RED }, modded and { string = localize('k_effective'), colour = G.C.BLUE } or nil }, colours = { G.C.RED }, silent = true, scale = 0.4, pop_in_rate = 10, pop_delay = 4 }) } }
				}
			},
			-- aces, faces and numbered cards
			{
				n = G.UIT.R,
				config = { align = "cm", minh = 0.05, padding = 0.1 },
				nodes = {
					tally_sprite({ x = 1, y = 0 },
						{ { string = '' .. ace_tally, colour = flip_col }, { string = '' .. mod_ace_tally, colour = G.C.BLUE } },
						{ localize('k_aces') }), --Aces
					tally_sprite({ x = 2, y = 0 },
						{ { string = '' .. face_tally, colour = flip_col }, { string = '' .. mod_face_tally, colour = G.C.BLUE } },
						{ localize('k_face_cards') }), --Face
					tally_sprite({ x = 3, y = 0 },
						{ { string = '' .. num_tally, colour = flip_col }, { string = '' .. mod_num_tally, colour = G.C.BLUE } },
						{ localize('k_numbered_cards') }), --Numbers
				}
			},
		}
		-- add suit tallies
		for i = 1, #suit_list, 2 do
			local n = {
				n = G.UIT.R,
				config = { align = "cm", minh = 0.05, padding = 0.1 },
				nodes = {
					tally_sprite(SMODS.Card.SUITS[suit_list[i]].ui_pos,
						{ { string = '' .. suit_tallies[suit_list[i]], colour = flip_col }, { string = '' .. mod_suit_tallies[suit_list[i]], colour = G.C.BLUE } },
						{ localize(suit_list[i], 'suits_plural') },
						suit_list[i]),
					suit_list[i + 1] and tally_sprite(SMODS.Card.SUITS[suit_list[i + 1]].ui_pos,
						{ { string = '' .. suit_tallies[suit_list[i + 1]], colour = flip_col }, { string = '' .. mod_suit_tallies[suit_list[i + 1]], colour = G.C.BLUE } },
						{ localize(suit_list[i + 1], 'suits_plural') },
						suit_list[i+1]) or nil,
				}
			}
			table.insert(tally_ui, n)
		end

		local t =
		{
			n = G.UIT.ROOT,
			config = { align = "cm", colour = G.C.CLEAR },
			nodes = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {} },
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{
							n = G.UIT.C,
							config = { align = "cm", minw = 1.5, minh = 2, r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
							nodes = {
								{
									n = G.UIT.C,
									config = { align = "cm", padding = 0.1 },
									nodes = {
										{
											n = G.UIT.R,
											config = { align = "cm", r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, padding = 0.15 },
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm" },
													nodes = {
														{ n = G.UIT.O, config = { object = DynaText({ string = G.GAME.selected_back.loc_name, colours = { G.C.WHITE }, bump = true, rotate = true, shadow = true, scale = 0.6 - string.len(G.GAME.selected_back.loc_name) * 0.01 }) } },
													}
												},
												{
													n = G.UIT.R,
													config = { align = "cm", r = 0.1, padding = 0.1, minw = 2.5, minh = 1.3, colour = G.C.WHITE, emboss = 0.05 },
													nodes = {
														{
															n = G.UIT.O,
															config = {
																object = UIBox {
																	definition = G.GAME.selected_back:generate_UI(nil, 0.7, 0.5, G.GAME.challenge),
																	config = { offset = { x = 0, y = 0 } }
																}
															}
														}
													}
												}
											}
										},
										{
											n = G.UIT.R,
											config = { align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5 },
											nodes = tally_ui
										}
									}
								},
								{ n = G.UIT.C, config = { align = "cm" },    nodes = rank_cols },
								{ n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
							}
						},
						{ n = G.UIT.B, config = { w = 0.2, h = 0.1 } },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables }
					}
				},
				{
					n = G.UIT.R,
					config = { align = "cm", minh = 0.8, padding = 0.05 },
					nodes = {
						modded and {
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7) },              nodes = {} },
								{ n = G.UIT.T, config = { text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3 } },
							}
						} or nil,
						wheel_flipped > 0 and {
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = flip_col }, nodes = {} },
								{
									n = G.UIT.T,
									config = {
										text = ' ' .. (wheel_flipped > 1 and
											localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
											localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
										colour = G.C.WHITE,
										scale = 0.3
									}
								},
							}
						} or nil,
					}
				}
			}
		}
		return t
	end

	function G.UIDEF.deck_preview(args)
		local _minh, _minw = 0.35, 0.5
		local suit_list = SMODS.Card.SUIT_LIST
		local suit_labels = {}
		local suit_counts = {}
		local mod_suit_counts = {}
		for _, v in ipairs(suit_list) do
			suit_counts[v] = 0
			mod_suit_counts[v] = 0
		end
		local mod_suit_diff = false
		local wheel_flipped, wheel_flipped_text = 0, nil
		local flip_col = G.C.WHITE
		local rank_counts = {}
		local deck_tables = {}
		remove_nils(G.playing_cards)
		table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
		local SUITS = {}
		for _, v in ipairs(suit_list) do
			SUITS[v] = {}
		end

		for k, v in pairs(SUITS) do
			for i = 1, 14 do
				SUITS[k][#SUITS[k] + 1] = {}
			end
		end

		local stones = nil
		local rank_name_mapping = { 'A', 'K', 'Q', 'J', '10', 9, 8, 7, 6, 5, 4, 3, 2 }

		for k, v in ipairs(G.playing_cards) do
			if v.ability.effect == 'Stone Card' then
				stones = stones or 0
			end
			if (v.area and v.area == G.deck) or v.ability.wheel_flipped then
				if v.ability.wheel_flipped then wheel_flipped = wheel_flipped + 1 end
				if v.ability.effect == 'Stone Card' then
					stones = stones + 1
				else
					for kk, vv in pairs(suit_counts) do
						if v.base.suit == kk then suit_counts[kk] = suit_counts[kk] + 1 end
						if v:is_suit(kk) then mod_suit_counts[kk] = mod_suit_counts[kk] + 1 end
					end
					if SUITS[v.base.suit][v.base.id] then
						table.insert(SUITS[v.base.suit][v.base.id], v)
					end
					rank_counts[v.base.id] = (rank_counts[v.base.id] or 0) + 1
				end
			end
		end

		wheel_flipped_text = (wheel_flipped > 0) and
			{ n = G.UIT.T, config = { text = '?', colour = G.C.FILTER, scale = 0.25, shadow = true } } or nil
		flip_col = wheel_flipped_text and mix_colours(G.C.FILTER, G.C.WHITE, 0.7) or G.C.WHITE

		suit_labels[#suit_labels + 1] = {
			n = G.UIT.R,
			config = { align = "cm", r = 0.1, padding = 0.04, minw = _minw, minh = 2 * _minh + 0.25 },
			nodes = {
				stones and
				{ n = G.UIT.T, config = { text = localize('ph_deck_preview_stones') .. ': ', colour = G.C.WHITE, scale = 0.25, shadow = true } }
				or nil,
				stones and
				{ n = G.UIT.T, config = { text = '' .. stones, colour = (stones > 0 and G.C.WHITE or G.C.UI.TRANSPARENT_LIGHT), scale = 0.4, shadow = true } }
				or nil,
			}
		}

		local _row = {}
		local _bg_col = G.C.JOKER_GREY
		for k, v in ipairs(rank_name_mapping) do
			local _tscale = 0.3
			local _colour = G.C.BLACK
			local rank_col = v == 'A' and _bg_col or (v == 'K' or v == 'Q' or v == 'J') and G.C.WHITE or _bg_col
			rank_col = mix_colours(rank_col, _bg_col, 0.8)

			local _col = {
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", r = 0.1, minw = _minw, minh = _minh, colour = rank_col, emboss = 0.04, padding = 0.03 },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{ n = G.UIT.T, config = { text = '' .. v, colour = _colour, scale = 1.6 * _tscale } },
								}
							},
							{
								n = G.UIT.R,
								config = { align = "cm", minw = _minw + 0.04, minh = _minh, colour = G.C.L_BLACK, r = 0.1 },
								nodes = {
									{ n = G.UIT.T, config = { text = '' .. (rank_counts[15 - k] or 0), colour = flip_col, scale = _tscale, shadow = true } }
								}
							}
						}
					}
				}
			}
			table.insert(_row, _col)
		end
		table.insert(deck_tables, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = _row })

		for j = 1, #suit_list do
			_row = {}
			_bg_col = mix_colours(G.C.SUITS[suit_list[j]], G.C.L_BLACK, 0.7)
			for i = 14, 2, -1 do
				local _tscale = #SUITS[suit_list[j]][i] > 0 and 0.3 or 0.25
				local _colour = #SUITS[suit_list[j]][i] > 0 and flip_col or G.C.UI.TRANSPARENT_LIGHT

				local _col = {
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, minw = _minw + 0.098, minh = _minh },
					nodes = {
						{ n = G.UIT.T, config = { text = '' .. #SUITS[suit_list[j]][i], colour = _colour, scale = _tscale, shadow = true, lang = G.LANGUAGES['en-us'] } },
					}
				}
				table.insert(_row, _col)
			end
			table.insert(deck_tables,
				{
					n = G.UIT.R,
					config = { align = "cm", r = 0.1, padding = 0.04, minh = 0.4, colour = _bg_col },
					nodes =
						_row
				})
		end

		for _, v in ipairs(suit_list) do
			local suit_data = SMODS.Card.SUITS[v]
			local t_s = Sprite(0, 0, 0.3, 0.3, (suit_data.ui_atlas_low_contrast or suit_data.ui_atlas_high_contrast) and
				G.ASSET_ATLAS
				[G.SETTINGS.colourblind_option and suit_data.ui_atlas_high_contrast or suit_data.ui_atlas_low_contrast] or
				G.ASSET_ATLAS["ui_" .. (G.SETTINGS.colourblind_option and 2 or 1)],
				suit_data.ui_pos)
			t_s.states.drag.can = false
			t_s.states.hover.can = false
			t_s.states.collide.can = false

			if mod_suit_counts[v] ~= suit_counts[v] then mod_suit_diff = true end

			suit_labels[#suit_labels + 1] =
			{
				n = G.UIT.R,
				config = { align = "cm", r = 0.1, padding = 0.03, colour = G.C.JOKER_GREY },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = _minw, minh = _minh },
						nodes = {
							{ n = G.UIT.O, config = { can_collide = false, object = t_s } }
						}
					},
					{
						n = G.UIT.C,
						config = { align = "cm", minw = _minw * 2.4, minh = _minh, colour = G.C.L_BLACK, r = 0.1 },
						nodes = {
							{ n = G.UIT.T, config = { text = '' .. suit_counts[v], colour = flip_col, scale = 0.3, shadow = true, lang = G.LANGUAGES['en-us'] } },
							mod_suit_counts[v] ~= suit_counts[v] and
							{ n = G.UIT.T, config = { text = ' (' .. mod_suit_counts[v] .. ')', colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7), scale = 0.28, shadow = true, lang = G.LANGUAGES['en-us'] } } or
							nil,
						}
					}
				}
			}
		end


		local t =
		{
			n = G.UIT.ROOT,
			config = { align = "cm", colour = G.C.JOKER_GREY, r = 0.1, emboss = 0.05, padding = 0.07 },
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm", r = 0.1, emboss = 0.05, colour = G.C.BLACK, padding = 0.1 },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = suit_labels },
								{ n = G.UIT.C, config = { align = "cm", padding = 0.02 }, nodes = deck_tables }
							}
						},
						mod_suit_diff and {
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7) },              nodes = {} },
								{ n = G.UIT.T, config = { text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3 } },
							}
						} or nil,
						wheel_flipped_text and {
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = flip_col }, nodes = {} },
								{
									n = G.UIT.T,
									config = {
										text = ' ' .. (wheel_flipped > 1 and
											localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
											localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
										colour = G.C.WHITE,
										scale = 0.3
									}
								},
							}
						} or nil,
					}
				}
			}
		}
		return t
	end

	function Card:set_base(card, initial)
		card = card or {}

		self.config.card = card
		for k, v in pairs(G.P_CARDS) do
			if card == v then self.config.card_key = k end
		end

		if next(card) then
			self:set_sprites(nil, card)
		end

		local suit_base_nominal_original = nil
		if self.base and self.base.suit_nominal_original then
			suit_base_nominal_original = self.base
				.suit_nominal_original
		end
		self.base = {
			name = self.config.card.name,
			suit = self.config.card.suit,
			value = self.config.card.value,
			nominal = 0,
			suit_nominal = 0,
			face_nominal = 0,
			colour = G.C.SUITS[self.config.card.suit],
			times_played = 0
		}
		local rank_data = SMODS.Card.RANKS[self.base.value] or {}
		local suit_data = SMODS.Card.SUITS[self.base.suit] or {}
		self.base.nominal = rank_data.nominal or 0
		self.base.id = rank_data.id or 0
		self.base_face_nominal = rank_data.face_nominal or nil

		if initial then self.base.original_value = self.base.value end

		self.base.suit_nominal = suit_data.suit_nominal
		self.base.suit_nominal_original = suit_base_nominal_original or
		suit_data.suit_nominal and suit_data.suit_nominal / 10 or nil

		if not initial then G.GAME.blind:debuff_card(self) end
		if self.playing_card and not initial then check_for_unlock({ type = 'modify_deck' }) end
	end

	function Card:change_suit(new_suit)
		local new_code = SMODS.Card.SUITS[new_suit].prefix
		local new_val = SMODS.Card.RANKS[self.base.value].suffix
		local new_card = G.P_CARDS[new_code .. '_' .. new_val]
		self:set_base(new_card)
		G.GAME.blind:debuff_card(self)
	end

	local Blind_set_blind_ref = Blind.set_blind
	function Blind:set_blind(blind, reset, silent)
		Blind_set_blind_ref(self, blind, reset, silent)
		if (self.name == "The Eye") and not reset then
			for _, v in ipairs(G.handlist) do
				self.hands[v] = false
			end
		end
	end

	local tally_sprite_ref = tally_sprite
	function tally_sprite(pos, value, tooltip, suit)
        local node = tally_sprite_ref(pos, value, tooltip)
		if not suit then return node end
		local suit_data = SMODS.Card.SUITS[suit]
		if suit_data.ui_atlas_low_contrast or suit_data.ui_atlas_high_contrast then
			local t_s = Sprite(0, 0, 0.5, 0.5,
				G.ASSET_ATLAS[G.SETTINGS.colourblind_option and suit_data.ui_atlas_high_contrast or suit_data.ui_atlas_low_contrast],
				{ x = suit_data.ui_pos.x or 0, y = suit_data.ui_pos.y or 0 })
			t_s.states.drag.can = false
			t_s.states.hover.can = false
			t_s.states.collide.can = false
			node.nodes[1].nodes[1].config.object = t_s
		end
		return node
	end
end

SMODS.Card:_extend()
-- ----------------------------------------------
-- ------------MOD CORE API SPRITE END-----------
