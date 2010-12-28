require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include SexpAnalysis

module AnalysisHelpers
  def clean_registry
    before do
      @backup_all = ProtocolRegistry.protocols.dup
      @backup_map = ProtocolRegistry.class_protocols.dup
    end

    after do
      ProtocolRegistry.protocols.replace @backup_all
      ProtocolRegistry.class_protocols.replace @backup_map
    end
  end
end