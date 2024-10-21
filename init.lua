local function get_tabs()
	local len = #cx.tabs
	if len == 1 then
		return { cx.tabs[1], cx.tabs[1] }
	elseif len == 2 then
		return { cx.tabs[1], cx.tabs[2] }
	elseif cx.tabs.idx < len then
		return { cx.tabs[cx.tabs.idx], cx.tabs[cx.tabs.idx + 1] }
	else
		return { cx.tabs[cx.tabs.idx - 1], cx.tabs[cx.tabs.idx] }
	end
end

local Pane = {
	_id = "pane",
}

function Pane:new(area, tab, pane)
	local me = setmetatable({ _area = area, _tab = tab }, { __index = self })
	me:layout()
	me:build(pane)
	return me
end

function Pane:layout()
	self._chunks = ui.Layout()
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Length(1),
			ui.Constraint.Fill(1),
		})
		:split(self._area)

	self._tab_chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({ ui.Constraint.Length(0), ui.Constraint.Fill(1), ui.Constraint.Length(0) })
		:split(self._chunks[2])
end

function Pane:build(pane)
	local header = Header:new(self._chunks[1], self._tab)
	header.pane = pane

	local tab = setmetatable({
		_area = self._chunks[2],
		_tab = self._tab,
		_chunks = self._tab_chunks,
	}, { __index = Tab })
	Tab.build(tab)

	self._children = {
		header,
		tab,
	}
end

setmetatable(Pane, { __index = Root })

local Panes = {
	_id = "panes",
}

function Panes:new(area, tab_left, tab_right)
	local me = setmetatable({ _area = area }, { __index = self })
	me:layout()
	me:build(tab_left, tab_right)
	return me
end

function Panes:layout()
	self._chunks = ui.Layout()
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Fill(1),
			ui.Constraint.Length(1),
		})
		:split(self._area)

	self._panes_chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Percentage(50),
			ui.Constraint.Percentage(50),
		})
		:split(self._chunks[1])
end

function Panes:build(tab_left, tab_right)
	self._children = {
		Pane:new(self._panes_chunks[1], tab_left, 0),
		Pane:new(self._panes_chunks[2], tab_right, 1),
		Status:new(self._chunks[2], cx.active),
	}
end

setmetatable(Panes, { __index = Root })

local DualPane = {
	pane = nil,
	left = nil,
	right = nil,
	view = nil, -- 0 = dual, 1 = current zoomed

	old_root_layout = nil,
	old_root_build = nil,
	old_tab_layout = nil,
	old_header_cwd = nil,
	old_header_tabs = nil,

	_header_tab_inc = 0,

	_create = function(self)
		self.pane = 0
		if cx then
			self.left = cx.tabs.idx - 1
			if #cx.tabs > 1 then
				self.right = (self.left + 1) % #cx.tabs
			else
				self.right = self.left
			end
		else
			self.left = 0
			self.right = 0
		end

		self.old_root_layout = Root.layout
		self.old_root_build = Root.build
		self._config_dual_pane(self)

		self.old_header_cwd = Header.cwd
		Header.cwd = function(header)
			local max = header._area.w - header._right_width
			if max <= 0 then
				return ui.Span("")
			end

			local s = ya.readable_path(tostring(header._tab.current.cwd)) .. header:flags()
			if header.pane == self.pane then
				return ui.Span(ya.truncate(s, { max = max, rtl = true })):style(THEME.manager.tab_active)
			else
				return ui.Span(ya.truncate(s, { max = max, rtl = true })):style(THEME.manager.tab_inactive)
			end
		end

		self.old_header_tabs = Header.tabs

		Header:children_remove(2, Header.RIGHT)
		self._header_tab_inc = Header:children_add(function(self)
			local active = self._tab.idx == cx.tabs.idx
			return ui.Line(" " .. self._tab.idx .. " ")
				:style(active and THEME.manager.tab_active or THEME.manager.tab_inactive)
		end, 2, Header.RIGHT)
	end,

	_destroy = function(self)
		Root.layout = self.old_root_layout
		self.old_root_layout = nil
		Root.build = self.old_root_build
		self.old_root_build = nil
		Header.cwd = self.old_header_cwd
		self.old_header_cwd = nil
		Header.tabs = self.old_header_tabs
		self.old_header_tabs = nil

		Header:children_remove(self._header_tab_inc, Header.RIGHT)
		Header:children_add("tabs", 2, Header.RIGHT)
	end,

	_config_dual_pane = function(self)
		Root.layout = function(root)
			root._chunks = ui.Layout()
				:direction(ui.Layout.HORIZONTAL)
				:constraints({
					ui.Constraint.Percentage(100),
				})
				:split(root._area)
		end

		Root.build = function(root)
			local tabs = get_tabs()
			root._children = {
				Panes:new(root._chunks[1], tabs[1], tabs[2]),
			}
		end
	end,

	_config_single_pane = function(self)
		Root.layout = function(root)
			root._chunks = ui.Layout()
				:direction(ui.Layout.VERTICAL)
				:constraints({
					ui.Constraint.Fill(1),
					ui.Constraint.Length(1),
				})
				:split(root._area)
		end

		Root.build = function(root)
			local tab
			if self.pane == 0 then
				tab = cx.tabs[self.left + 1]
			else
				tab = cx.tabs[self.right + 1]
			end
			root._children = {
				Pane:new(root._chunks[1], tab, self.pane),
				Status:new(root._chunks[2], tab),
			}
		end
	end,

	toggle = function(self)
		if self.view == nil then
			self._create(self)
			self.view = 0
		else
			self._destroy(self)
			self.view = nil
		end
		ya.app_emit("resize", {})
	end,

	toggle_zoom = function(self)
		if self.view then
			if self.view == 0 then
				self._config_single_pane(self)
				self.view = 1
			else
				self._config_dual_pane(self)
				self.view = 0
			end
			ya.app_emit("resize", {})
		end
	end,

	-- Copy selected files, or if there are none, the hovered item, to the
	-- destination directory
	copy_files = function(self, cut, force, follow)
		if self.view then
			local src_tab, dst_tab
			if self.pane == 0 then
				src_tab = self.left
				dst_tab = self.right
			else
				src_tab = self.right
				dst_tab = self.left
			end
			-- yank selected
			if cut then
				ya.manager_emit("yank", { cut = true })
			else
				ya.manager_emit("yank", {})
			end
			-- select dst tab
			ya.manager_emit("tab_switch", { dst_tab })
			-- paste
			ya.manager_emit("paste", { force = force, follow = follow })
			-- unyank
			ya.manager_emit("unyank", {})
			-- select src tab again
			ya.manager_emit("tab_switch", { src_tab })
			ya.app_emit("resize", {})
		end
	end,
}

local function entry(_, args)
	local action = args[1]
	if not action then
		return
	end

	if action == "toggle" then
		DualPane:toggle()
		return
	end

	if action == "toggle_zoom" then
		DualPane:toggle_zoom()
		return
	end

	local function get_copy_arguments(args)
		local force = false
		local follow = false
		if args[2] then
			if args[2] == "--force" then
				force = true
			elseif args[2] == "--follow" then
				follow = true
			end
			if args[3] then
				if args[3] == "--force" then
					force = true
				elseif args[3] == "--follow" then
					follow = true
				end
			end
		end
		return force, follow
	end

	if action == "copy_files" then
		local force, follow = get_copy_arguments(args)
		DualPane:copy_files(false, force, follow)
	end

	if action == "move_files" then
		local force, follow = get_copy_arguments(args)
		DualPane:copy_files(true, force, follow)
	end

	if action == "tab_create" then
		if args[2] then
			local dir
			if args[2] == "--current" then
				dir = cx.active.current.cwd
			else
				dir = args[2]
			end
			ya.manager_emit("tab_create", { dir })
		else
			ya.manager_emit("tab_create", {})
		end
		-- TODO: remove DualPane.left/right
		if DualPane.pane == 0 then
			if DualPane.right > DualPane.left then
				DualPane.right = DualPane.right + 1
			end
		else
			if DualPane.left > DualPane.right then
				DualPane.left = DualPane.left + 1
			end
		end
	end
end

local function setup(_, opts)
	if opts and opts.enabled then
		DualPane:toggle()
	end
end

return {
	entry = entry,
	setup = setup,
}
