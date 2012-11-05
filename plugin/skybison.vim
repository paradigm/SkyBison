" Vim plugin to expidite use of cmdline commands
" Maintainer: Daniel Thau (paradigm@bedrocklinux.org)
" Version: 0.2
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

" Determine cmdline-completion options.  Huge thanks to ZyX-I for
" helping me do this so cleanly.
function s:GetCmdlineCompletionResults(cmdline)
	let d={}
	execute "silent normal! :".a:cmdline."\<c-a>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
	if has_key(d, 'cmdline')
		return split(strpart(d['cmdline'],stridx(d['cmdline'],' ')+1),'\\\@<! ')
	else
		return []
	endif
endfunction

" Get c_ctrl-l response.  Again, Huge thanks to ZyX-I for helping me do this
" so cleanly.
function s:GetCCtrlLResult(cmdline)
	let d={}
	execute "silent normal! :".a:cmdline."\<c-l>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
	if has_key(d, 'cmdline')
		return strpart(d['cmdline'],stridx(d['cmdline'],' ')+1)
	else
		return strpart(a:cmdline,stridx(a:cmdline,' ')+1)
	endif
endfunction

function s:RunCommandAndQuit(cmdline)
	" reset changed settings
	let &more = s:initmore
	let &laststatus = s:initlaststatus
	bd!
	redraw
	if a:cmdline != ""
		echo ":".a:cmdline
	endif
	execute "silent! ".a:cmdline
	return 0
endfunction

function SkyBison(cmd,autoenter)
	" ensure we have room
	if &lines < 14
		redraw
		echo "Insufficient lines for SkyBison output"
		return 0
	endif

	" use try/catch to make sure we always properly clean up
	try

	" set and save global settings to restore on exit
	let s:initmore = &more
	let &more = 0
	let s:initlaststatus = &laststatus
	let &laststatus = 0

	" setup output window
	botright new
	resize 11
	normal "10oggzt"
	for l:linenumber in range(1,11)
		call setline(l:linenumber,"")
	endfor
	nohlsearch
	setlocal nonumber
	setlocal nocursorline
	setlocal nocursorcolumn

	" initialize other variables
	let l:argument = ""
	let l:ctrlv = 0

	" main loop
	while 1
		" if desired, fuzz l:argument
		if exists("g:skybison_fuzz") && g:skybison_fuzz == 1
			let l:fuzzed_argument = substitute(l:argument,".","*&","g")."*"
			let l:fuzzed_argument = substitute(l:fuzzed_argument,'*\.\*\.','..','g')
			let l:fuzzed_argument = substitute(l:fuzzed_argument,'/\*\.','/.','g')
			if l:fuzzed_argument[0:1] == "*/" || l:fuzzed_argument[0:3] == "*."
				let l:fuzzed_argument = l:fuzzed_argument[1:]
			endif
		else
			let l:fuzzed_argument = l:argument
		endif
		" get current completion results
		let l:results = s:GetCmdlineCompletionResults(a:cmd.' '.l:fuzzed_argument)

		" output
		%normal D
		let l:counter = 1
		let l:linenumber = 10-len(l:results[0:8])
		if len(l:results) > 1 && len(l:results) < 10
			let l:linenumber+=1
		endif
		for l:result in l:results[0:8]
			call setline(l:linenumber,"[".l:counter."] ".l:result)
			let l:linenumber+=1
			let l:counter+=1
		endfor
		if len(l:results) == 0
			call setline(10,"[No Results]")
		elseif len(l:results) == 1
			if a:autoenter
				return s:RunCommandAndQuit(a:cmd." ".l:results[0])
			else
				call setline(10,'Press <CR> to select "'.l:results[0].'"')
			endif
		elseif len(l:results) > 9
			call setline(10,"-- more --")
		endif
		if l:ctrlv
			call setline(11,":".a:cmd." ".l:argument."^")
		else
			call setline(11,":".a:cmd." ".l:argument."_")
		endif
		redraw

		" get input from user
		let l:input = getchar()
		echo ""
		if type(l:input) == 0
			let l:input = nr2char(l:input)
		endif

		" process input
		if l:ctrlv
			let l:ctrlv = 0
			let l:argument.=l:input
		elseif l:input == "\<esc>"
			return s:RunCommandAndQuit("")
		elseif l:input == "\<c-v>"
			let l:ctrlv = 1
		elseif l:input == "\<bs>" || l:input == "\<c-h>"
			if strlen(l:argument) > 0
				let l:argument = l:argument[:-2]
			endif
		elseif l:input == "\<c-u>"
			let l:argument = ""
		elseif l:input == "\<c-w>"
			if l:argument[-1:] == ""
				let l:argument = l:argument[:-2]
			endif
			while strlen(l:argument) > 0 && l:argument[-1:] != " "
				let l:argument = l:argument[:-2]
			endwhile
		elseif l:input == "\<tab>" || l:input == "\<c-l>"
			if len(l:results) > 0
				let l:argument = s:GetCCtrlLResult(a:cmd.' '.l:fuzzed_argument)
			endif
		elseif l:input == "\<cr>"
			let l:argument.=l:input
			if len(l:results) == 1
				return s:RunCommandAndQuit(a:cmd." ".l:results[0])
			else
				return s:RunCommandAndQuit(a:cmd." ".l:argument)
			endif
		elseif l:input =~ "[1-9]" && len(l:results) >= l:input
			let l:argument = l:results[l:input-1]
		else
			let l:argument.=l:input
		endif
	endwhile
	catch
	endtry
	" If we get here, either the user hit ctrl-c or there was some other
	" error.  Either way, quit cleanly.
	return s:RunCommandAndQuit("")
endfunction
