source "https://rubygems.org"
ruby RUBY_VERSION
# This will help ensure the proper Jekyll version is running.

gem "jekyll", ">=4.0.0"
# gem 'jekyll-theme-portfolio', :git => "https://github.com/tedivm/jekyll-theme-portfolio.git"
gem 'jekyll-theme-portfolio', '~> 1.3'

# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem "minima", "~> 2.5"
# If you want to use GitHub Pages, remove the "gem "jekyll"" above and
# uncomment the line below. To upgrade, run `bundle update github-pages`.
# gem "github-pages", group: :jekyll_plugins
# If you have any plugins, put them here!
group :jekyll_plugins do
  gem 'jekyll-seo-tag'
  gem 'jekyll-feed'
  gem 'jekyll-remote-theme'
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", ">= 1.2"
  gem "tzinfo-data"
end

