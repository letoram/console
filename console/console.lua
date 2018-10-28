local workspaces = {} -- use to track client states
local ws_index = 1 -- active workspace
local hotkey_modifier = "rshift"
local clipboard_last = ""

function console()
	KEYBOARD = system_load("builtin/keyboard.lua")() -- get a keyboard state machine
	system_load("builtin/mouse.lua")() -- get basic mouse button definitions
	KEYBOARD:load_keymap(get_key("keymap") or "devmaps/keyboard/default.lua")
	switch_workspace(ws_index)
end

function console_input(input)
-- apply the keyboard translation table to all keyboard (translated) input and forward
	if input.translated then
		KEYBOARD:patch(input)
		if valid_hotkey(input) then
			return
		end
	elseif input.mouse and input.digital and input.subid == MOUSE_MBUTTON then
		if input.active then
			clipboard_paste(clipboard_last)
		end
	end

	local target = workspaces[ws_index]
	if not target then
		return
	end
	target_input(target.vid, input)
end

-- find an empty workspace slot and assign / activate
function new_client(vid)
	if not valid_vid(vid) then
		return
	end
	local new_ws = find_free_space()

-- safe-guard against out of workspaces
	if not new_ws then
		delete_image(vid)
		return
	end

-- or assign and activate
	workspaces[new_ws] = { vid = vid, clipboard_temp = "" }
	switch_workspace(new_ws)
end

-- read configuration from database if its there, or use a default
-- e.g. arcan_db add_appl_kv console terminal env=LC_ALL=C:palette=solarized
function spawn_terminal()
	local term_arg = get_key("terminal") or "palette=solarized-white"
	return launch_avfeed(term_arg, "terminal", client_event_handler)
end

function client_event_handler(source, status)
-- Lost client, last visible frame etc. kept, and we get access to any exit-
-- message (last words) and so on here. Now, just clean up and remove any
-- tracking
	if status.kind == "terminated" then
		delete_image(source)
		local _, index = find_client(source)
		if index then
			workspaces[index] = nil
		end

-- this says that the 'storage' resolution has changed and might no longer be
-- synched with the 'presentation' resolution so it will be scaled and filtered,
-- explicitly resizing counteracts that. Resize will always be called the
-- first time a client has submitted a frame, so it can be used as a
-- connection trigger as well.
	elseif status.kind == "resized" then
		if not find_client(source) then
			new_client(source)
		end
		resize_image(source, status.width, status.height)

-- the 'preroll' state is the time to provide any starting state you'd like
-- the client to have access to immediately after the connection is activated

	elseif status.kind == "preroll" then
-- tell the client about the dimensions and density we'd prefer it to have,
-- these match whatever 'primary' display that arcan decided on
		target_displayhint(source,
			VRESW, VRESH, TD_HINT_IGNORE, {ppcm = VPPCM})

-- the client wish a new subwindow of a certain type, only ones we'll accept
-- now is a clipboard which is used for 'copy' operations
	elseif status.kind == "segment_request" and status.segkind == "clipboard" then

-- tell the client that we accept the new clipboard and assign its event handler
-- a dumb client could allocate more clipboards here, but we don't care about
-- tracking / limiting
		local vid = accept_target(clipboard_handler)
		if not valid_vid(vid) then
			return
		end
-- tie the lifespan of the clipboard to that of the parent
		link_image(vid, source)
	end
end

function switch_workspace(index)
-- hide the current one so we don't overdraw
	if workspaces[ws_index] then
		hide_image(workspaces[ws_index].vid)
	end

-- default-switch to empty workspace means spawning a terminal in it
	ws_index = index
	if not workspaces[ws_index] then
		spawn_terminal()
	end

	if workspaces[ws_index] and valid_vid(workspaces[ws_index].vid) then
		show_image(workspaces[ws_index].vid)
	end
end

-- scan the workspaces for one that hasn't been allocated yet,
-- bias towards the currently selected 'index'
function find_free_space()
	if not workspaces[ws_index] then
		return ws_index
	end

	for i=1,10 do
		if not workspaces[i] then
			return i
		end
	end
end

-- sweep the workspaces and look for an allocated one with a matching vid
function find_client(vid)
	for i=1,10 do
		if workspaces[i] and workspaces[i].vid == vid then
			return workspaces[i], i
		end
	end
end

function valid_hotkey(input)
-- absorb right-shift as our modifier key
	if decode_modifiers(input.modifiers, "") ~= hotkey_modifier then
		return false
-- only trigger on 'rising edge'
	elseif input.active then
		if input.keysym == KEYBOARD.v then
			clipboard_paste(clipboard_last)

-- covert Fn key to numeric index and switch workspace
		elseif input.keysym >= KEYBOARD.F1 and input.keysym <= KEYBOARD.F10 then
			switch_workspace(input.keysym - KEYBOARD.F1 + 1)
		end
	end

	return true
end

local clipboard_temp = ""
function clipboard_handler(source, status)
	if status.kind == "terminated" then
		delete_image(source)

-- A clipboard paste operation might be split multipart over multiple
-- messages, so we need to track its state and only 'promote' when we
-- have received all of them. To avoid a client- race the tracking is
-- done per- workspace.
	elseif status.kind == "message" then
		tbl, _ = find_client(image_parent(source))
		tbl.clipboard_temp = tbl.clipboard_temp .. status.message

-- Multipart set means that there are more to follow, with untrusted
-- clients - this should truncate / react on some size but we do not
-- do that here. Promote to the 'shared' paste slot.
		if not status.multipart then
			clipboard_last = tbl.clipboard_temp
			tbl.clipboard_temp = ""
		end
	end
end

-- Triggered by the 'paste' keybinding or mouse middle button press.
function clipboard_paste(msg)
	local dst_ws = workspaces[ws_index]
	if not dst_ws or not
		valid_vid(dst_ws.vid, TYPE_FRAMESERVER) or #clipboard_last == 0 then
		return false
	end

-- The client 'pasteboard' is allocated on demand, so if client
-- doesn't have one, reallocate again.
	if not valid_vid(dst_ws.clipboard) then
		dst_ws.clipboard = define_nulltarget(dst_ws.vid, "clipboard",
			function(source, status)
				if status.kind == "terminated" then
					delete_image(source)
				end
			end
		)
-- Frameserver allocations can always fail
		if not valid_vid(dst_ws.clipboard) then
			return
		end

-- And tie life-span to workspace video object
		link_image(dst_ws.clipboard, dst_ws.vid)
	end

	target_input(dst_ws.clipboard, msg)
end
