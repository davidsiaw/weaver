require 'weaver/page_types/structured_page'
module Weaver
  # Pages with navigation menus
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

  # Menu used in nav pages
  class Menu
    attr_accessor :items
    def initialize
      @items = []
    end

    def nav(name, icon = :question, url = nil, options = {}, &block)
      if url && !block
        @items << { name: name, link: url, icon: icon, options: options }
      elsif block
        menu = Menu.new
        menu.instance_eval(&block)
        @items << { name: name, menu: menu, icon: icon, options: options }
      else
        @items << { name: name, link: '#', icon: icon, options: options }
      end
    end
  end
end
