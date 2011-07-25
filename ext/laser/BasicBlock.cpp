#include "BasicBlock.h"
#include "ruby.h"

VALUE rb_mLaser;
VALUE rb_mAnalysis;
VALUE rb_mControlFlow;
VALUE rb_cBasicBlock;

using namespace Laser;

BasicBlock::BasicBlock(BasicBlock& other) {
	_name = other.name();
	_instructions = other.instructions();
	_incoming = other.predecessors();
	_outgoing = other.successors();
	_cache_flags = 0;
}

void BasicBlock::join(BasicBlock *other) {
	clear_cache();
	other->clear_cache();
	Edge *new_edge = new Edge(this, other);
	_outgoing.push_back(new_edge);
	other->_incoming.push_back(new_edge);
}

// Disconnects the block as the source in an edge
void BasicBlock::disconnect(BasicBlock *other) {
	using namespace std;

	vector<Edge*>::iterator it, it2;
	for (it = _outgoing.begin(); it < _outgoing.end(); ++it) {
		if ((*it)->to == other) {
			for (it2 = other->_incoming.begin(); it2 < other->_incoming.end(); ++it2) {
				if ((*it2)->from == this) {
					Edge* ptr = *it;
					_outgoing.erase(it);
					other->_incoming.erase(it2);
					delete ptr;
					
					clear_cache();
					other->clear_cache();
					return;
				}
			}
			break;
		}
	}
	throw NoSuchEdgeException();
}

void BasicBlock::insert_block_on_edge(BasicBlock* successor, BasicBlock* inserted) {
	using namespace std;
	vector<Edge*>::iterator it, it2;
	for (it = _outgoing.begin(); it < _outgoing.end(); ++it) {
		if ((*it)->to == successor) {
			for (it2 = successor->_incoming.begin(); it2 < successor->_incoming.end(); ++it2) {
				if ((*it2)->from == this) {
					Edge* old_edge = *it;
					*it = new Edge(this, inserted);
					*it2 = new Edge(inserted, successor);
					// we should place the flags of the replaced edge on just the
					// first new edge
					(*it)->flags = old_edge->flags;
					inserted->predecessors().push_back(*it);
					inserted->successors().push_back(*it2);
					delete old_edge;
					
					clear_cache();
					inserted->clear_cache();
					successor->clear_cache();
					return;
				}
			}
			break;
		}
	}
	throw NoSuchEdgeException();
}

void BasicBlock::clear_edges() {
	while (!_outgoing.empty()) {
		BasicBlock::Edge* edge = _outgoing.back();
		disconnect(edge->to);
	}
	while (!_incoming.empty()) {
		BasicBlock::Edge* edge = _incoming.back();
		edge->from->disconnect(this);
	}
}

uint8_t BasicBlock::get_flags(BasicBlock *dest) {
	return edge_to(dest).flags;
}
bool BasicBlock::has_flag(BasicBlock* dest, uint8_t flag) {
	return ((edge_to(dest).flags & flag) != 0);
}
void BasicBlock::add_flag(BasicBlock* dest, uint8_t flag) {
	clear_cache();
	dest->clear_cache();
	edge_to(dest).flags |= flag;
}
void BasicBlock::set_flag(BasicBlock* dest, uint8_t flag) {
	clear_cache();
	dest->clear_cache();
	edge_to(dest).flags = flag;
}
void BasicBlock::remove_flag(BasicBlock* dest, uint8_t flag) {
	clear_cache();
	dest->clear_cache();
	edge_to(dest).flags &= ~flag;
}

BasicBlock::Edge& BasicBlock::edge_to(BasicBlock* dest) {
	using namespace std;
	for (vector<Edge*>::iterator it = _outgoing.begin(); it < _outgoing.end(); ++it) {
		if ((*it)->to == dest) {
			return **it;
		}
	}
	throw NoSuchEdgeException();
}

void BasicBlock::mark() {
	using namespace std;
	rb_gc_mark(_instructions);
	rb_gc_mark(_name);
	rb_gc_mark(_post_order_number);
	rb_gc_mark(_representation);
	for (vector<Edge*>::iterator it = _outgoing.begin(); it < _outgoing.end(); ++it) {
		BasicBlock *other = (*it)->to;
		rb_gc_mark(other->representation());
	}
	for (vector<Edge*>::iterator it = _incoming.begin(); it < _incoming.end(); ++it) {
		BasicBlock *other = (*it)->from;
		rb_gc_mark(other->representation());
	}
	if (_cache_flags & EDGE_ALL_SUCC) {
		rb_gc_mark(_cached_successors);
	}
	if (_cache_flags & EDGE_REAL_SUCC) {
		rb_gc_mark(_cached_real_successors);
	}
	if (_cache_flags & EDGE_ALL_PRED) {
		rb_gc_mark(_cached_predecessors);
	}
	if (_cache_flags & EDGE_REAL_PRED) {
		rb_gc_mark(_cached_real_predecessors);
	}
}

extern "C" {
	#define NO_EDGE_MESSAGE "The given edge does not exist."
	static void bb_mark(void* p) {
		BasicBlock *block = (BasicBlock*)p;
		block->mark();
	}

	static void bb_free(void* p) {
		BasicBlock *block = (BasicBlock*)p;
		block->clear_edges();
		delete block;
	}

	static VALUE bb_alloc(VALUE klass) {
		BasicBlock *block = new BasicBlock;
	    VALUE result = Data_Wrap_Struct(klass, bb_mark, bb_free, block);
		block->set_representation(result);
		return result;
	}
	
	static VALUE bb_dup(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		BasicBlock *result_block = new BasicBlock(*block);
		VALUE result = Data_Wrap_Struct(rb_cBasicBlock, bb_mark, bb_free, result_block);
		block->set_representation(result);
		return result;
	}

	static VALUE bb_initialize(VALUE self, VALUE name) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		block->set_name(name);
		return Qnil;
	}
	
	static VALUE bb_equal(VALUE self, VALUE other) {
		BasicBlock *block, *other_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(other, BasicBlock, other_block);
		return (block == other_block) ? Qtrue : Qfalse;
	}

	static VALUE bb_eql(VALUE self, VALUE other) {
		BasicBlock *block, *other_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(other, BasicBlock, other_block);
		return (block == other_block ||
		        (rb_str_cmp(block->name(), other_block->name()) == 0)) ? Qtrue : Qfalse;
	}
	
	static VALUE bb_neq(VALUE self, VALUE other) {
		return (bb_eql(self, other)) ? Qfalse : Qtrue;
	}
	
	static VALUE bb_hash(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		return INT2FIX((unsigned long int)block);
	}

	static VALUE bb_clear_edges(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		try {
			block->clear_edges();
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return self;
	}

	static VALUE bb_get_name(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		return block->name();
	}

	static VALUE bb_get_instructions(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		return block->instructions();
	}

	static VALUE bb_set_instructions(VALUE self, VALUE new_insns) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		block->set_instructions(new_insns);
		return Qnil;
	}

	static VALUE bb_get_post_order_number(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		return block->post_order_number();
	}

	static VALUE bb_set_post_order_number(VALUE self, VALUE new_num) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		block->set_post_order_number(new_num);
		return Qnil;
	}
	
	static VALUE bb_get_flags(VALUE self, VALUE dest) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			return INT2FIX(block->get_flags(dest_block));
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
	}
	
	static VALUE bb_has_flag(VALUE self, VALUE dest, VALUE flag) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			return (block->has_flag(dest_block, FIX2INT(flag)) ? Qtrue : Qfalse);
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
	}
	
	static VALUE bb_add_flag(VALUE self, VALUE dest, VALUE flag) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			block->add_flag(dest_block, FIX2INT(flag));
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return Qnil;
	}
	
	static VALUE bb_set_flag(VALUE self, VALUE dest, VALUE flag) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			block->set_flag(dest_block, FIX2INT(flag));
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return Qnil;
	}
	
	static VALUE bb_remove_flag(VALUE self, VALUE dest, VALUE flag) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			block->remove_flag(dest_block, FIX2INT(flag));
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return Qnil;
	}

	static VALUE bb_join(VALUE self, VALUE dest) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		block->join(dest_block);
		return Qnil;
	}

	static VALUE bb_disconnect(VALUE self, VALUE dest) {
		BasicBlock *block, *dest_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(dest, BasicBlock, dest_block);
		try	{
			block->disconnect(dest_block);
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return Qnil;
	}

	static VALUE bb_insert_block_on_edge(VALUE self, VALUE succ, VALUE inserted) {
		BasicBlock *block, *succ_block, *inserted_block;
		Data_Get_Struct(self, BasicBlock, block);
		Data_Get_Struct(succ, BasicBlock, succ_block);
		Data_Get_Struct(inserted, BasicBlock, inserted_block);
		try	{
			block->insert_block_on_edge(succ_block, inserted_block);
		} catch (BasicBlock::NoSuchEdgeException e) {
			rb_raise(rb_eArgError, NO_EDGE_MESSAGE);
		}
		return Qnil;
	}

	static VALUE bb_successors(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		VALUE result;
		if ((result = block->cached_successors()) && result != Qnil) {
			return result;
		}
		std::vector<BasicBlock::Edge*>& list = block->successors();

		result = rb_ary_new();
		for (std::vector<BasicBlock::Edge*>::iterator it = list.begin();
			 it < list.end();
			 ++it) {
			rb_ary_push(result, (*it)->to->representation());
		}
		block->set_cached_successors(result);
		return result;
	}
	
	static VALUE bb_predecessors(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		VALUE result;
		if ((result = block->cached_predecessors()) && result != Qnil) {
			return result;
		}
		std::vector<BasicBlock::Edge*>& list = block->predecessors();
		
		result = rb_ary_new();
		for (std::vector<BasicBlock::Edge*>::iterator it = list.begin();
			 it < list.end();
			 ++it) {
			rb_ary_push(result, (*it)->from->representation());
		}
		block->set_cached_predecessors(result);
		return result;
	}

	/*    FILTERED PREDECESSORS    */

	static VALUE bb_filtered_predecessors(VALUE self, uint8_t flag, uint8_t expectation) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		std::vector<BasicBlock::Edge*>& list = block->predecessors();
		
		VALUE result = rb_ary_new();
		for (std::vector<BasicBlock::Edge*>::iterator it = list.begin();
			 it < list.end();
			 ++it) {
			if (((*it)->flags & flag) == expectation) {
				rb_ary_push(result, (*it)->from->representation());
			}
		}
		return result;
	}

	static VALUE bb_real_predecessors(VALUE self) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		VALUE result;
		if ((result = block->cached_real_predecessors()) && result != Qnil) {
			return result;
		}
		result = bb_filtered_predecessors(self, EDGE_FAKE, 0);
		block->set_cached_real_predecessors(result);
		return result;
	}
	
	static VALUE bb_normal_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_ABNORMAL, 0);
	}

	static VALUE bb_abnormal_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_ABNORMAL, EDGE_ABNORMAL);
	}

	static VALUE bb_block_taken_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_BLOCK_TAKEN, EDGE_BLOCK_TAKEN);
	}

	static VALUE bb_exception_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_ABNORMAL | EDGE_BLOCK_TAKEN, EDGE_ABNORMAL);
	}

	static VALUE bb_executed_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_EXECUTABLE, EDGE_EXECUTABLE);
	}

	static VALUE bb_unexecuted_predecessors(VALUE self) {
		return bb_filtered_predecessors(self, EDGE_EXECUTABLE, 0);
	}

	/*    FILTERED SUCCESSORS    */

	static VALUE bb_filtered_successors(VALUE self, uint8_t flag, uint8_t expectation) {
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		std::vector<BasicBlock::Edge*>& list = block->successors();
		
		VALUE result = rb_ary_new();
		for (std::vector<BasicBlock::Edge*>::iterator it = list.begin();
			 it < list.end();
			 ++it) {
			if (((*it)->flags & flag) == expectation) {
				rb_ary_push(result, (*it)->to->representation());
			}
		}
		return result;
	}

	static VALUE bb_real_successors(VALUE self) {
		VALUE result;
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		if ((result = block->cached_real_successors()) && result != Qnil) {
			return result;
		}
		result = bb_filtered_successors(self, EDGE_FAKE, 0);
		block->set_cached_real_successors(result);
		return result;
	}
	
	static VALUE bb_normal_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_ABNORMAL, 0);
	}

	static VALUE bb_abnormal_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_ABNORMAL, EDGE_ABNORMAL);
	}

	static VALUE bb_block_taken_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_BLOCK_TAKEN, EDGE_BLOCK_TAKEN);
	}

	static VALUE bb_exception_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_ABNORMAL | EDGE_BLOCK_TAKEN, EDGE_ABNORMAL);
	}

	static VALUE bb_executed_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_EXECUTABLE, EDGE_EXECUTABLE);
	}

	static VALUE bb_unexecuted_successors(VALUE self) {
		return bb_filtered_successors(self, EDGE_EXECUTABLE, 0);
	}

	/* Optimized enumerator form */

	static VALUE bb_each_real_predecessors(VALUE self) {
		RETURN_ENUMERATOR(self, 0, 0);
		BasicBlock *block;
		Data_Get_Struct(self, BasicBlock, block);
		VALUE result;
		if ((result = block->cached_real_predecessors()) && result != Qnil) {
			return rb_ary_each(result);
		}
		std::vector<BasicBlock::Edge*>& list = block->predecessors();

		for (std::vector<BasicBlock::Edge*>::iterator it = list.begin();
			 it < list.end();
			 ++it) {
			if (((*it)->flags & EDGE_FAKE) == 0) {
				rb_yield((*it)->from->representation());
			}
		}
		return Qnil;
	}

	#undef NO_EDGE_MESSAGE

    VALUE Init_BasicBlock()
    {
        rb_mLaser = rb_define_module("Laser");
		rb_mAnalysis = rb_define_module_under(rb_mLaser, "Analysis");
		rb_mControlFlow = rb_define_module_under(rb_mAnalysis, "ControlFlow");
        rb_cBasicBlock = rb_define_class_under(rb_mControlFlow, "BasicBlock", rb_cObject);
        
        rb_define_alloc_func(rb_cBasicBlock, bb_alloc);
		rb_define_method(rb_cBasicBlock, "initialize", RUBY_METHOD_FUNC(bb_initialize), 1);
		rb_define_method(rb_cBasicBlock, "dup", RUBY_METHOD_FUNC(bb_dup), 0);
		rb_define_method(rb_cBasicBlock, "eql?", RUBY_METHOD_FUNC(bb_eql), 1);
		rb_define_method(rb_cBasicBlock, "===", RUBY_METHOD_FUNC(bb_eql), 1);
		rb_define_method(rb_cBasicBlock, "==", RUBY_METHOD_FUNC(bb_eql), 1);
		rb_define_method(rb_cBasicBlock, "!=", RUBY_METHOD_FUNC(bb_neq), 1);
		rb_define_method(rb_cBasicBlock, "equal?", RUBY_METHOD_FUNC(bb_equal), 1);
		rb_define_method(rb_cBasicBlock, "hash", RUBY_METHOD_FUNC(bb_hash), 0);
		rb_define_method(rb_cBasicBlock, "clear_edges", RUBY_METHOD_FUNC(bb_clear_edges), 0);
		rb_define_method(rb_cBasicBlock, "name=", RUBY_METHOD_FUNC(bb_initialize), 1);
		rb_define_method(rb_cBasicBlock, "name", RUBY_METHOD_FUNC(bb_get_name), 0);
		rb_define_method(rb_cBasicBlock, "instructions=", RUBY_METHOD_FUNC(bb_set_instructions), 1);
		rb_define_method(rb_cBasicBlock, "instructions", RUBY_METHOD_FUNC(bb_get_instructions), 0);
		rb_define_method(rb_cBasicBlock, "post_order_number=", RUBY_METHOD_FUNC(bb_set_post_order_number), 1);
		rb_define_method(rb_cBasicBlock, "post_order_number", RUBY_METHOD_FUNC(bb_get_post_order_number), 0);

		rb_define_method(rb_cBasicBlock, "get_flags", RUBY_METHOD_FUNC(bb_get_flags), 1);
		rb_define_method(rb_cBasicBlock, "has_flag?", RUBY_METHOD_FUNC(bb_has_flag), 2);
		rb_define_method(rb_cBasicBlock, "add_flag", RUBY_METHOD_FUNC(bb_add_flag), 2);
		rb_define_method(rb_cBasicBlock, "set_flag", RUBY_METHOD_FUNC(bb_set_flag), 2);
		rb_define_method(rb_cBasicBlock, "remove_flag", RUBY_METHOD_FUNC(bb_remove_flag), 2);

		rb_define_method(rb_cBasicBlock, "join", RUBY_METHOD_FUNC(bb_join), 1);
		rb_define_method(rb_cBasicBlock, "disconnect", RUBY_METHOD_FUNC(bb_disconnect), 1);
		rb_define_method(rb_cBasicBlock, "insert_block_on_edge", RUBY_METHOD_FUNC(bb_insert_block_on_edge), 2);

		rb_define_method(rb_cBasicBlock, "successors", RUBY_METHOD_FUNC(bb_successors), 0);
		rb_define_method(rb_cBasicBlock, "predecessors", RUBY_METHOD_FUNC(bb_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "each_real_predecessors", RUBY_METHOD_FUNC(bb_each_real_predecessors), 0);
		
		rb_define_method(rb_cBasicBlock, "real_predecessors", RUBY_METHOD_FUNC(bb_real_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "normal_predecessors", RUBY_METHOD_FUNC(bb_normal_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "abnormal_predecessors", RUBY_METHOD_FUNC(bb_abnormal_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "block_taken_predecessors", RUBY_METHOD_FUNC(bb_block_taken_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "exception_predecessors", RUBY_METHOD_FUNC(bb_exception_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "executed_predecessors", RUBY_METHOD_FUNC(bb_executed_predecessors), 0);
		rb_define_method(rb_cBasicBlock, "unexecuted_predecessors", RUBY_METHOD_FUNC(bb_unexecuted_predecessors), 0);
		
		rb_define_method(rb_cBasicBlock, "real_successors", RUBY_METHOD_FUNC(bb_real_successors), 0);
		rb_define_method(rb_cBasicBlock, "normal_successors", RUBY_METHOD_FUNC(bb_normal_successors), 0);
		rb_define_method(rb_cBasicBlock, "abnormal_successors", RUBY_METHOD_FUNC(bb_abnormal_successors), 0);
		rb_define_method(rb_cBasicBlock, "block_taken_successors", RUBY_METHOD_FUNC(bb_block_taken_successors), 0);
		rb_define_method(rb_cBasicBlock, "exception_successors", RUBY_METHOD_FUNC(bb_exception_successors), 0);
		rb_define_method(rb_cBasicBlock, "executed_successors", RUBY_METHOD_FUNC(bb_executed_successors), 0);
		rb_define_method(rb_cBasicBlock, "unexecuted_successors", RUBY_METHOD_FUNC(bb_unexecuted_successors), 0);
		return Qnil;
	}
}