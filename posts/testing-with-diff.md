# Simple Testing with `git diff`

Automatic tests are great, but creating and maintaining them is time consuming and sometimes really complicated. Often, getting a moderate test coverage to prevent regressions is important, but written a "proper" test suite is more work than you can justify. Let me show you how to solve this in a way that is easy to apply and does not rely on any specific programming language or ecosystem.

## Snapshot Testing
What is a quick way to get test cases? You take a well defined run of your program (usually something you did during manual testing before) and save the output. After changing your code, you run the program again and compare the outputs. This can yield one of three results:

* The output stays the same. You now know that you did not add a regression for this test case.
* The output differs in a wrong way. Go fix your code!
* The output differs in just the way you intended when changing the code. You should mark the new output as correct.

This approach is called "Snapshot Testing" and is especially useful when your program's output is so large that it is hard to describe in a test, or when you need to guarantee backwards compatibility across a huge number of test cases. But it is also great for creating high level tests quickly.

## Testing snapshots with `git diff`
There are libraries that can help you do snapshot testing. But those usually rely on a specific programming language, test runner or other infrastructure and take some time to learn. I prefer to go with tools I and most other developers already know and use: `git`, `sh` and optionally `make`. What do we actually need? We need a way to
* generate the output
* compare the differences to the accepted output
* mark output as accepted

### Generate Output
This is the hardest part and the part that depends on your specific program the most. If it is a simple unix tool, you can just create a directory with program inputs and write a small script to generate and save the corresponding outputs. I like to put such things in a Makefile like
```
# We want to generate one .out file for each .in file in `tests`
test: $(patsubst %.in,%.out,$(wildcard tests/*.in)) 

# An .out file can be created by calling myprogram on the corresponding .in file
%.out: %.in myprogram
		./myprogram $< > $@
```

### Mark Output as Accepted
It is good practice to store the test cases along with the code in you git repository. So let's just add and commit the output to the git repo! I know the general rule is to not add generated files to git, but this is no random output, it is our test suite!

### Compare the Differences to the Accepted Output
Now that we have our accepted output in git, it is trivial to check for differences and show them in a nice way:
	git diff -- tests
It is a good idea to add `--exit-code` so that a difference (and thus a failing test) will yield a non-zero exit code. Adding that to the `test` make target above results in
```
# We want to generate one .out file for each .in file in `tests`
test: $(patsubst %.in,%.out,$(wildcard tests/*.in)) 
		git diff --exit-code -- tests

# An .out file can be created by calling myprogram on the corresponding .in file
%.out: %.in myprogram
		./myprogram $< > $@
```
which will run you code on all test cases and compare the results with just a run of `make test`. A complete test runner, implemented in just four lines of `make`!

## Common Objections

### My Output Is Not Diffable
If your output is not very readable in the default diff format, there are ways to improve the situation (in order of preference):
* change your output to be more diffable (e.g. sort objects by keys if your output is JSON)
* postprocess your output (run PDFs through `pdftotext`)
* use a custom diff tool with git (you can configure different diff drivers per file type via git attributes)
* write a custom script to compare the outputs instead of using `git diff`

### My Program Does Not Create Output Files
Make it do so!
* Write a thin wrapper around core parts of you logic and serialize the results
* If it outputs user interfaces, you could create screenshots of them
* If it creates network traffic, capture it
* Get creative!

This will not only help with automatic testing, but allow you to script you program for one-off tests or other tasks.

### This Does Not Create Unit Tests
No, it doesn't. Oftentimes, you don't really need unit tests if your overall testing exercises your code well. You can still add unit tests later if you realize you need them. This is mostly about getting working tests with low effort, not about creating the perfect test suite.

### Does This Work for Real Projects
Yes, I have used it in multiple commercial projects, as well as for the [smu markdown parser](https://github.com/karlb/smu).
