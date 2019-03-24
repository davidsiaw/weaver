module Weaver

  class Row < Elements
    attr_accessor :extra_classes, :style

    def initialize(page, anchors, options)
      @columns = []
      @free = 12
      @extra_classes = options[:class] || ''
      @style = options[:style]
      @anchors = anchors
      @page = page
    end

    def col(occupies, options = {}, &block)
      raise 'Not enough columns!' if @free < occupies

      elem = Elements.new(@page, @anchors)
      elem.instance_eval(&block)

      @columns << { occupy: occupies, elem: elem, options: options }
      @free -= occupies
    end

    def generate
      @columns.map do |col|
        xs = col[:options][:xs] || col[:occupy]
        sm = col[:options][:sm] || col[:occupy]
        md = col[:options][:md] || col[:occupy]
        lg = col[:options][:lg] || col[:occupy]

        hidden = ''

        xs_style = "col-xs-#{xs}" unless col[:options][:xs] == 0
        sm_style = "col-sm-#{sm}" unless col[:options][:sm] == 0
        md_style = "col-md-#{md}" unless col[:options][:md] == 0
        lg_style = "col-lg-#{lg}" unless col[:options][:lg] == 0

        hidden += 'hidden-xs ' if col[:options][:xs] == 0
        hidden += 'hidden-sm ' if col[:options][:sm] == 0
        hidden += 'hidden-md ' if col[:options][:md] == 0
        hidden += 'hidden-lg ' if col[:options][:lg] == 0

        <<-ENDCOLUMN
		<div class="#{xs_style} #{sm_style} #{md_style} #{lg_style} #{hidden}">
			#{col[:elem].generate}
		</div>
        ENDCOLUMN
      end.join
    end
  end

  # Add row and column elements
  class Elements
    def row(options = {}, &block)
      options[:class] = 'row'
      div options do
        instance_eval(&block)
      end
    end

    def twothirds(&block)
      opts =
        {
          xs: 12,
          sm: 12,
          md: 8,
          lg: 8
        }
      col(4, opts, &block)
    end

    def half(&block)
      opts =
        {
          xs: 12,
          sm: 12,
          md: 12,
          lg: 6
        }
      col(4, opts, &block)
    end

    def third(&block)
      opts =
        {
          xs: 12,
          sm: 12,
          md: 4,
          lg: 4
        }
      col(4, opts, &block)
    end

    def quarter(&block)
      opts =
        {
          xs: 12,
          sm: 12,
          md: 6,
          lg: 3
        }
      col(3, opts, &block)
    end

    def col(occupies, options = {}, &block)
      xs = options[:xs] || occupies
      sm = options[:sm] || occupies
      md = options[:md] || occupies
      lg = options[:lg] || occupies

      hidden = ''

      xs_style = "col-xs-#{xs}" unless options[:xs] == 0
      sm_style = "col-sm-#{sm}" unless options[:sm] == 0
      md_style = "col-md-#{md}" unless options[:md] == 0
      lg_style = "col-lg-#{lg}" unless options[:lg] == 0

      hidden += 'hidden-xs ' if options[:xs] == 0
      hidden += 'hidden-sm ' if options[:sm] == 0
      hidden += 'hidden-md ' if options[:md] == 0
      hidden += 'hidden-lg ' if options[:lg] == 0

      div_options = {
        class: "#{xs_style} #{sm_style} #{md_style} #{lg_style} #{hidden}",
        style: options[:style]
      }

      div div_options do
        instance_eval(&block)
      end
    end
  end
end
