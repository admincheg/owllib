FILES = \
	owllib/helpers.sh

ifeq ($(PREFIX),)
	PREFIX="${HOME}/.local/share"
endif

default:
	@ echo "You can specify PREFIX environment variable before installing"
	@ echo "By default we place libraries to ${HOME}/.local/share"
	@ echo "Installation command is 'make install'"

install:
	@ for i in $(FILES); do \
		install -D -m 0644 "$${i}" "$(PREFIX)/$${i}" ; \
	done

	@ echo "Library installed to $(PREFIX)"
