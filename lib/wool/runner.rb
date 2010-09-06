module Wool
  class Runner
    def initialize(argv)
      @argv = argv
    end
    
    def run
      settings = {:fix => false}
      scanner = Wool::Scanner.new(settings)
      
      warnings = collect_warnings(@argv, scanner)
      display_warnings(warnings)
    end
    
    def collect_warnings(argv, scanner)
      if argv.any?
        warnings = []
        argv.each do |arg|
          warnings.concat scanner.scan(File.read(arg), arg)
        end
        warnings
      else
        scanner.scan(STDIN.read(), '(stdin)')
      end
    end
    
    def display_warnings(warnings)
      num_fixable = warnings.select { |warning| warning.line != warning.fix(nil) }.size
      num_total = warnings.size

      results = "#{num_total} warnings found. #{num_fixable} are fixable."
      puts results
      puts "=" * results.size

      warnings.each do |warning|
        puts "#{warning.file}:#{warning.line_number} #{warning.name} (#{warning.severity}) - #{warning.desc}"
      end
    end
  end
end