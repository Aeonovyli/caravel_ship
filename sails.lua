minetest.register_entity("caravel_ship:sail_entity", {
    initial_properties = {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        selectionbox = {0, 0, 0, 0, 0, 0},
        visual = "mesh",
        mesh = "main_sail.obj",
        textures = {"sail.png"},
    },
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end,
})
