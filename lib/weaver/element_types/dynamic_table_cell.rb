module Weaver
  class DynamicTableCell < Elements
    attr_accessor :transform_script

    def data_button(anIcon, title = {}, options = {}, &block)
      options[:icon] = anIcon
      options[:title] = title
      options[:data] = "$(this).closest('td').data('object')"
      _button(options, &block)
    end

    def transform(script)
      @transform_script = script
    end
  end
end
