# Hacking on "smu", a Minimal Markdown Parser

## Introduction

I wanted to get my hands dirty and improve a [suckless](https://suckless.org/) related program. So I had a look at the [project ideas page](https://suckless.org/project_ideas/) and picked out something simple:

> Improve the Markdown parser used by the suckless wiki called "smu" to conform more to Markdown. for example for nested codeblocks. Difficulty: trivial-medium.  
> Specs: http://daringfireball.net/projects/markdown/syntax.text and http://commonmark.org/.  
> smu: https://github.com/Gottox/smu  

## First Impressions

While C is pleasantly simple in many regards, writing good code can be quite cumbersome if you're not used to it. I didn't write any serious amount of C for many years and I tend to think that C is generally a bad choice for anything that does large amounts of string manipulation. I was expecting many regular expressions and some hard-to-get-right memory allocation code. To my surprise, I didn't find a single regex and hardly any memory management code. Instead of regexes, the code relied on basic string functions like `strstr` and lots of manually-iterating-through-char-arrays.

Like most suckless programs, smu consists of a single C file with only a few hundred lines (624 in this case), had no dependencies and compiled instantly without the need to run a `configure` script.

## How smu Manages to Stay Simple

### Put Logic Into Data instead of Code

Markdown has a large amount of different syntax elements, but many of them behave in similar ways. Smu takes advantage of this by declaring the different syntax elements in data structures that can be processed by a small amount of different functions. Here's one example:

```c
static Tag lineprefix[] = {
    { "   ",        0,  "<pre><code>", "</code></pre>" },
    { "\t",         0,  "<pre><code>", "</code></pre>" },
    { "> ",         2,  "<blockquote>", "</blockquote>" },
    { "###### ",    1,  "<h6>",         "</h6>" },
    { "##### ",     1,  "<h5>",         "</h5>" },
    { "#### ",      1,  "<h4>",         "</h4>" },
    { "### ",       1,  "<h3>",         "</h3>" },
    { "## ",        1,  "<h2>",         "</h2>" },
    { "# ",         1,  "<h1>",         "</h1>" },
    { "- - -\n",    1,  "<hr />",       ""},
};
```

These declarations provide the basis of handling code indents (both with spaces and with tabs), blockquotes, headings of different levels and horizontal rules. All of these different syntax elements can now be processed by a single small functions (~45 lines). Not only does this reduce the amount of code, but it also makes it a lot easier to get an overview of the possible markup constructs and how they relate to each other.

### Avoid Memory Management

Since these syntax elements have to be parsed into different parts (markdown syntax, content, link title, link target, etc.), I was expecting many strings allocations to hold these parts. But smu gets around this in most cases by doing one of these two things:

* Instead of saving the parsed data structures, the corresponding output is generated immediately, so that the parsed strings don't have to be saved at all
* Instead of allocation a new string, two pointers are used to mark the desired substring in smu's input.

### Simplify Spec

Markdown is not something that falls out of a beautiful mathematical model, rather it is grown over the time, driven by what people "mean" when they write pseudo-plaintext. This led to a bunch of weird edge case handling rules and syntax oddities. Smu took the liberty to ignore parts of markdown (reference style links) and handle some details differently (escaping, white space handling).

## Changing smu

### Test Suite

As mentioned above, I didn't write C for a long time. I also was not sure how all Markdown should be interpreted in detail. So to prevent me from breaking everything, I needed some way to spot regressions or other bugs. When looking for Markdown test cases, I found [mdtest](https://github.com/michelf/mdtest/) and took a set of basis tests from it that mostly worked with smu. Then I looked through the remaining differences and tried to understand why smu delivered different results. That way, the tests did not only provide some safety while hacking on smu, but also showed me where it differed from other markdown implementations.

To turn the *(input, expected output)* pairs into automated test cases, I committed both to git and added a make target that regenerates the output and runs `git diff` on the test directory. When the diff shows no output, the tests have passed! This will give more false positives than mdtest's algorithm that accounts for insignificant white space, but it is much simpler.

### CommonMark Compatibility

These differences provided a nice starting ground for the first steps towards improved markdown compatibility. I could pick some minor differences that could easily be adjusted by modifying just a few line of code. At the same time, I collected a list of differences to CommonMark that I noticed but couldn't (or didn't want to) fix right away in order to add that to the documentation.

By doing a few of these changes I got more confident when changing the code and felt ready to start bigger changes. For my personal usage, one feature omitted by smu proved to be a annoyance: code fences. Without code fences, copy/pasting code to and from your markdown code blocks requires changes in indentation, which is error prone and a bit of a hassle. To implement code fences, extending one of the lists of syntax elements was not enough, since they work neither by prefixing every line of the block nor are the surrounding markers for other elements sufficient to accurately capture their block behavior. So I unfortunately had to add another parsing function to handle them correctly. That however, worked without much surprises and yielded results to my satisfaction.

One other conceptual difference I introduced was a different escaping rules. Originally, smu had the simple rule of escaping the characters `` \ ` * _ { } [ ] ( ) # + - . ! ``. This worked fine in most cases, but brought downsides with it:

1. There is not way to escape text parts that look like HTML but aren't
2. Some code parts containing backslashes lost their backslashes unless you escape them (bad for copy/paste).

To remedy the first problem, I looked up the [CommonMark escaping rules](https://spec.commonmark.org/0.29/#backslash-escapes) and added all characters from the CommomMark list to smu's list of escaped characters. Inside code spans, `` \` `` was the only escape needed to be allowed, since it would mean the end of a code span without escape and all other characters have no special meaning inside code spans/blocks. But this was an ugly special case in the code and would also lead to silently broken code samples when you add code that does contain a literal `` \` ``. How does CommonMark deal with this? The rules for code spans and code blocks allow an unlimited amount of different start and end markers, so markers can be chosen that are not present in the code itself. I chose a subset of these rules that could be expressed with smu's existing matching declarations, so that you can write ``` `` ` `` ``` if you want a code span that contains a single backtick (The pair of single white spaces is ignored). When first reading the CommonMark specs, I felt that these rules were strange and arbitrary, but after trying to find simpler alternative, I started to appreciate the spec more and more, even though I still consider parts of it to allow an unnecessarily amount of different syntaxes.

<!--
### Different approaches

* used regex
* more comments
-->

## Conclusion

Overall, the small and well structured code base allowed me to dive into the project quickly and get my first small success within the first hour of coding. This is a pleasant contrast to bigger software projects where I'm sometimes happy to have it build successfully during that time frame. The only thing that really slowed me down was the lack of tests, since I didn't dare to change most parts before I added some test coverage.

The resulting program is very usable for my markdown use cases (it rendered this page), but I would not dare to run it on potentially malicious input. I'm also not sure how well the HTML pass-through works, since I haven't used it myself, yet.

The increased CommonMark compliance should make it easier for new users to start working with smu, but it did come at a slight increase of complexity. My version is ~100 lines longer, but about half of that is comments, blank lines and additional escaping declarations. This feels like a good trade off to me.

The result can be seen on [my smu fork's github page](https://github.com/karlb/smu). Feedback welcome!
