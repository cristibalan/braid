require 'yaml'

class Hash
  def to_yaml(opts = {})
    YAML::quick_emit(object_id, opts) do |out|
      out.map(taguri, to_yaml_style) do |map|
        sort.each do |k, v|
          map.add(k, v)
        end
      end
    end
  end
end
