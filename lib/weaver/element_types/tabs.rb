# frozen_string_literal: true

module Weaver
  class Tabs
    def initialize(page, anchors)
      @anchors = anchors
      @tabs = {}
      @page = page
      @orientation = :normal # :left, :right
    end

    def tab(title, &block)
      @anchors['tabs'] = [] unless @anchors['tabs']

      tabArray = @anchors['tabs']

      elem = Elements.new(@page, @anchors)
      elem.instance_eval(&block)

      tabname = "tab#{tabArray.length}"
      tabArray << tabname

      @tabs[tabname] =
        {
          title: title,
          elem: elem
        }
    end

    def orientation(direction)
      @orientation = direction
    end

    def generate
      tabbar = Elements.new(@page, @anchors)
      tabs = @tabs
      orientation = @orientation

      tabbar.instance_eval do
        div class: 'tabs-container' do
          div class: "tabs-#{orientation}" do
            ul class: 'nav nav-tabs' do
              cls = 'active'
              tabs.each do |anchor, value|
                li class: cls do
                  a "data-toggle": 'tab', href: "##{anchor}" do
                    if value[:title].is_a? Symbol
                      icon value[:title]
                    else
                      text value[:title]
                    end
                  end
                end

                cls = ''
              end
            end

            div class: 'tab-content' do
              cls = 'tab-pane active'
              tabs.each do |anchor, value|
                div id: anchor.to_s, class: cls do
                  div class: 'panel-body' do
                    text value[:elem].generate
                  end
                end
                cls = 'tab-pane'
              end
            end
          end
        end
      end

      tabbar.generate
    end
  end
end
