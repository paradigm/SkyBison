" Vim plugin to expidite use of cmdline commands
" Maintainer: Daniel Thau (paradigm@bedrocklinux.org)
" Version: 0.4
" Description: SkyBison is a Vim plugin used to expedite the use of cmdline.
" Last Change: 2012-11-05
" Location: plugin/SkyBison.vim
" Website: https://github.com/paradigm/skybison
"
" See skybison.txt for documentation.

if exists('g:skybison_loaded')
	finish
endif
let g:skybison_loaded = 1

function s:RunCommandAndQuit(cmdline)
	" reset changed settings
	let &more = s:initmore
	let &laststatus = s:initlaststatus
	bdelete!
	execute s:initwinnr."wincmd w"
	redraw
	" run command and quit
	execute a:cmdline
	return 0
endfunction

" Determine cmdline-completion options.  Huge thanks to ZyX-I for
" helping me do this so cleanly.
function s:GetCmdlineCompletionResults(cmdline)
	let l:termcount = s:GetTermCount(a:cmdline)
	let l:d={}
	execute "silent normal! :".a:cmdline."\<c-a>\<c-\>eextend(l:d, {'cmdline':getcmdline()}).cmdline\n"
	if has_key(l:d, 'cmdline') && l:d['cmdline'] !~ ''
		return split(l:d['cmdline'],'\\\@<! ')[l:termcount-1:]
	else
		return []
	endif
endfunction

" Get c_ctrl-l response.  Again, Huge thanks to ZyX-I for helping me do this
" so cleanly.
function s:GetCCtrlLResult(cmdline)
	let l:d={}
	execute "silent normal! :".a:cmdline."\<c-l>\<c-\>eextend(d, {'cmdline':getcmdline()}).cmdline\n"
	if has_key(l:d, 'cmdline')
		return l:d['cmdline']
	else
		return a:cmdline
	endif
endfunction

function s:StripLastTerm(cmdline)
	if a:cmdline[-1:] == ' ' && a:cmdline[-2:] != '\\ '
		return a:cmdline[:-2]
	elseif a:cmdline =~ '\\\@<! '
		return join(split(a:cmdline,'\\\@<! ')[:-2])
	else
		return ''
	endif
endfunction

function s:GetLastTerm(cmdline)
	let l:lastterm = strpart(a:cmdline,strlen(s:StripLastTerm(a:cmdline)))
	if l:lastterm[:0] == " "
		let l:lastterm = l:lastterm[1:]
	endif
	return l:lastterm
endfunction

function s:GetTermCount(cmdline)
	let l:termcount = 0
	let l:nextstart = 0
	while l:nextstart != -1
		let l:nextstart = match(a:cmdline,'\\\@<! ',l:nextstart+1)
		let l:termcount += 1
	endwhile
	return l:termcount
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

	" use try/catch to make sure we always properly clean up
	try

	" set and save global settings to restore on exit
	let s:initmore = &more
	let &more = 0
	let s:initlaststatus = &laststatus
	let &laststatus = 0
	let s:initwinnr = winnr()

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
	syntax match LineNr /^\d/
	syntax match MoreMsg /^-.*/
	syntax match Comment /^\[.*/
	syntax match NONE /^:.*/
	syntax match Comment /^:.*\zs_$/

	" initialize other variables
	let l:cmdline = a:initcmdline
	let l:ctrlv = 0

	" main loop
	while 1
		" if desired, fuzz the last item of the cmdline
		let l:fuzzed_cmdline = l:cmdline
		let l:fuzzed_argument = s:GetLastTerm(l:cmdline)
		if exists("g:skybison_fuzz")
			if g:skybison_fuzz == 1
				" full fuzzing - asterisk between every character
				let l:fuzzed_argument = substitute(l:fuzzed_argument,'.','*&','g')
			elseif g:skybison_fuzz == 2
				" substring-match - just start groups of wordchars with
				" an asterisks
				let l:fuzzed_argument = substitute(l:fuzzed_argument,'\w\+','*&','g')
			end
			" asterisks break some corner cases - ensure we don't hit those
			if l:fuzzed_argument[0:1] == "*/"
				let l:fuzzed_argument = l:fuzzed_argument[1:]
			endif
			let l:fuzzed_argument = substitute(l:fuzzed_argument,'*\.\*\.','..','g')
			let l:fuzzed_argument = substitute(l:fuzzed_argument,'/\*\.','/.','g')
			let l:fuzzed_argument = substitute(l:fuzzed_argument,'\*|','|','g')
			" append fuzzed argument to the cmdline
			let l:fuzzed_cmdline = s:StripLastTerm(l:cmdline).' '.l:fuzzed_argument
		endif

		" highlight prompt in results
		syntax clear Identifier
		if l:fuzzed_argument != ''
			" escape backslashes
			let l:escaped_argument = substitute(l:fuzzed_argument,'\\','\\\\','g')
			" escape forwardslashes
			let l:escaped_argument = substitute(l:escaped_argument,'/','\\/','g')
			" remove leading asterisk
			if l:escaped_argument[:0] == "*"
				let l:escaped_argument = l:escaped_argument[1:]
			endif
			" convert remaining globbing-style asterisks to regex-style
			let l:escaped_argument = substitute(l:escaped_argument,'*','\\.\\*','g')
			execute 'syntax match Identifier /\V\c'.l:escaped_argument.'/'
		endif

		" get current completion results
		let l:results = s:GetCmdlineCompletionResults(l:fuzzed_cmdline)

		" output
		%normal D
		let l:counter = 1
		let l:linenumber = 10-len(l:results[0:8])
		if len(l:results) > 1 && len(l:results) < 10
			let l:linenumber+=1
		endif
		for l:result in l:results[0:8]
			call setline(l:linenumber,l:counter." ".l:result)
			let l:linenumber+=1
			let l:counter+=1
		endfor
		if len(l:results) == 0
			call setline(10,"[No Results]")
		elseif len(l:results) == 1
			if s:GetTermCount(l:cmdline) == v:count
				return s:RunCommandAndQuit(s:StripLastTerm(l:cmdline).l:results[0])
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
		let l:input = getchar()
		echo ""
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
		elseif l:input == "\<esc>"
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
			if l:cmdline[-1:] == ""
				let l:cmdline = l:cmdline[:-2]
			endif
			while strlen(l:cmdline) > 0 && l:cmdline[-1:] != " "
				let l:cmdline = l:cmdline[:-2]
			endwhile
		elseif l:input == "\<tab>" || l:input == "\<c-l>"
			if len(l:results) > 0
				let l:cmdline = s:GetCCtrlLResult(l:fuzzed_cmdline)
			endif
		elseif l:input == "\<cr>"
			if len(l:results) == 1
				return s:RunCommandAndQuit(s:StripLastTerm(l:cmdline).l:results[0])
			else
				return s:RunCommandAndQuit(l:cmdline)
			endif
		elseif l:input =~ "[1-9]" && len(l:results) >= l:input
			let l:cmdline = s:StripLastTerm(l:cmdline).l:results[l:input-1]
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
