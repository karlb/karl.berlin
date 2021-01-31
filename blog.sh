#!/bin/sh
set -eu
MARKDOWN=smu
GEMINI() { <"$1" perl -0pe 's/<a href="([^"]*)".*>(.*)<\/a>/[\2](\1)/g;s/<!--.*-->//gs' | md2gemini --links paragraph; }
IFS='	'

# Create tab separated file with filename, title, creation date, last update
index_tsv() {
	for f in "$1"/*.md
	do
		created=$(git log --pretty='format:%aI' "$f" 2> /dev/null | tail -1)
		updated=$(git log --pretty='format:%aI' "$f" 2> /dev/null | head -1)
		title=$(sed -n '/^# /{s/# //p; q}' "$f")
		printf '%s\t%s\t%s\t%s\n' "$f" "${title:="No Title"}" "${created:="draft"}" "${updated:="draft"}"
	done
}

index_html() {
	# Print header
	title=$(sed -n '/^# /{s/# //p; q}' index.md)
	sed "s/{{TITLE}}/$title/" header.html

	# Intro text
	$MARKDOWN index.md

	# Posts
	while read -r f title created updated; do
		if [ "$created" = "draft" ] && [ "$2" = "hide-drafts" ]; then continue; fi
		link=$(echo "$f" | sed -E 's|.*/(.*).md|\1.html|')
		created=$(echo "$created" | sed -E 's/T.*//')
	 	echo "$created &mdash; <a href=\"$link\">$title</a><br/>"
	done < "$1"
}

atom_xml() {
	uri=$(sed -rn '/atom.xml/ s/.*href="([^"]*)".*/\1/ p' header.html)
	host=$(echo "$uri" | sed -r 's|.*//([^/]+).*|\1|')
	first_commit_date=$(git log --pretty='format:%ai' . | cut -d ' ' -f1 | tail -1)

	cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>$(sed -n '/^# /{s/# //p; q}' index.md)</title>
	<link href="$uri" rel="self" />
	<updated>$(date --iso=seconds)</updated>
	<author>
		<name>$(git config user.name)</name>
	</author>
	<id>tag:$host,$first_commit_date:default-atom-feed</id>
EOF

	while read -r f title created updated; do
		if [ "$created" = "draft" ]; then continue; fi

		day=$(echo "$created" | sed 's/T.*//')
		content=$($MARKDOWN "$f" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')

		cat <<EOF
	<entry>
		<title>$title</title>
		<content type="html">$content</content>
		<link href="$f"/>
		<id>tag:$host,$day:$f</id>
		<published>$created</published>
		<updated>$updated</updated>
	</entry>
EOF
	done < "$1"

	echo '</feed>'
}

write_page() {
	filename=$1
	target=$(echo "$filename" | sed -r 's|\w+/(.*).md|build/\1.html|')
	created=$(echo "$3" | sed 's/T.*//')
	updated=$(echo "$4" | sed 's/T.*//')
	dates_text="Written on ${created}."
	if [ "$created" != "$updated" ]; then
		dates_text="$dates_text Last updated on ${updated}."
	fi
	title=$2

	$MARKDOWN "$filename" | \
		sed "$ a <small>$dates_text</small>" | \
		cat header.html - |\
		sed "s/{{TITLE}}/$title/" \
		> "$target"

	GEMINI "$filename" | \
		sed "$ s/$/\\n\\n$dates_text/" \
		> "$(echo "$target" | sed s/.html/.gmi/)"
}


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

rm -fr build && mkdir build

# Blog posts
index_tsv posts | sort -rt "	" -k 3 > build/posts.tsv
index_html build/posts.tsv hide-drafts > build/index.html
index_html build/posts.tsv show-drafts > build/index-with-drafts.html
index_gmi build/posts.tsv hide-drafts > build/index.gmi
atom_xml build/posts.tsv > build/atom.xml
while read -r f title created updated; do
	write_page "$f" "$title" "$created" "$updated"
done < build/posts.tsv

# Pages
index_tsv pages > build/pages.tsv
while read -r f title created updated; do
	write_page "$f" "$title" "$created" "$updated"
done < build/pages.tsv

# Static files
cp -r posts/*/ build
