require 'weaver/element_types/form_elements'
module Weaver

  class Form
    def initialize(page, anchors, options = {}, &block)
      @formName = options[:id] || page.create_anchor('form')

      @form_element = FormElements.new(page, anchors, @formName, options)

      @form_element.instance_eval(&block)
    end

    def generate_script
      <<-SCRIPT
function get_#{@formName}_object()
{
	var object = {}
#{@form_element.scripts.join "\n"}
	return object;
}
      SCRIPT
    end

    def generate
      inner = @form_element.generate
      formName = @formName
      options = @form_element.options

      elem = Elements.new(@page, @anchors)
      elem.instance_eval do
        form_opts = {
          id: formName,
          role: 'form'
        }

        form_opts[:action] = options[:action] if options[:action]
        form_opts[:method] = options[:method] if options[:method]
        form_opts[:class] = options[:class] if options[:class]

        method_missing :form, form_opts do
          text inner
        end
      end

      elem.generate
    end
  end
end
