caravel_ship.walkmap = {}

local faces = {
	{min_x = -1.2, max_x = 1.2, min_z = 0.5, max_z = 1.5, floor_y = -0.2, ceil_y = 2.0},
	{min_x = -1.2, max_x = 1.2, min_z = 1.5, max_z = 3.0, floor_y = -0.2, ceil_y = 2.0},
	{min_x = -1.2, max_x = 1.2, min_z = -1.5, max_z = 0.5, floor_y = 0.8, ceil_y = 4.0},
	{min_x = -1.2, max_x = 1.2, min_z = -4.0, max_z = -1.5, floor_y = 0.8, ceil_y = 4.0},
	{min_x = -1.2, max_x = 1.2, min_z = 3.0, max_z = 5.0, floor_y = 0.8, ceil_y = 4.0},
	{min_x = -1.2, max_x = 1.2, min_z = 5.0, max_z = 7.0, floor_y = 0.8, ceil_y = 4.0},
	{min_x = -3.2, max_x = -1.2, min_z = -4.0, max_z = 0.0, floor_y = 1.2, ceil_y = 5.0},
	{min_x = -3.2, max_x = -1.2, min_z = 0.0, max_z = 4.0, floor_y = 1.2, ceil_y = 5.0},
	{min_x = 1.2, max_x = 3.2, min_z = -4.0, max_z = 0.0, floor_y = 1.2, ceil_y = 5.0},
	{min_x = 1.2, max_x = 3.2, min_z = 0.0, max_z = 4.0, floor_y = 1.2, ceil_y = 5.0},
	{min_x = -3.2, max_x = 3.2, min_z = 7.0, max_z = 9.0, floor_y = 2.6, ceil_y = 6.0},
	{min_x = -3.2, max_x = 3.2, min_z = 9.0, max_z = 11.0, floor_y = 2.6, ceil_y = 6.0},
	{min_x = -2.5, max_x = 2.5, min_z = 11.0, max_z = 13.0, floor_y = 3.4, ceil_y = 7.0},
	{min_x = -2.5, max_x = 2.5, min_z = 13.0, max_z = 15.0, floor_y = 3.4, ceil_y = 7.0},
	{min_x = -2.0, max_x = 2.0, min_z = -6.0, max_z = -5.0, floor_y = 2.0, ceil_y = 6.0},
	{min_x = -2.0, max_x = 2.0, min_z = -5.0, max_z = -4.0, floor_y = 1.6, ceil_y = 5.5},
	{min_x = -0.5, max_x = 0.5, min_z = -8.0, max_z = -6.0, floor_y = 2.4, ceil_y = 6.5},
	{min_x = -3.5, max_x = -3.0, min_z = -2.0, max_z = 2.0, floor_y = 1.2, ceil_y = 4.5},
	{min_x = 3.0, max_x = 3.5, min_z = -2.0, max_z = 2.0, floor_y = 1.2, ceil_y = 4.5},
	{min_x = -0.8, max_x = 0.8, min_z = -12.0, max_z = -8.0, floor_y = 2.8, ceil_y = 7.0}
}

function caravel_ship.walkmap.process_passengers(self, dtime)
	local pos = self.object:get_pos()
	if not pos then return end
	local yaw = self.object:get_yaw() or 0
	local ship_vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
	local cos_yaw = math.cos(yaw)
	local sin_yaw = math.sin(yaw)

	local width = 5.0
	local length = 15.0
	local min_y = -3.0
	local max_y = 10.0

	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 18)) do
		if obj:is_player() then
			local p_name = obj:get_player_name()
			local p_pos = obj:get_pos()
			local dx = p_pos.x - pos.x
			local dz = p_pos.z - pos.z

			local lx = dx * cos_yaw + dz * sin_yaw
			local lz = -dx * sin_yaw + dz * cos_yaw
			local ly = p_pos.y - pos.y

			if lx >= -width and lx <= width and lz >= -length and lz <= length and ly >= min_y and ly <= max_y then
				local current_floor = ly
				local inside_face = false

				for i = 1, #faces do
					local f = faces[i]
					if lx >= f.min_x and lx <= f.max_x and lz >= f.min_z and lz <= f.max_z then
						if ly >= f.floor_y - 0.6 and ly <= f.ceil_y then
							current_floor = f.floor_y
							inside_face = true
							break
						end
					end
				end

				if inside_face then
					if obj:get_attach() ~= self.object then
						obj:set_attach(self.object, "", {x = lx * 10, y = current_floor * 10, z = lz * 10}, {x = 0, y = 0, z = 0})
						if mcl_player and mcl_player.player_attached then
							mcl_player.player_attached[p_name] = true
						end
					end

					local ctrl = obj:get_player_control()
					if ctrl.sneak and p_name ~= self.driver then
						obj:set_detach()
						if mcl_player and mcl_player.player_attached then
							mcl_player.player_attached[p_name] = false
							mcl_player.player_set_animation(obj, "stand", 30)
						end
						local exit_x = pos.x - sin_yaw * (lz + 2.0) - cos_yaw * lx
						local exit_z = pos.z + cos_yaw * (lz + 2.0) - sin_yaw * lx
						obj:set_pos({x = exit_x, y = pos.y + current_floor + 0.5, z = exit_z})
					elseif p_name == self.driver then
						local mx = 0
						local mz = 0
						local speed = 4.5 * dtime

						if ctrl.up then mz = speed end
						if ctrl.down then mz = -speed end
						if ctrl.left then mx = -speed end
						if ctrl.right then mx = speed end

						if mx ~= 0 or mz ~= 0 then
							local nx = lx + mx
							local nz = lz + mz
							local target_y = current_floor
							local movement_valid = false

							for i = 1, #faces do
								local f = faces[i]
								if nx >= f.min_x and nx <= f.max_x and nz >= f.min_z and nz <= f.max_z then
									if current_floor >= f.floor_y - 1.2 and current_floor <= f.ceil_y then
										target_y = f.floor_y
										movement_valid = true
										break
									end
								end
							end

							if movement_valid then
								obj:set_attach(self.object, "", {x = nx * 10, y = target_y * 10, z = nz * 10}, {x = 0, y = 0, z = 0})
								if mcl_player and mcl_player.player_set_animation then
									mcl_player.player_set_animation(obj, "walk", 30)
								end
							end
						else
							obj:set_attach(self.object, "", {x = lx * 10, y = current_floor * 10, z = lz * 10}, {x = 0, y = 0, z = 0})
							if mcl_player and mcl_player.player_set_animation then
								mcl_player.player_set_animation(obj, "stand", 30)
							end
						end
					end
				else
					if obj:get_attach() == self.object then
						obj:set_detach()
						if mcl_player and mcl_player.player_attached then
							mcl_player.player_attached[p_name] = false
							mcl_player.player_set_animation(obj, "stand", 30)
						end
					end
				end
			else
				if obj:get_attach() == self.object then
					obj:set_detach()
					if mcl_player and mcl_player.player_attached then
						mcl_player.player_attached[p_name] = false
						mcl_player.player_set_animation(obj, "stand", 30)
					end
				end
			end
		end
	end
end
