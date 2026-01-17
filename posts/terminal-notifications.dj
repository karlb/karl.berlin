# Raising Notifications From Terminal

When executing long-running jobs in the terminal, it's useful to get notified when they complete so you can do other things while waiting. Here are a few ways to achieve this.

## Using notify-send (Linux)

The simplest approach is to chain your command with `notify-send`:

```sh
slow-job; notify-send "done"
```

## If You Already Started the Job

If you've already started a long-running job and forgot to add a notification, you can still do it:

1. Press `Ctrl-Z` to suspend the job and put it in the background
2. Run `fg; notify-send "done"`

The job will resume in the foreground, and you'll get notified when it finishes.

## Notify on Success or Failure

Using `;` to chain commands will always raise the notification, regardless of whether the job succeeded or failed. You can use `&&` and `||` to be more selective:

```sh
slow-job && notify-send "success"   # only on success
slow-job || notify-send "failed"    # only on failure
```

This also works when adding the notification after backgrounding the process with Ctrl-Z:

```sh
fg || notify-send "failed"
```

## Using osascript (macOS)

On macOS, you can use `osascript` instead:

```sh
slow-job; osascript -e 'display notification "done" with title "Terminal"'
```

I've put this osascript command (with a `$1` instead of `done`) into a small script called `notify-send`, so that I can use the same command on both Linux and macOS. Since I don't use more than a single text parameter for my notifications, that works well for me.

## The Terminal Bell

An interesting alternative is ringing the terminal bell:

```sh
slow-job; echo -e '\a'
```

Many terminal emulators show some kind of notification or badge when the bell rings while the terminal is in the background. The great thing about this approach is that it works across many platforms and even through SSH sessions!

## OSC 777

Some terminals support the (highly underdocumented) OSC 777 escape sequence for desktop notifications:

```sh
slow-job; printf '\x1b]777;notify;Command;Job finished\x1b\\'
```

Just like the terminal bell, this emits an escape sequence that is interpreted by the terminal emulator, but is made specifically for raising desktop notifications. So it keeps the terminal bell's advantages of not requiring external tools and working through SSH. Terminals that support this include foot, Ghostty, WezTerm and some others.

[Kitty](https://sw.kovidgoyal.net/kitty/) has its own [notification protocol](https://sw.kovidgoyal.net/kitty/desktop-notifications/) with advanced features like icons, buttons, and urgency levels. It comes with a convenient [notify kitten](https://sw.kovidgoyal.net/kitty/kittens/notify/) that wraps this:

```sh
slow-job; kitten notify "Done" "Job finished"
```

## Closing Thoughts

For quick local work, `notify-send` or `osascript` are straightforward and provided by the system. The terminal bell is the most portable option. OSC 777 gives you proper notifications without external tools. The last two also work through SSH. In the long run, I'm hoping for proper standardization, documentation and widespread support of OSC 777, but for now I can't blindly recommend a single approach, so this blog post seems necessary.
