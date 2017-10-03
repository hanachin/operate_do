# OperateDo

OperateDo provide current operator in context.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'operate_do'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install operate_do

## Usage

First, operatable class includes `OperateDo::Operator`.

```ruby
class Admin
  include OperateDo::Operator
end
```

`OperateDo::Operator` provides `operate` and `self_operate` methods.

`operate` methods accept block. `OperateDo.current_operator` is `operate` method reciver in block.

```ruby
admin = Admin.new # => #<Admin:0x007ff02b235cf8>

admin.operate do
  OperateDo.current_operator # => #<Admin:0x007ff02b235cf8>
end
```

`operate` method can nest.

```ruby
admin1 = Admin.new
admin2 = Admin.new

admin1.operate do
  OperateDo.current_operator == admin1 # => true
  admin2.operate do
    OperateDo.current_operator == admin2 # => true
  end
  OperateDo.current_operator == admin1 # => true
end
```

If you logging with operator, you can use `Operate.write` method.

```ruby
admin.operate do
  OperateDo.write 'call in admin blcok'
end

# => I, [2017-10-04T07:13:15.713900 #21515]  INFO -- : 2017/10/04/ 07:13:15 - #<Admin:0x007ff02b235cf8> has operated : call in admin blcok
```

`OperateDo.write` uses `OperateDo::Logger` by default. `OperateDo::Logger` is wrap Ruby's Logger.

You can create your custome logger and use it by setting.

Your custome logger class expect and implements `flush!` method.
`flush!` method recive array of `OperateDo::Message`.

```ruby
class StringIOLogger
  def initialize(io_object)
    @io_object = io_object
  end

  def flush!(messages)
    messages.each do |message|
      @io_object.puts [
        message.operate_at.strftime('%Y/%m/%d/ %H:%M:%S'),
        "#{message.operator.operate_inspect} has operated : #{message.message}"
      ].join(" - ")
    end
  end
end
```

And, set `OperateDo.configure`.

```ruby
logger_string = StringIO.new

OperateDo.configure do |config|
  config.logger = StringIOLogger
  config.logger_initialize_proc = -> { logger_string }
end
admin.operate do
  OperateDo.write 'call in admin blcok'
end

logger_string.rewind
logger_string.read # => 2017/10/04/ 07:47:57 - #<Admin:0x007f9f6695cc40> has operated : call in admin blcok
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/esminc/operate_do. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OperateDo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/esminc/operate_do/blob/master/CODE_OF_CONDUCT.md).
