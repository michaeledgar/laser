module Wool
  module Rake
    class WoolTask
      class Settings < Struct.new(:libs, :extras, :options)
        def initialize(*args)
          super
          self.libs ||= []
          self.extras ||= []
          self.options ||= ''
        end
      end

      attr_accessor :settings

      def initialize(task_name)
        @settings = Settings.new
        yield @settings if block_given?
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
        Wool::Runner.new(self.settings.options.split(/\n/) + files).run
      end
    end
  end
end