gem 'russian'

# Environment settings management
gem 'figaro'

gem_group :console do
  gem 'awesome_print'
  gem 'hirb'
end

gem_group :development do
  # Debuging and profiling
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'quiet_assets'

  # Code styling
  gem 'rubocop', require: false
  gem 'rubocop-rspec'

  # Guard
  gem 'guard'
  gem 'guard-rubocop'
  gem 'guard-bundler', require: false
  gem 'guard-rspec', require: false
  gem 'terminal-notifier'
  gem 'terminal-notifier-guard'
end

gem_group :development, :test do
  gem 'rspec-rails'
end

gem_group :test do
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end


application <<-RUBY
    config.time_zone = 'Moscow'
    I18n.enforce_available_locales = true

    # Disable unnecessary generators
    config.generators do |g|
      g.assets = false
      g.helper = false
    end

    # Application locale
    I18n.default_locale = :ru
    I18n.locale = :ru

    # Enable console tweaks
    console do
      Bundler.require(:console)
      ActiveRecord::Base.logger = Logger.new(STDOUT)

      AwesomePrint.irb! if defined?(::AwesomePrint)
      Hirb.enable if defined?(::Hirb)
    end
RUBY

create_file 'Guardfile', 'guard :bundler do
  require \'guard/bundler\'
  require \'guard/bundler/verify\'
  helper = Guard::Bundler::Verify.new

  files = [\'Gemfile\']
  files += Dir[\'*.gemspec\'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

guard :rubocop do
  watch(/.+\.rb$/)
  watch(%r{/(?:.+\/)?\.rubocop\.yml$/}) { |m| File.dirname(m[0]) }
end

guard :rspec, cmd: \'bundle exec rspec\' do
  watch(\'spec/spec_helper.rb\')                        { \'spec\' }
  watch(\'config/routes.rb\')                           { \'spec/routing\' }
  watch(\'app/controllers/application_controller.rb\')  { \'spec/controllers\' }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  do |m|
    ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"]
  end
end
'

create_file '.rubocop.yml','Style/Documentation:
  Enabled: false
Metrics/LineLength:
  Max: 120
Metrics/MethodLength:
  Max: 20

AllCops:
  Exclude:
      - \'db/**/*\'
      - \'bin/*\'
      - \'config/**/*\'
      - \'lib/tasks/auto_annotate_models.rake\'
      - \'app/views/**/*\'
      - \'Guardfile\'
      - \'Gemfile\'
  RunRailsCops: true'

create_file '.rspec','--color
--color
--require spec_helper'

remove_file '.gitignore'
create_file '.gitignore', '# Ignore bundler config.
/.bundle

# Ignore all logfiles and tempfiles.
/log/*.log
/tmp

# Ignore sensitive data
config/application.yml

.rubocop_todo.yml
vendor/bundle
db/schema.rb
'

create_file '.editorconfig', '# EditorConfig helps developers define and maintain consistent
# coding styles between different editors and IDEs
# editorconfig.org

root = true

[*]

# Change these settings to your own preference
indent_style = space
indent_size = 2

# We recommend you to keep these unchanged
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false
'

create_file 'config/application.yml'
create_file 'config/application.yml.sample'

create_file 'spec/spec_helper.rb', 'RSpec.configure do |config|
end
'

create_file 'spec/rails_helper.rb', 'require \'spec_helper\'
require File.expand_path(\'../../config/environment\', __FILE__)
require \'rspec/rails\'
Dir[Rails.root.join(\'spec/support/**/*.rb\')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.render_views = true

  config.include Requests::JsonHelpers, type: :controller

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
'

create_file 'spec/support/request_helpers.rb', 'module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end
end
'
