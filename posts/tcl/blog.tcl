#!/usr/bin/env tclsh
set markdown smu

proc from_file {re filename} {
	set f [open $filename]
	regexp -line -- $re [read $f] -> match
	close $f
	return $match
}

proc make_index dir {
	foreach f [glob $dir/*] {
		set commit_times [exec git log --pretty=format:%aI $f 2> /dev/null]
		set created [lindex $commit_times end]
		set updated [lindex $commit_times 0]
		set title [from_file {^# (.*)} $f]
		if {$title eq ""} {set title "No Title"}
		if {$created eq ""} {set created "draft"}
		if {$updated eq ""} {set updated "draft"}
		lappend index [list $f $title $created $updated]
	}
	return [lsort -index 2 -decreasing $index]
}

proc index_html {index drafts} {
	# Print header
	set title [from_file {^# (.*)} index.md]
	append result [regsub "{{TITLE}}" [read [open header.html]] $title]

	# Intro text
	append result [exec $::markdown index.md] \n

	# Posts
	foreach post $index {
		lassign $post filename title created updated
		if {$created eq "draft" && $drafts eq "hide-drafts"} continue
		set link [string map {.md .html posts/ ""} $filename]
		set created [regsub T.* $created ""]
		append result "$created &mdash; <a href=\"$link\">$title</a><br/>\n"
	}
	return $result
}

proc write_page post {
	lassign $post filename title created updated
	set created [regsub T.* $created ""]
	set updated [regsub T.* $updated ""]
	set dates_text "Written on $created."
	if {$created ne $updated} {set dates_text "$dates_text Last updated on $updated."}
	
	set target [string map {.md .html posts build pages build} $filename]
	set content [exec $::markdown $filename]
	set header [regsub "{{TITLE}}" [read [open header.html]] $title]

	puts [open $target w] "$header\n$content\n<small>$dates_text</small>"
}

proc atom_xml posts {
	set uri [from_file {href="(.*?atom\.xml)"} header.html]
	regexp {.*//([^/]+).*} $uri -> host
	set first_commit_date [exec git log --pretty=format:%ai . | cut -d " " -f1 | tail -1]

	set f [open build/atom.xml w]
	puts $f "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<feed xmlns=\"http://www.w3.org/2005/Atom\">
	<title>[from_file {^# (.*)} index.md]</title>
	<link href=\"$uri\" rel=\"self\" />
	<updated>[exec date --iso=seconds]</updated>
	<author>
		<name>[exec git config user.name]</name>
	</author>
	<id>tag:$host,$first_commit_date:default-atom-feed</id>
"

	foreach post $posts {
		lassign $post filename title created updated
		if {$created eq "draft"} continue
		set day [regsub T.* $created ""]
		set content [
			string map {
				& &amp;
				< &lt;
				> &gt;
				\" &quot;
				' &#39;
			} [exec $::markdown $filename]
		]
		puts $f "
	<entry>
		<title>$title</title>
		<content type=\"html\">$content</content>
		<link href=\"$filename\"/>
		<id>tag:$host,$day:$filename</id>
		<published>$created</published>
		<updated>$updated</updated>
	</entry>"
	}

	puts $f </feed>
	close $f
}

# Build index page
set index [make_index posts]
puts [open build/index.html w] [index_html $index hide-drafts]
puts [open build/index-with-drafts.html w] [index_html $index show-drafts]
atom_xml $index

# Blog posts
foreach post $index {write_page $post}

# Pages
foreach post [make_index pages] {write_page $post}
