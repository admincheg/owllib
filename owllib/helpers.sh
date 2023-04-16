#!/bin/bash

# {{{ Declares
declare _256COLOR=0
# }}}

# {{{ Bash version check
if [[ ${BASH_VERSINFO[0]} -lt 5 ]]; then
	echo "Sorry, but this helpers works only Bash 5 and newer" >&2
	exit 1
fi
# }}}

# {{{ Functions
# {{{ _color(string color)
_color() {
	local _color="$1"; shift
	local _prefix='\e[0;3'

	if [[ -z "${OWLLIB_COLOR}" ]]; then
		return
	fi

	if [[ ${_256COLOR} -eq 1 ]]; then
		_prefix='\e[38;5;'
	else
		if [[ "${_color}" =~ ^L.*$ ]]; then
			_color=${_color:1}
		fi
	fi

	case "${_color}" in
		"BLACK")
			echo "${_prefix}0m" ;;
		"RED")
			echo "${_prefix}1m" ;;
		"GREEN")
			echo "${_prefix}2m" ;;
		"YELLOW")
			echo "${_prefix}3m" ;;
		"BLUE")
			echo "${_prefix}4m" ;;
		"MAGENTA")
			echo "${_prefix}5m" ;;
		"CYAN")
			echo "${_prefix}6m" ;;
		"WHITE")
			echo "${_prefix}7m" ;;
		"LBLACK")
			echo "${_prefix}8m" ;;
		"LRED")
			echo "${_prefix}9m" ;;
		"LGREEN")
			echo "${_prefix}10m" ;;
		"LYELLOW")
			echo "${_prefix}11m" ;;
		"LBLUE")
			echo "${_prefix}12m" ;;
		"LMAGENTA")
			echo "${_prefix}13m" ;;
		"LCYAN")
			echo "${_prefix}14m" ;;
		"LWHITE")
			echo "${_prefix}15m" ;;
		"NOCOLOR")
			echo '\e[0m' ;;
		*)
			echo "WHAT COLOR, DUDE?" >&2
	esac
}
# }}}

# {{{ _print(string prefix, string text)
_print() {
	local _prefix="$1"; shift
	local _text="$1"; shift

	while read line; do
		# Check for stdout or pass data to pipe
		if [ -t 1 ]; then
			echo -e "${_prefix} ${line}" >&2
		else
			echo "${line}" >&2
		fi
		shift
	done <<< ${_text}
}
# }}}

# {{{ _info(string text)
_info() {
	local _text="$1"; shift
	local _prefix="$(_color GREEN)[INF]$(_color NOCOLOR)"

	_print "${_prefix}" "${_text}"
}
# }}}

# {{{ _debug(string text)
_debug() {
	local _text="$1"; shift
	local _prefix="$(_color BLUE)[DBG]$(_color NOCOLOR) [${FUNCNAME[1]}]"

	if [[ ${DEBUG} -eq 1 ]]; then
		if [[ -z "${_text}" ]]; then
			_print "${_prefix}" "Text is not specified"
		else
			_print "${_prefix}" "${_text}"
		fi
	fi
}
# }}}

# {{{ _lib_debug(string text)
_lib_debug() {
	local _text="$1"; shift

	if [[ "${OWLLIB_DEBUG}" -eq 1 ]]; then
		DEBUG=1 _debug "${_text}"
	fi
}
# }}}

# {{{ _error(string text)
_error() {
	local _text="$1"; shift
	local _prefix="$(_color RED)[ERR]$(_color NOCOLOR)"

	if [[ ${DEBUG} -eq 1 ]]; then
		_prefix="$(_color RED)[ERR]$(_color NOCOLOR) [${FUNCNAME[1]}]"
	fi

	_print "${_prefix}" "${_text}"
	exit 1
}
# }}}

# {{{ _warn(string text)
_warn() {
	local _text="$1"; shift
	local _prefix="$(_color YELLOW)[WAR]$(_color NOCOLOR)"

	if [[ ${DEBUG} -eq 1 ]]; then
		_prefix="$(_color YELLOW)[WAR]$(_color NOCOLOR) [${FUNCNAME[1]}]"
	fi

	_print "${_prefix}" "${_text}"
}
# }}}

# TODO: rewrite to pointers
# {{{ _choose(string type, array elements)
_choose() {
	local _type="$1"; shift
	local _elements=( $@ ); shift

	if [[ ${#_elements[@]} -eq 0 ]]; then
		_error "${type} is empty, nothing to choose"
		return 1
	fi

	if [[ ${#_elements[@]} -eq 1 ]]; then
		echo "${_elements[0]}"
		return 0
	fi

	local _num=""
	local _res=""
	local _pos=0
	while :; do
		_info "What ${_type} are you looking for: "
		local _pos=0
		for i in ${_elements[@]}; do
			echo "${_pos}. ${i}" >&2
			_pos=$((_pos + 1))
		done

		_num=""
		echo -n "Enter number or name part of ${_type} (type -1 for exit): " >&2
		read _num

		local _part=( $(printf -- '%s\n' "${_elements[@]}" | grep "${_num}") )

		if [[ -z "${_num}" || ${_num} -lt 0 ]]; then
			_warn "You choose nothing, just exit"
			return 1
		else
			if [[ "${_num}" =~ ^[0-9]+$ ]]; then
				if [[ -z "${_elements[${_num}]}" ]]; then
					_warn "${_type} by number ${_num} is not found, try another one"
				else
					_ret="${_elements[${_num}]}"
					break
				fi
			else
				if [[ -z "${_part[@]}" ]]; then
					_warn "${_type} by name ${_part[@]} is not found, try another one"
				elif [[ "${#_part[@]}" -gt 1 ]]; then
					_warn "${_type} found ${#_part[@]} times, try to explain"
				else
					_ret="${_part}"
					break
				fi
			fi
		fi
	done

	_info "You choose ${_ret} ${_type}"

	echo "${_ret}"
}
# }}}

# TODO: rewrite to pointers
# {{{ _http_array_to_data(string key, array data)
_http_array_to_data() {
	local _key="$1"; shift
	local _arr=( $@ )

	local _ret=""

	for (( i=0; i < ${#_arr[@]}; i=$((i+1)) )); do
		if [[ -z "${_ret}" ]]; then
			_ret="${_key}%5B${i}%5D=${_arr[${i}]}"
		else
			_ret="${_ret}&${_key}%5B${i}%5D=${_arr[${i}]}"
		fi
	done

	echo "${_ret}"
}
# }}}
# }}}

# {{{ Initialization
_lib_debug "Owllib helper loaded"

if [[ $(tput colors) -eq 256 ]]; then
	_lib_debug "THERE IS 256 COLORS"
	_256COLOR=1
fi
# }}}
