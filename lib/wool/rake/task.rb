module Wool
  module Rake
    class WoolTask
      class Settings < Struct.new(:libs)
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
        %x(wool #{files.join(' ')})
      end
    end
  end
end