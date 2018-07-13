# GenerateSchemafile

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/generate_schemafile`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'generate_schemafile'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install generate_schemafile

## Usage

# make schemafile
bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile

# help
bundle exec generate_schemafile --help
