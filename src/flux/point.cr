require "./line_protocol"

# Model for InfluxDB data points.
#
# TODO: make this generic over a NamedTuple of the associated fields. Currently
# this causes issues elsewhere as you can not have an `Array`, `Channel` etc of
# a generic type.
struct Flux::Point
  alias TagSet = Hash(String, String)

  alias FieldType = Float64 | Int64 | UInt64 | String | Bool

  alias FieldSet = Hash(String, FieldType)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields : FieldSet

  getter timestamp : Time?

  # Creates a new data point that can be serialized for entry to InfluxDB.
  def self.new(measurement, timestamp = nil, tags = nil, **fields : **T) forall T
    {% raise "points must have at least one field" if T.keys.empty? %}

    fieldset = FieldSet.new
    {% for key, type in T %}
      {% unless type < FieldType %}
        {% raise "invalid type for '#{key}' (#{type}) - fields must be #{FieldType}" %}
      {% end %}
      fieldset[{{key.stringify}}] = fields[{{key.stringify}}]
    {% end %}

    new measurement, fieldset, timestamp, tags
  end

  # Creates a point from a set of nilable fields, discarding any that are nil.
  def self.new!(measurement, timestamp = nil, tags = nil, **fields : **T) forall T
    {% raise "points must have at least one field" if T.keys.empty? %}

    fieldset = FieldSet.new
    {% for key, type in T %}
      {% unless type < FieldType? %}
        {% raise "invalid type for '#{key}' (#{type}) - fields must be #{FieldType?}" %}
      {% end %}
      fieldset[{{key.stringify}}] = fields[{{key.stringify}}].not_nil! \
        unless fields[{{key.stringify}}].nil?
    {% end %}

    new measurement, fieldset, timestamp, tags
  end

  private def initialize(@measurement, @fields, @timestamp = nil, @tags = nil)
  end

  # Append or change tags associated with the point.
  def tag(**tags : **T) forall T
    {% for key in T %}
      self.tags[{{key.stringify}}] = tags[{{key.stringify}}]
    {% end %}
  end

  # Checks if any tags are defined for the point.
  def tagged?
    !@tags.nil?
  end

  def to_s(io)
    LineProtocol.serialize self, io
  end
end
