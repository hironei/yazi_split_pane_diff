local source = arg[1] or "pane-diff.yazi/main.lua"

local notifications = {}
local launched = {}
local successful_child = {}
function successful_child:wait()
	return { success = true, code = 0 }, nil
end

local spawn_result = { child = successful_child, err = nil }

ya = {
	sync = function(fn)
		return fn
	end,
	notify = function(notification)
		notifications[#notifications + 1] = notification
	end,
}

local command = {}
function command:arg(args)
	self.args = args
	return self
end

function command:spawn()
	launched[#launched + 1] = {
		program = self.program,
		args = self.args,
	}
	return spawn_result.child, spawn_result.err
end

function Command(program)
	return setmetatable({ program = program }, { __index = command })
end

local plugin = assert(loadfile(source))()

local function url(path, is_regular)
	return setmetatable({ path = path, is_regular = is_regular ~= false }, {
		__tostring = function(value)
			return value.path
		end,
	})
end

local function modern_url(path, is_regular)
	return setmetatable({ path = path, spec = { is_regular = is_regular ~= false } }, {
		__tostring = function(value)
			return value.path
		end,
	})
end

local function file(path, opts)
	opts = opts or {}
	return {
		url = opts.modern and modern_url(path, opts.is_regular) or url(path, opts.is_regular),
		cha = {
			is_dir = opts.is_dir or false,
			is_orphan = opts.is_orphan or false,
			is_block = opts.is_block or false,
			is_char = opts.is_char or false,
			is_fifo = opts.is_fifo or false,
			is_sock = opts.is_sock or false,
		},
	}
end

local function tab(selected, hovered)
	return {
		selected = selected or {},
		current = { hovered = hovered },
	}
end

local function reset()
	notifications = {}
	launched = {}
	spawn_result = { child = successful_child, err = nil }
end

local function run(tabs, active_index)
	tabs.idx = active_index or 1
	cx = { tabs = tabs }
	plugin.entry()
end

local function assert_equal(actual, expected, message)
	assert(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assert_notification(level, fragment)
	assert_equal(#notifications, 1, "notification count")
	assert_equal(notifications[1].level, level, "notification level")
	assert(notifications[1].content:find(fragment, 1, true), "notification did not contain: " .. fragment)
end

-- Cursor targets preserve spaces and Japanese characters as separate arguments.
reset()
run({
	tab({}, file([[C:\work\left pane\左.txt]])),
	tab({}, file([[C:\work\right pane\右.txt]])),
})
assert_equal(#notifications, 0, "success notification count")
assert_equal(launched[1].program, "git", "program")
assert_equal(launched[1].args[1], "difftool", "git subcommand")
assert_equal(launched[1].args[4], "--", "path separator")
assert_equal(launched[1].args[5], [[C:\work\left pane\左.txt]], "active path")
assert_equal(launched[1].args[6], [[C:\work\right pane\右.txt]], "other path")

-- One explicit selection takes precedence over the hovered file.
reset()
run({
	tab({ url([[C:\selected\one.txt]]) }, file([[C:\hovered\left.txt]])),
	tab({}, file([[C:\hovered\right.txt]])),
})
assert_equal(launched[1].args[5], [[C:\selected\one.txt]], "selected path")

-- Yazi 26.8.15 selected entries are File objects; use their URL, not the
-- wrapper's string representation, and preserve one selected file per pane.
reset()
run({
	tab({ file([[C:\selected\File entry\左.txt]], { modern = true }) }, file([[C:\hovered\left.txt]])),
	tab({ file([[C:\selected\other\右.txt]], { modern = true }) }, file([[C:\hovered\right.txt]])),
})
assert_equal(launched[1].args[5], [[C:\selected\File entry\左.txt]], "selected File path")
assert_equal(launched[1].args[6], [[C:\selected\other\右.txt]], "selected File path in other pane")

-- The active pane is always the first argument.
reset()
run({
	tab({}, file([[C:\first.txt]])),
	tab({}, file([[C:\second.txt]])),
}, 2)
assert_equal(launched[1].args[5], [[C:\second.txt]], "reversed active path")
assert_equal(launched[1].args[6], [[C:\first.txt]], "reversed other path")

-- Invalid target states do not launch a process.
reset()
run({ tab({}, file([[C:\left.txt]], { is_dir = true })), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "directory launch count")
assert_notification("warn", "ディレクトリは比較できません")

reset()
run({ tab({}, file([[C:\left.link]], { is_orphan = true })), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "orphan launch count")
assert_notification("warn", "シンボリックリンク先を解決できません")

reset()
run({ tab({ url([[C:\one.txt]]), url([[C:\two.txt]]) }, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "multiple selection launch count")
assert_notification("warn", "各ペインの選択ファイルは1つ")

reset()
run({ tab({}, nil), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "missing target launch count")
assert_notification("warn", "カーソル位置に比較対象がありません")

reset()
run({ tab({}, file([[C:\left.txt]])) })
assert_equal(#launched, 0, "wrong tab count launch count")
assert_notification("warn", "比較には2つのタブが必要です")

reset()
run({ tab({ url([[C:\directory]], false) }, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "selected directory launch count")
assert_notification("warn", "通常ファイルのみ比較できます")

reset()
run({ tab({ file([[C:\selected\special]], { modern = true, is_regular = false }) }, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 0, "selected File non-regular launch count")
assert_notification("warn", "通常ファイルのみ比較できます")

-- Process-start errors are converted to Yazi error notifications.
reset()
spawn_result = { child = nil, err = "git not found" }
run({ tab({}, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_equal(#launched, 1, "failed launch attempt count")
assert_notification("error", "git not found")

reset()
local failed_child = {}
function failed_child:wait()
	return { success = false, code = 3 }, nil
end
spawn_result = { child = failed_child, err = nil }
run({ tab({}, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_notification("error", "終了コード 3")

-- git difftool --no-index uses exit code 1 for differing files.
reset()
local differing_child = {}
function differing_child:wait()
	return { success = false, code = 1 }, nil
end
spawn_result = { child = differing_child, err = nil }
run({ tab({}, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_equal(#notifications, 0, "difference result notification count")

-- Wait failures remain visible as errors.
reset()
local wait_failed_child = {}
function wait_failed_child:wait()
	error("wait exploded")
end
spawn_result = { child = wait_failed_child, err = nil }
run({ tab({}, file([[C:\left.txt]])), tab({}, file([[C:\right.txt]])) })
assert_notification("error", "wait exploded")

print("pane-diff.yazi tests passed")
