# `make` as a Static Site Generator

Static site generators are in fashion for good reasons. The resulting pages are easy to host, fast and extremely low on maintenance while being sufficient for many use cases.
As I learned when [setting up my blog](blog.html), writing a simple script myself is faster and more satisfying than learning one of the other site builders and customizing it to my needs.
This time, I only need a plain site without automatically updated timestamps or an RSS-feed, so I can go even simpler than by blog script.

## Basic setup

To get the site into a working state, I require the following functionality:
* All input files reside in the `source` directory, in the same layout as I want them in the output.
* During processing, add a header to all HTML files.
* Copy all other files to the `build` directory as they are.

Each of these points results in one rule in the Makefile:

```make
# The `build` target depends on all output files in the `build` directory. It
# does not do anything by itself, but causes one of the following rules to be
# applied for each file.
build: $(patsubst source/%,build/%,$(shell find source -type f))

# For each .html file do `cat header.html $input > $output`.
build/%.html: source/%.html header.html Makefile
	@mkdir -p $(dir $@)
	cat header.html $< > $@

# Copy all other files without changes.
build/%: source/%
	cp $< $@
```

With a corresponding `header.html` and these rules in place, calling `make build` will create a `build` directory that can be browsed locally or uploaded to any web server.

## Variations

This is really all you need, but the real strength of this approach is that it is so simple, that you can trivially extend it to fit different needs. Let me show you a few examples!

### Mark Current Page

It is helpful to highlight the current page in the navigation so that the visitor sees where he is within the site at a glance. To do this, we search for the link within the navigation and replace the link with a highlighted version. The specifics vary depending on your markup. I'm using the following code to add the `current` class to the link tag:

```make
build/%.html: source/%.html header.html Makefile
	@mkdir -p $(dir $@)
	sed -E 's|(href="$(subst source,,$<))|class="current" \1|' header.html | cat - $< > $@
```

### Generate Page From Markdown

If you dislike writing HTML or if you have existing content in markdown format, you can pipe your markdown content through a markdown-to-HTML converter of you choice (I like [smu](https://github.com/karlb/smu)).
```make
build/%.html: source/%.html header.html Makefile
	@mkdir -p $(dir $@)
	smu $< | cat header.html - > $@
```

Since we still assume that `build/foo.html` is built from `source/foo.html`, you should keep the `.html` suffix for the markdown files or modify the rules to look for `.md` files as input.

## Little Helpers

You can not only modify the site generation itself. Convenience features can also be added as additional make targets.

### Serve Site Locally

Not all sites can be accurately previewed by opening the local files in your browser.
The most common reason for this is using absolute links instead of relative ones.
In those cases, you will want to run a small test web server locally to preview your site.
Python is already installed on many systems and comes with a web server this is suitable for the task.

```make
serve:
	python -m http.server -d build
```

### Rebuild on Change

If you work a lot on your site, manually rebuilding after each change is a hassle.
Just use [`entr`](https://eradman.com/entrproject/) (or [`inotifywait`](https://linux.die.net/man/1/inotifywait) if you want to avoid the dependency) to rebuild automatically when a file in the source directory changes.

```make
watch:
	find source header.html Makefile | entr make build
```

### Upload to GitHub Pages

I store my repositories on GitHub, so using GitHub Pages to host the resulting HTML is a natural choice.
Getting the commands just right so that you don't have to care about git details when publishing is a bit tricky, but easy enough in the end.
The approach is based on [Sangsoo Nam's post](https://sangsoonam.github.io/2019/02/08/using-git-worktree-to-deploy-github-pages.html).

```make
deploy:
	git worktree add public_html gh-pages
	cp -rf build/* public_html
	cd public_html && \
	  git add --all && \
	  git commit -m "Deploy to github pages" && \
	  git push origin gh-pages
	git worktree remove public_html
```

## Summary

Having your own static site generator in only six simple lines in a Makefile is great!
There are no exotic dependencies, nothing to maintain and you can quickly adapt it to your needs.
A page I built using this approach is available at <https://github.com/karlb/astridbartel.de> and can serve as a real world example.
