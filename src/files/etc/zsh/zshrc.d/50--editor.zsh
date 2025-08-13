# Set EDITOR for Dev Container.

if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
	export EDITOR="code --wait"
# region selected JetBrains IDEs
elif pgrep fleet > /dev/null; then
	export EDITOR="$(readlink --canonicalize /proc/$(pgrep fleet | tail --lines=1)/exe)"
elif pgrep goland > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep goland | tail --lines=1)/exe))/goland.sh"
elif pgrep idea > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep idea | tail --lines=1)/exe))/idea.sh"
elif pgrep pycharm > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep pycharm | tail --lines=1)/exe))/pycharm.sh"
elif pgrep rider > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep rider | tail --lines=1)/exe))/rider.sh"
elif pgrep rustrover > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep rustrover | tail --lines=1)/exe))/rustrover.sh"
elif pgrep webstorm > /dev/null; then
	export EDITOR="$(dirname $(readlink --canonicalize /proc/$(pgrep webstorm | tail --lines=1)/exe))/webstorm.sh"
# endregion selected JetBrains IDEs
fi
