FROM ruby:3.1.2

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4567
CMD ["ruby", "server.rb", "-o", "0.0.0.0"]
