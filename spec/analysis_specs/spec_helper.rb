require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include SexpAnalysis

module AnalysisHelpers
  def clean_registry
    before do
      @backup_map = ProtocolRegistry.class_protocols.dup
    end

    after do
      ProtocolRegistry.class_protocols.replace @backup_map
    end
  end
end