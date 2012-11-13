# Monkey patching for Numeric class.
class Numeric
  # Convert the number to an ordinal string (e.g. 1st, 2nd, 3rd, etc).
  #
  # @return [String] ordinal string for the number
  def to_ordinal
    (10...20) === self ? "#{self}th" : self.to_s + %w{ th st nd rd th th th th th th }[self.to_s[-1..-1].to_i]
  end
end