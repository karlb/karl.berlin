# blog.sh

`blog.sh` is a minimal blog engine in a small shell script. Features:

* Requires only a posix shell, a markdown processor and git
* Handle both blog posts and normal pages
* No boilerplate, just create a markdown file
* Show creation and update timestamps (taken from git history)

See the [blog post](http://www.karl.berlin/blog.html) for more details.

## Quickstart

* Clone this repository `git clone git@github.com:karlb/karl.berlin.git`
* Put your blog posts as markdown files into `posts`
* Run `./blog.sh` and your posts will show up in `build/index-with-drafts.html`
* Commit posts in git to add timestamps and have them show up in `build/index.html`
* Copy the content of `build` to your webserver, so that other people can read your blog

Feel free to [contact me](karl@karl.berlin) if you have any questions.

# karl.berlin

The repo also contains the content for my personal blog and homepage (http://www.karl.berlin). If this is a problem for anyone who wants to use `blog.sh`, please let me know and I will split the repos. For now, this is more convenient for me.
