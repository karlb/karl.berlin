build:
	./blog.sh

clean:
	rm -f build/*

watch:
	while true; do \
	ls -d .git/* * posts/* pages/* header.html | entr -cd make ;\
	done

deploy: build
	rsync -avz --progress -e ssh build/ www.karl.berlin:hosts/karl.berlin

.PHONY: build clean watch deploy
