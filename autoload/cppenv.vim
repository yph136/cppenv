"if exists("g:loaded_cppenv")
"    finish
"endif
"let g:loaded_cppenv = 1

let s:indent_space = repeat(' ', 4)

func! cppenv#dummy()
endfunc

func! cppenv#warn(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl NONE
endfunc

" comment one line code
func! cppenv#comment()
    let line_info = getline('.')
    "if line_info =~ '^\s*$'
    "   let indent_n = cindent(line('.') - 1)
    "   let line_info = repeat(' ', indent_n)
    "endif
    
    "let new_info = substitute(line_info, '\s*', '\0//', "")
    let new_info = '//' . line_info
    call setline('.', new_info)
endfunc

" uncomment one line code
func! cppenv#uncomment()
    let line_info = getline('.')
    "echo line_info
    if line_info =~ '^\s*//'
        let result = substitute(line_info, "///*", "", "")
        call setline('.', result)
    endif
endfunc

" auto complete () [] {}
func! cppenv#auto_brackets(bracket)
    let line_info = getline('.')
    let pos = getpos('.')
    if empty(line_info)
        let line_info = line_info . a:bracket
        " indent
        noremap <C-a>auto ==a
    elseif len(line_info) <= pos[2]
        let line_info = line_info . a:bracket
        noremap <C-a>auto a
    elseif line_info[pos[2]] == a:bracket[1]
        let n1 = cppenv#strcount(line_info, a:bracket[0])
        let n2 = cppenv#strcount(line_info, a:bracket[1])
        if n1 < n2
            let line_info = strpart(line_info, 0, pos[2]) . a:bracket[0] . strpart(line_info, pos[2])
        else
            let line_info = strpart(line_info, 0, pos[2]) . a:bracket . strpart(line_info, pos[2])
        endif
        noremap <C-a>auto a
    else
        let line_info = strpart(line_info, 0, pos[2]) . a:bracket[0] . strpart(line_info, pos[2])
        noremap <C-a>auto a
    endif

    call setline('.', line_info)
    let pos[2] = pos[2] + 1
    call setpos('.', pos)
endfunc

func! cppenv#strcount(str, c)
    let n = 0
    let iter = 0
    while iter < strlen(a:str)
        let s:char = a:str[iter]
        if s:char == a:c
            let n += 1
        endif
        let iter += 1
    endwhile
    return n
endfunc

" end () [] {}
func! cppenv#end_brackets(bracket)
    let line_info = getline('.')
    let pos = getpos('.')
    let active = 1
    "if empty(line_info)
    "    let active = 0
    "elseif line_info[pos[2]] == a:bracket[1]
    "    let active = 1
    "endif
    
    let n1 = cppenv#strcount(line_info, a:bracket[0])
    let n2 = cppenv#strcount(line_info, a:bracket[1])
    if line_info[pos[2]] == a:bracket[1] && n1 <= n2
        let active = 0
    endif

    let bracket = active == 1 ? a:bracket[1] : ''
    let result = strpart(line_info, 0, pos[2]) . bracket . strpart(line_info, pos[2])
    call setline('.', result)
    let pos[2] = pos[2] + 1
    call setpos('.', pos)
endfunc

let s:pos_back=[0,0,0,0]
let s:mapping = 0

func! cppenv#back_imode_cursor()
    let s:pos_back=getpos('.')
    let s:mapping = 0
    return ''
endfunc

func! cppenv#restore_imode_cursor()
    call setpos('.', s:pos_back)
    let pos = getpos('.')
    if s:mapping == 1
        return
    endif

    "if pos[2] < s:pos_back[2]
    "    noremap <C-a>i a
    "else
        noremap <C-a>i i
    "endif
endfunc

func! cppenv#onEnter()
    let pos = getpos('.')
    let line1 = getline(pos[1] - 1)
    let line2 = getline('.')

    " trimspace
    let idx = 0
    let start = 0
    while idx < strlen(line2)
        if line2[idx] =~ '\s'
            let start += 1
        else
            break
        endif
        let idx += 1
    endw
    let line2 = strpart(line2, start)
    let line_info = line1 . line2
    "echo line_info
    "redir ""

    let s:bracket = ""
    if line2 =~ '}' && line_info =~ '{}\s*$'
        let s:bracket = "{}"
    elseif line2 =~ ')' && line_info =~ '^import\s*()\s*$'
        let s:bracket = "()"
        echo "match"
    endif

    " 分行
    if s:bracket != ""
        " for cpp
        if line_info =~ '^\s*{}\s*$' && pos[1] > 1
            let prev_line_info = getline(pos[1] - 1)
            if prev_line_info =~ '^\s*\(class\|struct\|union\)\s\+[^{}]*$' || prev_line_info =~ '^.*=\s*$' || prev_line_info =~ '^\s*go\s\+\[.*\][^{}]*$'
                call setline('.', line2 . ";")
            endif
        elseif line_info =~ '^\(\s*\|.*\s\+\)\(class\|struct\|union\)\s\+\(\w\|\d\|_\)\+\s*{}\s*$' || line_info =~ '^.*=\s*{}\s*$' || line_info =~ '^\s*go\s\+\[.*\][^{}]*{}$'
            call setline('.', line2 . ";")
        endif

        " for go.import
        " nothing need to do

        call append(pos[1] - 1, "")
        let s:mapping = 1
        noremap <C-a>i S
    else
        echo "normal enter"
        let s:mapping = 1
        if line2 =~ "^\s*$"
            noremap <C-a>i S
        else
            noremap <C-a>i i
        endif
    endif
    "redir ""
endfunc

let g:py_dir = fnamemodify(expand('<sfile>'), ':p:h:gs?\\?/?')
let g:pyclang_dir = fnamemodify(expand('<sfile>'), ':p:h:h:gs?\\?/?') . '/pyclang'

" switch in .h/.hpp/.inl/.cpp/.c/.cc files
" @up_deep: 向上搜索的深度(等于-1时, 用locate命令全局搜索)
" @down_deep：向下搜索的深度
" @vsplit: 是否拆分出新的窗口
func! cppenv#switch_dd(up_deep, down_deep, vsplit)
    let s:abs_filename = expand('%:p')
    let s:directory = expand('%:p:h')
    let s:extension = expand('%:e')
    let s:filename = expand('%:r')
    let s:extension_list = ['h', 'hpp', 'ipp', 'inl', 'c', 'cc', 'cpp']

    let s:extension_expr = '^\('
    for ext in s:extension_list
        let s:extension_expr = s:extension_expr . ext . '\|'
    endfor
    let s:extension_expr = s:extension_expr[:-3] . '\)$'
    "echo(s:extension_expr)

    if a:up_deep >= 0 && s:extension =~ s:extension_expr
        exec(':pyf ' . g:py_dir . '/switch_dd.py')
        return 
    elseif a:up_deep == -1
        let s:grep_pattern = ''
        for ext in s:extension_list
            let s:grep_pattern = s:grep_pattern . '\(\/' . s:filename . '\\.' . ext . '\)' . '\|'
        endfor
        let s:grep_pattern = s:grep_pattern[:-3]

        let s:command = 'locate ' . s:filename . ' | grep -E ' . s:grep_pattern
        let s:locate_result = system(s:command)
        let s:abs_path_list = split(s:locate_result)

        if len(s:abs_path_list) > 1
            exec(':cexpr ""')
            for abs_path in s:abs_path_list
                let s:ccmd = ':caddexpr "' . abs_path . ':1:-"'
                if s:abs_filename == abs_path
                    let s:ccmd = s:ccmd[:-2] . ' <<<<"'
                endif
                exec(s:ccmd)
            endfor
            exec(':cw')
        endif
    endif

    echo('Not find switch files.')
endfunc

" switch to .proto files
func! cppenv#switch_proto()
    let s:filename = expand('%:r:r')
    let s:protofile = s:filename . '.proto'
    exec(':e ' . s:protofile)
endfunc

""""""""""""""""""""maps"""""""""""""""""""""
let s:is_infect = 0

func! cppenv#test_expr()
    return '###'
endfunc

func! cppenv#infect()
    let s:is_infect = 1

    map <C-k> :call cppenv#comment()<CR>
    imap <C-k> <Esc>:call cppenv#comment()<CR>

    map <C-u> :call cppenv#uncomment()<CR>
    imap <C-u> <Esc>:call cppenv#uncomment()<CR>

    imap <expr> <C-a>b cppenv#back_imode_cursor()
    map <C-a>r :call cppenv#restore_imode_cursor()<CR><C-a>i
    "imap <C-a>i "was setting in func! restore_imode_cursor()"
    
    cnoremap <C-a>cr <CR>
    inoremap <C-a>cr <CR>
    " use =j to indent below line '}'
    "imap <C-a>= <C-a>b<ESC>==<C-a>r
    "imap <C-l> <C-a>b<ESC>:call cppenv#enter()<C-a>cr<C-a>r<C-a>=<C-a>cr
    "imap <C-l> <C-a>cr<C-a>b<ESC>ko
    imap <C-l> <C-a>cr<C-a>b<ESC>:call cppenv#onEnter()<C-a>cr<C-a>r

    "imap ( <Esc>:call cppenv#auto_brackets('()')<CR>a
    "imap [ <Esc>:call cppenv#auto_brackets('[]')<CR>a
    "imap { <Esc>:call cppenv#auto_brackets('{}')<CR>a
    
    imap ( <Esc>:call cppenv#auto_brackets('()')<CR><C-a>auto
    imap [ <Esc>:call cppenv#auto_brackets('[]')<CR><C-a>auto
    imap { <Esc>:call cppenv#auto_brackets('{}')<CR><C-a>auto

    imap ) <Esc>:call cppenv#end_brackets('()')<CR>a
    imap ] <Esc>:call cppenv#end_brackets('[]')<CR>a
    imap } <Esc>:call cppenv#end_brackets('{}')<CR>a


    if has("unix")
        "imap < <Esc>:call cppenv#auto_brackets('<>')<CR><C-a>auto
        "imap > <Esc>:call cppenv#end_brackets('<>')<CR><C-a>auto

        imap <CR> <C-l>

        "inoremap <expr> G cppenv#test_expr()
        "imap F G<CR>
    endif

    map gp :call cppenv#switch_proto()<CR>
    map gs :call cppenv#switch_dd(0, 0, 0)<CR>
    map gns :call cppenv#switch_dd(2, 2, 0)<CR>
    map gvs :call cppenv#switch_dd(0, 0, 1)<CR><C-W>L<C-W>h
    map gvns :call cppenv#switch_dd(2, 2, 1)<CR><C-W>L<C-W>h
    map gnvs gvns
    map gS :call cppenv#switch_dd(-1, 0, 0)<CR>
endfunc

func! cppenv#uninfect()
    let s:is_infect = 0

    unmap <C-k>
    iunmap <C-k>

    unmap <C-u>
    iunmap <C-u>

    iunmap (
    iunmap [
    iunmap {

    iunmap )
    iunmap ]
    iunmap }

    iunmap <C-l>

    if has("unix")
        "iunmap <
        "iunmap >

        iunmap <CR>
    endif

    call cppenv#warn("Close cppenv.")
    unmap gp
    unmap gs
    unmap gns
    unmap gvs
    unmap gvns
    unmap gS
endfunc

func! cppenv#toggle()
    if s:is_infect == 0
        call cppenv#infect()
    else
        call cppenv#uninfect()
    endif
endfunc

map <C-F2> :call cppenv#toggle()<CR>
