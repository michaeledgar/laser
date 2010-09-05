module Wool
  module Rake
    class WoolTask
      class Settings < Struct.new(:libs, :extras)
        def initialize(*args)
          super
          self.libs ||= []
        end
      end
      
      def initialize(task_name)
        @settings = Settings.new
        yield @settings
        task task_name do
          run
        end
      end
      
      def run
        files = []
        if @settings.libs.any?
          @settings.libs.each do |lib|
            Dir["#{lib}/**/*.rb"].each do |file|
              files << file
            end
          end
        end
        p "Running on files: #{files.inspect}"
        Wool::Runner.new(files).run
      end
    end
  end
end