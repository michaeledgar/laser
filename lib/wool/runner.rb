module Wool
  class Runner
    def initialize(argv)
      @argv = argv
    end
    
    def run
      settings = {:fix => false}
      scanner = Wool::Scanner.new(settings)
      
      warnings = []
      if @argv.any?
        @argv.each do |arg|
          warnings.concat scanner.scan(File.read(arg), arg)
        end
      else
        warnings = scanner.scan(STDIN.read(), '(stdin)')
      end

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