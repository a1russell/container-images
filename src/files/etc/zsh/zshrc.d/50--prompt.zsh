if command -v starship > /dev/null 2>&1; then
	znap eval starship 'starship init zsh --print-full-init'
	znap prompt
else
	znap prompt adam1
fi
