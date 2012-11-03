" Vim plugin to expidite use of cmdline commands
" Maintainer: Daniel Thau (paradigm@bedrocklinux.org)
" Version: 0.1
" Description: SkyBison is a Vim plugin used to expedite the use of cmdline
" 	commands which take one cmdline-completion-able argument such as :b,
" 	:tag, :e, and :h
" Last Change: 2012-10-31
" Location: plugin/SkyBison.vim
" Website: https://github.com/paradigm/skybison
"
" See skybison.txt for documentation.

if exists('g:skybison_loaded')
	finish
endif
let g:skybison_loaded = 1

function! SkyBison(cmd,autoenter)
	let l:initmore = &more
	let l:ctrlv = 0
	set nomore
	" build arg up from user input
	let l:arg = ""
	redraw
        " if the cmd has an argument appended to it
        if a:cmd =~ '\s\S\+$'
          let prefix = matchstr(a:cmd, '^\zs.\+\ze\s') . ' '
          let cmd = a:cmd
        else
          let cmd = a:cmd . ' '
        endif
	while 1
		" Determine cmdline-completion options.  Huge thanks to ZyX-I for
		" helping me do this so cleanly.
		let d={}
		execute "silent normal! :".cmd.l:arg."\<c-a>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
		if has_key(d, 'cmdline')
			let l:results = split(strpart(d['cmdline'],stridx(d['cmdline'],' ')+1),'\\\@<! ')
		else
			let l:results = []
		endif
		" display results and special items for zero or one results
		let counter = 1
		for result in l:results[0:8]
			echo "[".counter."] ".l:result
			let counter+=1
		endfor
		if len(results) == 0
			echo "[No results]"
		elseif len(results) == 1
			if a:autoenter
				redraw
				echo ":".cmd.l:results[0]
                                if exists('prefix')
                                  execute "silent ".prefix.l:results[0]
                                else
                                  execute "silent ".cmd.l:results[0]
                                endif
				let &more = l:initmore
				return 0
			else
				echo "Press <CR> to select \"".l:results[0]."\""
			endif
		endif
		" get input from user
		if l:ctrlv == 1
			echo ":".cmd.l:arg."^"
		else
			echo ":".cmd.l:arg
		endif
		let l:input = getchar()
		if type(l:input) == 0
			let l:input = nr2char(l:input)
		endif
		" process input
		redraw
		if l:ctrlv
			let l:ctrlv = 0
			let l:arg.=l:input
		else
			if l:input == "\<c-v>"
				let l:ctrlv = 1
			elseif l:input == "\<esc>"
				let &more = l:initmore
				return 0
			elseif strlen(l:arg) > 0 && l:input == "\<bs>" || l:input == "\<c-h>"
				let l:arg = l:arg[:-2]
			elseif l:input == "\<c-u>"
				let l:arg = ""
			elseif l:input == "\<c-w>"
				if l:arg[-1:] == " "
					let l:arg = l:arg[:-2]
				endif
				while strlen(l:arg) > 0 && l:arg[-1:] != " "
					let l:arg = l:arg[:-2]
				endwhile
			elseif l:input == "\<tab>" || l:input == "\<c-l>"
                                if exists('prefix')
                                        let cmd = prefix
                                endif
				execute "silent normal! :".cmd.l:arg."\<c-l>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
				if has_key(d, 'cmdline')
					let l:arg = strpart(d['cmdline'],stridx(d['cmdline'],' ')+1)
				endif
			elseif l:input == "\<cr>"
				if len(l:results) == 1
					echo ":".cmd.l:results[0]
                                        if exists('prefix')
                                          execute "silent ".prefix.l:results[0]
                                        else
                                          execute "silent ".cmd.l:results[0]
                                        endif
				else
					echo ":".cmd.l:arg
                                        if exists('prefix')
                                          execute "silent ".prefix.l:results[0]
                                        else
                                          execute "silent ".cmd.l:results[0]
                                        endif
				endif
				let &more = l:initmore
				return 0
			elseif l:input =~ "[1-9]" && len(results) >= l:input
				let l:arg = l:results[l:input-1]
                                if exists('prefix')
                                        let cmd = prefix
                                endif
				if a:autoenter
                                        if exists('prefix')
                                          echo ":".prefix.l:results[l:input-1]
                                          execute "silent ".prefix.l:arg
                                        else
                                          echo ":".cmd.l:results[l:input-1]
                                          execute "silent ".cmd.l:results[0]
                                        endif
					let &more = l:initmore
					return 0
				endif
			else
				let l:arg.=l:input
			endif
		endif
	endwhile
endfunction
