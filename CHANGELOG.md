# v0.3.1 2015-12-08

### Added

* Support for `Range` and `Array` as an argument in `size?` predicate (solnic)

### Fixed

* Error compiler returns an empty hash rather than a nil when there are no errors (solnic)

[Compare v0.3.0...v0.3.1](https://github.com/dryrb/dry-validation/compare/v0.3.0...v0.3.1)

# v0.3.0 2015-12-07

### Added

* I18n messages support (solnic)
* Ability to configure `messages` via `configure { config.messages = :i18n }` (solnic)
* `rule` interface in DSL for defining rules that depend on other rules (solnic)
* `confirmation` interface as a shortcut for defining "confirmation of" rule (solnic)
* Error messages can be now matched by input value type too (solnic)

### Fixed

* `optional` rule with coercions work correctly with `|` + multiple `&`s (solnic)
* `Schema#[]` checks registered predicates first before defaulting to its own predicates (solnic)

### Changed

* `Schema#messages(input)` => `Schema#call(input).messages` (solnic)
* `Schema#call` returns `Schema::Result` which has access to all rule results,
  errors and messages
* `Schema::Result#messages` returns a hash with rule names, messages and input values (solnic)

[Compare v0.2.0...HEAD](https://github.com/dryrb/dry-validation/compare/v0.2.0...HEAD)

# v0.2.0 2015-11-30

### Added

* `Schema::Form` with a built-in coercer inferred from type-check predicates  (solnic)
* Ability to pass a block to predicate check in the DSL ie `value.hash? { ... }` (solnic)
* Optional keys using `optional(:key_name) { ... }` interface in the DSL (solnic)
* New predicates:
  - `bool?`
  - `date?`
  - `date_time?`
  - `time?`
  - `float?`
  - `decimal?`
  - `hash?`
  - `array?`

### Fixed

* Added missing `and` / `or` interfaces to composite rules (solnic)

[Compare v0.1.0...HEAD](https://github.com/dryrb/dry-validation/compare/v0.1.0...HEAD)

# v0.1.0 2015-11-25

First public release
