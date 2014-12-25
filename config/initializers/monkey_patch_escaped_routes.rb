# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2014, Sebastian Staudt

class ActionDispatch::Journey::Visitors::FormatBuilder

  alias_method :orig_visit_SYMBOL, :visit_SYMBOL

  def visit_SYMBOL(n)
    symbol = n.to_sym
    if symbol == :repository_id
      [ActionDispatch::Journey::Format::Parameter.new(symbol, ->(value) { value })]
    else
      orig_visit_SYMBOL n
    end
  end

end
