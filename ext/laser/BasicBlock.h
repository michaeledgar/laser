#ifndef LASER_BASIC_BLOCK_H_
#define LASER_BASIC_BLOCK_H_

#include <vector>
#include <exception>
#include <stdexcept>

namespace Laser {
	const char EDGE_NORMAL = 1 << 0;
	const char EDGE_ABNORMAL = 1 << 1;
	const char EDGE_FAKE = 1 << 2;
	const char EDGE_EXECUTABLE = 1 << 3;
	const char EDGE_BLOCK_TAKEN = 1 << 4;
	class BasicBlock {
	  public:
		// Joins the block as a source to a destination
		void join(BasicBlock *other);
		// Disconnects the block as the source in an edge
		void disconnect(BasicBlock *other);
		
		uint8_t get_flags(BasicBlock *dest);
		bool has_flag(BasicBlock* dest, uint8_t flag);
		void add_flag(BasicBlock* dest, uint8_t flag);
		void set_flag(BasicBlock* dest, uint8_t flag);
		void remove_flag(BasicBlock* dest, uint8_t flag);
	  private:
		class NoSuchEdgeException : public std::logic_error {
		  public:
			NoSuchEdgeException() : std::logic_error("No such edge exists between the specified block.") {}
		};
		struct Edge {
			Edge(const BasicBlock *inFrom, const BasicBlock *inTo) : from(inFrom), to(inTo) {}

			const BasicBlock *from;
			const BasicBlock *to;
			uint8_t flags;
		};

		Edge& edge_to(BasicBlock* dest);
		
		std::vector<Edge*> _incoming;
		std::vector<Edge*> _outgoing;
	};
}

#endif