run:
	@rm -rf _site
	@docker container run --rm -it -v $(CURDIR):/srv/jekyll -p 4000:4000 jekyll/jekyll:3.8 jekyll serve --incremental
