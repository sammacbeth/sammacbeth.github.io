FROM ruby:2
WORKDIR /opt/
RUN apt-get update && apt-get install -y bundler
COPY Gemfile ./
COPY Gemfile.lock ./
RUN gem install bundler:1.16.1
RUN bundle install

CMD ["jekyll", "serve"]
EXPOSE 4000