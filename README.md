# OwlLib

Some collection of personal functions for increasing quality of live and
code reusing in another projects.

It's requires Bash 5+ version!

## Installation

By default makefile places files to ${HOME}/.local/share/owllib, but you can
override this behavior by passing PREFIX environment variable.

Installation is pretty simple:

	make install

## Usage

Very simple. Just include library at the start of your script and use predefined
functions.

For example (Bash of course):

	declare _owllib_path="${HOME}/.local/owllib/helpers.sh"
	if [[ -f "${_owllib_path}" ]]; then
		. "${_owllib_path}"
	fi

	_info "Simple formatted output!"

## Functions

### _color(string color)

Simple converter from human-readable color name to shell sequence.

### _print(string prefix, string text)

Simple wrapper for output destination checking.
Just output all to stderr.

### _info(string text)

Show text to stderr with prefix [INF] and some colors.
Multiline supported.

Legacy: using stderr

### _debug(string text)

Show text to stderr with prefix [DBG] and some colors only if DEBUG environment
variable equals 1.
Multiline supported.

### _warn(string text)

Show text to stderr with prefix [WAR] and some colors.
Multiline supported.

Legacy: using stderr

### _error(string text)

Show text to stderr with prefix [ERR] and some colors.
Multiline supported.

### _choose(string type, array data)

Function which wrap user interactive interface for choosing one of passed data
elements. Type just a string wich be placed in prompt.

### _http_array_to_data(string key, array data)

Converts bash array to url_encoded parameter string:

	declare _key="item"
	declare -a _items=(
		"a"
		"b"
		"c"
	)

	_http_array_to_data "${_key}" "${_items[@]}"

	# It'll returns item%5B0%5D=a&item%5B1%5D=b&item%5B2%5D=c
