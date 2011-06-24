#ifndef LASER_BASIC_BLOCK_H_
#define LASER_BASIC_BLOCK_H_

#include <vector>
#include <exception>
#include <stdexcept>
#include "ruby.h"

namespace Laser {
	enum edge_flag {
	    EDGE_NORMAL = 1 << 0,
	    EDGE_ABNORMAL = 1 << 1,
	    EDGE_FAKE = 1 << 2,
	    EDGE_EXECUTABLE = 1 << 3,
	    EDGE_BLOCK_TAKEN = 1 << 4,
	};
	enum cache_flag {
		EDGE_ALL_SUCC = 1 << 0,
		EDGE_REAL_SUCC = 1 << 1,
		EDGE_ALL_PRED = 1 << 2,
		EDGE_REAL_PRED = 1 << 3,
	};
	class BasicBlock {
	  public:
		struct Edge;
		BasicBlock() : _name(NULL), _instructions(rb_ary_new()), _post_order_number(NULL), _cache_flags(0) {}
		BasicBlock(BasicBlock& other);
		// Joins the block as a source to a destination
		void join(BasicBlock* other);
		// Disconnects the block as the source in an edge
		void disconnect(BasicBlock* other);
		// Adds a block on the given edge
		void insert_block_on_edge(BasicBlock* successor, BasicBlock* inserted);
		void clear_edges();

		inline VALUE name() { return _name; }
		inline void set_name(VALUE name) { _name = name; }
		inline VALUE instructions() { return _instructions; }
		inline void set_instructions(VALUE instructions) { _instructions = instructions; }
		inline VALUE post_order_number() { return _post_order_number; }
		inline void set_post_order_number(VALUE post_order_number) { _post_order_number = post_order_number; }
		inline VALUE representation() { return _representation; }
		inline void set_representation(VALUE representation) { _representation = representation; }
		inline std::vector<Edge*>& predecessors() { return _incoming; }
		inline std::vector<Edge*>& successors() { return _outgoing; }
		
		uint8_t get_flags(BasicBlock *dest);
		bool has_flag(BasicBlock* dest, uint8_t flag);
		void add_flag(BasicBlock* dest, uint8_t flag);
		void set_flag(BasicBlock* dest, uint8_t flag);
		void remove_flag(BasicBlock* dest, uint8_t flag);

		void mark();

		inline uint8_t cache_flags() { return _cache_flags; }
		inline void clear_cache() { _cache_flags = 0; }
		inline VALUE cached_successors() {
			return (_cache_flags & EDGE_ALL_SUCC) ? _cached_successors : Qnil;
		}
		inline void set_cached_successors(VALUE cached_successors) {
			_cached_successors = cached_successors;
			_cache_flags |= EDGE_ALL_SUCC;
		}
		inline VALUE cached_real_successors() {
			return (_cache_flags & EDGE_REAL_SUCC) ? _cached_real_successors : Qnil;
		}
		inline void set_cached_real_successors(VALUE cached_real_successors) {
			_cached_real_successors = cached_real_successors;
			_cache_flags |= EDGE_REAL_SUCC;
		}
		inline VALUE cached_predecessors() {
			return (_cache_flags & EDGE_ALL_PRED) ? _cached_predecessors : Qnil;
		}
		inline void set_cached_predecessors(VALUE cached_predecessors) {
			_cached_predecessors = cached_predecessors;
			_cache_flags |= EDGE_ALL_PRED;
		}
		inline VALUE cached_real_predecessors() {
			return (_cache_flags & EDGE_REAL_PRED) ? _cached_real_predecessors : Qnil;
		}
		inline void set_cached_real_predecessors(VALUE cached_real_predecessors) {
			_cached_real_predecessors = cached_real_predecessors;
			_cache_flags |= EDGE_REAL_PRED;
		}

		struct Edge {
			Edge(BasicBlock * const inFrom, BasicBlock * const inTo) : from(inFrom), to(inTo) {}

			BasicBlock * const from;
			BasicBlock * const to;
			uint8_t flags;
		};
		class NoSuchEdgeException : public std::logic_error {
		  public:
			NoSuchEdgeException() : std::logic_error("No such edge exists between the specified block.") {}
		};
  	  private:
		Edge& edge_to(BasicBlock* dest);
		
		std::vector<Edge*> _incoming;
		std::vector<Edge*> _outgoing;
		VALUE _name;
		VALUE _instructions;
		VALUE _post_order_number;
		VALUE _representation;
		
		uint8_t _cache_flags;
		VALUE _cached_successors;
		VALUE _cached_real_successors;
		VALUE _cached_predecessors;
		VALUE _cached_real_predecessors;
	};
}
extern "C" {
	static void bb_mark(void*);
}

#endif