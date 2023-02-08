return require("telescope").register_extension({
	setup = function(ext_config, config)
		-- access extension config and user config
	end,
	exports = {
		syntax = require("telescope-misc").syntax,
		extensions = require("telescope-misc").extensions,
		namespaces = require("telescope-misc").namespaces,
		augroups = require("telescope-misc").augroups,
		options = require("telescope-misc").options,
	},
})
