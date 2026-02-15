# Easily Entering Umlauts With a US Keyboard Layout

As a software developer, a US keyboard layout is great for entering all the special characters you need while coding and for using certain applications like vim. But as a German speaker, I also frequently need to enter German characters that don't exist in English: the Umlauts äÄöÖüÜ and ß. I want to do this without giving up the US layout and without having to press complicated key combinations (no dead keys, no unintuitive combinations).

My goal is to get the German characters by holding right alt ("Alt Gr") while pressing the respective Latin character. E.g. ralt+a => ä.

## Previous Approach: xmodmap

For the last years, I used the following `.Xmodmap` file, which could be applied by running `xmodmap .Xmodmap`:

```keycode 108 = Mode_switch Alt_R
keycode 39 = s S ssharp
keycode 38 = a A adiaeresis Adiaeresis
keycode 30 = u U udiaeresis Udiaeresis
keycode 32 = o O odiaeresis Odiaeresis
```

This worked, but had two downsides:
* It only works with Xorg, but not with Wayland.
* The applied modmap got lost regularly (related to suspend or screen locking?), so I had to rerun `xmodmap` frequently.

## New approach: xkb

Fortunately, there is a way that (despite its name) works for both Wayland and Xorg: setting up a user specific xkb configuration. Based on a [detailed blog post](http://who-t.blogspot.com/2020/09/user-specific-xkb-configuration-putting.html) and a [github comment](http://who-t.blogspot.com/2020/09/user-specific-xkb-configuration-putting.html), I created the following configuration:

```
File: .config/xkb/rules/evdev.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xkbConfigRegistry SYSTEM "xkb.dtd">
<xkbConfigRegistry version="1.1">
  <layoutList>
    <layout>
      <configItem>
        <name>us</name>
      </configItem>
      <variantList>
        <variant>
          <configItem>
            <name>umlaut</name>
            <shortDescription>umlaut</shortDescription>
            <description>English (US, international with German umlauts)</description>
          </configItem>
        </variant>
      </variantList>
    </layout>
  </layoutList>
</xkbConfigRegistry>

File: .config/xkb/symbols/us
partial alphanumeric_keys
xkb_symbols "umlaut" {
    include "us(altgr-intl)"
    include "level3(caps_switch)"
    name[Group1] = "English (US, international with German umlaut)";
    key <AD03> { [ e, E, EuroSign, cent ] };
    key <AD07> { [ u, U, udiaeresis, Udiaeresis ] };
    key <AD09> { [ o, O, odiaeresis, Odiaeresis ] };
    key <AC01> { [ a, A, adiaeresis, Adiaeresis ] };
    key <AC02> { [ s, S, ssharp ] };
};
```

If you prefer, you can also find the files in [my dotfiles repo](https://github.com/karlb/dotfiles/tree/master/.config/xkb).

After restarting your desktop environment, you can select the keyboard layout and start using it. Under GNOME, you'll find it under Settings -> Keyboard -> Input Sources -> + -> English.

## Alternatives

Recent versions of xkeyboard-config include a ["de\_se\_fi" variant for the us layout](https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/blob/master/symbols/us#L2241-2262), that should give you the same results as my approach above.

There's also the [AltGr-wEur](https://altgr-weur.eu/) keyboard layout, which fits the Danish, Dutch, Finnish, French, German, Italian, Norwegian, Portuguese, Spanish and Swedish characters all into a single keyboard layout without using dead keys. Combining all of these languages requires compromises, which results in the German ß not being on the S key but on number 8 key. If that's ok for you, this layout is a good choice.
