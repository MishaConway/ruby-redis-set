# Redis::Set

A unique set of unordered items. Lightweight wrapper over redis sets with some additional enumeration and atomic operations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-set'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-set

## Getting started

```ruby
s = Redis::Set.new 'completed_customer_ids'
```

Or you can pass in your own instance of the Redis class.

```ruby
s = Redis::Set.new 'completed_customer_ids', Redis.new(:host => "10.0.1.1", :port => 6380, :db => 15)
```

A third option is to instead pass your Redis configurations.

```ruby
s = Redis::Set.new 'completed_customer_ids', :host => "10.0.1.1", :port => 6380, :db => 15
```

## Using the set

You can add data to the set using either the add or push methods.

```ruby
s.add "hello"
s.add "world"
s.add "hello" # the item 'hello' will only exist once in the set since it is unique
```

You can insert multiple items set using the add_multi or push_multi methods

```ruby
s.add_multi ["one","two","three"]
s.add_multi "four","five","six"
# set should have items "one","two","three","four","five","six" now
```

You can insert a new item into the set and get the resultant size of the set atomically
```ruby
new_count = s.add_with_count "awesome"
```

You can pop a random item from the set
```ruby
result = s.pop
```

You can pop multiple random items from the set
```ruby
result = s.pop_multi 5 # pop 5 random items from set and return them
```

You can remove a specific item from the set
```ruby
s.remove 5  #remove the item 5 from the set if it exists
```

You can atomically remove multiple items from the set.

```ruby
s.remove_multi 3,4,5  #removes items 3,4, and 5 from the set if they exist
```

You can get the size of the set.

```ruby
s.size
```

You can see if an item exists in the set.

```ruby
s.include? "hello"
```

You can get all items in the set.

```ruby
s.all
```

The set can be cleared of all items
```ruby
s.clear
```

The set can also be set to expire (in seconds).
```ruby
# expire in five minutes
s.expire 60*5
```

You can enumerate the set in batches.
```ruby
s.enumerator(100).each{ |i| puts i } #enumerate through the set in batches of 100 items per redis op
```

