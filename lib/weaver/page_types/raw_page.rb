module Weaver
  # Raw oage with no html
  class RawPage < Page
    def initialize(title, global_settings, options, &block)
      super
    end

    def generate(_back_folders, _options = {})
      elem = Elements.new(self, {})
      elem.instance_eval(&@block)

      elem.generate
    end
  end
end

Weaver::Weave.register_page_type(:raw_page, Weaver::RawPage)
