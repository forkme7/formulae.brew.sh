# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2015, Sebastian Staudt

module Kernel

  alias_method :orig_backtick, :'`'

  def `(command)
    if command == 'which brew'
      File.join $homebrew_path, 'bin', 'brew'
    elsif command == '/usr/bin/mdfind "kMDItemCFBundleIdentifier == \'com.apple.dt.Xcode\'"'
      '/Applications/Xcode.app'
    elsif command == 'xcodebuild -version 2>&1'
      "Xcode 5.0.2\nBuild version 5A3005"
    elsif command == 'php -v'
      "5.4"
    elsif command =~ /^\/usr\/sbin\/sysctl -n/
      "1"
    else
      orig_backtick command
    end
  end

end
