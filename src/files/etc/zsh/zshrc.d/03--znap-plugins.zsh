if [ -d "$ZNAP_HOME" ]; then

	# Znap plugins

	# fzf-tab must load before plugins which wrap widgets, e.g. zsh-autosuggestions
	znap source Aloxaf/fzf-tab

	znap source zsh-users/zsh-autosuggestions
	znap source zsh-users/zsh-syntax-highlighting

fi
