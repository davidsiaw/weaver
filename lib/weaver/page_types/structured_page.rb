module Weaver

  class StructuredPage < Page
    def initialize(title, global_settings, options, &block)
      @rows = []
      super
    end

    def header(&block)
      row(class: 'wrapper border-bottom white-bg page-heading', &block)
    end

    def row(options = {}, &block)
      r = Row.new(self, @anchors, options)
      r.instance_eval(&block)
      @rows << r
    end
  end
end
