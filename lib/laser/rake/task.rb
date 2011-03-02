module Laser
  module Rake
    class LaserTask
      Settings = Struct.new(:libs, :extras, :options, :using, :fix) do
        def initialize(*args)
          super
          self.libs ||= []
          self.extras ||= []
          self.options ||= ''
          self.using ||= []
          self.fix ||= []
        end
      end

      attr_accessor :settings

      def initialize(task_name)
        @settings = Settings.new
        yield @settings if block_given?
        @settings.using = [:all] if @settings.using.empty?
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
        runner = Laser::Runner.new(self.settings.options.split(/\s/) + files)
        runner.using = self.settings.using
        runner.fix = self.settings.fix
        runner.run
      end
    end
  end
end