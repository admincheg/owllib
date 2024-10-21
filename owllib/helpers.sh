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
	declare _color="$1"; shift
	declare _prefix='\e[0;3'

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

# {{{ _print(string prefix, string text, int newline)
_print() {
	declare _prefix="$1"; shift
	declare _text="$1"; shift
	declare -i _newline="${1:-1}"; shift

	declare -a _args=()

	if [[ ${DEBUG} -gt 0 ]]; then
		_prefix="[${FUNCNAME[1]}] ${_prefix}"
	fi

	if [[ -t 1 ]]; then
		_args+=( "-e" )
	fi

	if [[ ${_newline} -eq 0 ]]; then
		_args+=( "-n" )
	fi

	while IFS= read -r line; do
		if [[ -n "${_prefix}" ]]; then
			line="${_prefix} ${line}"
		fi

		echo ${_args[@]} "${line}" >&2
		shift
	done <<< "${_text}"
}
# }}}

# {{{ _info(string text)
_info() {
	declare _text="$1"; shift
	declare _prefix="$(_color GREEN)[INF]$(_color NOCOLOR)"

	_print "${_prefix}" "${_text}"
}
# }}}

# {{{ _debug(string text)
_debug() {
	declare _text="$1"; shift
	declare _prefix="$(_color BLUE)[DBG]$(_color NOCOLOR)"

	if [[ ${DEBUG} -gt 0 ]]; then
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
	declare _text="$1"; shift

	if [[ "${OWLLIB_DEBUG}" -eq 1 ]]; then
		DEBUG=1 _debug "${_text}"
	fi
}
# }}}

# {{{ _error(string text)
_error() {
	declare _text="$1"; shift
	declare _prefix="$(_color RED)[ERR]$(_color NOCOLOR)"

	_print "${_prefix}" "${_text}"
	exit 1
}
# }}}

# {{{ _warn(string text)
_warn() {
	declare _text="$1"; shift
	declare _prefix="$(_color YELLOW)[WAR]$(_color NOCOLOR)"

	_print "${_prefix}" "${_text}"
}
# }}}

# {{{ _print_pos(refarray data, int pos_show, int count_show)
_print_pos() {
  declare -n _data_ref=$1; shift
  declare -i _pos_show=${1:-1}; shift
  declare -i _count_show=${1:-0}; shift
  declare -i _pos=0

  for e in "${_data_ref[@]}"; do
	declare _prefix=""
	if [[ ${_pos_show} -eq 1 ]]; then
		if [[ ${_count_show} -eq 1 ]]; then
			_prefix="[${_pos}/${#_data_ref[@]}]"
		else
			_prefix="${_pos}."
		fi

		_print "${_prefix}" "${_data_ref[${_pos}]}"
	else
		_warn "${_data_ref[${_pos}]}"
	fi

	_pos=$((_pos + 1))
  done
}
# }}}

# {{{ _print_hash(refhash data)
_print_hash() {
	declare -n _data_ref="$1"; shift

	if [[ ${#_data_ref[@]} -eq 0 ]]; then
		_warn "Hash ${!_data_ref} is empty"
		return
	fi

	for i in "${!_data_ref[@]}"; do
		_print "${i}:" "${_data_ref[${i}]}"
	done
}

# {{{ _choose(refstring ret, arrayref elements, string type, int insensitive)
_choose() {
	declare -n _ret_ref="$1"; shift
	declare -n _elements_ref="$1"; shift
	declare _type="$1"; shift
	declare -i _insense=${1:-0}

	if [[ ${#_elements_ref[@]} -eq 0 ]]; then
		_error "${type} is empty, nothing to choose"
		return 1
	fi

	if [[ ${#_elements_ref[@]} -eq 1 ]]; then
		_print "0." "${_elements_ref[0]}"
		return 0
	fi

	declare _pattern=""
	declare -i _pos=0
	while :; do
		_info "What ${_type} are you looking for: "
		_print_pos _elements_ref

		_pattern=""
		_print "" "Enter number or name part of ${_type} (type -1 for exit): " 0
		read _pattern

		if [[ -z "${_pattern}" ]]; then
			_warn "You choose nothing, just exit"
			return 1
		else
			if [[ "${_pattern}" =~ ^[0-9]+$ ]]; then
				if [[ -z "${_elements_ref[${_pattern}]}" ]]; then
					_warn "${_type} by number ${_pattern} is not found, try another one"
				else
					_ret_ref="${_pattern}"
					break
				fi
			else
				declare -a _found_elements=()
				_lookup_pos _found_elements _elements_ref "${_pattern}" ${_insense}
				if [[ ${#_found_elements[@]} -eq 0 ]]; then
					_warn "Nothing found, try again"
				elif [[ ${#_found_elements[@]} -gt 1 ]]; then
					declare -a _tmp_elements=()
					for i in ${_found_elements[@]}; do
						_tmp_elements+=( "${_elements_ref[${i}]}" )
					done
					_warn "Found several times!"
					_print_pos _tmp_elements 0
				else
					_ret_ref="${_found_elements[0]}"
					break
				fi
			fi
		fi
	done

	_info "You choose ${_ret_ref} element in ${_type}"
	return 0
}
# }}}

# {{{ _lookup(refarray ret, refarray array, string text, int insensitive)
_lookup() {
	declare -n _ret_ref="$1"; shift
	declare -n _array_ref="$1"; shift
	declare _string="$1"; shift
	declare -i _insense=${1:-0}; shift

	if [[ ${_insense} -eq 1 ]]; then
		_string="${_string,,}"
	fi

	for _elem in "${_array_ref[@]}"; do
		if [[ ${_insense} -eq 1 && "${_elem,,}" =~ ${_string} ]]; then
			echo "${_elem}"
			_ret_ref+=( "${_elem}" )
		elif [[ "${_elem}" =~ ${_string} ]]; then
			_ret_ref+=( "${_elem}" )
		fi
	done

	if [[ ${#_ret_ref[@]} -eq 0 ]]; then
		return 1
	fi
}
# }}}

# {{{ _lookup_pos(refarray ret, refarray array, string text, int insensitive)
_lookup_pos() {
	declare -n _ret="$1"; shift
	declare -n _array_ref="$1"; shift
	declare _string="$1"; shift
	declare -i _insense=${1:-0}; shift
    declare _pos=0

	if [[ ${_insense} -eq 1 ]]; then
		_string="${_string,,}"
	fi

    while [[ ${_pos} -lt ${#_array_ref[@]} ]]; do
      if [[ ${_insense} -eq 1 && "${_array_ref[${_pos}],,}" =~ ${_string} ]]; then
		  _ret+=( "${_pos}" )
	  elif [[ "${_array_ref[${_pos}]}" =~ ${_string} ]]; then
		  _ret+=( "${_pos}" )
	  fi
      _pos=$((_pos + 1))
    done

	if [[ ${#_ret[@]} -eq 0 ]]; then
		return 1
	fi
}
# }}}

# {{{ _merge_hash(refhash ret, refhash second, int replace)
_merge_hash() {
	declare -n _ret="$1"; shift
	declare -n _second="$1"; shift
	declare -i _replace=${1:-0}; shift

	for i in "${!_second[@]}"; do
		if [[ ${_replace} -eq 1 ]]; then
			_ret[${i}]="${_second[${i}]}"
		elif [[ -z "${_ret[${i}]}" ]]; then
			_ret[${i}]="${_second[${i}]}"
		fi
	done
}
# }}}

# {{{ Initialization
_lib_debug "Owllib helper loaded"

if [[ $(tput colors) -eq 256 ]]; then
	_lib_debug "THERE IS 256 COLORS"
	_256COLOR=1
fi
# }}}

# {{{ _http_array_to_data(refstring ret, refarray data, string key)
_http_array_to_data() {
	declare -n _ret_ref="$1"; shift
	declare -n _data_ref="$1"; shift
	declare _key="${1}"; shift

	for (( i=0; i < ${#_data_ref[@]}; i=$((i+1)) )); do
		if [[ -z "${_ret_ref}" ]]; then
			_ret_ref="${_key}%5B${i}%5D=${_data_ref[${i}]}"
		else
			_ret_ref="${_ret_ref}&${_key}%5B${i}%5D=${_data_ref[${i}]}"
		fi
	done
}
# }}}
