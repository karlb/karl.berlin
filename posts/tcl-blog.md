# Tcl as a Shell Scripting Replacement

Summary: I got interested in the old scripting language [Tcl](https://www.tcl.tk/), rewrote my blog generator in it as an exercise and compare it to shell scripting.

## Motivation

Every once in a while, the "[Tcl the Misunderstood](http://antirez.com/articoli/tclmisunderstood.html)" article by [antirez](http://invece.org/) gets to the front page of [Hacker News](https://news.ycombinator.com/). I've read it at least two of those times, since I appreciate antirez' opinions and I'm generally interested in programming languages. I've also often heard of Tk, one of the few simple cross-platform GUI libraries, which comes bundled with your Tcl install. Tcl is also close to the awesome SQLite project, which started out as a Tcl extension.

All of this provided a base interest in the language, but what really pushed me into action was reading the well-written "[A Philosophy of Software Design](https://www.goodreads.com/en/book/show/39996759)" book by John Ousterhout, the creator of Tcl. When his general ideas about software development resonate well with me, the language he created might do so, too. So I got his other book [Tcl and the Tk Toolkit](https://www.oreilly.com/library/view/tcl-and-the/9780321601766/) and read through most of it, playing with small code samples along the way. But to get a real feel for the language, I needed to write a real project in it, even if it is a tiny one.

## Rewriting My Blog Engine

The [simple blog engine](https://github.com/karlb/karl.berlin) I wrote recently is small enough that I could rewrite it in Tcl within a few hours. Rewriting an existing project also gave me the opportunity to compare both versions afterwards, which shows the differences caused by the change of programming language in a nice way. The comparison won't be totally fair for two reasons:

* I'm writing the code for a second time, so I already know exactly how I want the program to behave.
* I'm biased by the existing implementation, so the code will be less idiomatic in the new language.

I chose to use the existing code as a starting point and port that to Tcl line by line, so the latter point is the more serious one. Even more so, since I'm new to Tcl but have used shell scripting before.

### Rewriting Line by Line
Rewriting the first few lines already made one thing obvious: using Tcl in to call external commands is very easy and works mostly like it does in the shell. The code I use to get the time of the first git commit hardly changed:

```
-	$(git log --pretty='format:%aI' "$f" 2> /dev/null | tail -1)
+	[exec git log --pretty=format:%aI $f 2> /dev/null | tail -1]
```

The only notable difference is the lack of quoting required in the Tcl version. [Tcl's quoting rules](https://wiki.tcl-lang.org/page/Tcl+Quoting) are a bit unusual, but actually quite simple and more regular and robust than the ones in traditional Unix shells. I won't go into the details here, but I want to point out one example of increased robustness of the Tcl way. Although list elements are separated by spaces, just like in sh, having spaces in your variables will never make the variable accidentally split into multiple variables. Let's assume you have the following variables:

```
a="eggs"
b="bacon spam"
```

When you call `myfunc $a $b` in sh, you will pass three parameters to myfunc, because b gets split up at the space. In contrast, Tcl will always pass two parameters, irregardless of the content of those two variables. There are ways to avoid this in sh (and even more ways in bash), but I still run into edge cases from time to time and find Tcl's approach more pleasant and sane.

Other changes compared to the shell version were
* Use of a nested list instead of writing temporary data to a TSV, because Tcl made it easier to deal with the nested data
* Some syntactic sugar like `lassign` and explicitly named function parameters
* Replace some `sed` usages with built-in string functions

This led me to my first working Tcl version of the blog engine ([blog.1.tcl](tcl/blog.1.tcl), compare with [blog.sh](tcl/blog.sh)) which resulted in the same output as my original version, except for some insignificant whitespace differences.

### Cleaning Things Up
The next step was to go through the code a second time and look for opportunities to simplify and clean up parts that felt out of place in a Tcl program. Calls to `sed` can be replaced by using Tcl's regex support:

```
-	set host [exec echo $uri | sed -r {s|.*//([^/]+).*|\1|}]
+	regexp {.*//([^/]+).*} $uri -> host
```

One use of `sed` was not as straightforward to replace as I expected. I didn't find a compact way to return a regexp match from a file, so I wrote a small helper function.

```tcl
proc from_file {re filename} {
	set f [open $filename]
	regexp -line -- $re [read $f] -> match
	close $f
	return $match
}
```

This allowed me to replace four lines lines like `set title [exec sed -n "/^# /{s/# //p; q}" $f]` with `set title [from_file {^# (.*)} $f]`. The regexp is easier to read for me (the curly braces are just part of Tcl's quoting), which somewhat offsets the downside of requiring an extra function. Still, I don't see this as a clear improvement and would like to hear about better solutions.

The simple access to proper data structures also made me replace two calls to git (for getting first and last commit) by a single one and using the list functions get the desired parts from the result.

```diff
-       set created [exec git log --pretty=format:%aI $f 2> /dev/null | tail -1]
-       set updated [exec git log --pretty=format:%aI $f 2> /dev/null | head -1]
+       set commit_times [exec git log --pretty=format:%aI $f 2> /dev/null]
+       set created [lindex $commit_times end]
+       set updated [lindex $commit_times 0]
```

The new code is a bit longer, but less redundant and clearly displays the relationship between `created` and `updated`.

### Result
Together, these changes resulted in the final version of my blog script ([blog.tcl](tcl/blog.tcl)). Let's compare the size and run times as a last discipline.

```
$ wc blog.*
 105  354 2934 blog.sh
 105  409 3099 blog.1.tcl
 113  406 3143 blog.tcl
 323 1169 9176 total

$ time ./blog.sh
real    0m0,280s
user    0m0,263s
sys     0m0,098s

$ time ./blog.1.tcl 
real    0m0,125s
user    0m0,078s
sys     0m0,071s

$ time ./blog.tcl 
real    0m0,111s
user    0m0,085s
sys     0m0,035s
```

So the script got marginally longer but significantly faster, although all versions are more than fast enough for my case. I could probably have kept the file size the same if I wanted, but I went for readability in more cases in the Tcl script. E.g. I used `$filename` instead of `$f` and used more lines breaks (with the additional bytes for indentation that come with it) in cases like this escaping of HTML characters:

```
-	sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
+	string map {
+		& &amp;
+		< &lt;
+		> &gt;
+		\" &quot;
+		' &#39;
+	}
```

Overall, the effort for porting was low and I'm happy with the result, especially the improvement in readability.

## What Now?

So what do I do with it? Do I use it instead of my old shell version? Do I discard the code just as part of an experiment? I'm not sure, yet. I like the new code, but should I add another language to the zoo of code bases I'm maintaining? I guess it will depend on whether I find Tcl suitable for other projects. I currently see three areas that seem interesting:

* shell scripting replacement, as described in this post
* python alternative in certain use cases (lots of external programs or heavy meta programming)
* as language for interactive shells

Originally, I wanted to write about the latter two points in this article, too. But it got long enough as it is and writing separate posts will keep me more focused. If those topics sound interesting, [let me](mailto:mail@karl.berlin) know to make sure that I actually get around to writing those posts!
