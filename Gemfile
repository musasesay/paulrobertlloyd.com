source "https://rubygems.org"

# Capistrano (automates deployment)
group :development do
  gem 'capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
end

# Guard (automates development tasks)
group :development do
  gem 'guard'
  gem 'guard-jekyll-plus', github: 'berrberr/guard-jekyll-plus'
  gem 'guard-jshintrb'
  gem 'guard-livereload'
  gem 'guard-sass'
  gem 'guard-scss-lint'
  gem 'guard-shell'

  gem 'autoprefixer-rails'
end

# Jekyll (generates static files)
gem 'jekyll'
group :jekyll_plugins do
  gem 'jekyll-archives'
  gem 'jekyll-assets'
  gem 'jekyll-minify-html'
  gem 'jekyll-pypedown'
  gem 'jekyll-sitemap'
end

# Rake (manages build tasks)
gem 'rake'

# Other dependancies
# gem 'exiftool'
gem 'mini_exiftool'
gem 'nokogiri'
gem 'therubyracer'
gem 'typogruby'
gem 'uglifier'
