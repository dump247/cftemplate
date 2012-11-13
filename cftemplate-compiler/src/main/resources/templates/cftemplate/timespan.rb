# Represents a span of time.
class Timespan
  # Initialize a new timespan
  # @option values [Numeric] :days (0) number of days
  # @option values [Numeric] :hours (0) number of hours
  # @option values [Numeric] :minutes (0) number of minutes
  # @option values [Numeric] :seconds (0) number of seconds
  # @option values [Numeric] :milliseconds (0) number of milliseconds
  def initialize(values={})
    days = values.fetch(:days, 0)
    hours = values.fetch(:hours, 0) + (days * 24)
    minutes = values.fetch(:minutes, 0) + (hours * 60)
    seconds = values.fetch(:seconds, 0) + (minutes * 60)
    @total_mils = (values.fetch(:milliseconds, 0) + (seconds * 1000)).to_f
  end

  # Get the total number of days represented by this timespan
  # @return [Float] total days
  def to_days
    @total_mils / MILLISECONDS_PER_DAY
  end

  # Get the total number of hours represented by this timespan
  # @return [Float] total hours
  def to_hours
    @total_mils / MILLISECONDS_PER_HOUR
  end

  # Get the total number of minutes represented by this timespan
  # @return [Float] total minutes
  def to_minutes
    @total_mils / MILLISECONDS_PER_MINUTE
  end

  # Get the total number of seconds represented by this timespan
  # @return [Float] total seconds
  def to_seconds
    @total_mils / MILLISECONDS_PER_SECOND
  end

  # Get the total number of milliseconds represented by this timespan
  # @return [Float] total milliseconds
  def to_milliseconds
    @total_mils
  end

  # Timespan of length zero.
  ZERO=Timespan.new()

  private

  MILLISECONDS_PER_SECOND=1000.0
  MILLISECONDS_PER_MINUTE=60.0 * MILLISECONDS_PER_SECOND
  MILLISECONDS_PER_HOUR=60.0 * MILLISECONDS_PER_MINUTE
  MILLISECONDS_PER_DAY=24.0 * MILLISECONDS_PER_HOUR
end

# Monkey patching for Numeric class with Timespan conversions.
class Numeric
  # Convert the value to a Timespan of days.
  # @return [Timespan] value in days
  def days
    Timespan.new(:days => self)
  end

  alias :day :days

  # Convert the value to a Timespan of hours.
  # @return [Timespan] value in hours
  def hours
    Timespan.new(:hours => self)
  end

  alias :hour :hours

  # Convert the value to a Timespan of minutes.
  # @return [Timespan] value in minutes
  def minutes
    Timespan.new(:minutes => self)
  end

  alias :minute :minutes

  # Convert the value to a Timespan of seconds.
  # @return [Timespan] value in seconds
  def seconds
    Timespan.new(:seconds => self)
  end

  alias :second :seconds

  # Convert the value to a Timespan of milliseconds.
  # @return [Timespan] value in milliseconds
  def milliseconds
    Timespan.new(:milliseconds => self)
  end

  alias :millisecond :milliseconds
end