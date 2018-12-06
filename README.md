# GenerateSchemafile

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

### make schemafile
bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile

# 既存のschefileとの共存
bundle exec generate_schemafile --file_path doc/DB設計書_test.xlsx --output_path db/Schemafile --require schemas/fugafuga,hogehoge/hogehoe

# Schemafileを指定してexport
bundle exec generate_schemafile --export --file_path db/Schemafile_old.schema --output_path DB設計書.xlsx

### help
bundle exec generate_schemafile --help
