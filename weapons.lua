minetest.register_entity("caravel_ship:cannon_mesh", {
    initial_properties = {
        physical = false,
        collisionbox = {-0.4, -0.4, -0.6, 0.4, 0.4, 0.6},
        selectionbox = {-0.4, -0.4, -0.6, 0.4, 0.4, 0.6},
        visual = "mesh",
        mesh = "cannon_barrel.obj",
        textures = {"cannon_iron.png"},
    },
    side_angle = 0,
    slot_index = nil,
    parent_lua_ship = nil,
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end,
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local inv = clicker:get_inventory()
        if inv:contains_item("main", "mcl_core:gunpowder") or minetest.settings:get_bool("creative_mode") then
            if not minetest.settings:get_bool("creative_mode") then
                inv:remove_item("main", "mcl_core:gunpowder 1")
            end
            local pos = self.object:get_pos()
            local parent = self.object:get_attach()
            local ship_yaw = 0
            if parent then ship_yaw = parent:get_yaw() or 0 end
            local absolute_yaw = ship_yaw + math.rad(self.side_angle)
            local dir = {x = -math.sin(absolute_yaw), y = 0.1, z = math.cos(absolute_yaw)}
            local spawn_pos = {x = pos.x + dir.x * 1.5, y = pos.y + 0.4, z = pos.z + dir.z * 1.5}
            minetest.sound_play("mcl_fireworks_rocket_blast", {pos = pos, gain = 2.0})
            local ent = minetest.add_entity(spawn_pos, "mcl_explosives:tnt")
            if ent then
                ent:set_velocity(vector.multiply(dir, 24))
            end
        end
    end,
    on_punch = function(self, puncher)
        if not puncher or not puncher:is_player() then return end
        if self.parent_lua_ship and self.slot_index then
            if self.parent_lua_ship.cannon_slots[self.slot_index] then
                self.parent_lua_ship.cannon_slots[self.slot_index].occupied = false
            end
        end
        if not minetest.settings:get_bool("creative_mode") then
            local inv = puncher:get_inventory()
            if inv and inv:room_for_item("main", "caravel_ship:cannon_barrel_item") then
                inv:add_item("main", "caravel_ship:cannon_barrel_item")
            end
        end
        self.object:remove()
    end,
})

minetest.register_craftitem("caravel_ship:cannon_barrel_item", {
    description = "Cast Iron Cannon Barrel",
    inventory_image = "cannon_barrel_inv.png",
})

minetest.register_entity("caravel_ship:artillery_layer", {
	initial_properties = {
		physical = false,
		collisionbox = {0, 0, 0, 0, 0, 0},
		selectionbox = {0, 0, 0, 0, 0, 0},
		visual = "mesh",
		mesh = "c_1.obj",
		textures = {"c_top.png", "c_bottom.png"},
		pointable = false,
	},
	on_activate = function(self)
		self.object:set_armor_groups({immortal = 1})
	end,
})
