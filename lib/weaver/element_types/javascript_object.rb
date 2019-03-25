module Weaver
  class JavaScriptObject
    def initialize(&block)
      @object = {}
      instance_eval(&block) if block
    end

    def string(name, string)
      @object[name] = { type: :string, value: string }
    end

    def variable(name, var_name)
      @object[name] = { type: :var, value: var_name }
    end

    def generate
      result = @object.map do |key, value|
        value_expression = value[:value]

        value_expression = "\"#{value[:value]}\"" if value[:type] == :string

        "#{key}: #{value_expression}"
      end.join ','

      "{#{result}}"
    end
  end
end
