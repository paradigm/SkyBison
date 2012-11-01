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
	set nomore
	" build arg up from user input
	let l:arg = ""
	redraw
	while 1
		" Determine cmdline-completion options.  Huge thanks to ZyX-I for
		" helping me do this so cleanly.
		let d={}
		execute "silent normal! :".a:cmd." ".l:arg."\<c-a>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
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
				echo ":".a:cmd." ".l:results[0]
				execute "silent ".a:cmd." ".l:results[0]
				let &more = l:initmore
				return 0
			else
				echo "Press <CR> to select \"".l:results[0]."\""
			endif
		endif
		" get input from user
		echo ":".a:cmd." ".l:arg
		let l:input = getchar()
		if type(l:input) == 0
			let l:input = nr2char(l:input)
		endif
		" process input
		redraw
		if l:input == "\<esc>"
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
			execute "silent normal! :".a:cmd." ".l:arg."\<c-l>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
			if has_key(d, 'cmdline')
				let l:arg = strpart(d['cmdline'],stridx(d['cmdline'],' ')+1)
			endif
		elseif l:input == "\<cr>"
			if len(l:results) == 1
				echo ":".a:cmd." ".l:results[0]
				execute "silent ".a:cmd." ".l:results[0]
			else
				echo ":".a:cmd." ".l:arg
				execute "silent ".a:cmd." ".l:arg
			endif
			let &more = l:initmore
			return 0
		elseif l:input =~ "[1-9]" && len(results) >= l:input
			let l:arg = l:results[l:input-1]
			if a:autoenter
				echo ":".a:cmd." ".l:results[l:input-1]
				execute "silent ".a:cmd." ".l:arg
				let &more = l:initmore
				return 0
			endif
		else
			let l:arg.=l:input
		endif
	endwhile
endfunction
