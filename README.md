SkyBison
========

If you'd like to skip the whole "reading" nonsense and watch a nice, wholesome
video which explains SkyBison instead, see
[here](http://www.youtube.com/watch?v=cIiHzHbYckQ).

Description
-----------

It is well established that some of Vim's cmdline commands can be a bit
awkward to use, especially in comparison to how keystroke-efficient most of
the rest of Vim's functionality is, and as a result there are a plethora of
plugins designed to make functionality such as :b and :tag more accessible.

SkyBison is another attempt at tackling this problem.  It differs from other
options in two key ways:
1. It is intended to have a clean, simple and small code base.
2. It is designed to alleviate the awkwardness of the cmdline itself rather
than targeting specific commands.  SkyBison has no code specifically for :b,
for :tag, etc - it supports them as a side-effect of making the cmdline more
comfortable.

More specifically, SkyBison alleviates three issues where the author felt Vim's
cmdline was both obviously lacking during normal usage and easily capable of
remedying:
1. If Vim knows likely values for the term the user is typing (such as from its
cmdline-completion), it should print them constantly.  It seems silly to
require the user input c_ctrl-d when he or she wishes to see completion
options when it could just show them all the time.
2. If Vim (again through the cmdline-completion) narrows down the
possibilities for the term the user is typing to a single one, it seems silly
to require the user to hit c_ctrl-l or c_&lt;tab&gt; (or even worse, finish
typing the whole thing) in order to accept it when the user enters c_&lt;cr&gt;.
Vim already knows what is going on - just accept the term the user is in the
process of typing.
3. As an extension of (2) above, if Vim has a way of knowing the number of
terms that will be on the cmdline, why have the user hit c_&lt;cr&gt; at all?  When
only one possibility remains, skip the c-ctrl-lc_&lt;cr&gt; and immediate accept
it.

For example:

If Vim has three (listed) buffers, ".vimrc", ".bashrc" and ".zshrc", and the
user calls SkyBison("b "), the user will see the following:

    1 .vimrc
    2 .bashrc
    3 .zshrc
    :b 

If the user inputs "v", SkyBison will recognize that the user wants ".vimrc"
and select it (or prompt the user to hit &lt;cr&gt; to select it).  However, if the
user inputs "s" (which is in both .bashrc and .zshrc, but not in .vimrc), the
user will see the following:

    1 .bashrc
    2 .zshrc
    :b s

SkyBison recognizes that .vimrc is no longer an option and drops it from the
possibilities.  However, all of the remaining characters after "s" are shared
in the remaining options.  Here, the user could enter "1" or "2" to select an
option.  In fact, the user could have entered "1", "2" or "3" earlier to
select a buffer when all three were possibilities.

This works wherever cmdline-completion works, including at a empty cmdline
prompt and after :bar, including (but not limited to) :b for buffers,
:tag (for jumping to a tag), :e (for editing a file), :h (for help), and
many others.

Setup
-----

Note that as of 0.3, SkyBison's configuration is slightly different from how it
was in previous versions (as a result of added functionality).

SkyBison can be installed like most other Vim plugins.  On a Unixy system
without a plugin manager, the skybison.vim file should be located at:

    ~/.vim/plugin/skybison.vim

On a Unixy system with pathogen, the skybison.vim file should be located at:

    ~/.vim/bundle/skybison/plugin/skybison.vim

On a Windows system without a plugin manager, the skybison.vim file should be located at:

    %USERPROFILE%\vimfiles\plugin\skybison.vim

On a Windows system with pathogen, the skybison.vim file should be located at:

    %USERPROFILE%\vimfiles\bundle\skybison\plugin\skybison.vim

If you are using a plugin manager other than pathogen, see its documentation
for how to install skybison - it should be comparable to other plugins.

If you would like the documentation to also be installed, include skybison.txt
into the relevant directory described above, replacing "plugin" with "doc".

SkyBison can be called via:

    :call SkyBison({string})

Where {string} is a string containing the characters you would like to be in
the prompt when it starts.  Rather than going to the cmdline to run it, you
could make a mapping, like so:

    nnoremap {keys} {count}:<c-u>call SkyBison({string})<cr>

Here, {keys} are the keys you would like to use to launch SkyBison, {count} is
an optional number you could use to tell SkyBison how many terms to expect
(at which it will automatically accept the cmdline without waiting for &lt;cr&gt;),
and {string} is the same as it was above.

Note: If you do not include {count} in the mapping, you can type it before you
type the map {keys} to manually set it before each launch of SkyBison.  Or
simply do not include or type it to opt out of the functionality if you do
prefer to always have Vim wait for you to hit &lt;cr&gt;.

For example:

    nnoremap <leader>s :<c-u>call SkyBison("")<cr>

Or, if you find you much prefer SkyBison to the normal cmdline, you could map
it over the default:

    nnoremap : :<c-u>call SkyBison("")<cr>

Be sure you know another way to get to the cmdline, just in case there are
problems with SkyBison.

If you would like to further expedite access to specific cmdline commands, you
can make mappings which launch SkyBison with the command already in the
prompt.  For example:

    nnoremap <leader>b 2:<c-u>call SkyBison("b ")<cr>
    nnoremap <leader>t 2:<c-u>call SkyBison("tag ")<cr>
    nnoremap <leader>h 2:<c-u>call SkyBison("h ")<cr>
    nnoremap <leader>e :<c-u>call SkyBison("e ")<cr>

Note: The space after the command is necessary to let SkyBison know to start
looking for an argument for the command rather than to continue looking for
possible commands.

Note: For commands which browse the filesystem, such as :e, it is
recommended not to include a {count} so that SkyBison does not immediately
accept a directory when you want the argument to be a file in that directory.

With those mappings:
- &lt;leader&gt;b will call SkyBison to find an argument for :b (and immediately
  accept once there you've uniquely identified a buffer),
- &lt;leader&gt;t will call SkyBison to find an argument for :tag (and immediately
  accept once there you've uniquely identified a buffer),
- &lt;leader&gt;h will call SkyBison to find an argument for :help (and immediately
  accept once there you've uniquely identified a buffer),
- &lt;leader&gt;e will call SkyBison to find an argument for :e (but wait for the
  user to hit &lt;cr&gt;)

With the above mappings, if the user had several buffers open, but only one
starting with "v", the user could select that buffer in three keystrokes:
&lt;leader&gt;bv.  It could be further reduced to two keystrokes if a shorter
mapping was used (e.g.: just &lt;space&gt; or &lt;cr&gt;)

You can also include more than just the command in SkyBison's argument,
but also a starting string, if you'd like.  For example, if you regularly edit
files in ~/projects/, you could use the following:

    nnoremap <leader>p :<c-u>call SkyBison("e ~/projects/")<cr>

Moreover, you can have SkyBison take over from an in-progress cmdline, with a
mapping like so:

    cnoremap {keys} <c-r>=SkyBison("")<cr><cr>

where {keys} is replaced with what you want to type, such as "&lt;c-l&gt;"

Usage
-----

Once a mapping (as described in skybison-setup) is called, the user will see
the what Vim considers as possible arguments to the current cmdline's prompt.
From here, the user may:

- Press &lt;esc&gt; to abort, akin to c_&lt;esc&gt;
- Press ctrl-u to clear prompt, akin to c_ctrl-u
- Press ctrl-w to remove the word behind the cursor, akin to c_ctrl-w
- Press &lt;tab&gt; or ctrl-l to complete the shared part of the last term, akin to
  c_ctrl-l
- If numberselect is on (which it is by default), press the number next to an
  option to select it.
- Press ctrl-g to toggle numberselect for the current SkyBison session
- Press ctrl-v to literally insert the next character.  This can be used to
  bypass numberselect for the next keystroke.  Akin to |c_ctrl-v|.
- Press &lt;cr&gt;.  If SkyBison recognizes only one possible value for the last
  term (and ctrl-v was not just pressed), SkyBison will substitute that value
  in for the last term and run the cmdline.  If either ctrl-v just pressed or
  SkyBison sees either no value completions or more than one completion for
  the last term, SkyBison will simply execute the cmdline as it is.
- Press &lt;c-p&gt; or &lt;up&gt; to go back in the cmdline history.
- Press &lt;c-n&gt; or &lt;down&gt; to go forward in the cmdline history.
- Enter another character.  This could serve to narrow down the possible
  values for the last term or simply be new content unrelated to completion
  (such as using :e on a new file).

Due to the way SkyBison parses possible options from Vim's cmdline-completion,
items with non-escaped spaces in them will appear as multiple items, split at
the whitespace.  To select one, give enough information to uniquely identify
the first part of it, then use either ctrl-l or &lt;tab&gt; and SkyBison will
fill out the rest, at which point you can hit &lt;cr&gt;.

Options
-------

SkyBison supports two variations of fuzzy matching.  To use no fuzzy matching,
either set:

    let g:skybison_fuzz = 0

or simply leave that variable unset.  To use "full" fuzzy matching, where SkyBison
will only care that the possible match includes the characters you've entered
in order (irrelevant of what is or is not between them, set:

    let g:skybison_fuzz = 1

To use substring matching, where SkyBison will ignore characters before and
after the string you've entered, but require that all of the characters you've
entered are available in the possible match in order with nothing in between
them, set:

    let g:skybison_fuzz = 2

By default, if you press a number 1-9 and at least that many items exist in
the output, that item will be selected.  This can be disabled by default by
setting the following:

    let g:skybison_numberselect = 0

You can also toggle this setting for the duration of a given SkyBison session
by pressing ctrl-g.

SkyBison has two input methods, each of which has a advantages and
disadvantages.  You can set

    g:skybison_input = 0

or

    g:skybison_input = 1

to pick which one you'd like.  If you leave the variable unset,
g:skybison_input=0 is the default.

With g:skybison_input empty or set to "0", SkyBison will use |getchar()|.  The
advantages of this are:
- It is probably more efficient while waiting for input than the alternative.
- It seems to work properly.
The disadvantages are:
- The cursor flashes input is typed.  Some people find this annoying.

With g:skybison_input set to "1", SkyBison will use a while loop waiting for
getchar(1).  The advantages of this are:
- Hides the cursor
The disadvantages are:
- As of Vim 7.4.9, you have to hit |<esc>| twice for it to be recognized.
  Note that |ctrl-c| can be used to cancel in one key press.  This is probably
  Vim's fault; eventually someone will probably patch this.
- It may keep the CPU awake while waiting for input, and thus be less
  efficient than the alternative.

Changelog
---------

0.9 (2013-09-18):
 - Added g:skybison_numberselect and ctrl-g

0.8 (2013-09-09):
 - reworked docs
 - added alternative input method which hides cursor
 - explicitly set desired showmode
 - removed signs in skybison window set by other plugins

0.7 (2013-06-19):
 - added basic history functionality

0.6 (2012-12-18):
 - bug fix

0.5 (2012-11-07):
 - refactored code, slight cleaner and faster

0.4 (2012-11-07):
 - added syntax highlighting

0.3 (2012-11-05):
 - generalized to work with commands with less than or more than one argument
   in addition to just one argument
 - changed how autoenter is indicated such that it can be called on the fly
 - support running from the cmdline
 - substring matching

0.2 (2012-11-04):
 - changed output system to one which no longer flickers/shakes
 - fuzzy matching

0.1 (2012-10-31):
 - initial release
