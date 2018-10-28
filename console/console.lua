local selected;

function console()
	KEYBOARD = system_load("builtin/keyboard.lua")() -- get a keyboard state machine
	system_load("builtin/mouse.lua")() -- get basic mouse button definitions
	KEYBOARD:load_keymap(get_key("keymap") or "devmaps/keyboard/default.lua")
	selected = spawn_terminal()
	show_image(selected)
end

function console_input(input)
-- apply the keyboard translation table to all keyboard (translated) input and forward
	if input.translated then
		KEYBOARD:patch(input)
	end
	target_input(selected, input)
end

-- read configuration from database if its there, or use a default
-- e.g. arcan_db add_appl_kv console terminal env=LC_ALL=C:palette=solarized
function spawn_terminal()
	local term_arg = get_key("terminal") or "palette=solarized-white"
	return launch_avfeed(term_arg, "terminal", client_event_handler)
end

function client_event_handler(source, status)
	if status.kind == "terminated" then
		return shutdown()

-- this says that the 'storage' resolution has changed and might no longer be
-- synched with the 'presentation' resolution so it will be scaled and filtered,
-- explicitly resizing counteracts that.
	elseif status.kind == "resized" then
		resize_image(source, status.width, status.height)

-- the 'preroll' state is the time to provide any starting state you'd like
-- the client to have access to immediately after the connection is activated

	elseif status.kind == "preroll" then
-- tell the client about the dimensions and density we'd prefer it to have,
-- these match whatever 'primary' display that arcan decided on
		target_displayhint(source,
			VRESW, VRESH, TD_HINT_IGNORE, {ppcm = VPPCM})
	end
end
