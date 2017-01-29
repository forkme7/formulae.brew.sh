# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2016, Sebastian Staudt

class CoreTap

  def self.ensure_installed!(*_)
  end

  def formula_dir
    Pathname $core_formula_path
  end

end
