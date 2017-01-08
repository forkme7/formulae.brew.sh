# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013-2015, Sebastian Staudt

unless defined? ::MacOS
  ::MacOS = ::OS::Mac if defined? ::OS::Mac
end

if defined? ::MacOS
  MacOS.singleton_class.instance_methods.select { |m| m.to_s =~ /_version$/ }.each do |m|
    MacOS.singleton_class.send :undef_method, m
    if m == :full_version
      MacOS.singleton_class.send :define_method, m, ->{ '10.11' }
    else
      MacOS.singleton_class.send :define_method, m, ->{ '1.0' }
    end
  end

  if defined? ::MacOS::Xcode
    MacOS::Xcode.methods.select { |m| m.to_s =~ /_version$/ }.each do |m|
      MacOS::Xcode.send :undef_method, m
      MacOS::Xcode.send :define_method, m, ->{ '1.0' }
    end
  end
end
