local M = {}
local buffer_number = -1
local last_test = nil

function M.setup(opts)
	opts = opts or {}
end

local function current_test_name()
	-- Get the current buffer and cursor position
	local bufnr = vim.api.nvim_get_current_buf()
	---@diagnostic disable-next-line: deprecated
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

	local function_declaration_line = 0
	local function_name = ""

	-- Check lines above the cursor for the #[test] attribute and function definition
	for i = row, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]

		-- Check for function start and capture the function name
		if line:match("^%s*fn%s") then
			function_declaration_line = i
			function_name = line:match("^%s*fn%s([%w_]+)%s*%(")
			break
		end
	end

	for i = function_declaration_line, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
		if line:match("^%s*#%[test%]") then
			return function_name
		end
	end

	return nil
end

local function append_to_buffer(bufnr, text)
	-- Check if the buffer exists and is loaded
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		print("Buffer is not loaded.")
		return
	end

	-- Determine the last line of the buffer
	local line_count = vim.api.nvim_buf_line_count(bufnr)

	-- Append the text to the buffer
	-- If `text` is a string, convert it to a table with one element
	if type(text) == "string" then
		text = { text }
	end
	vim.api.nvim_buf_set_lines(bufnr, line_count, -1, false, text)
end

local function open_buffer(cmd)
	local buffer_visible = vim.api.nvim_call_function("bufwinnr", { buffer_number }) ~= -1

	if buffer_number == -1 or not buffer_visible then
		vim.api.nvim_command("botright split " .. last_test)
		buffer_number = vim.api.nvim_get_current_buf()

		append_to_buffer(buffer_number, "Running: " .. cmd)
		vim.api.nvim_command("resize 10")
		vim.api.nvim_command("wincmd p")
	end
end

local function log(_, data)
	if data then
		-- Make it temporarily writable so we don't have warnings.
		vim.api.nvim_buf_set_option(buffer_number, "modifiable", true)
		vim.api.nvim_buf_set_option(buffer_number, "readonly", false)
		vim.api.nvim_buf_set_option(buffer_number, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buffer_number, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buffer_number, "swapfile", false)

		-- Append the data.
		vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, data)

		-- Get the window the buffer is in and set the cursor position to the bottom.
		local buffer_window = vim.api.nvim_call_function("bufwinid", { buffer_number })
		local buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
		vim.api.nvim_win_set_cursor(buffer_window, { buffer_line_count, 0 })

		-- Mark as not modified, otherwise you'll get an error when
		-- attempting to exit vim.
		vim.api.nvim_buf_set_option(buffer_number, "modifiable", false)
		vim.api.nvim_buf_set_option(buffer_number, "readonly", true)
	end
end

local function run_test(test_name)
	local cmd = "cargo test -- " .. test_name .. " --nocapture 2>&1"
	open_buffer(cmd)
	vim.fn.jobstart(cmd, {
		stdout_buffered = false,
		on_stdout = log,
		-- on_stderr = log,
	})
end

function M.run_test()
	local test_name = current_test_name()

	if test_name == nil then
		print("No test found")
		return
	end

	last_test = test_name
	run_test(test_name)
end

function M.run_last_test()
	if last_test == nil then
		print("No last test found")
		return
	end

	run_test(last_test)
end

function M.close()
	if buffer_number ~= -1 then
		vim.api.nvim_command("bd! " .. buffer_number)
		buffer_number = -1
	end
end

vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>lua require'runst'.run_test()<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap(
	"n",
	"<leader>tl",
	"<cmd>lua require'runst'.run_last_test()<cr>",
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap("n", "<leader>tc", "<cmd>lua require'runst'.close()<cr>", { noremap = true, silent = true })

return M
