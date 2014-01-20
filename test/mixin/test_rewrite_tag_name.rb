require 'helper'

class RewriteTagNameMixinTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag                rewrited.${tag}
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::RewriteTagNameMixinOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver('unknown_keys')
    }
    d = create_driver(CONFIG)
    puts d.instance.inspect
    assert_equal 'rewrited.${tag}', d.instance.config['tag']
  end

  def test_emit
    d1 = create_driver(CONFIG, 'input.access')
    d1.run do
      d1.emit({'message' => 'foo'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    p emits[0]
    assert_equal 'rewrited.input.access', emits[0][0] # tag
    assert_equal 'foo', emits[0][2]['message']
  end

  def test_emit_with_HandleTagNameMixin
    d1 = create_driver(%[
      tag                rewrited.${tag}
      remove_tag_prefix  input.
    ], 'input.access')
    d1.run do
      d1.emit({'message' => 'foo'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    p emits[0]
    assert_equal 'rewrited.access', emits[0][0] # tag
    assert_equal 'foo', emits[0][2]['message']
  end

  def test_emit_tag_parts
    d1 = create_driver(%[
      tag                rewrited.${tag_parts[1]}.__TAG_PARTS[1]__
    ], 'input.access.foo.bar')
    d1.run do
      d1.emit({'message' => 'foo'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    p emits[0]
    assert_equal 'rewrited.access.access', emits[0][0] # tag
  end

  def test_emit_tag_parts_negative
    d1 = create_driver(%[
      tag                rewrited.${tag_parts[-1]}.__TAG_PARTS[-1]__
    ], 'input.access.foo.bar')
    d1.run do
      d1.emit({'message' => 'foo'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    p emits[0]
    assert_equal 'rewrited.bar.bar', emits[0][0] # tag
    assert_equal 'foo', emits[0][2]['message']
  end

  def test_emit_tag_parts_negative2
    d1 = create_driver(%[
      tag                rewrited.${tag_parts[-2]}.__TAG_PARTS[-2]__
    ], 'input.access.foo.bar')
    d1.run do
      d1.emit({'message' => 'foo'})
    end
    emits = d1.emits
    assert_equal 1, emits.length
    p emits[0]
    assert_equal 'rewrited.foo.foo', emits[0][0] # tag
    assert_equal 'foo', emits[0][2]['message']
  end
end
