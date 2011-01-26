TESTDATA_DIR = File.join(File.dirname(__FILE__), '..', 'support', 'testdata')

Given(/the following inputs and outputs:/) do |table|
  @table = table
end

When(/I scan for warnings/) do
  @result_table = [ ['input', 'output'] ]
  swizzling_io do
    @table.hashes.each do |hash|
      full_path = File.join(TESTDATA_DIR, hash[:input])
      runner = Laser::Scanner.new({})
      warnings = runner.scan(File.read(full_path), hash[:input])
      @result_table << [hash[:input], warnings.size.to_s]
    end
  end
end

Then(/the input and output tables should match/) do
  @table.diff!(@result_table)
end

When(/I scan-and-fix warnings/) do
  @result_table = [ ['input', 'output'] ]
  swizzling_io do
    @table.hashes.each do |hash|
      full_path = File.join(TESTDATA_DIR, hash[:input])
      expected_output = File.read(File.join(TESTDATA_DIR, hash[:output]))
      captured_output = StringIO.new
      Laser::LineLengthMaximum(80)
      runner = Laser::Scanner.new(fix: true, output_file: captured_output)
      runner.scan(File.read(full_path), hash[:input])
      reported_output = hash[:output]
      reported_output += '+' if captured_output.string != expected_output
      STDERR.puts [captured_output.string, expected_output].inspect if captured_output.string != expected_output
      @result_table << [hash[:input], reported_output]
    end
  end
end