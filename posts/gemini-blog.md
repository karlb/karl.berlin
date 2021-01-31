# Adding Gemini Support With Just a Few Lines of Code

The Gemini protocol nicely matches my preference for simplicity, so I want to start providing content for it to show my support. The first step for doing that is providing this blog via Gemini. I'll quickly summarize the steps that were necessary to do this in this post.

## What is Gemini?

[Gemini](https://gemini.circumlunar.space/) is an extremely simplified version of the web. It doesn't have Javascript, CSS (or any other kind of styling) and it's markup language Gemtext is much simpler than Markdown. It doesn't use HTTP, but works in a similar way. Don't be irritated by the lack of content about Gemini on the web. You'll see most of the content about it only after installing a Gemini client. My recommendation is [LaGrange](https://gmi.skyjake.fi/lagrange/). The great thing about Gemini is that both creating and consuming content is pretty easy due to the low complexity in every regard.

## Generating Gemtext

I don't want to write each block post twice, so I'd like to convert the existing posts (written in Markdown) to Gemtext automatically. Fortunately, there's [md2gemini](https://github.com/makeworld-the-better-one/md2gemini), which can handle the conversion process. Since Gemtext does not support inline links, the links in my posts have to be moved out of the paragraphs into separate lines. md2gemini offers multiple ways to that. Putting the links at the end of each paragraph and numbering the references inside the paragraph (like this `[1]`) seemed like the most readable way to me, so I chose that one.

The resulting Gemini pages worked, but had two problems left:
* The comments I left for myself in some posts suddenly became visible
* The HTML-links I use to include the `rel="me"` attribute on the index page were not converted

Both of these issues arise because md2gemini does not try to interpret HTML (which is allowed in Markdown documents). The easy fix was to replace the HTML markup before passing it to md2gemini with regular expressions:
```
s/<a href="([^"]*)".*>(.*)<\/a>/[\2](\1)/g
s/<!--.*-->//gs
```

Combined with the call to md2gemini, this led to the following shell function to process Markdown to Gemtext.
```
GEMINI() {
	<"$1" perl -0pe 's/<a href="([^"]*)".*>(.*)<\/a>/[\2](\1)/g;s/<!--.*-->//gs' | md2gemini --links paragraph;
}
```

Now I can use this inside my page generation loop, I just have to replace the target suffix and append the last modification date.

```
GEMINI "$filename" | \
	   sed "$ s/$/\\n\\n$dates_text/" \
	   > "$(echo "$target" | sed s/.html/.gmi/)"
```

With the posts working, I'm still missing a proper index page. It should consist of an introductory text and a list of blog posts, ideally prefixed by the ISO date of the post, so that it matches the optional [Gemini feed format](gemini://gemini.circumlunar.space/docs/companion/subscription.gmi). Instead of doing any abstractions, I just copied the index generation code for the HTML version and adapted it to Gemtext.

```
index_gmi() {
       # Intro text
       GEMINI index.md

       # Posts
       while read -r f title created updated; do
               if [ "$created" = "draft" ] && [ "$2" = "hide-drafts" ]; then continue; fi
               link=$(echo "$f" | sed -E 's|.*/(.*).md|\1.gmi|')
               created=$(echo "$created" | sed -E 's/T.*//')
               echo "=> $link $created - $title"
       done < "$1"
 }
```

That's all that was necessary to create Gemtext pages for my blog. Right now, there are only two things I plan to improve in the future:
* Add the [list of my projects](projects.html). That page is not a blog post and thus slightly special.
* Keep links between blog pages consistent. Right now, they all link to the HTML version, even in the Gemini version.

## Setting Up the Server

Since Gemini doesn't use HTTP, I can't just copy the generated pages to my normal webspace. Fortunately, setting up a Gemini server is pretty easy.

### Choosing a Server

There are plenty of Gemini servers. I chose [gmnisrv](https://git.sr.ht/~sircmpwn/gmnisrv) for the following reasons:
* Few dependencies (written in plain C)
* Automatic certificate handling (Gemini always uses TLS and thus needs certificates)
* Support for virtual hosts, which will allow me to add more Gemini services on the same host in the future

### Installing gmnisrv

The compilation and installation was dead simple and done in a minute, just by following the instructions in gmnisrv's readme. Writing the configuration was also straightforward and resulted in this small config.

```
listen=0.0.0.0:1965 [::]:1965

[:tls]
store=/var/lib/gemini/certs

[gmi.karl.berlin]
root=/home/karl/hosts/karl.berlin/
```

The Gemini server itself worked now, but it was not reachable from the outside, yet. The two missing steps were
* Configure the DNS setting for gmi.karl.berlin.
* Open the Gemini ports in the firewall: `sudo ufw allow 1965/tcp`

As a final touch, I added a systemd unit to automatically start gmnisrv.

```
[Unit]
Description=gmnisrv Gemini server (see /usr/local/etc/gmnisrv.ini for config)

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=gmnisrv

[Install]
WantedBy=default.target
```

Please note that you want to use a non-root user if there are other important services on the machine.

## Result

That's it! If you are still reading this in your web browser, fire up your Gemini client and look at [the result](gemini://gmi.karl.berlin/)! Considering that this was a low effort way to create a presence in Gemini space, I'm quite pleased with the results.

My next goal regarding Gemini will be to bring [WikDict](http://www.wikdict.com) to Gemini, which should be a bit more challenging.
