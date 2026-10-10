caravel_ship = {}

caravel_ship.WIND_DIRECTION = {x = 1, z = 0}
caravel_ship.WIND_SPEED = 4.5

caravel_ship.dye_colors = {
    ["dye:white"] = "ffffff", ["dye:red"] = "ff0000", ["dye:blue"] = "0000ff",
    ["dye:green"] = "00ff00", ["dye:black"] = "222222", ["dye:yellow"] = "ffff00"
}

caravel_ship.bed_colors = {
    ["dye:white"] = "white", ["dye:red"] = "red", ["dye:blue"] = "blue",
    ["dye:green"] = "green", ["dye:black"] = "black", ["dye:yellow"] = "yellow"
}

minetest.register_entity("caravel_ship:door_child", {
    initial_properties = {
        physical = true,
        collisionbox = {-0.4, 0, -0.1, 0.4, 2, 0.1},
        selectionbox = {-0.4, 0, -0.1, 0.4, 2, 0.1},
        visual = "mesh",
        mesh = "door_spruce.obj",
        textures = {"door_top.png", "door_bottom", "door_top_top"},
    },
    state_open = false,
    parent_ship = nil,
    local_offset = {x=0, y=0, z=0},
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end,
    on_rightclick = function(self, clicker)
        if not self.parent_ship or not self.parent_ship:get_pos() then return end
        self.state_open = not self.state_open
        if self.state_open then
            self.object:set_attach(self.parent_ship, "", self.local_offset, {x=0, y=90, z=0})
            minetest.sound_play("mcl_doors_spruce_open", {object = self.object})
        else
            self.object:set_attach(self.parent_ship, "", self.local_offset, {x=0, y=0, z=0})
            minetest.sound_play("mcl_doors_spruce_close", {object = self.object})
        end
    end,
})

minetest.register_entity("caravel_ship:bed_child", {
    initial_properties = {
        physical = true,
        collisionbox = {-0.5, -0.5, -1, 0.5, 0.5, 1},
        selectionbox = {-0.5, -0.5, -1, 0.5, 0.5, 1},
        visual = "mesh",
        mesh = "bed.obj",
        textures = {"bed_white.png"},
    },
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end,
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local item = clicker:get_wielded_item()
        local item_name = item:get_name()
        if caravel_ship.bed_colors[item_name] then
            local color = caravel_ship.bed_colors[item_name]
            self.object:set_properties({textures = {"bed_" .. color .. ".png"}})
            if not minetest.settings:get_bool("creative_mode") then
                item:take_item()
                clicker:set_wielded_item(item)
            end
            return
        end
        if mcl_beds and mcl_beds.on_rightclick then
            local pos = self.object:get_pos()
            mcl_beds.on_rightclick(pos, clicker)
        end
    end,
})

local modpath = minetest.get_modpath("caravel_ship")
dofile(modpath .. "/weapons.lua")
dofile(modpath .. "/ship.lua")
dofile(modpath .. "/sails.lua")