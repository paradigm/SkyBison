" Vim plugin to expidite use of cmdline commands
" Maintainer: Daniel Thau (paradigm@bedrocklinux.org)
" Version: 0.9
" Description: SkyBison is a Vim plugin used to expedite the use of cmdline.
" Last Change: 2013-09-18
" Location: plugin/SkyBison.vim
" Website: https://github.com/paradigm/skybison
"
" See skybison.txt for documentation.

scriptencoding utf-8

if exists('g:skybison_loaded')
	finish
endif
let g:skybison_loaded = 1

" Runs command and cleans up to prepare to quit
function s:RunCommandAndQuit(cmdline)
	" reset changed settings
	let &laststatus = s:initlaststatus
	let &showmode = s:initshowmode
	let &shellslash = s:initshellslash
	let &winheight = s:initwinheight
	silent! hide
	execute s:initwinnr."wincmd w"
	execute s:winsizecmd
	redraw

	" run command, add to history and quit
	execute a:cmdline
	if a:cmdline != ""
		call histadd(':', a:cmdline)
	endif
	return 0
endfunction

" main function
function SkyBison(initcmdline)
	" If starting from the cmdline, restart with the cmdline's value
	if a:initcmdline == "" && getcmdline() != ""
		return "\<c-u>call SkyBison('".getcmdline()."')"
	endif

	" ensure we have room
	if &lines < 14
		redraw
		echoerr "Insufficient lines for SkyBison output"
		return 0
	endif

	" store v:count here, before any :normal commands are run which could
	" potentially change it.
	let l:vcount = v:count

	" set the initial g:skybison_numberselect setting for the session
	let l:numberselect = get(g:, "skybison_numberselect", 1)

	" use try/catch to make sure we always properly clean up
	try

	" set and save global settings to restore on exit
	let s:winsizecmd = winrestcmd()
	let s:initlaststatus = &laststatus
	let &laststatus = 0
	let s:initshowmode = &showmode
	let &showmode = 1
	let s:initshellslash = &shellslash
	let &shellslash = 1
	let s:initwinnr = winnr()
	let s:initwinheight = &winheight
	let &winheight = 1

	" setup output window
	botright 11new
	let s:sbwinnr = winnr()
	normal "10oggzt"
	for l:linenumber in range(1,11)
		call setline(l:linenumber,"")
	endfor
	nohlsearch
	setlocal nocursorcolumn
	setlocal nocursorline
	setlocal nonumber
	setlocal nowrap
	setlocal bufhidden=delete
	if exists("&relativenumber")
		setlocal norelativenumber
	endif
	" line numbering on left
	syntax match LineNr  /^[0-9·]/
	" -- more -- message
	syntax match MoreMsg /^-.*/
	" [No Results] message
	syntax match Comment /^\[.*/
	" prompt cursor
	syntax match Comment /^:.*_$/hs=e
	" remove any signs that could be placed in the output window from things
	" such as other plugins.
	redir => l:signs | silent execute "sign place buffer=" . bufnr("%") | redir END
	if len(split(l:signs,"\n")) > 1
		execute "sign unplace * buffer=" . bufnr(".")
	endif

	" initialize other variables
	let l:cmdline = a:initcmdline
	let l:ctrlv = 0
	let l:histnr = histnr(':') + 1
	let l:cmdline_newest = ""

	" main loop
	while 1
		" get various aspects of the current cmdline - makes later
		" calculations easier
		" get the cmdline as a list of terms
		let l:cmdline_terms = split(l:cmdline,'\\\@<!\s\+')
		if l:cmdline[-1:] == ' '
			call add(l:cmdline_terms,'')
		endif
		" a string containing all the cmdline terms but the last
		let l:cmdline_head = join(l:cmdline_terms[0:-2])
		" the last cmdline term as a string
		if len(l:cmdline_terms) > 0
			let l:cmdline_tail = l:cmdline_terms[-1]
		else
			let l:cmdline_tail = ""
		endif

		" fuzz the cmdline
		if get(g:, "skybison_fuzz",0) == 1
			" full fuzzing
			" throw an asterisk between every character
			let l:fuzzed_tail = substitute(l:cmdline_tail,'.','*&','g')
		elseif get(g:, "skybison_fuzz", 0) == 2
			" substring match
			" prefix groups of wordchars with an asterisk
			let l:fuzzed_tail = substitute(l:cmdline_tail,'[^/]\+','*&','g')
		else
			" no fuzzing
			let l:fuzzed_tail = l:cmdline_tail
		endif
		" asterisks break some corner cases - ensure we don't hit those
		if l:fuzzed_tail[0:1] == '*/' || l:fuzzed_tail[0:1] == '*.'
			let l:fuzzed_tail = l:fuzzed_tail[1:]
		endif
		let l:fuzzed_tail = substitute(l:fuzzed_tail,'*\.\*\.','..','g')
		let l:fuzzed_tail = substitute(l:fuzzed_tail,'/\*\.','/.','g')
		let l:fuzzed_tail = substitute(l:fuzzed_tail,'\*|','|','g')
		" build fuzzed cmdline from fuzzed_tail
		if l:cmdline_head != ''
			let l:fuzzed_cmdline = l:cmdline_head .' '.l:fuzzed_tail
		elseif l:cmdline_tail != ''
			let l:fuzzed_cmdline = l:fuzzed_tail
		else
			let l:fuzzed_cmdline = ''
		endif

		" highlight cmdline_tail in results
		syntax clear Identifier
		if l:fuzzed_tail != ''
			" escape slashes
			let l:escaped_tail = substitute(l:fuzzed_tail,'\\\|/','\\&','g')
			" remove leading asterisk
			if l:escaped_tail[:0] == "*"
				let l:escaped_tail = l:escaped_tail[1:]
			endif
			" convert remaining globbing-style asterisks to regex-style
			let l:escaped_tail = substitute(l:escaped_tail,'*','\\.\\*','g')
			" syntax highlight
			execute 'syntax match Identifier /\V\c'.l:escaped_tail.'/'
		endif

		" move focus back to previous window so buffer/window-specific items
		" are properly completely
		execute s:initwinnr."wincmd w"

		" Determine cmdline-completion options.  Huge thanks to ZyX-I for
		" helping me do this so cleanly.
		let l:d={}
		execute "silent normal! :".l:fuzzed_cmdline."\<c-a>\<c-\>eextend(l:d, {'cmdline':getcmdline()}).cmdline\n"
		" If l:d was given the key 'cmdline', that will be the cmdline output
		" from c_ctrl-a.  If that is the case, strip the non-completion terms.
		" Otherwise, there was no completion - return an empty list.
		if has_key(l:d, 'cmdline') && l:d['cmdline'] !~ ''
			let l:results = split(l:d['cmdline'],'\\\@<!\s\+')[abs(len(l:cmdline_terms)-1):]
		else
			let l:results = []
		endif

		" switch back to skybison window
		execute s:sbwinnr."wincmd w"

		" output
		" clear buffer
		%normal "_D
		let l:counter = 1
		let l:linenumber = 10-len(l:results[0:8])
		if len(l:results) > 1 && len(l:results) < 10
			let l:linenumber+=1
		endif
		for l:result in l:results[0:8]
			if l:numberselect == 1
				call setline(l:linenumber,l:counter." ".l:result)
			else
				call setline(l:linenumber,"· ".l:result)
			endif
			let l:linenumber+=1
			let l:counter+=1
		endfor
		if len(l:results) == 0
			call setline(10,"[No Results]")
		elseif len(l:results) == 1
			if len(l:cmdline_terms) == l:vcount && l:vcount != 0
				return s:RunCommandAndQuit(l:cmdline_head.' '.l:results[0])
			else
				if l:ctrlv
					call setline(10,'Press <CR> to run cmdline as entered')
				else
					call setline(10,'Press <CR> to select and run with "'.l:results[0].'"')
				endif
			endif
		elseif len(l:results) > 9
			call setline(10,"-- more --")
		endif
		if l:ctrlv
			call setline(11,":".l:cmdline."^")
		else
			call setline(11,":".l:cmdline."_")
		endif
		redraw

		" get input from user
		if get(g:, "skybison_input", 0) == 1
			while getchar(1) == 0
			endwhile
		endif
		let l:input = getchar()
		if type(l:input) == 0
			let l:input = nr2char(l:input)
		endif

		" process input
		if l:ctrlv
			if l:input == "\<cr>"
				return s:RunCommandAndQuit(l:cmdline)
			end
			let l:ctrlv = 0
			let l:cmdline.=l:input
		elseif l:input == "\<esc>" || l:input == "\<c-c>"
			return s:RunCommandAndQuit("")
		elseif l:input == "\<c-v>"
			let l:ctrlv = 1
		elseif l:input == "\<bs>" || l:input == "\<c-h>"
			if strlen(l:cmdline) > 0
				let l:cmdline = l:cmdline[:-2]
			endif
		elseif l:input == "\<c-u>"
			let l:cmdline = ""
		elseif l:input == "\<c-w>"
			if l:cmdline[-1:] == " "
				let l:cmdline = l:cmdline[:-2]
			endif
			while strlen(l:cmdline) > 0 && l:cmdline[-1:] != " "
				let l:cmdline = l:cmdline[:-2]
			endwhile
		elseif l:input == "\<tab>" || l:input == "\<c-l>"
			if len(l:results) > 0
				let l:d={}
				" Huge thanks to ZyX-I for this line as well
				execute "silent normal! :".l:fuzzed_cmdline."\<c-l>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
				let l:cmdline = l:d['cmdline']
			endif
		elseif l:input == "\<cr>"
			if len(l:results) == 1
				return s:RunCommandAndQuit(l:cmdline_head.' '.l:results[0])
			else
				return s:RunCommandAndQuit(l:cmdline)
			endif
		elseif l:input == "\<c-p>" || l:input == "\<up>"
			if l:histnr > 0
				if l:histnr == histnr(':') + 1
					let l:cmdline_newest = l:cmdline
				endif
				let l:histnr -= 1
				let l:cmdline = histget(':', l:histnr)
			endif
		elseif l:input == "\<c-n>" || l:input == "\<down>"
			if l:histnr < histnr(':')
				let l:histnr += 1
				let l:cmdline = histget(':', l:histnr)
			else
				let l:histnr = histnr(':') + 1
				let l:cmdline = l:cmdline_newest
			endif
		elseif l:input == "\<c-g>"
			let l:numberselect = 1 - l:numberselect
		elseif l:input =~ "[1-9]" && l:numberselect == 1 && len(l:results) >= l:input
			let l:cmdline = l:cmdline_head.' '.l:results[l:input-1]
		else
			let l:cmdline.=l:input
		endif

	endwhile

	catch
	endtry
	" If we get here, either the user hit ctrl-c or there was some other
	" error.  Either way, quit cleanly.
	call s:RunCommandAndQuit("")
endfunction
