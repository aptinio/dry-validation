[gem]: https://rubygems.org/gems/dry-validation
[travis]: https://travis-ci.org/dryrb/dry-validation
[gemnasium]: https://gemnasium.com/dryrb/dry-validation
[codeclimate]: https://codeclimate.com/github/dryrb/dry-validation
[coveralls]: https://coveralls.io/r/dryrb/dry-validation
[inchpages]: http://inch-ci.org/github/dryrb/dry-validation

# dry-validation [![Join the chat at https://gitter.im/dryrb/chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/dryrb/chat)

[![Gem Version](https://badge.fury.io/rb/dry-validation.svg)][gem]
[![Build Status](https://travis-ci.org/dryrb/dry-validation.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/dryrb/dry-validation.svg)][gemnasium]
[![Code Climate](https://codeclimate.com/github/dryrb/dry-validation/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/dryrb/dry-validation/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/dryrb/dry-validation.svg?branch=master)][inchpages]

Data validation library based on predicate logic and rule composition.

## Overview

Unlike other, well known, validation solutions in Ruby, `dry-validation` takes
a different approach and focuses a lot on explicitness, clarity and preciseness
of validation logic. It is designed to work with any data input, whether it's a
simple hash, an array or a complex object with deeply nested data.

It is based on a simple idea that each validation is encapsulated by a simple,
stateless predicate, that receives some input and returns either `true` or `false`.

Those predicates are encapsulated by `rules` which can be composed together using
`predicate logic`. This means you can use the common logic operators to build up
a validation `schema`.

It's very explicit, powerful and extendible.

Validations can be described with great precision, `dry-validation` eliminates
ambigious concepts like `presence` validation where we can't really say whether
some attribute or key is *missing* or it's just that the value is `nil`.

There's also the concept of type-safety, completely missing in other validation
libraries, which is quite important and useful. It means you can compose a validation
that does rely on the type of a given value. In example it makes no sense to validate
each element of an array when it turns out to be an empty string.

## The DSL

The core of `dry-validation` is rules composition and predicate logic. The DSL
is a simple front-end for that. It only allows you to define the rules by using
predicate identifiers. There are no magical options, conditionals and custom
validation blocks known from other libraries. The focus is on pure validation
logic.

## Examples

### Basic

Here's a basic example where we validate following things:

* The input *must have a key* called `:email`
  * Provided the email key is present, its value *must be filled*
* The input *must have a key* called `:age`
  * Provided the age key is present, its value *must be an integer* and it *must be greater than 18*

This can be easily expressed through the DSL:

``` ruby
require 'dry-validation'

class Schema < Dry::Validation::Schema
  key(:email) { |email| email.filled? }

  key(:age) do |age|
    age.int? & age.gt?(18)
  end
end

schema = Schema.new

errors = schema.call(email: 'jane@doe.org', age: 19).messages

puts errors.inspect
# []

errors = schema.call(email: nil, age: 19).messages

puts errors.inspect
# { :email => [["email must be filled", nil]] }
```

A couple of remarks:

* `key` assumes that we want to use the `:key?` predicate to check the existance of that key
* `age.gt?(18)` translates to calling a predicate like this: `schema[:gt?].(18, age)`
* `age.int? & age.gt?(18)` is a conjunction, so we don't bother about `gt?` unless `int?` returns `true`
* You can also use `|` for disjunction
* Schema object does not carry the input as its state, nor does it know how to access the input values, we
  pass the input to `call` and get error set as the response

### Optional Keys

You can define which keys are optional and define rules for their values:

``` ruby
require 'dry-validation'

class Schema < Dry::Validation::Schema
  key(:email) { |email| email.filled? }

  optional(:age) do |age|
    age.int? & age.gt?(18)
  end
end

schema = Schema.new

errors = schema.call(email: 'jane@doe.org').messages

puts errors.inspect
# []

errors = schema.call(email: 'jane@doe.org', age: 17).messages

puts errors.inspect
# { :age => [["age must be greater than 18"], 17] }
```

### Optional Values

When it is valid for a given value to be `nil` you can use `none?` predicate:

``` ruby
require 'dry-validation'

class Schema < Dry::Validation::Schema
  key(:email) { |email| email.filled? }

  key(:age) do |age|
    age.none? | (age.int? & age.gt?(18))
  end
end

schema = Schema.new

errors = schema.call(email: 'jane@doe.org', age: nil).messages

puts errors.inspect
# []

errors = schema.call(email: 'jane@doe.org', age: 19).messages

puts errors.inspect
# []

errors = schema.call(email: 'jane@doe.org', age: 17).messages

puts errors.inspect
# { :age => [["age must be greater than 18"], 17] }
```

### Optional Key vs Value

We make a clear distinction between specifying an optional `key` and an optional
`value`. This gives you a way of being very specific about validation rules. You
can define a schema which can give you precise errors when a key was missing or
key was present but the value was nil.

This also comes with the benefit of being explicit about the type expectation.
In the example above we explicitly state that `:age` *can be nil* or it *can be an integer*
and when it *is an integer* we specify that it *must be greater than 18*.

Another benefit is that we can infer specific coercion rules when types are specified.
In example [`Schema::Form`](https://github.com/dryrb/dry-validation#form-validation-with-coercions)
will use `form.nil` type from dry-data to coerce empty strings into `nil` for you
whenever you specify `value.none? | value.int?`. Furthermore it will try to coerce
to `int` since that is our type expectation.

### Nested Hash

We are free to define validations for anything, including deeply nested structures:

``` ruby
require 'dry-validation'

class Schema < Dry::Validation::Schema
  key(:address) do |address|
    address.hash? do
      address.key(:city) do |city|
        city.min_size?(3)
      end

      address.key(:street) do |street|
        street.filled?
      end

      address.key(:country) do |country|
        country.key(:name, &:filled?)
        country.key(:code, &:filled?)
      end
    end
  end
end

schema = Schema.new

errors = schema.call({}).messages

puts errors.inspect
# { :address => ["address is missing"] }

errors = schema.call(address: { city: 'NYC' }).messages

puts errors.to_h.inspect
# {
#   :address => [
#     { :street => ["street is missing"] },
#     { :country => ["country is missing"] }
#   ]
# }
```

### Array Elements

You can use `each` rule for validating each element in an array:

``` ruby
class Schema < Dry::Validation::Schema
  key(:phone_numbers) do |phone_numbers|
    phone_numbers.array? do
      phone_numbers.each(&:str?)
    end
  end
end

schema = Schema.new

errors = schema.call(phone_numbers: '').messages

puts errors.inspect
# { :phone_numbers => [["phone_numbers must be an array", ""]] }

errors = schema.call(phone_numbers: ['123456789', 123456789]).messages

puts errors.inspect
# {
#   :phone_numbers => [
#     {
#       :phone_numbers => [
#         ["phone_numbers must be a string", 123456789]
#       ]
#     }
#   ]
# }
```

### Rules Depending On Other Rules

When a rule needs input from other rules and depends on their results you can
define it using `rule` DSL. A common example of this is "confirmation validation":

``` ruby
class Schema < Dry::Validation::Schema
  key(:password, &:filled?)
  key(:password_confirmation, &:filled?)

  rule(:password_confirmation, eql?: [:password, :password_confirmation])
end
```

A short version of the same thing:

``` ruby
class Schema < Dry::Validation::Schema
  confirmation(:password)
end
```

Notice that you must add `:password_confirmation` error message configuration if
you want to have the error converted to a message.

### Form Validation With Coercions

Probably the most common use case is to validate form params. This is a special
kind of a validation for a couple of reasons:

* The input is a hash with stringified keys
* The input include values that are strings, hashes or arrays
* Prior validation, we need to coerce values and symbolize keys based on the
  information from rules

For that reason, `dry-validation` ships with `Schema::Form` class:

``` ruby
require 'dry-validation'
require 'dry/validation/schema/form'

class UserFormSchema < Dry::Validation::Schema::Form
  key(:email) { |value| value.str? & value.filled? }

  key(:age) { |value| value.int? & value.gt?(18) }
end

schema = UserFormSchema.new

errors = schema.call('email' => '', 'age' => '18').messages

puts errors.inspect
# {
#   :email => [["email must be filled", nil]],
#   :age => [["age must be greater than 18 (18 was given)", 18]]
# }
```

There are few major differences between how it works here and in `ActiveModel`:

* We have type checking as predicates, ie `gt?(18)` will not be applied if the value
  is not an integer
* Thus, error messages are provided *only for the rules that failed*
* There's a planned feature for generating "validation hints" which lists information
  about all possible rules
* Coercion is handled by `dry-data` coercible hash using its `form.*` types that
  are dedicated for this type of coercions
* It's very easy to add your own types and coercions (more info/docs coming soon)

### Defining Custom Predicates

You can simply define predicate methods on your schema object:

``` ruby
class Schema < Dry::Validation::Schema
  key(:email) { |value| value.str? & value.email? }

  def email?(value)
    ! /magical-regex-that-matches-emails/.match(value).nil?
  end
end
```

You can also re-use a predicate container across multiple schemas:

``` ruby
module MyPredicates
  include Dry::Validation::Predicates

  predicate(:email?) do |input|
    ! /magical-regex-that-matches-emails/.match(value).nil?
  end
end

class Schema < Dry::Validation::Schema
  configure do |config|
    config.predicates = MyPredicates
  end

  key(:email) { |value| value.str? & value.email? }
end
```

You need to provide error messages for your custom predicates if you want them
to work with `Schem#messages` interface.

You can learn how to do that in the [Error Messages](https://github.com/dryrb/dry-validation#error-messages) section.

## List of Built-In Predicates

### Basic

* `none?`
* `eql?`
* `key?`

### Types

* `str?`
* `int?`
* `float?`
* `decimal?`
* `bool?`
* `date?`
* `date_time?`
* `time?`
* `array?`
* `hash?`

### Number, String, Collection

* `empty?`
* `filled?`
* `gt?`
* `gteq?`
* `lt?`
* `lteq?`
* `max_size?`
* `min_size?`
* `size?(int)`
* `size?(range)`
* `format?`
* `inclusion?`
* `exclusion?`

## Error Messages

By default `dry-validation` comes with a set of pre-defined error messages for
every built-in predicate. They are defined in [a yaml file](https://github.com/dryrb/dry-validation/blob/master/config/errors.yml)
which is shipped with the gem. This file is compatible with `I18n` format.

You can provide your own messages and configure your schemas to use it like that:

``` ruby
class Schema < Dry::Validation::Schema
  configure { |config| config.messages_file = '/path/to/my/errors.yml' }
end
```

You can also provide a namespace per-schema that will be used by default:

``` ruby
class Schema < Dry::Validation::Schema
  configure { |config| config.namespace = :user }
end
```

Lookup rules:

``` yaml
en:
  errors:
    size?:
      arg:
        default: "%{name} size must be %{num}"
        range: "%{name} size must be within %{left} - %{right}"

      value:
        string:
          arg:
            default: "%{name} length must be %{num}"
            range: "%{name} length must be within %{left} - %{right}"

    filled?: "%{name} must be filled"

    rules:
      email:
        filled?: "the email is missing"

      user:
        filled?: "%{name} name cannot be blank"

        rules:
          address:
            filled?: "You gotta tell us where you live"
```

Given the yaml file above, messages lookup works as follows:

``` ruby
messages = Dry::Validation::Messages.load('/path/to/our/errors.yml')

# matching arg type for size? predicate
messages[:size?, rule: :name, arg_type: Fixnum] # => "%{name} size must be %{num}"
messages[:size?, rule: :name, arg_type: Range] # => "%{name} size must within %{left} - %{right}"

# matching val type for size? predicate
messages[:size?, rule: :name, val_type: String] # => "%{name} length must be %{num}"

# matching predicate
messages[:filled?, rule: :age] # => "%{name} must be filled"
messages[:filled?, rule: :address] # => "%{name} must be filled"

# matching predicate for a specific rule
messages[:filled?, rule: :email] # => "the email is missing"

# with namespaced messages
user_messages = messages.namespaced(:user)

user_messages[:filled?, rule: :age] # "%{name} cannot be blank"
user_messages[:filled?, rule: :address] # "You gotta tell us where you live"
```

By configuring `messages_file` and/or `namespace` in a schema, default messages
are going to be automatically merged with your overrides and/or namespaced.

## I18n Integration

If you are using `i18n` gem and load it before `dry-validation` then you'll be
able to configure a schema to use `i18n` messages:

``` ruby
require 'i18n'
require 'dry-validation'

class Schema < Dry::Validation::Schema
  configure { config.messages = :i18n }

  key(:email, &:filled?)
end

schema = Schema.new

# return default translations
puts schema.call(email: '').messages
{ :email => ["email must be filled"] }

# return other translations (assuming you have it :))
puts schema.call(email: '').messages(locale: :pl)
{ :email => ["email musi być wypełniony"] }
```

Important: I18n must be initialized before using schema, `dry-validation` does
not try to do it for you, it only sets its default error translations automatically.

## Rule AST

Internally, `dry-validation` uses a simple AST representation of rules and errors
to produce rule objects and error messages. If you would like to programatically
generate rules, it is a very simple process:

``` ruby
ast = [
  [
    :and,
    [
      [:key, [:age, [:predicate, [:key?, []]]]],
      [
        :and,
        [
          [:val, [:age, [:predicate, [:filled?, []]]]],
          [:val, [:age, [:predicate, [:gt?, [18]]]]]
        ]
      ]
    ]
  ]
]

compiler = Dry::Validation::RuleCompiler.new(Dry::Validation::Predicates)

# compile an array of rule objects
rules = compiler.call(ast)

puts rules.inspect
# [
#   #<Dry::Validation::Rule::Conjunction
#     left=#<Dry::Validation::Rule::Key name=:age predicate=#<Dry::Validation::Predicate id=:key?>>
#     right=#<Dry::Validation::Rule::Conjunction
#       left=#<Dry::Validation::Rule::Value name=:age predicate=#<Dry::Validation::Predicate id=:filled?>>
#       right=#<Dry::Validation::Rule::Value name=:age predicate=#<Dry::Validation::Predicate id=:gt?>>>>
# ]

# dump it back to ast
puts rules.map(&:to_ary).inspect
# [[:and, [:key, [:age, [:predicate, [:key?, [:age]]]]], [[:and, [:val, [:age, [:predicate, [:filled?, []]]]], [[:val, [:age, [:predicate, [:gt?, [18]]]]]]]]]]
```

Complete docs for the AST format are coming soon, for now please refer to
[this spec](https://github.com/dryrb/dry-validation/blob/master/spec/unit/rule_compiler_spec.rb).

## Status and Roadmap

This library is in a very early stage of development but you are encauraged to
try it out and provide feedback.

For planned features check out [the issues](https://github.com/dryrb/dry-validation/labels/feature).

## License

See `LICENSE` file.
