require_relative 'spec_helper'
require 'ostruct'

describe Visitor do
  before do
    @class = Class.new do
      include Visitor
      add :foo do |node|
        node.visited = node[1]
      end
      add :bar do |node|
        node.product = node[1] * node[2]
      end
      add(proc {|node| node.children.any? && node[1] == 5 }) do |node|
        node.lotto_winner = true
      end
    end
  end
  
  describe '#visit' do
    it 'runs the matching method when one is defined' do
      a = Sexp.new([:foo, true])
      a.should_receive(:visited=).with(true)
      @class.new.visit(a)
    end
    it 'matches symbol-based filters as a shortcut for node type matching' do
      b = Sexp.new([:bar, 3, 2])
      b.should_receive(:product=).with(6)
      @class.new.visit(b)
    end
    it 'uses arbitrary procs to match nodes' do
      c = Sexp.new([:lotto_entry, 5])
      c.should_receive(:lotto_winner=).with(true)
      @class.new.visit(c)
    end
    
    it 'automatically DFSs the tree to visit nodes when they are not handled' do
      a = Sexp.new([:a, [:b, [:foo, false], 2, 3], [:c, [:bar, 19, 22], [:bar, 23, 2]]])
      a[1][1].should_receive(:visited=).with(false)
      a[2][1].should_receive(:product=).with(19 * 22)
      a[2][2].should_receive(:product=).with(46)
      @class.new.visit(a)
    end
    
    it 'calls #default_visit when it encounters an unknown AST node' do
      klass = Class.new do
        include Visitor
        def default_visit(node)
          node.count = (@count ||= 1)
          @count += 1
          node.children.select {|x| Sexp === x}.each {|x| visit(x)}
        end
        add :bar do |node|
        end
      end
      a = Sexp.new([:a, [:b, [:foo, false], 2, 3], [:c, [:bar, 19, 22], [:bar, 23, 2]]])
      a.should_receive(:count=).with(1)
      a[1].should_receive(:count=).with(2)
      a[1][1].should_receive(:count=).with(3)
      a[2].should_receive(:count=).with(4)
      klass.new.visit(a)
    end
  end
end
