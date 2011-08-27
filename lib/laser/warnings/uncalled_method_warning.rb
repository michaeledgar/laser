# Warning for methods that are not called, ever.
class Laser::UncalledMethodWarning < Laser::FileWarning
	type :dangerous
  short_desc "Unused method"
  desc { "The method #{method.owner.name}##{method.name} is never called." }
  setting_accessor :method
end
