--- @since 26.5.6

local messages = {
	title = "Pane diff",
	wrong_tab_count =
		"比較には2つのタブが必要です。split-tabsを有効にしてください。",
	missing_target = "カーソル位置に比較対象がありません。",
	multiple_selection = "各ペインの選択ファイルは1つにしてください。",
	tab_unavailable = "比較対象のタブを取得できませんでした。",
	directory = "ディレクトリは比較できません。",
	non_regular = "通常ファイルのみ比較できます。",
	orphan = "シンボリックリンク先を解決できません。",
	selected_unavailable = "選択ファイルを取得できませんでした。",
	process_unavailable = "Diffツールのプロセスを開始できませんでした。",
	launch_failed = "Diffツールを起動できませんでした: ",
	wait_failed = "Diffツールの実行状態を取得できませんでした: ",
	process_failed = "Diffツールが異常終了しました: ",
}

local function notify(level, content)
	ya.notify {
		title = messages.title,
		content = content,
		timeout = level == "error" and 7 or 5,
		level = level,
	}
end

local function count_selected(selected)
	local count = 0

	for _ in pairs(selected or {}) do
		count = count + 1
	end

	return count
end

local function get_single_selected(selected)
	for _, url in pairs(selected or {}) do
		return url
	end

	return nil
end

local function validate_url(url)
	if not url then
		return nil, messages.selected_unavailable
	end

	-- Url.is_regular is part of the current Yazi plugin API. A false value
	-- means the selected URL is not a regular file (for example a directory).
	if url.is_regular == false then
		return nil, messages.non_regular
	end

	return tostring(url), nil
end

local function validate_hovered(hovered)
	if not hovered then
		return nil, messages.missing_target
	end

	local cha = hovered.cha
	if cha then
		if cha.is_dir then
			return nil, messages.directory
		end

		if cha.is_orphan then
			return nil, messages.orphan
		end

		if cha.is_block or cha.is_char or cha.is_fifo or cha.is_sock then
			return nil, messages.non_regular
		end
	end

	return validate_url(hovered.url)
end

local function get_target_from_tab(tab)
	local selected_count = count_selected(tab.selected)

	if selected_count == 1 then
		return validate_url(get_single_selected(tab.selected))
	end

	if selected_count > 1 then
		return nil, messages.multiple_selection
	end

	return validate_hovered(tab.current and tab.current.hovered)
end

local get_compare_targets = ya.sync(function()
	if #cx.tabs ~= 2 then
		return nil, nil, messages.wrong_tab_count
	end

	local active_index = cx.tabs.idx
	local other_index = active_index == 1 and 2 or 1
	local active_tab = cx.tabs[active_index]
	local other_tab = cx.tabs[other_index]

	if not active_tab or not other_tab then
		return nil, nil, messages.tab_unavailable
	end

	local active_path, active_error = get_target_from_tab(active_tab)
	if not active_path then
		return nil, nil, "アクティブペイン: " .. tostring(active_error)
	end

	local other_path, other_error = get_target_from_tab(other_tab)
	if not other_path then
		return nil, nil, "反対側ペイン: " .. tostring(other_error)
	end

	return active_path, other_path, nil
end)

local function launch_diff(file1, file2)
	return Command("git")
		:arg {
			"difftool",
			"--no-index",
			"--no-prompt",
			"--",
			file1,
			file2,
		}
		:spawn()
end

local function monitor_diff(child)
	local ok, status, wait_error = pcall(function()
		return child:wait()
	end)

	if not ok then
		notify("error", messages.wait_failed .. tostring(status))
		return
	end

	if wait_error then
		notify("error", messages.wait_failed .. tostring(wait_error))
		return
	end

	if status and not status.success then
		notify("error", messages.process_failed .. "終了コード " .. tostring(status.code))
	end
end

local function entry()
	local active_path, other_path, target_error = get_compare_targets()
	if target_error then
		notify("warn", target_error)
		return
	end

	-- Protect the plugin from API/runtime errors while starting an external
	-- process. Paths are still passed as separate arguments to Command.
	local ok, child, launch_error = pcall(launch_diff, active_path, other_path)
	if not ok then
		notify("error", messages.launch_failed .. tostring(child))
		return
	end

	if launch_error then
		notify("error", messages.launch_failed .. tostring(launch_error))
		return
	end

	if not child then
		notify("error", messages.process_unavailable)
		return
	end

	monitor_diff(child)
end

return {
	entry = entry,
}
