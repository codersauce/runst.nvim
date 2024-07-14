local M = {}
local buffer_number = -1
local last_test = nil

function M.setup(opts)
	opts = opts or {}
end

local function get_params()
	local params = vim.lsp.util.make_position_params()
	params.textDocument = vim.lsp.util.make_text_document_params()
	return params
end

local function get_current_test_args()
	local params = get_params()
	local result = vim.lsp.buf_request_sync(0, "experimental/runnables", params, 1000)
	if result and result[1] and result[1].result then
		for _, runnable in ipairs(result[1].result) do
			if runnable.kind == "cargo" and runnable.args.executableArgs then
				local args = runnable.args.executableArgs
				-- Check if this is a specific test
				if #args >= 1 and args[1]:match("^[%w_:]+::[%w_]+$") and runnable.label:match("^test ") then
					return runnable.args
				end
			end
		end
	end
	return nil
end

local function get_current_test_regex()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

	-- Search for the #[test] attribute above the cursor
	for i = cursor_line, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
		if line:match("#%[test%]") then
			-- Found the test attribute, now look for the function name
			for j = i, cursor_line do
				line = vim.api.nvim_buf_get_lines(bufnr, j - 1, j, false)[1]
				local fn_name = line:match("fn%s+([%w_]+)%s*%(%s*%)%s*{?")
				if fn_name then
					return {
						cargoArgs = { "test", "--package", vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h:h:t"), "--lib" },
						executableArgs = { fn_name, "--exact", "--show-output" },
					}
				end
			end
			break
		end
	end
	return nil
end

local function append_to_buffer(bufnr, text)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		print("Buffer is not loaded.")
		return
	end
	local line_count = vim.api.nvim_buf_line_count(bufnr)
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
		vim.api.nvim_buf_set_option(buffer_number, "modifiable", true)
		vim.api.nvim_buf_set_option(buffer_number, "readonly", false)
		vim.api.nvim_buf_set_option(buffer_number, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buffer_number, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buffer_number, "swapfile", false)
		vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, data)
		local buffer_window = vim.api.nvim_call_function("bufwinid", { buffer_number })
		local buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
		vim.api.nvim_win_set_cursor(buffer_window, { buffer_line_count, 0 })
		vim.api.nvim_buf_set_option(buffer_number, "modifiable", false)
		vim.api.nvim_buf_set_option(buffer_number, "readonly", true)
	end
end

local function run_test(cmd)
	open_buffer(cmd)
	vim.fn.jobstart(cmd, {
		stdout_buffered = false,
		on_stdout = log,
	})
end

function M.run_test()
	local args
	if pcall(require, "lspconfig") then
		args = get_current_test_args()
	end
	if args == nil then
		print("LSP method failed or not available, falling back to regex method")
		args = get_current_test_regex()
	end
	if args == nil then
		print("No test found")
		return
	end
	local cmd = "cargo " .. table.concat(args.cargoArgs, " ") .. " -- " .. table.concat(args.executableArgs, " ")
	last_test = cmd
	run_test(cmd)
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
