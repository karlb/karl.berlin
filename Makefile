all:
	./blog.sh

clean:
	rm -f build/*

watch:
	while true; do \
	ls -d .git/* * posts/* pages/* | entr -cd make ;\
	done

# deploy:
# 	rsync -avz build/ -e ssh www.wikdict.com:hosts/static.karl.berlin/blog

.PHONY: all clean watch deploy
