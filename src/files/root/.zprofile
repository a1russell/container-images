[[ -r /root/.profile ]] && emulate sh -c '. /root/.profile'

if [ "$(( ls /root/.zprofile.d/*.zsh ) 2> /dev/null | wc --lines)" -gt '0' ]; then
	for f in /root/.zprofile.d/*.zsh; do
		. "$f"
	done
fi
