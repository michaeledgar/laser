require 'test/unit'
require 'laser/third_party/stream'

module StreamExamples
  def new_collection_stream; (1..5).create_stream; end

  # a stream which is aquivalent to new_collection_stream
  def new_implicit_stream
    s = Stream::ImplicitStream.new { |s|
	  x = 0
      s.at_beginning_proc = proc {x < 1}
      s.at_end_proc = proc {x == 5}
      s.forward_proc = proc {x += 1 }
      s.backward_proc = proc {y = x; x -= 1; y }
    }
  end

  def filtered_streams
	[
	  new_collection_stream.filtered { |x| true },
	  new_collection_stream.filtered { |x| false },
	  new_collection_stream.filtered { |x| x > 3 },
	  new_collection_stream.filtered { |x| x % 2 == 0 },
	  new_collection_stream.filtered { |x| x % 2 == 0 }.filtered { |x| x > 3 }
	]
  end

  def new_concatenated_stream
	[1, 2, 3].create_stream.concatenate_collected { |i|
	  [i,-i].create_stream
	}
  end

  def all_examples
	[
	  new_collection_stream,
	  new_implicit_stream,
	  new_collection_stream.remove_first,
	  new_collection_stream.remove_last,
	  new_collection_stream.remove_first.remove_last,
	  Stream::WrappedStream.new(new_collection_stream),
	  Stream::IntervalStream.new(6),
	  Stream::IntervalStream.new(1),
	  new_collection_stream.collect { |x| x * 2 },

	  # Some concatenated streams
	  Stream::EmptyStream.instance.concatenate,
	  new_concatenated_stream,
	  # concatenated inside concatenated
	  new_concatenated_stream + new_concatenated_stream,
	  new_collection_stream + Stream::EmptyStream.instance,
	  Stream::EmptyStream.instance + new_collection_stream
	].concat(filtered_streams)
  end

  private

  def standard_tests_for(s)
    arrayStream = s.to_a.create_stream	# A collection stream that should be OK
    assert_equal(s.to_a, arrayStream.to_a)
    # Tests at end of stream
    assert_equal(s.at_end?, arrayStream.at_end?)
    assert_raises(Stream::EndOfStreamException) {s.forward}
    assert_equal(s.at_beginning?, arrayStream.at_beginning?)
    assert_equal(s.peek,s)
    unless arrayStream.at_beginning?
      assert_equal(arrayStream.current,s.current)
      assert_equal(arrayStream.backward, s.backward)
    end
    assert_equal(arrayStream.at_end?, s.at_end?)
    
    # Tests at begin of stream
    s.set_to_begin; arrayStream.set_to_begin
    assert_raises(Stream::EndOfStreamException) {s.backward}
    assert_equal(s.at_beginning?,arrayStream.at_beginning?)
    assert_equal(s.at_end?,arrayStream.at_end?)
    assert_equal(s.current,s)
    unless arrayStream.at_end?
      assert_equal(s.peek,arrayStream.peek)
      assert_equal(s.forward,arrayStream.forward)
      assert_equal(s.current,arrayStream.current)
      unless arrayStream.at_end?
        assert_equal(s.peek,arrayStream.peek)
      end
    end
  end

end

class TestStream < Test::Unit::TestCase
  include StreamExamples

  def test_enumerable
    s = new_collection_stream
    assert_equal([2, 4, 6, 8, 10], s.collect {|x| x*2}.entries)
    assert_equal([2,4],s.select {|x| x[0]== 0})# even numbers
  end

  def test_collection_stream
    s = new_collection_stream
    assert_equal([1, 2, 3, 4, 5], s.entries)
    assert(s.at_end?)
	assert_raises(Stream::EndOfStreamException) {s.forward}
    assert_equal(5, s.backward)
    assert_equal(5, s.forward)
    assert_equal(5, s.current)
    assert_equal(s, s.peek)

    s.set_to_begin
    assert(s.at_beginning?)
	assert_raises(Stream::EndOfStreamException) {s.backward}
    assert_equal(s, s.current)
    assert_equal(1, s.peek)
    assert_equal(1, s.forward)
    assert_equal(1, s.current)
    assert_equal(2, s.peek)

	# move_forward_until
	assert_equal(4, s.move_forward_until { |x| x > 3 })
	assert_equal(nil, s.move_forward_until { |x| x < 3 })
	assert(s.at_end?)

	s.set_to_begin
	assert_equal(nil, s.move_forward_until { |x| x > 6 })
  end

  def test_standard_for_examples
	all_examples.each do |exampleStream|
	  standard_tests_for(exampleStream)
	end
  end

  def test_for_examples_reversed
	all_examples.each do |exampleStream|
	  assert_equal(exampleStream.entries.reverse, exampleStream.reverse.entries)
	  assert_equal(exampleStream.entries, exampleStream.reverse.reverse.entries)
	  standard_tests_for(exampleStream.reverse)
	  standard_tests_for(exampleStream.reverse.reverse)
	end
  end

  def test_filtered_stream
    [(1..6).create_stream.filtered {|x| x % 2 == 0 }].each do |s| 
	  standard_tests_for(s)
	end
  end

  def test_interval_stream
	s = Stream::IntervalStream.new 6
	standard_tests_for(s)
	assert_equal([0, 1, 2, 3, 4, 5], s.entries)
	s.increment_stop
	assert(!s.at_end?)
	assert_equal([0, 1, 2, 3, 4, 5, 6], s.entries)
	standard_tests_for(s)
  end

  def test_enumerable_protocol
	s = [1, 2, 3, 4, 5].create_stream
	assert(s.include?(2))
	assert_equal(3,s.detect {|x| x > 2})
	assert_equal(nil,s.detect {|x| x < 0})
	assert_equal([1,2],s.find_all {|x| x < 3})
  end

  def test_modified_stream
	a = [1,2,3]
	assert_equal([2,3],a.create_stream.remove_first.to_a)
	assert_equal([1,2],a.create_stream.remove_last.to_a)
	assert_raises(Stream::EndOfStreamException) {
	  [1].create_stream.remove_last.forward
	}
	assert_raises(Stream::EndOfStreamException) {
	  [1].create_stream.remove_first.forward
	}
  end
end
