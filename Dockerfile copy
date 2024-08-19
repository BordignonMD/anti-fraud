# Dockerfile

# Use an official Ruby runtime as a parent image
FROM ruby:3.2.2

# Set environment variables
# ENV RAILS_ENV=development

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs npm postgresql-client

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Precompile assets for production
# RUN RAILS_ENV=development rails assets:precompile
# RUN bundle exec rake assets:precompile

# Expose port 3000 to the outside world
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
