# Can We Make Simpler Software With LLMs?

Growing numbers of abstraction layers, vast amounts of dependencies and general complexity are what annoy me most about modern software development. LLMs are powerful tools, but in practice they often lead to even larger, more complex projects with even more dependencies. Can we use them for the opposite: small, simple software without dependencies? I tried this recently when I wanted a specific piece of software to do simple calculations inside short texts. Not all the approaches I tried are ones I'm convinced are a good idea, but I intentionally wanted to experiment a bit.

## The Project

[calced](https://github.com/karlb/calced) is a notepad calculator. You write natural-looking text with math in it, and calced evaluates the expressions and appends results. It supports things like variables, percentages (`200 + 15%`), unit conversions (`100 km in miles`), date arithmetic (`2025-01-15 + 3 weeks`), different number formats and custom conversion rates.

I wanted two implementations: a Python CLI to work on local files and a web version. The typical approach today would involve TypeScript, a bundler and lots of npm dependencies for the web version; maybe Pyodide to run the Python version in the browser and some React UI around it. Instead, I tried to use the LLM to do it in a more primitive way without spending a lot of time handcrafting code I don't care too much about.

## No Dependency Management

The web version uses [big.js](https://github.com/MikeMcl/big.js/) for arbitrary-precision math. Instead of using npm and a bundler, I had the LLM inline the library directly into the HTML file. Same for the logo SVG. The result is a single 52KB HTML file that works offline.

The Python CLI is even simpler: a single 47KB file using only the standard library. Although I prefer `click` for the nicer API, I used `argparse` instead, since the LLM can easily generate the more verbose but dependency-free version. The same is true for many similar decisions.

## No Build System

With dependencies either inlined or avoided, there is nothing left that needs a build system. No TypeScript, no bundler, no transpiler, no node_modules, no minifier. Just a single HTML file with plain JavaScript for the web version. For small projects, TypeScript is not necessary anyway, but when the LLM writes most of the code, the benefit becomes tiny (at least for the user, it might help the LLM). So let's just use JS directly! And without big dependencies the code is small enough to serve as is.

Both the JS and the Python versions can be run exactly as they are stored in version control, even when downloading just that single file.

## Two Implementations Without Transpilation

Instead of running the Python implementation in the browser via Pyodide or transpiling one version into the other, I simply asked the LLM to write and maintain both versions. To make this work, I needed a proper test setup: 18 markdown files serve as [integration tests using `git diff`](testing-with-diff.html), where calced processes them and the test verifies the output has not changed. Both implementations run against the same files, so any behavioral difference between Python and JavaScript is caught immediately. Shared JSON fixtures cover additional cases that don't fit this specific testing pattern. As long as the test fixtures are shared and cover enough of the functionality, I can use the LLM to keep both versions in sync.

Another (probably more sane) approach would have been to use JS for the CLI version too. But
* I personally prefer python
* Python has a better stdlib, requiring fewer dependencies
* the UI/CLI part needs to be done separately anyway
* having implementations in different languages prevents me from accidentally relying on that language's specifics in my math syntax
* it wouldn't allow me to try out this "keep two implementations in sync with LLM" approach (let me have some fun!)

## Avoid Needless Inconsistency

When you write something from scratch, it is easy to accidentally deviate from established conventions. I had the LLM check the CLI against the excellent [clig.dev](https://clig.dev/) and compare behavior with existing tools like [Soulver](https://soulver.app/), [Numi](https://numi.app/) and [Numbr](https://numbr.dev/), adopting the same conventions where I had no strong preference. Better consistency is not simpler in a direct technical way, but usually makes the user's life simpler, so I'll still count it towards this goal.

## Verdict

As intended, the result is small and simple compared to similar projects: a 52KB HTML file, a 47KB Python file, a 62-line Makefile and no trace of the npm ecosystem. The really interesting part will be to see how maintainable this is over a longer time frame. But I'm optimistic that at least some of the approaches are genuinely good ideas (e.g. letting the LLM check against clig.dev and comparing with similar projects).

I might have created something technically better if I wrote it by hand, but realistically, I just would not have written it at all. And when most people use LLMs to quickly generate vast amounts of code, it is nice to see that you can also use them to generate less in some cases.
