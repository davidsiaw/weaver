require 'weaver/page_types/structured_page'
module Weaver

  class NavPage < StructuredPage
    def initialize(title, global_settings, options, &block)
      super
      @menu = Menu.new
    end

    def menu(&block)
      @menu.instance_eval(&block)
    end

    def brand(text, link = '/')
      @brand = text
      @brand_link = link
    end
  end
end
