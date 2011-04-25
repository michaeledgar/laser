require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::RaiseProperties do
  it 'should recognize simple methods that raise no exceptions due to constants' do
    g = cfg_method <<-EOF
def foo(x)
p('hello' * 2)
p self.singleton_class
end
EOF
    g.raise_type.should be Frequency::NEVER
  end

  it 'should recognize simple methods that unconditionally raise' do
    g = cfg_method <<-EOF
def foo(x)
raise SomeError.new(x)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end

  it 'should recognize raiseability via aliases' do
    g = cfg_method <<-EOF
def foo(x)
fail SomeError.new(x)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end

  it 'should recognize simple methods that might raise' do
    g = cfg_method <<-EOF
def foo(x)
if x > 2  # may raise
  'hi'
else
  'there'
end
end
EOF
    g.raise_type.should be Frequency::MAYBE
  end

  it 'should recognize when private methods are called' do
    g = cfg_method <<-EOF
def foo(x)
String.alias_method(:bar, :<<)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end
end