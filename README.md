# nvim-mail-merge

**nvim-mail-merge** is a small mail merge plugin for [Neovim](https://github.com/neovim/neovim). It is primarily designed to work with [NeoMutt](https://github.com/neomutt) by default but also offers support for [mailx](https://linux.die.net/man/1/mailx). This plugin can send emails in either HTML format (`neomutt` only) or plain text.

## FEATURES

* **Create an individual and personalized message for each recipient of a .csv file**:  
Prepare a `.csv` file including the `MAIL` field along with variables of your choice. `nvim-mail-merge` automatically fills in the information based on your values for personalized emails.
* **Converts and sends an email written in Markdown to HTML format**:  
Write your email using the standard Markdown syntax. `nvim-mail-merge` converts it to HTML format for optimal formatting of your message (`neomutt` only).
* **Sends plain text format emails** using either `neomutt` or `mailx`.
* **Preview** the fully merged email before sending to ensure everything looks as expected.
* **Save the history of sent emails** (date, subject, email)
* **Monitor the progress of deliveries and view encountered errors** in the quickfix window.

## REQUIREMENTS

This plugin requires :

* [pandoc](https://github.com/jgm/pandoc) for HTML format emails
* [NeoMutt](https://github.com/neomutt) configured correctly (see [.neomuttrc minimal example](https://github.com/martineausimon/nvim-mail-merge#neomuttrc-minimal-example))
* For plain text format emails, you also have the option to use [mailx](https://linux.die.net/man/1/mailx), which might be faster

## INSTALLATION WITH CONFIG

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua 
{ 
  'martineausimon/nvim-mail-merge',
  ft = { 'markdown' }, --optional
  config = function()
    require('nvmm').setup({
      mappings = {
        attachment = "<leader>a",
        config = "<leader>c",
        preview = "<leader>p",
        send_text = "<leader>st",
        send_html = "<leader>sh",
      },
      options = {
        mail_client = {
          text = "neomutt", -- or "mailx"
          html = "neomutt"
        },
        auto_break_md = true, -- line breaks without two spaces for markdown
        neomutt_config = "$HOME/.neomuttrc",
        mailx_account = nil, -- if you use different accounts in .mailrc
        save_log = true,
        log_file = "./nvmm.log",
        date_format = "%Y-%m-%d"
      }
    })
  end
}
```

To monitor the progress of deliveries and view encountered errors, you can manually open quickfix with `:copen` (see [:h quickfix](https://vimhelp.org/quickfix.txt.html#quickfix)), or add this autocommand to your `init.lua` :

```lua
vim.api.nvim_create_autocmd('QuickFixCmdPost', { 
  command = "cwindow",
  pattern = "*"
})
```

## USAGE

### DIRECT SEND

This plugin can directly send the buffer to specified recipient(s) (comma separated emails if several) with these commands :

`:NVMMSendText charlie.haden@aol.com,paul.motian@yahoo.fr` (send the buffer in plain text format)  

`:NVMMSendHtml charlie.haden@aol.com,paul.motian@yahoo.fr` (convert buffer from markdown to html and send)

### MAIL MERGE

#### 1) Create a .csv file containing the data of each contact

⚠ The first line of this file must contain the headers, and one of the headers must be exactly `MAIL` (containing the email address)

example : `/home/user/list.csv`

```csv
CIV,LASTNAME,FIRSTNAME,MAIL
M.,Tyner,Mc Coy,mccoy.tyner@gmail.com
Mrs.,Garrison,Jimmy,jimmy.garrison@caramail.com
M.,Jones,Elvin,elvin.jones@yahoo.com
```
#### 2) Write a template mail in markdown in NeoVim

Variables must be preceded by the symbol `$`

example : `nvim ~/template.md`

```markdown
Hello $CIV $LASTNAME,

Your message

Best regards,

Your name
```

#### 3) Configure the mail merge

In NeoVim, run the command `:NVMMConfig` (default mapping `<leader>c`) and enter the exact path of the csv file, then the subject of the mail. The subject can contain variables, always preceded by the symbol `$`.

#### 4) Add attachment (optional)

Run `:NVMMAttachment` (default mapping `<leader>a`) to add attachment to your mail. It can be a complete path (e.g. `/home/user/file.pdf`) or a variable, completed from your csv file content (e.g. : `$ATT`).

#### 5) Preview the sending

The `:NVMMPreview` function (default mapping `<leader>p`) allows you to preview the sending with the data of the first recipient of the csv file.

#### 6) Send

Run one of the following commands :

`:NVMMSendText` (default `<leader>st`)  
`:NVMMSentHtml` (default `<leader>sh`)

#### Log file

By default, NVMM writes a log file `./nvmm.log` with the date, format (text or html), subject and recipient's email when sending all.

## TIPS AND TRICKS

### neomuttrc minimal example

This config works with a Gmail account, and [pass](https://wiki.archlinux.org/title/Pass) to keep your password encrypted. With Gmail you'll also need an [app password](https://support.google.com/accounts/answer/185833?hl=en).

Add this lines to your NeoMutt config file (default `$HOME/.neomuttrc`) :

```bash
set my_pass = `pass eric.dolphy@gmail.com`
set from = "eric.dolphy@gmail.com"
set realname = "Eric Dolphy"
set imap_user = "eric.dolphy@gmail.com"
set imap_pass = $my_pass
set smtp_url = "smtps://eric.dolphy@smtp.gmail.com"
set smtp_pass = $my_pass
set copy = no
```

### mailx minimal config example

This config works with a Gmail account. With Gmail you'll also need an [app password](https://support.google.com/accounts/answer/185833?hl=en).

Add this lines to your mailx config file (`$HOME/.mailrc`) :

* one account :

```bash
set v15-compat
set from="jim.hall@gmail.com(Jim Hall)"
set smtp-use-starttls
set smtp-auth=login
set mta=smtps://jim.hall:app_password@smtp.gmail.com:465
```

* multiple accounts :  

Don't forget to set `mailx_account` in `setup()` function

```bash
account main {
  set v15-compat
  set from="jim.hall@gmail.com(Jim Hall)"
  set smtp-use-starttls
  set smtp-auth=login
  set mta=smtps://jim.hall:app_password@smtp.gmail.com:465
}

account anotheraccount {
  set v15-compat
  set from="ron.carter@gmail.com(Ron Carter)"
  set smtp-use-starttls
  set smtp-auth=login
  set mta=smtps://ron.carter:app_password@smtp.gmail.com:465
}
```
