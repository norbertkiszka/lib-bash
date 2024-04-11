## What is this?

This is a bash library primarily intented for a project Orange Rigol at https://github.com/norbertkiszka/rigol-orangerigol-build

But... should be usable for many other projects with bash scripts.

Also it can be used directly straight from the terminal.

## Features in short

- Colors.
- Version checker.
- Whiptail menu helper.
- Error handling by calling functions with colorized output.
- Script and function call trace.
- Exit and int signal traps.
- Adding own traps for different situations (see public function list below).
- Possibility to use it directly from a terminal ($ source /path/to/lib-bash.sh) instead of from script.
- After being called directly, it can be recalled by a some script (it shouldnt trigger any problems).

## Usage - include in script
Add `lib-bash.sh` to your script:
```bash
source "/path/to/lib-bash.sh"
```
## Usage - inside terminal with interactive bash (not in script)
You can call it directly (from interactive bash instead from a script) and after that, You can call functions in this lib just by typing them like a in a script.

First and simpliest method to do this:
```bash
source "/path/to/lib-bash.sh" # it will detect direct call and it will not call exit when error function is executed (kinda ugly behaviour)
```
Instead of calling it everytime, Yoy can add this line into ~/.bashrc or into ~/.profile file.

Other method possible from v0.1.2 which will behave more like in a real script. At first copy paste this code into terminal (not into script):
```bash
while true
do
  bash # nested bash
done
```
From now any bash exit will cause to go back to loop in previous bash which will execute another bash.

After that You can type this:
```bash
source "/path/to/lib-bash.sh" libignoredirect # it will ignore direct call and it will behave same as included from script
```
In that way, call to exit from this lib will cause to kill nested bash and return to previous bash which will execute another bash in a loop, instead of closing terminal emulator or using return when no arg ignoredirect is given.

After each error You have to execute last line (source...) again because we are in another bash.

Ugly workaround of this is to add this line into ~/.bashrc - but still You have to copy this loop into terminal (and press enter ofc).

This currently cannot be scripted due to another bash behaviour in interactive mode - at least as far I know.

## Public functions list, description and usage

List below describes functions in order as its defined by this lib.

General:
- version_is_eqal_or_greater_than  
	<pre>  Will return 1 when true, 0 otherwise.
	
    Example:</pre>
	```bash
	if ! version_is_eqal_or_greater_than "${BASH_VERSION}" "1.2.3" ; then
		echo "We have required bash version or greater"
		do_something
	fi
	```
Colors:
- echo_green, echo_red, echo_yellow, echo_white  
	<pre>  Colorized echo.</pre>
- echo_green_e, echo_red_e, echo_yellow_e, echo_white_e  
	<pre>  Colorized echo with interpretation of backslash escapes (same as echo -e).</pre>

Error handling and debugging:
- sctrace  
	<pre>  Trace of process execution tree.</pre>
- show_stacktrace_for_warnings
	<pre>  Will force to display (execute) stacktrace as normally only in error and error_e.</pre>
- always_show_stacktrace_at_exit
	<pre>  Display (execute) stacktrace always when exit is trapped.</pre>
- forbidden_warning  
	<pre>  Warning will trigger error (like in a gcc with -Werror).</pre>
- check_require_args_with_real_data  
	<pre>  Function helper to require arg(s).</pre>
- is_executable  
	<pre>  Check if given command is executable by bash.
	
    It will check only first arg, since first arg is a command and remaining args are args...</pre>
- require_executable  
	<pre>  Helper for functions that require (first) arg to be executable by bash (uses is_executable())
	
    It will check only first arg, since first arg is a command and remaining args are args...</pre>
- info, notice, warning, error_without_exit, error, success, success_whiptail  
	<pre>  Self explanatory.
	
    error function will trigger exit 1 unless lib was called directly from a terminal (bash interactive mode) and without libignoredirect passed as first arg.
    
    Any call to exit is catched by this lib and any exit code different than 0 will trigger debug output.</pre>
- info_e, notice_e, warning_e, error_without_exit_e, error_e, success_e, success_whiptail_e  
	<pre>  _e -  interpretation of backslash escapes (same as echo -e).</pre>
- errorhandling_use_whiptail_for_warning, errorhandling_use_whiptail_for_error  
	<pre>  Will force warning, warning_e, error and error_e to additionally show same message by whiptail
- whiptail_display_warning  </pre>
	<pre>  Display warning only by whiptail... And nothing more than just that.
	
    It will return after displaying whiptail msgbox.
    
    Used internally, but it can be used outside of this lib.</pre>
- whiptail_display_error  
	<pre>  Display error only by whiptail... And nothing more than just that.
	
    It will return after displaying whiptail msgbox.
    
    Used internally, but it can be used outside of this lib.</pre>

Traps:
- trap_exit_at_first  
	<pre>  Add function to trap exit at first (both on exit success and on exit error).</pre>
- trap_exit_at_end  
	<pre>  Add trap function at exit and at very end.</pre>
- trap_exit_at_ok  
	<pre>  Add trap function at exit and when exit code is 0 (exit success).</pre>
- trap_exit_at_error  
	<pre>  Add trap function at exit and when exit code is not 0.</pre>

Debugging:
- scriptstacktrace  
	<pre>  Display (via echo) script and function call stack.</pre>

Whiptail menu helper:
- whiptail_menu_reset  
	<pre>  Reset all options and settings.
	
    Normally is no need to call it, since its being called everytime in function whiptail_menu_execute.</pre>
- whiptail_menu_set_height  
	<pre>  Set different menubox height than default.
	
    This option is one time - its reset to default after each whiptail_menu_execute() call.
    
    See: whiptail_menu_set_default_height, whiptail_menu_set_default_dimensions</pre>
- whiptail_menu_set_width  
	<pre>  Set different menubox width than default.
	
    This option is one time - its reset to default after each whiptail_menu_execute() call.
    
    See: whiptail_menu_set_default_width, whiptail_menu_set_default_dimensions</pre>
- whiptail_menu_set_list_height  
	<pre>  Set different menubox list height than default.
	
    This option is one time - its reset to default after each whiptail_menu_execute() call.
    
    See: whiptail_menu_set_default_list_height, whiptail_menu_set_default_dimensions</pre>
- whiptail_menu_set_dimensions  
	<pre>  Arg1: height.
    Arg2: width.
    Arg3: list height.
    
    See: whiptail_menu_set_default_dimensions</pre>
- whiptail_menu_set_default_height, whiptail_menu_set_default_width, whiptail_menu_set_default_list_height
	<pre>  Self explanatory.</pre>
- whiptail_menu_dont_add_dot_in_key  
	<pre>  Force to not add dot in option ids.
	
    Those dots are only for displaying - it will be removed from WHIPTAIL_MENU_OPTION_ID by whiptail_menu_execute.
	
    This option is one time - its reset to default (display dot) after each whiptail_menu_execute() call.</pre>
- whiptail_menu_title_set_prefix  
	<pre>  Set prefix for titles in every whiptail_menu_execute calls (it will not be reset by whiptail_menu_reset).</pre>
- whiptail_menu_set_backtitle  
	<pre>  Set backtitle for next whiptail_menu_execute call.</pre>
- whiptail_menu_set_default_backtitle, whiptail_menu_is_option_id_exist  
	<pre>  Self explanatory.</pre>
- whiptail_menu_set_default_item  
	<pre>  User will see selected this option id.
	
    Option should be previously added by using whiptail_menu_options_add(), otherwise it will generate warning.
    
    See: warning, forbidden_warning</pre>
- whiptail_menu_options_add  
	<pre>  Add option to display.
	
    Arg1: numeric id. It can be any integer without any order and is not required to start with any special number.
    Arg2: text with displayed option</pre>
- whiptail_menu_execute  
	<pre>  Display whiptail (execute whiptail) to user.
	
    Selected option id is saved to a var WHIPTAIL_MENU_OPTION_ID without dot (see whiptail_menu_dont_add_dot_in_key).
	
    Selected option name is saved into a var WHIPTAIL_MENU_OPTION_NAME.
    
    If not sure how to use it, see tests/test-whiptail-menu.sh</pre>
