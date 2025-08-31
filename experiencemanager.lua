local function increase_infamous_with_prestige_overflow()
	local rank = managers.experience:current_rank() + 1
	local offshore_cost = managers.money:get_infamous_cost(rank)
	local max_rank = type(tweak_data.infamy.ranks) == "table" and #tweak_data.infamy.ranks or tweak_data.infamy.ranks or 500
	if managers.experience:current_level() < 100 or offshore_cost > managers.money:offshore() or max_rank <= managers.experience:current_rank() then
		return false
	end

	managers.experience:set_current_rank(rank)
	managers.experience:set_current_prestige_xp(0)

	if offshore_cost > 0 then
		managers.money:deduct_from_total(managers.money:total(), TelemetryConst.economy_origin.increase_infamous)
		managers.money:deduct_from_offshore(offshore_cost)
	end

	if managers.menu_component then
		managers.menu_component:refresh_player_profile_gui()
	end

	local logic = managers.menu:active_menu().logic
	if logic then
		logic:refresh_node()
		logic:select_item("crimenet")
	end

	managers.savefile:save_progress()
	managers.savefile:save_setting(true)
	managers.menu:post_event("infamous_stinger_generic")

	if type(SystemInfo.distribution) ~= "nil" and SystemInfo:distribution() == Idstring("STEAM") then
		managers.statistics:publish_level_to_steam()
	end
	
	return true
end

Hooks:PostHook(ExperienceManager, "set_current_prestige_xp", "ExperienceManager.set_current_prestige_xp.add_infamy_on_pool_overflow", function(self, amount)
	if self:get_prestige_xp_percentage_progress() >= 1 then
		local remains = amount - self:get_max_prestige_xp()
		if increase_infamous_with_prestige_overflow() then
			self._global.prestige_xp_gained = Application:digest_value(remains, true)
		end
	end
end)