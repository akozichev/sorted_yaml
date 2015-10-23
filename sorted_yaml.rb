#
# LICENSE: https://gist.github.com/aj-jester/e0078c38db9eb7c1ef45
#
require 'yaml'

module YAML
  class << self
    @@loop = -1 # set to -1 so the first key starts from position 0

        
    def sorted_pretty_generate(obj, indent_len=4)

      # Indent length
      indent = " " * indent_len

      case obj

        when Fixnum, Float, TrueClass, FalseClass, NilClass, String
          return obj.to_s

        when Array
          arrayRet = []

          # We need to increase the loop count before #each so the objects inside are indented twice.
          # When we come out of #each we decrease the loop count so the closing brace lines up properly.
          #
          # If you start with @@loop = 1, the count will be as follows
          #
          # "start_join":       <-- @@loop == 1
          #   "192.168.50.20",  <-- @@loop == 2
          #   "192.168.50.21",  <-- @@loop == 2
          #   "192.168.50.22"   <-- @@loop == 2
          #
          @@loop += 1
          obj.each do |a|
            arrayRet.push(sorted_pretty_generate(a, indent_len))
          end
          @@loop -= 1

          return "\n#{indent * (@@loop + 1)}- " << arrayRet.join("\n#{indent * (@@loop + 1)}- ");

        when Hash
          ret = []

          # This loop works in a similar way to the above
          @@loop += 1
          obj.keys.sort.each do |k|
            ret.push("#{indent * @@loop}" << k.to_s << ": " << sorted_pretty_generate(obj[k], indent_len))
          end
          @@loop -= 1

          return "\n" << ret.join("\n");
        else
          raise Exception("Unable to handle object of type <%s>" % obj.class.to_s)
      end

    end # end def

  end # end class

end # end module


module Puppet::Parser::Functions
  newfunction(:sorted_yaml, :type => :rvalue, :doc => <<-EOS
This function takes unsorted hash and outputs YAML object making sure the keys are sorted.
No multiline support for string values.

*Examples:*

    -------------------
    -- UNSORTED HASH --
    -------------------
    unsorted_hash = {
      'client_addr' => '127.0.0.1',
      'bind_addr'   => '192.168.34.56',
      'start_join'  => [
        '192.168.34.60',
        '192.168.34.61',
        '192.168.34.62',
      ],
      'ports'       => {
        'rpc'   => 8567,
        'https' => 8500,
        'http'  => -1,
      },
    }

    -----------------
    -- SORTED JSON --
    -----------------

    sorted_yaml(unsorted_hash)

  ---
  
  bind_addr: 192.168.34.56
  client_addr: 127.0.0.1
  ports: 
    http: -1
    https: 8500
    rpc: 8567
  start_join: 
    - 192.168.34.60
    - 192.168.34.61
    - 192.168.34.62


    EOS
  ) do |args|

    unsorted_hash = args[0]      || {}
    indent_len    = 2

    unsorted_hash.reject! {|key, value| value == :undef }

    return "---\n" << YAML.sorted_pretty_generate(unsorted_hash, indent_len) << "\n"
  end
end
