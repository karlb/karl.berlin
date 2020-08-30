all:
	./blog.sh

clean:
	rm -f build/*

watch:
	while true; do \
	ls -d .git/* * posts/* pages/* header.html | entr -cd make ;\
	done

deploy:
	rsync -avz --progress -e ssh build/ www.karl.berlin:hosts/karl.berlin

.PHONY: all clean watch deploy
