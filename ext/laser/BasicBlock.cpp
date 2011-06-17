#include "BasicBlock.h"
#include "ruby.h"

using namespace Laser;

void BasicBlock::join(BasicBlock *other) {
	Edge *new_edge = new Edge(this, other);
	_outgoing.push_back(new_edge);
	other->_incoming.push_back(new_edge);
}

// Disconnects the block as the source in an edge
void BasicBlock::disconnect(BasicBlock *other) {
	using namespace std;

	vector<Edge*>::iterator it;
	for (it = _outgoing.begin(); it < _outgoing.end(); ++it) {
		if ((*it)->to == other) {
			_outgoing.erase(it);
			break;
		}
	}
	if (it == _outgoing.end()) {
		throw NoSuchEdgeException();
	}
	for (it = other->_incoming.begin(); it < other->_incoming.end(); ++it) {
		if ((*it)->from == this) {
			other->_incoming.erase(it);
			break;
		}
	}
	if (it == other->_incoming.end()) {
		throw NoSuchEdgeException();
	}
}

uint8_t BasicBlock::get_flags(BasicBlock *dest) {
	return edge_to(dest).flags;
}
bool BasicBlock::has_flag(BasicBlock* dest, uint8_t flag) {
	return edge_to(dest).flags & flag;
}
void BasicBlock::add_flag(BasicBlock* dest, uint8_t flag) {
	edge_to(dest).flags |= flag;
}
void BasicBlock::set_flag(BasicBlock* dest, uint8_t flag) {
	edge_to(dest).flags = flag;
}
void BasicBlock::remove_flag(BasicBlock* dest, uint8_t flag) {
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