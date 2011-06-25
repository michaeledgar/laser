require_relative '../spec_helper'
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
shared_examples_for 'an annotator' do
  it 'should be in the global annotation list' do
    expect do
      Annotations.global_annotations.any? do |annotation|
        annotation.is_a?(described_class)
      end
    end.to be_true
  end
end

def annotate_all(body)
  Annotations.annotate_inputs([['(stdin)', body]]).first[1]
end