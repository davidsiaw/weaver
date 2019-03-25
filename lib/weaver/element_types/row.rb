module Weaver
  # Row element
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

      @columns << Column.new(occupies, @page, @anchors, options, &block)
      @free -= occupies
    end

    def generate
      @columns.map(&:generate).join
    end
  end

  # Column element
  class Column
    attr_reader :width, :options, :elem

    def initialize(width, page, anchors, options = {}, &block)
      @width = width
      @options = options
      @elem = Elements.new(page, anchors)
      @elem.instance_eval(&block)
    end

    def colsize(size)
      options[size] || width
    end

    def style(size)
      return "hidden-#{size} " if colsize(size).zero?

      "col-#{size}-#{colsize(size)}"
    end

    def generate
      styles = %i[xs sm md lg].map { |size| style(size) }.join(' ')

      <<-ENDCOLUMN
  <div class="#{styles}">
    #{elem.generate}
  </div>
      ENDCOLUMN
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
      column = Column.new(occupies, @page, @anchors, options, &block)
      text column.generate
    end
  end
end
