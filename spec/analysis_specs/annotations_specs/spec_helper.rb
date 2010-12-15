require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def is_sexp?(sexp)
  SexpAnalysis::Sexp === sexp
end