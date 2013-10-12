This project adds [GorillaScript] support to the vim editor. It handles syntax,
indenting, compiling, and more. Also included is support for GorillaScript in
HTML.

[GorillaScript]: http://ckknight.github.io/gorillascript/

## Install with Unbundle

Since this plugin has rolling versions based on git commits, using unbundle and
git is the preferred way to install. The plugin ends up contained in its own
directory and updates are just a `git pull` away.

1. Git clone sunaku's [unbundle] into `~/.vim/bundle/` and add this line to your
   vimrc:

```vim
runtime bundle/vim-unbundle/unbundle.vim
syntax enable
filetype plugin indent on
```

[unbundle]: https://github.com/sunaku/vim-unbundle

2. Create and change into `~/.vim/ftbundle/gorilla`:

        $ mkdir -p ~/.vim/ftbundle/gorilla
        $ cd ~/.vim/ftbundle/gorilla

3. Make a clone of the `vim-gorilla-script` repository:

        $ git clone https://github.com/unc0/vim-gorilla-script.git

### Updating

1. Change into `~/.vim/ftbundle/gorilla/vim-gorilla-script/`:

        $ cd ~/.vim/ftbundle/gorilla/vim-gorilla-script

2. Pull in the latest changes:

        $ git pull

## Compile to JavaScript

A `gorilla` wrapper for use with `:make` is enabled automatically for gorilla
files if no other compiler is loaded. To enable it manually, run

    :compiler gorilla

The `:make` command is then configured to use the `gorilla` compiler and
recognize its errors. I've included a quick reference here but be sure to check
out [`:help :make`][make] for a full reference of the command.

[make]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#:make_makeprg

Consider the full signature of a `:make` call as

    :[silent] make[!] [GORILLA-OPTIONS]...

By default `:make` shows all compiler output and jumps to the first line
reported as an error. Compiler output can be hidden with a leading `:silent`:

    :silent make

Line-jumping can be turned off by adding a bang:

    :make!

`GORILLA-OPTIONS` given to `:make` are passed along to `gorilla` (see also
[`gorilla_make_options`](#gorilla_make_options)):

    :make --bare --output /some/dir

*Configuration*: [`gorilla_compiler`](#gorilla_compiler),
[`gorilla_make_options`](#gorilla_make_options)

### The quickfix window

Compiler errors are added to the [quickfix] list by `:make`, but the quickfix
window isn't automatically shown. The [`:cwindow`][cwindow] command will pop up
the quickfix window if there are any errors:

    :make
    :cwindow

This is usually the desired behavior, so you may want to add an autocmd to your
vimrc to do this automatically:

```vim
autocmd QuickFixCmdPost * nested cwindow | redraw!
```

The `redraw!` command is needed to fix a redrawing quirk in terminal vim, but
can removed for gVim.

[quickfix]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix
[cwindow]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#:cwindow

### Recompile on write

To recompile a file when it's written, add an `BufWritePost` autocmd to your
vimrc:

```vim
autocmd BufWritePost *.gs silent make!
```

## GorillaCompile: Compile GorillaScript Snippets

GorillaCompile shows how the current file or a snippet of GorillaScript is
compiled to JavaScript.

    :[RANGE] GorillaCompile [vert[ical]] [WINDOW-SIZE]

Calling `:GorillaCompile` without a range compiles the whole file.

Calling `:GorillaCompile` with a range, like in visual mode, compiles the selected
snippet of GorillaScript.

Each file gets its own GorillaCompile buffer, and the same buffer is used for all
future calls of `:GorillaCompile` on that file. It can be quickly closed by
hitting `q` in normal mode.

Using `vert` opens the GorillaCompile buffer vertically instead of horizontally
(see also [`gorilla_compile_vert`](#gorilla_compile_vert)):

    :GorillaCompile vert

Set the `gorilla_compile_vert` variable to split the buffer vertically by
default:

```vim
let gorilla_compile_vert = 1
```

By default the GorillaCompile buffer splits the source buffer in half, but this
can be overridden by passing in a `WINDOW-SIZE`:

    :GorillaCompile 4

*Configuration*: [`gorilla_compiler`](#gorilla_compiler`),
[`gorilla_compile_vert`](#gorilla_compile_vert)

### Quick syntax checking

If compiling a snippet results in a compiler error, GorillaCompile adds that
error to the [quickfix] list.

[quickfix]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix

## GorillaWatch: Live Preview Compiling

GorillaWatch emulates using the Try GorillaScript preview box on the [GorillaScript
homepage][GorillaScript].

GorillaWatch takes the same options as GorillaCompile:

    :GorillaWatch [vert[ical]] [WINDOW-SIZE]

After a source buffer is watched, leaving insert mode or saving the file fires
off a recompile of the GorillaScript.

You can force recompilation by calling `:GorillaWatch`.

To get synchronized scrolling of the source buffer and GorillaWatch buffer, set
[`'scrollbind'`](http://vimdoc.sourceforge.net/htmldoc/options.html#'scrollbind')
on each:

    :setl scrollbind

*Configuration*: [`gorilla_compiler`](#gorilla_compiler),
[`gorilla_watch_vert`](#gorilla_watch_vert)

## GorillaRun: Run GorillaScript Snippets

GorillaRun compiles the current file or selected snippet and runs the resulting
JavaScript.

The command has two forms:

    :GorillaRun [PROGRAM-OPTIONS]...

This form applies when no `RANGE` is given or when the given range is `1,$`
(first line to last line). It allows passing `PROGRAM-OPTIONS` to your compiled
program. The filename is passed directly to `gorilla` so you must save the file
for your changes to take effect.

    :RANGE GorillaRun [COFFEE-OPTIONS]...

This form applies with all other ranges. It compiles and runs the lines within
the given `RANGE` and any extra `COFFEE-OPTIONS` are passed to `gorilla`.

*Configuration*: [`gorilla_compiler`](#gorilla_compiler),
[`gorilla_run_vert`](#gorilla_run_vert)

## GorillaScript in HTML

GorillaScript is highlighted and indented within

```html
<script type="text/gorillascript">
</script>
```

blocks in html files.

## Custom Autocmds

You can [define commands][autocmd-explain] to be ran automatically on these
custom events.

In all cases, the name of the command running the event (`GorillaCompile`,
`GorillaWatch`, or `GorillaRun`) is matched by the [`{pat}`][autocmd] argument.
You can match all commands with a `*` or only specific commands by separating
them with a comma: `GorillaCompile,GorillaWatch`.

[autocmd-explain]: http://vimdoc.sourceforge.net/htmldoc/usr_40.html#40.3
[autocmd]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#:autocmd

### GorillaBufNew

GorillaBufNew is ran when a new scratch buffer is created. It's called from the
new buffer, so it can be used to do additional set up.

```vim
augroup GorillaBufNew
autocmd User * set wrap
augroup END
```

*Used By*: GorillaCompile, GorillaWatch, GorillaRun

### GorillaBufUpdate

GorillaBufUpdate is ran when a scratch buffer is updated with output from
`gorilla`. It's called from the scratch buffer, so it can be used to alter the
compiled output.

```vim
" Switch back to the source buffer after updating.
augroup GorillaBufUpdate
autocmd User GorillaCompile,GorillaRun exec bufwinnr(b:gorilla_src_buf) 'wincmd w'
augroup END
```

*Used By*: GorillaCompile, GorillaWatch, GorillaRun

## Configuration Variables

This is the full list of configuration variables available, with example
settings and default values. Use these in your vimrc to control the default
behavior.

#### gorilla\_indent\_keep\_current

By default, the indent function matches the indent of the previous line if it
doesn't find a reason to indent or outdent. To change this behavior so it
instead keeps the [current indent of the cursor][98], use

```vim
let gorilla_indent_keep_current = 1
```

[98]: https://github.com/kchmck/vim-gorilla-script/pull/98

*Default*: `unlet gorilla_indent_keep_current`

Note that if you change this after a gorilla file has been loaded, you'll have to
reload the indent script for the change to take effect:

```vim
unlet b:did_indent | runtime indent/gorilla.vim
```

#### gorilla\_compiler

Path to the `gorilla` executable used by the `Gorilla` commands:

```vim
let gorilla_compiler = '/usr/bin/gorilla'
```

*Default*: `'gorilla'` (search `$PATH` for executable)

#### gorilla\_make\_options

Options to pass to `gorilla` with `:make`:

```vim
let gorilla_make_options = '--bare'
```

*Default*: `''` (nothing)

Note that `gorilla_make_options` is embedded into `'makeprg'`, so `:compiler
gorilla` must be ran after changing `gorilla_make_options` for the changes to take
effect.

#### gorilla\_compile\_vert

Open the GorillaCompile buffer with a vertical split instead of a horizontal
one:

```vim
let gorilla_compile_vert = 1
```

*Default*: `unlet gorilla_compile_vert`

#### gorilla\_watch\_vert

Open the GorillaWatch buffer with a vertical split instead of a horizontal
one:

```vim
let gorilla_watch_vert = 1
```

*Default*: `unlet gorilla_watch_vert`

#### gorilla\_run\_vert

Open the GorillaRun buffer with a vertical split instead of a horizontal
one:

```vim
let gorilla_run_vert = 1
```

*Default*: `unlet gorilla_run_vert`

## Configure Syntax Highlighting

Add these lines to your vimrc to disable the relevant syntax group.

### Disable trailing whitespace error

Trailing whitespace is highlighted as an error by default. This can be disabled
with:

```vim
hi link GorillaSpaceError NONE
```

### Disable reserved words error

Reserved words like `function` and `var` are highlighted as an error where
they're not allowed in GorillaScript. This can be disabled with:

```vim
hi link gorillaReservedError NONE
```

## Tune Vim for GorillaScript

Changing these core settings can make vim more GorillaScript friendly.

### Fold by indentation

Folding by indentation works well for GorillaScript functions and classes.

To fold by indentation in GorillaScript files, add this line to your vimrc:

```vim
autocmd BufNewFile,BufReadPost *.gs setl foldmethod=indent nofoldenable
```

With this, folding is disabled by default but can be quickly toggled per-file
by hitting `zi`. To enable folding by default, remove `nofoldenable`:

```vim
autocmd BufNewFile,BufReadPost *.gs setl foldmethod=indent
```

### Two-space indentation

To get standard two-space indentation in GorillaScript files, add this line to
your vimrc:

```vim
autocmd BufNewFile,BufReadPost *.gs setl shiftwidth=2 expandtab
```

## Cooperate with other plugins

### [NERDCommenter]

```vim
let g:NERDCustomDelimiters.gorilla = {
  \ 'left': '//',
  \ 'leftAlt': '/*',
  \ 'rightAlt': '*/',
  \}
```

### [Phrase]

```vim
let g:phrase_ft_tbl.gorilla = {
  \ "ext": "gs",
  \ "cmt": ["/*", "*/"]
  \}
```

### [Syntastic]

*You should comment this autocmd out in your vimrc:*

```vim
" autocmd BufWritePost *.gs silent make!
```

1. Install Syntastic:

        $ cd ~/.vim/bundle
        $ git clone https://github.com/scrooloose/syntastic.git

2. Copy/link the checker to syntastic:

        $ mkdir -p syntastic/syntax_checkers/gorilla
        $ cd syntastic/syntax_checkers/gorilla
        $ ln -s ~/.vim/ftbundle/gorilla/vim-gorilla-script/syntastic_checker/gorilla.vim

### [Tagbar]

1. Install Tagbar:

        $ cd ~/.vim/bundle
        $ git clone https://github.com/majutsushi/tagbar.git

2. Add this to your .ctags:

        --langdef=gorilla
        --langmap=gorilla:.gs
        --regex-gorilla=/^let[ \t]+([A-Za-z0-9_$\-]+)[ \t]*=[ \t]*require/\1/e,module,modules/
        --regex-gorilla=/^let[ \t]+([A-Za-z0-9_$\-]+)[ \t]*=[ \t]*\{/\1/o,object,objects/
        --regex-gorilla=/^const[ \t]+([A-Z][A-Z0-9_\-]+)[ \t]*=/\1/C,constant,constants/
        --regex-gorilla=/^let[ \t]+([A-Za-z0-9_$\-]+)[ \t]*=[ \t]*#(\(.*\))?/\1/f,function,functions/
        --regex-gorilla=/^let[ \t]+([A-Za-z0-9_$\-]+)[ \t]*\(.*\)/\1/f,function,functions/
        --regex-gorilla=/^[^\/*]*class[ \t]+([A-Za-z0-9_$\-]+)/\1/c,class,classes/
        --regex-gorilla=/^[^\/*]*def[ \t]+([A-Za-z0-9_$\-]+)/\1/m,method,methods/
        --regex-gorilla=/^let[ \t]+([A-Za-z0-9_$\-]+)[ \t]*=[ \t]*\[/\1/a,array,arrays/
        --regex-gorilla=/^let[ \t]+([^= ]+)[ \t]*=[ \t]*r'[^']*/\1/r,regex,regexes/
        --regex-gorilla=/^let[ \t]+([^= ]+)[ \t]*=[ \t]*r"[^"]*/\1/r,regex,regexes/
        --regex-gorilla=/^let[ \t]+([^= ]+)[ \t]*=[ \t]*[^"r]'[^']*/\1/s,string,strings/
        --regex-gorilla=/^let[ \t]+([^= ]+)[ \t]*=[ \t]*[^'r]"[^"]*/\1/s,string,strings/

3. Add this to your .vimrc:

  ```vim
  let g:tagbar_type_gorilla = {
    \ 'ctagstype' : 'gorilla',
    \ 'kinds' : [
    \   'C:constant',
    \   'e:module',
    \   'f:function',
    \   'c:class',
    \   'a:array',
    \   'o:object',
    \   'r:regex',
    \   's:string'
    \ ],
    \ 'sro' : ".",
    \}
  ```

[NERDCommenter]: https://github.com/scrooloose/nerdcommenter
[Phrase]: https://github.com/t9md/vim-phrase
[Syntastic]: https://github.com/scrooloose/syntastic
[Tagbar]: https://github.com/majutsushi/tagbar
