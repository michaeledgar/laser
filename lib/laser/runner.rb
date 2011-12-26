module Laser
  class Runner
    attr_accessor :using, :fix

    def initialize(argv)
      @argv = argv
      @using = [:all]
      @fix = [:all]
    end

    def run
      settings, files = collect_options_and_arguments
      # parse_forest: Array<Array<String, Sexp>>
      parse_forest = files.zip(files.map { |file| Ripper.sexp(read_file(file))})
      settings[:__using__] = warnings_to_consider
      settings[:__fix__] = warnings_to_fix
      scanner = Scanner.new(settings)
      warnings = collect_warnings(files, scanner)
      display_warnings(warnings, settings) if settings[:display]
      print_modules if settings[:"list-modules"]
    end

    def collect_options_and_arguments
      swizzling_argv do
        settings = get_settings
        handle_global_options(settings)
        p settings if settings[:debug]
        files = ARGV.dup
        [settings, files]
      end
    end
    
    # Processes the global options, which includes picking which warnings to
    # run against the source code. The settings provided determine what
    # modifies the runner's settings.
    #
    # @param [Hash] settings the settings from the command-line to process.
    # @option settings :only (String) a list of warning names or short names
    #   that will be the only warnings run. The names should be whitespace-delimited.
    # @option settings :"line-length" (Integer) a maximum line length to
    #   generate a warning for. A common choice is 80/83.
    def handle_global_options(settings)
      if settings[:"line-length"]
        @using << Laser.LineLengthWarning(settings[:"line-length"])
      end
      if (only_name = settings[:only])
        @fix = @using = Warning.concrete_warnings.select do |w|
          classname = w.name && w.name.split('::').last
          (classname && only_name.index(classname)) || (w.short_name && only_name.index(w.short_name))
        end
      end
      if settings[:profile]
        require 'benchmark'
        require 'profile'
        SETTINGS[:profile] = true
      end
      if settings[:include]
        Laser::SETTINGS[:load_path] = settings[:include].reverse
      end
      ARGV.replace(['(stdin)']) if settings[:stdin]
    end

    # Parses the command-line options using Trollop
    #
    # @return [Hash{Symbol => Object}] the settings entered by the user
    def get_settings
      warning_opts = get_warning_options
      Trollop::options do
        banner 'LASER: Lexically- and Semantically-Enriched Ruby'
        opt :fix, 'Should errors be fixed in-line?', short: '-f'
        opt :display, 'Should errors be displayed?', short: '-b', default: true
        opt :'report-fixed', 'Should fixed errors be reported anyway?', short: '-r'
        opt :'line-length', 'Warn at the given line length', short: '-l', type: :int
        opt :only, 'Only consider the given warning (by short or full name)', short: '-O', type: :string
        opt :stdin, 'Read Ruby code from standard input', short: '-s'
        opt :'list-modules', 'Print the discovered, loaded modules'
        opt :profile, 'Run the profiler during execution'
        opt :include, 'specify $LOAD_PATH directory (may be used more than once)', short: '-I', multi: true, type: :string
        opt :S, 'look for scripts using PATH environment variable', short: '-S'
        warning_opts.each { |warning| opt(*warning) }
      end
    end

    # Gets all the options from the warning plugins and collects them
    # with overriding rules. The later the declaration is run, the higher the
    # priority the option has.
    def get_warning_options
      all_options = Warning.all_warnings.inject({}) do |result, warning|
        options = warning.options
        options = [options] if options.any? && !options[0].is_a?(Array)
        options.each do |option|
          result[option.first] = option
        end
        result
      end
      all_options.values
    end

    # Prints the known modules after analysis.
    def print_modules
      Analysis::LaserModule.all_modules.map do |mod|
        result = []
        result << if Analysis::LaserClass === mod && mod.superclass
                  then "#{mod.path} < #{mod.superclass.path}"
                  else mod.name
                  end
        result
      end.sort.flatten.each { |name| puts name }
    end

    def read_file(file)
      case file
      when '(stdin)' then $stdin.read
      else File.read(file)
      end
    end

    # Converts a list of warnings and symbol shortcuts for warnings to just a
    # list of warnings.
    def convert_warning_list(list)
      list.map do |list|
        case list
        when :all then Warning.all_warnings
        when :whitespace
          [ExtraBlankLinesWarning, ExtraWhitespaceWarning,
           OperatorSpacing, MisalignedUnindentationWarning]
          else list
        end
      end.flatten
    end

    # Returns the list of warnings the user has activated for use.
    def warnings_to_consider
      convert_warning_list(@using)
    end

    # Returns the list of warnings the user has selected for fixing
    def warnings_to_fix
      convert_warning_list(@fix)
    end

    # Sets the ARGV variable to the runner's arguments during the execution
    # of the block.
    def swizzling_argv
      old_argv = ARGV.dup
      ARGV.replace @argv
      yield
    ensure
      ARGV.replace old_argv
    end

    # Collects warnings from all the provided files by running them through
    # the scanner.
    #
    # @param [Array<String>] files the files to scan. If (stdin) is in the
    #   array, then data will be read from STDIN until EOF is reached.
    # @param [Scanner] scanner the scanner that will look for warnings
    #   in the source text.
    # @return [Array<Warning>] a set of warnings, ordered by file.
    def collect_warnings(files, scanner)
      full_list = files.map do |file|
        data = file == '(stdin)' ? STDIN.read : File.read(file)
        if scanner.settings[:fix]
          scanner.settings[:output_file] = scanner.settings[:stdin] ? STDOUT : File.open(file, 'w')
        end
        results = scanner.scan(data, file)
        if scanner.settings[:fix] && !scanner.settings[:stdin]
          scanner.settings[:output_file].close
        end
        results
      end
      full_list.flatten
    end

    # Displays warnings using user-provided settings.
    #
    # @param [Array<Warning>] warnings the warnings generated by the input
    #   files, ordered by file
    # @param [Hash{Symbol => Object}] settings the user-set display settings
    def display_warnings(warnings, settings)
      num_fixable = warnings.select { |warn| warn.fixable? }.size
      num_total = warnings.size

      results = "#{num_total} warnings found. #{num_fixable} are fixable."
      puts results
      puts '=' * results.size

      warnings.each do |warning|
        puts "#{warning.file}:#{warning.line_number} #{warning.name} " +
             "(#{warning.severity}) - #{warning.desc}"
      end
    end
  end
end
