#ifndef LASER_BASIC_BLOCK_H_
#define LASER_BASIC_BLOCK_H_

#include <vector>
#include <exception>
#include <stdexcept>
#include "ruby.h"

namespace Laser {
	const char EDGE_NORMAL = 1 << 0;
	const char EDGE_ABNORMAL = 1 << 1;
	const char EDGE_FAKE = 1 << 2;
	const char EDGE_EXECUTABLE = 1 << 3;
	const char EDGE_BLOCK_TAKEN = 1 << 4;
	class BasicBlock {
	  public:
		struct Edge;
		BasicBlock() : _name(NULL), _instructions(rb_ary_new()), _post_order_number(NULL) {}
		BasicBlock(BasicBlock& other);
		// Joins the block as a source to a destination
		void join(BasicBlock *other);
		// Disconnects the block as the source in an edge
		void disconnect(BasicBlock *other);
		void clear_edges();

		inline VALUE name() { return _name; }
		inline void set_name(VALUE name) { _name = name; }
		inline VALUE instructions() { return _instructions; }
		inline void set_instructions(VALUE instructions) { _instructions = instructions; }
		inline VALUE post_order_number() { return _post_order_number; }
		inline void set_post_order_number(VALUE post_order_number) { _post_order_number = post_order_number; }
		inline std::vector<Edge*>& predecessors() { return _incoming; }
		inline std::vector<Edge*>& successors() { return _outgoing; }
		
		uint8_t get_flags(BasicBlock *dest);
		bool has_flag(BasicBlock* dest, uint8_t flag);
		void add_flag(BasicBlock* dest, uint8_t flag);
		void set_flag(BasicBlock* dest, uint8_t flag);
		void remove_flag(BasicBlock* dest, uint8_t flag);

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
	};
}

#endif