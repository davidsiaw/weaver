# frozen_string_literal: true

module Weaver
  class Panel < Elements
    def initialize(page, anchors, options = {})
      super(page, anchors)
      @title = nil
      @footer = nil
      @type = :ibox
      @body = true
      @extra = nil
      @min_height = nil
      @page = page
      @options = options
    end

    def generate
      inner = super

      types =
        {
          ibox: { outer: 'ibox float-e-margins', header: 'ibox-title', body: 'ibox-content', footer: 'ibox-footer' },
          panel: { outer: 'panel panel-default', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          primary: { outer: 'panel panel-primary', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          success: { outer: 'panel panel-success', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          info: { outer: 'panel panel-info',	header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          warning: { outer: 'panel panel-warning', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          danger: { outer: 'panel panel-danger', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' },
          blank: { outer: 'panel blank-panel', header: 'panel-heading', body: 'panel-body', footer: 'panel-footer' }
        }

      title = @title
      footer = @footer
      hasBody = @body
      extra = @extra
      options = @options
      classNames = types[@type]
      min_height = @min_height

      elem = Elements.new(@page, @anchors)

      outer_class = classNames[:outer]

      outer_class = 'ibox collapsed' if options[:collapsed]

      elem.instance_eval do
        div class: outer_class do
          if title
            div class: classNames[:header] do
              h5 title

              div class: 'ibox-tools' do
                if options[:collapsible] || options[:collapsed]
                  a class: 'collapse-link' do
                    icon :"chevron-up"
                  end
                end
                if options[:expandable]
                  a class: 'fullscreen-link' do
                    icon :expand
                  end
                end
                if options[:closable]
                  a class: 'close-link' do
                    icon :times
                  end
                end
              end
            end
          end
          if hasBody
            div class: classNames[:body], style: "min-height: #{min_height}px" do
              text inner
            end
          end
          text extra if extra
          if footer
            div class: classNames[:footer] do
              text footer
            end
          end
        end
      end

      elem.generate
    end

    def min_height(val)
      @min_height = val
    end

    def type(aType)
      @type = aType
    end

    def body(hasBody)
      @body = hasBody
    end

    def title(title = nil, &block)
      @title = title
      if block
        elem = Elements.new(@page, @anchors)
        elem.instance_eval(&block)
        @title = elem.generate
      end
    end

    def extra(&block)
      if block
        elem = Elements.new(@page, @anchors)
        elem.instance_eval(&block)
        @extra = elem.generate
      end
    end

    def footer(footer = nil, &block)
      @footer = footer
      if block
        elem = Elements.new(@page, @anchors)
        elem.instance_eval(&block)
        @footer = elem.generate
      end
    end
  end
end
