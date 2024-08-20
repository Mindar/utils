# `Audiotoggle.sh`
`audiotoggle.sh` is a small bash script to cycle the pulseaudio default sink between all available sinks. The usecase for which it was developed is to bind a keyboard key to it to quickly change audio outputs.

## Usage

There are no arguments or configurable options. Simply download the script 

`curl https://raw.githubusercontent.com/Mindar/utils/main/audiotoggle/audiotoggle.sh > audiotoggle.sh`

Then make it executable using `chmod +x audiotoggle.sh`

And finally run it `./audiotoggle.sh`


## Recommendations
These recommendations describe how I use this script. Though feel free to use it however you like.

I store it in `~/.config/i3/audiotoggle.sh`(*) and bound the XF86AudioStop key i.e. the "rectangle" audio key on my keyboard to toggle audio outputs, because I only really use the play/pause button, but not the stop button. This allowed me to bind the Stop key to switch audio outputs. Imo a thematically fitting binding for it. The relevant line in my `~/.config/i3/config` file looks like this:

```
bindsym XF86AudioStop exec $HOME/.config/i3/audiotoggle.sh
```


---

(*) That's not actually true. I actually store it in a project directory in my `$HOME` and symlinked it to that location. But that's only because I have this script in a git repo with a bunch of other scripts. If I wasn't the dev, I'd store it in the given location directly without any symlinks.