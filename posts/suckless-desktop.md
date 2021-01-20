# Suckless Software on My Desktop

I took a look at which simple programs I could use as a desktop environment instead of Gnome and picked out the following ones

* [st](https://st.suckless.org/) as a terminal
* [dwm](https://dwm.suckless.org/) as a window manager, along with [slstatus](https://tools.suckless.org/slstatus/)
* [slock](https://tools.suckless.org/slock/) for screen locking

## Initial Impression

The suckless tools are configured by editing C header files before compilation. This is pretty straightforward to do in most cases, but it requires dealing with source changes in git repos instead of using config files. For now these changes stay outside my dotfiles repo and I'm not sure about the best way to version and sync this type of configuration.

One very pleasant aspect is how easily and fast the programs compile. They have hardly any dependencies and compilation is finished nearly at the same moment as you hit the enter key to call make.

Since each of the programs handles only a single concern, you have to collect more of them than you're used to when you want to cover the usual amount of use cases. This allows freely mixing and matching different tools as you like. I like the general approach, but would have preferred a way to get a selection of recommended programs and configs and start using a known-good setup before fiddling with the details.

## Additional Configuration

### xbindkeys

I want to be able to change the volume and screen brightness with the media keys and have a keybinding to turn off and lock my screen. This can be configured with [xbindkeys](https://www.nongnu.org/xbindkeys/) by assigning shell commands to certain keys. This has a nice unix feel to it, but needs some fiddling to get right. I also miss the visual feedback when changing brightness and volume.

```
# Brightness +
"lux -a 100"
    XF86MonBrightnessUp 

# Brightness -
"lux -s 100"
    XF86MonBrightnessDown 


# Increase volume
"pactl set-sink-volume @DEFAULT_SINK@ $(pacmd list-sinks | awk '/volume:/ {print int($3 * 1.2); exit}'); pacmd list-sinks | awk '/volume:/ {print $5; exit}' | dzen2 -p 2"
   XF86AudioRaiseVolume
# Decrease volume
"pactl set-sink-volume @DEFAULT_SINK@ $(pacmd list-sinks | awk '/volume:/ {print int($3 * 0.8); exit}'); pacmd list-sinks | awk '/volume:/ {print $5; exit}' | dzen2 -p 2"
   XF86AudioLowerVolume
# Mute volume
"pactl set-sink-mute @DEFAULT_SINK@ toggle"
   XF86AudioMute

# Shift + super + L locks screen and turns display off
"slock & (sleep 1 && xset dpms force off)"
   Shift + Mod4 + l

# turn screen off
"sleep 1.0 && xset dpms force off"
   shift + mod4 + s

"systemctl suspend"
   shift + mod4 + z

"autorandr -c"
   control+shift + a

# toggle redshift
"killall redshift || redshift -l 52.5200:13.4050 -b 0.7:0.3 &"
   shift + mod4 + r
```

## Problems

### autolock

I didn't find an autolock setup that worked as well as I would like. My goal would be:
* Lock screen when sleeping or after X minutes
* Turn screen off when locking
* Don't lock when watching fullscreen videos in Firefox

I could not get the last point working reliably for me with xautolock or [xidlehook](https://github.com/jD91mZM2/xidlehook) ([bug report](https://github.com/jD91mZM2/xidlehook/issues/23)). I stopped using autolock and just manually lock my screen.

### Versioning My Setup

As noted above, the suckless tools don't use config files, so they I can't put their configuration in version control as I am used to.

### Lack of Good Predefined Setup

While the programs work well and reliably, using them is not just matter of installing and running them. Getting to a usable setup involves quite some time of choosing the right set of programs and configuration that works for you. I would have liked a known-good setup as a starting point.

<!--
## Other simple tools

* tmux
* cmus

## Not relevant because not desktop

* smu
* entr

## Big software

* Web browser (Firefox, Chromium)
* Games (steam, etc)

## Web Apps

* GMail
* Spotify

-->
