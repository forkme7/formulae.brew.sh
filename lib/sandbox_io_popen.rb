# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2016, Sebastian Staudt

require 'stringio'

class IO

  class << self
    alias_method :orig_popen, :popen
  end

  def self.popen(command, mode = 'r', &block)
    if command.end_with? 'phpize -v'
      StringIO.new <<PHPIZE
Configuring for:
PHP Api Version:         20090626
Zend Module Api No:      20090626
Zend Extension Api No:   220090626
PHPIZE
    elsif command == '-' && block_given?
      block_self = block.binding.receiver
      def block_self.exec(*args)
        return 'gpg (GnuPG) 1.4.20' if args.first.to_s.end_with? 'gpg'
        ''
      end
      result = yield
      block_self.singleton_class.send :undef_method, :exec
      result
    else
      self.orig_popen command, mode
    end
  end

end
