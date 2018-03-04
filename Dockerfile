FROM jekyll/jekyll


# use -v to give it the real path of blog folder when `docker run`
VOLUME /blog

WORKDIR /blog

EXPOSE 4000

CMD ["jekyll", "s", "--watch"]
