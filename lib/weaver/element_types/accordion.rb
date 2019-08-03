# frozen_string_literal: true

module Weaver
  # Accordion element
  class Accordion
    def initialize(page, anchors)
      @anchors = anchors
      @tabs = {}
      @paneltype = :panel
      @is_collapsed = false
      @page = page

      @anchors['accordia'] = [] unless @anchors['accordia']

      accArray = @anchors['accordia']

      @accordion_name = "accordion#{accArray.length}"
      accArray << @accordion_name
    end

    def collapsed(isCollapsed)
      @is_collapsed = isCollapsed
    end

    def type(type)
      @paneltype = type
    end

    def tab(title, options = {}, &block)
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

      if options[:mixpanel_event_name]
        @tabs[tabname][:mixpanel_event_name] = options[:mixpanel_event_name]
      end

      if options[:mixpanel_event_props]
        @tabs[tabname][:mixpanel_event_props] = options[:mixpanel_event_props]
      end
    end

    def generate
      tabbar = Elements.new(@page, @anchors)

      tabs = @tabs
      paneltype = @paneltype
      accordion_name = @accordion_name
      is_collapsed = @is_collapsed

      tabbar.instance_eval do
        div class: 'panel-group', id: accordion_name do
          cls = 'panel-collapse collapse in'
          cls = 'panel-collapse collapse' if is_collapsed
          tabs.each do |anchor, value|
            ibox do
              type paneltype
              body false
              title do
                div class: 'panel-title' do
                  options = {
                    "data-toggle": 'collapse',
                    "data-parent": "##{accordion_name}",
                    href: "##{anchor}"
                  }

                  if value[:mixpanel_event_name]
                    props = {}
                    if value[:mixpanel_event_props].is_a? Hash
                      props = value[:mixpanel_event_props]
                    end
                    options[:onclick] = "mixpanel.track('#{value[:mixpanel_event_name]}', #{props.to_json.tr('"', "'")})"
                  end

                  a options do
                    if value[:title].is_a? Symbol
                      icon value[:title]
                    else
                      text value[:title]
                    end
                  end
                end
              end

              extra do
                div id: anchor, class: cls do
                  div class: 'panel-body' do
                    text value[:elem].generate
                  end
                end
              end
            end

            cls = 'panel-collapse collapse'
          end
        end
      end

      tabbar.generate
    end
  end

  # Add accordion to elements
  class Elements
    def accordion(&block)
      acc = Accordion.new(@page, @anchors)
      acc.instance_eval(&block)

      @inner_content << acc.generate
    end
  end
end
