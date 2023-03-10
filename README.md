# nvim-mail-merge

**nvim-mail-merge** is a small mail merge plugin ([Neovim](https://github.com/neovim/neovim) only) that I made for my personal use. It allows to convert in `html` a mail written in `markdown` format containing variables, and to send it to a list from a `csv` file.

For now, it works with [NeoMutt](https://github.com/neomutt), but I plan to integrate other cli email software later, feel free to open an issue if you are interested!

## Requirements

This plugin requires [pandoc](https://github.com/jgm/pandoc) and [NeoMutt](https://github.com/neomutt) configured correctly (see [.neomuttrc minimal example](https://github.com/martineausimon/nvim-mail-merge#neomuttrc-minimal-example)).

## Installation with config

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua 
{ 
  'martineausimon/nvim-mail-merge',
  ft = { 'markdown' },
  config = function()
    require('nvmm').setup({
      mappings = {
        attachment = "<leader>a",
        config = "<leader>c",
        preview = "<leader>p",
        send_all = "<leader>sa"
      },
      options = {
        tmp_folder = "/tmp/nvmm/", 
        neomutt_config = "$HOME/.neomuttrc",
        save_log = true,
        log_file = "./nvmm.log",
        date_format = "%Y-%m-%d"
      }
    })
  end
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { 'martineausimon/nvim-mail-merge',
  ft = { 'markdown' },
  config = function()
    require('nvmm').setup({
      mappings = {
        attachment = "<leader>a",
        config = "<leader>c",
        preview = "<leader>p",
        send_all = "<leader>sa"
      },
      options = {
        tmp_folder = "/tmp/nvmm/", 
        neomutt_config = "$HOME/.neomuttrc",
        save_log = true,
        log_file = "./nvmm.log",
        date_format = "%Y-%m-%d"
      }
    })
  end
}
```

## Usage

### 1) Create a .csv file containing the data of each contact

⚠ The first line of this file must contain the headers, and one of the headers must be exactly `MAIL` (containing the email address)

example : `/home/user/list.csv`

```csv
CIV,LASTNAME,FIRSTNAME,MAIL
M.,Doe,John,john.doe@example.com
Mrs.,Smith,Jane,jane.smith@example.com
M.,Cohn,Bob,bob.cohn@example.com
```
### 2) Write a template mail in markdown in NeoVim

Variables must be preceded by the symbol `$`

example : `nvim ~/template.md`

```markdown
Hello $CIV $LASTNAME,

[Your message]

Best regards,

[Your name]
```

**note : line breaks are automatic, and do not require two spaces.**

### 3) Configure the mail merge

In NeoVim, run the command `:NVMMConfig` (default mapping `<leader>c`) and enter the exact path of the csv file, then the subject of the mail. The subject can contain variables, always preceded by the symbol `$`.

### 4) Add attachment (optional)

Run `:NVMMAttachment` (default mapping `<leader>a`) to add attachment to your mail. It can be a complete path (e.g. `/home/user/file.pdf`) or a variable, completed from your csv file content (e.g. : `$ATT`).

### 5) Preview the sending

The `:NVMMPreview` function (default mapping `<leader>p`) allows you to preview the sending with the data of the second line of the csv file.

### 6) Send

Run the function `:NVMMSendAll` (default mapping `<leader>sa`)

### Log file

By default, NVMM writes a log file `./nvmm.log` with the date, subject and recipient's email when sending all.

### neomuttrc minimal example

This config works with a Gmail account, and [pass](https://wiki.archlinux.org/title/Pass) to keep your password encrypted. With Gmail you'll also need an [app password](https://support.google.com/accounts/answer/185833?hl=en).

Add this lines to your NeoMutt config file (default `$HOME/.neomuttrc`) :

```bash
set my_pass = `pass john.smith@gmail.com`
set from = "john.smith@gmail.com"
set realname = "John Smith"
set imap_user = "john.smith@gmail.com"
set imap_pass = $my_pass
set smtp_url = "smtps://john.smith@smtp.gmail.com"
set smtp_pass = $my_pass
set copy = no
```
