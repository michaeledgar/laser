module Wool
  module SexpAnalysis
    # This module contains a class hierarchy that represents the type
    # hierarchy in the analyzed Ruby code. This is where method responsiveness
    # can be checked. Some protocols are simple, such as a ClassProtocol,
    # which responds to all the methods that the corresponding Class does.
    # Some might be structural or dependent or generic! The key part is that
    # method signatures can be listed and queried.
    module Protocols
      # The base class for all protocols.
      class Base
        # Returns the list of all known signatures that this protocol responds
        # to.
        #
        # @return [Array<Signature>] the supported signatures for this protocol.
        def signatures
          raise NotImplementedError.new('You must implement #signatures yourself.')
        end
      end
      
      # A protocol that has the same signatures as a given class.
      class ClassProtocol < Base
        # Initializes the class protocol with the given class.
        #
        # @param [WoolClass] klass the wool class whose protocol we are representing
        def initialize(klass)
          @class = klass
        end
        
        # Returns all the signatures that the class responds to, since this protocol
        # has the same signatures.
        #
        # @return [Array<Signature>] the supported signatures for this protocol.
        def signatures
          @class.signatures
        end
      end
    end
  end
end