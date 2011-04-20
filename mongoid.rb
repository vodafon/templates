puts "Modifying a new Rails app to use Mongoid..."

#----------------------------------------------------------------------------
# Configure
#----------------------------------------------------------------------------

if yes?('Would you like to use jQuery instead of Prototype? (yes/no)')
  jquery_flag = true
else
  jquery_flag = false
end

if yes?('Would you like to use Blueprintcss? (yes/no)')
  blueprint_flag = true
else
  blueprint_flag = false
end

#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------
puts "setting up source control with 'git'..."
append_file '.gitignore' do <<-FILE
.DS_Store
*.swp
public/system/*
config/database.yml
FILE
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
puts "removing unneeded files..."
run 'rm config/database.yml'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'rm app/views/layouts/application.html.erb'
run 'touch README'

puts "banning spiders from your site by changing robots.txt..."
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'

#----------------------------------------------------------------------------
# jQuery Option
#----------------------------------------------------------------------------
if jquery_flag
  gem 'jquery-rails'
end

#----------------------------------------------------------------------------
# Set up Mongoid
#----------------------------------------------------------------------------
puts "setting up Gemfile for Mongoid..."
gsub_file 'Gemfile', /gem \'sqlite3/, '# gem \'sqlite3-ruby'
append_file 'Gemfile', "\n# Bundle gems needed for Mongoid\n"
gem "mongoid", "2.0.1"
gem 'bson_ext'
gem 'nifty-generators'

puts "installing Mongoid gems (takes a few minutes!)..."
run 'bundle install'

puts "creating 'config/mongoid.yml' Mongoid configuration file..."
run 'rails generate mongoid:config'

puts "creating nifty app layout"
run 'rails generate nifty:layout'

puts "modifying 'config/application.rb' file for Mongoid..."
gsub_file 'config/application.rb', /require 'rails\/all'/ do
<<-RUBY
# If you are deploying to Heroku and MongoHQ,
# you supply connection information here.
#require 'uri'
#if ENV['MONGOHQ_URL']
#  mongo_uri = URI.parse(ENV['MONGOHQ_URL'])
#  ENV['MONGOID_HOST'] = mongo_uri.host
#  ENV['MONGOID_PORT'] = mongo_uri.port.to_s
#  ENV['MONGOID_USERNAME'] = mongo_uri.user
#  ENV['MONGOID_PASSWORD'] = mongo_uri.password
#  ENV['MONGOID_DATABASE'] = mongo_uri.path.gsub('/', '')
#end

require 'mongoid/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require 'rails/test_unit/railtie'
RUBY
end

#----------------------------------------------------------------------------
# Tweak config/application.rb for Mongoid
#----------------------------------------------------------------------------
gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
<<-RUBY
config.generators do |g|
      g.orm             :mongoid
    end

    # Configure the default encoding used in templates for Ruby 1.9.
RUBY
end

puts "prevent logging of passwords"
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

#----------------------------------------------------------------------------
# Set up jQuery
#----------------------------------------------------------------------------
if jquery_flag
  run 'rm public/javascripts/rails.js'
  puts "replacing Prototype with jQuery"
  # "--ui" enables optional jQuery UI
  run 'rails generate jquery:install --ui'
end

#----------------------------------------------------------------------------
# Create a home page
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
if blueprint_flag
puts "adding blueprint-css in app"

run 'git clone git://github.com/joshuaclayton/blueprint-css.git'
run 'cp -R blueprint-css/blueprint public/stylesheets/'
run 'rm -Rf blueprint-css'

gsub_file 'app/views/layouts/application.html.erb', /<%= stylesheet_link_tag "application" %>/ do
<<-RUBY
<link rel="stylesheet" href="/stylesheets/blueprint/screen.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="/stylesheets/blueprint/print.css" type="text/css" media="print">
<!--[if lt IE 8]>
  <link rel="stylesheet" href="/stylesheets/blueprint/ie.css" type="text/css" media="screen, projection">
  <![endif]-->
<link rel="stylesheet" href="/stylesheets/blueprint/plugins/buttons/screen.css" type="text/css">
<link rel="stylesheet" href="/stylesheets/blueprint/plugins/fancy-type/screen.css" type="text/css">
<%= stylesheet_link_tag "application" %>
RUBY
end
end

puts "checking everything into git..."
git :add => '.'
git :commit => "-am 'modified Rails app to use Mongoid'"

puts "Done setting up your Rails app with Mongoid."
