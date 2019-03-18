" Main plugin logic

fun! vwm#close(name)
  let l:node = g:vwm#layouts[s:lookup_node(a:name)]
  call s:close_main(l:node, l:node.cache, l:node.unlisted)
endfun

fun! s:close_main(node, cache, unlisted)
  if s:buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      if a:unlisted
        execute('setlocal nobuflisted')
      endif
      execute('wincmd c')
    else
      execute(a:node.bid . 'bd')
    endif
  endif

  if s:node_has_child(a:node, 'left')
    call s:close_main(a:node.left, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'right')
    call s:close_main(a:node.right, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'top')
    call s:close_main(a:node.top, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'bot')
    call s:close_main(a:node.bot, a:cache, a:unlisted)
  endif

endfun

fun! vwm#open(name)
  let l:nodeIndex = s:lookup_node(a:name)
  let l:node = g:vwm#layouts[l:nodeIndex]
  call s:close_main(l:node, l:node.cache, l:node.unlisted)

  if s:node_has_child(l:node, 'left')
    echo "should not see anything here"
    let l:mod = l:node.abs ? 'to' : ''
    execute('vert ' . l:mod . ' ' . l:node.bot.sz . 'new')
    let g:vwm#layouts[l:nodeIndex].left = s:open_main(l:node.left)
  endif
  if s:node_has_child(l:node, 'right')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute('vert ' . l:mod . ' ' . l:node.bot.sz . 'new')
    let g:vwm#layouts[l:nodeIndex].right = s:open_main(l:node.right)
  endif
  if s:node_has_child(l:node, 'top')
    let l:mod = l:node.abs ? 'to' : ''
    execute(l:mod . ' ' . l:node.bot.sz . 'new')
    let g:vwm#layouts[l:nodeIndex].top = s:open_main(l:node.top)
  endif
  if s:node_has_child(l:node, 'bot')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute(l:mod . ' ' . l:node.bot.sz . 'new')
    let g:vwm#layouts[l:nodeIndex].bot = s:open_main(l:node.bot)
  endif
endfun

fun! s:open_main(node)
  let l:commands = s:buf_exists(a:node.bid) ? a:node.restore : a:node.init
  let l:node = a:node
  let l:node.bid = s:place_content(a:node)

  if s:node_has_child(a:node, 'left')
    execute('vert ' . a:node.left.sz . 'new')
    let l:node.left = s:open_main(a:node.left)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'right')
    execute('vert belowright ' . a:node.right.sz . 'new')
    let l:node.right = s:open_main(a:node.right)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'top')
    execute(a:node.top.sz . 'new')
    let l:node.top = s:open_main(a:node.top)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'bot')
    execute('belowright ' . a:node.bot.sz . 'new')
    let l:node.bot = s:open_main(a:node.bot)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  return l:node
endfun

fun! s:place_content(node)
  let l:commands = a:node.init
  if s:buf_exists(a:node.bid)
    let l:to_del = bufnr('%')
    execute(a:node.bid . 'b')
    execute(bufnr('#') . 'bw')
    let l:commands = a:node.restore 
  endif
  for cmd in l:commands
    execute(cmd)
  endfor
  return bufnr('%')
endfun

fun! s:buf_active(bid)
  return bufwinnr(a:bid) == -1 ? 0 : 1
endfun

fun! s:buf_exists(bid)
  return bufname(a:bid) =~ '^$' ? 0 : 1
endfun

fun! s:node_has_child(node, pos)
  if eval("exists('a:node." . a:pos . "')")
    return eval('len(a:node.' . a:pos . ')') ? 1 : 0
  endif
  return 0
endfun

fun! s:lookup_node(name)
  let l:i = 0
  for layout_root in g:vwm#layouts 
    let l:layout_name = layout_root.name
    if l:layout_name =~ a:name
      return l:i
    endif
    let l:i = l:i + 1
  endfor
  execute("echoerr '" . a:name . " not in list of root nodes'")
  return -1
endfun