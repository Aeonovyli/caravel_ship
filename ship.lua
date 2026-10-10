minetest.register_entity("caravel_ship:ship", {
	initial_properties = {
		physical = true,
		collisionbox = {-3.0, -1.5, -6.0, 3.0, 4.0, 6.0},
		selectionbox = {-3.0, -1.5, -6.0, 3.0, 4.0, 6.0},
		visual = "mesh",
		mesh = "caravel.obj",
		textures = {"wood.png", "ladder.png", "sail.png", "rope.png"}
	},
	driver = nil,
	anchor_down = false,
	sails_hoisted = false,
	rudder_angle = 0,
	children_spawned = false,
	door_entities = {},
	artillery_entity = nil,
	current_anim = "",
	space_key_released = true,
	cannon_count = 0,
	max_cannons = 10,

	on_activate = function(self, staticdata)
		self.object:set_armor_groups({fleshy = 0, immortal = 1})
		if staticdata and staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			if data and data.cannon_count then
				self.cannon_count = data.cannon_count
			end
		end
	end,

	get_staticdata = function(self)
		return minetest.serialize({
			cannon_count = self.cannon_count
		})
	end,

	spawn_children = function(self)
		if self.children_spawned then return end
		local pos = self.object:get_pos()
		if self.cannon_count > 0 then
			local c = minetest.add_entity(pos, "caravel_ship:artillery_layer")
			if c then
				c:set_properties({
					mesh = "c_" .. self.cannon_count .. ".obj",
					textures = {"c_top.png", "c_bottom.png"}
				})
				c:set_attach(self.object, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
				self.artillery_entity = c
			end
		end
		self.children_spawned = true
	end,

	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end
		if not self.children_spawned then self:spawn_children() end
		local itm = clicker:get_wielded_item()
		local name = itm:get_name()

		if name == "caravel_ship:cannon_barrel_item" then
			if self.cannon_count < self.max_cannons then
				self.cannon_count = self.cannon_count + 1
				local pos = self.object:get_pos()
				if self.artillery_entity then
					local old_art = self.artillery_entity
					self.artillery_entity = nil
					old_art:remove()
				end
				local c = minetest.add_entity(pos, "caravel_ship:artillery_layer")
				if c then
					c:set_properties({
						mesh = "c_" .. self.cannon_count .. ".obj",
						textures = {"c_top.png", "c_bottom.png"}
					})
					c:set_attach(self.object, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
					self.artillery_entity = c
				end
				if not minetest.settings:get_bool("creative_mode") then
					itm:take_item()
					clicker:set_wielded_item(itm)
				end
			end
			return
		end

		if caravel_ship.dye_colors[name] then
			local hex = caravel_ship.dye_colors[name]
			self.object:set_properties({
				textures = {"wood.png", "ladder.png", "sail.png^[multiply:#" .. hex, "rope.png"}
			})
			if not minetest.settings:get_bool("creative_mode") then
				itm:take_item()
				clicker:set_wielded_item(itm)
			end
			return
		end

		local p_name = clicker:get_player_name()
		if not self.driver then
			self.driver = p_name
			clicker:set_attach(self.object, "", {x = 0, y = 30, z = 45}, {x = 0, y = 0, z = 0})
			if mcl_player and mcl_player.player_attached then
				mcl_player.player_attached[self.driver] = true
				mcl_player.player_set_animation(clicker, "stand", 30)
			end
		end
	end,
	on_step = function(self, dtime)
		if not self.children_spawned then self:spawn_children() end
		local pos = self.object:get_pos()
		local yaw = self.object:get_yaw() or 0
		local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
		
		if caravel_ship.walkmap and caravel_ship.walkmap.process_passengers then
			caravel_ship.walkmap.process_passengers(self, dtime)
		end

		if not self.driver then
			if vector.length(vel) > 0 then self.object:set_velocity(vector.multiply(vel, 0.95)) end
			return
		end

		local pilot = minetest.get_player_by_name(self.driver)
		if not pilot then return end
		local ctrl = pilot:get_player_control()

		if ctrl.sneak then
			if mcl_player and mcl_player.player_attached then
				mcl_player.player_attached[self.driver] = false
			end
			local sin_y = math.sin(yaw)
			local cos_y = math.cos(yaw)
			
			self.driver = nil
			self.object:set_velocity({x = 0, y = 0, z = 0})
			
			minetest.after(0.1, function()
				if pilot and pilot:is_player() then
					pilot:set_detach()
					pilot:set_pos({x = pos.x - sin_y * -6.5, y = pos.y + 4.5, z = pos.z + cos_y * -6.5})
				end
			end)
			return
		end

		if ctrl.jump then
			if self.space_key_released then
				self.sails_hoisted = not self.sails_hoisted
				self.space_key_released = false
			end
		else
			self.space_key_released = true
		end

		local current_speed = vector.length(vel)
		local ship_dir = {x = math.sin(yaw), y = 0, z = -math.cos(yaw)}
		if vel.x * ship_dir.x + vel.z * ship_dir.z < 0 then current_speed = -current_speed end

		if ctrl.left then
			self.rudder_angle = math.min(self.rudder_angle + 1.5, 35)
			self.object:set_yaw(yaw + 0.03 * dtime * (current_speed + 0.5))
		elseif ctrl.right then
			self.rudder_angle = math.max(self.rudder_angle - 1.5, -35)
			self.object:set_yaw(yaw - 0.03 * dtime * (current_speed + 0.5))
		else
			self.rudder_angle = self.rudder_angle * 0.9
		end

		local target_speed = 0
		if self.sails_hoisted then
			if ctrl.up then
				target_speed = 8.5
			elseif ctrl.down then
				target_speed = -4.5
			else
				target_speed = current_speed * 0.98
			end
		else
			if ctrl.up then
				target_speed = 2.0
			elseif ctrl.down then
				target_speed = -1.5
			else
				target_speed = current_speed * 0.90
			end
		end

		local speed = current_speed + (target_speed - current_speed) * 0.05
		self.object:set_velocity({x = ship_dir.x * speed, y = vel.y, z = ship_dir.z * speed})

		self.object:set_bone_position("Rudder_Bone", {x = 0, y = 0, z = 0}, {x = 0, y = self.rudder_angle, z = 0})
	end,

	on_punch = function(self, puncher)
		if not puncher or not puncher:is_player() then return end
		
		if puncher:get_wielded_item():get_name() == "" and self.cannon_count > 0 then
			local inv = puncher:get_inventory()
			if inv and inv:room_for_item("main", "caravel_ship:cannon_barrel_item") then
				inv:add_item("main", "caravel_ship:cannon_barrel_item")
				self.cannon_count = self.cannon_count - 1
				if self.artillery_entity then
					local old_art = self.artillery_entity
					self.artillery_entity = nil
					old_art:remove()
				end
				if self.cannon_count > 0 then
					local c = minetest.add_entity(self.object:get_pos(), "caravel_ship:artillery_layer")
					if c then
						c:set_properties({
							mesh = "c_" .. self.cannon_count .. ".obj",
							textures = {"c_top.png", "c_bottom.png"}
						})
						c:set_attach(self.object, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
						self.artillery_entity = c
					end
				end
				return
			end
		end

		for _, d in ipairs(self.door_entities) do if d and d:get_luaentity() then d:remove() end end
		if self.artillery_entity then self.artillery_entity:remove() end
		if not minetest.settings:get_bool("creative_mode") then
			local inv = puncher:get_inventory()
			if inv and inv:room_for_item("main", "caravel_ship:ship") then
				inv:add_item("main", "caravel_ship:ship")
			end
			if self.cannon_count > 0 then
				if inv and inv:room_for_item("main", "caravel_ship:cannon_barrel_item " .. self.cannon_count) then
					inv:add_item("main", "caravel_ship:cannon_barrel_item " .. self.cannon_count)
				end
			end
		end
		self.object:remove()
	end
})

minetest.register_craftitem("caravel_ship:ship", {
	description = "Caravel Exploration Ship",
	inventory_image = "boat_inv.png",
	wield_image = "boat_inv.png",
	liquids_pointable = true,
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
		local pos = table.copy(pointed_thing.under)
		local node = minetest.get_node(pos)
		local nodedef = minetest.registered_nodes[node.name]
		if nodedef and nodedef.drawtype == "liquid" then
			pos.y = pos.y + 0.35
		else
			pos = pointed_thing.above
			pos.y = pos.y + 0.6
		end
		local ent = minetest.add_entity(pos, "caravel_ship:ship")
		if ent then
			ent:set_yaw(placer and placer:get_look_horizontal() or 0)
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
		end
		return itemstack
	end,
})
