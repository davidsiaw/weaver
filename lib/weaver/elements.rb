module Weaver
  # Base element class for all HTML elements
  class Elements
    def initialize(page, anchors)
      @inner_content = []
      @anchors = anchors
      @page = page
    end

    def method_missing(name, *args, &block)
      tag = "<#{name} />"

      inner = args.shift if args[0].is_a? String
      if block
        elem = Elements.new(@page, @anchors)
        elem.instance_eval(&block)
        inner = elem.generate
      end

      if !inner

        options = args[0] || []
        opts = options.map { |key, value| "#{key}=\"#{value}\"" }.join ' '

        tag = "<#{name} #{opts} />"
      elsif args.empty?
        tag = "<#{name}>#{inner}</#{name}>"
      elsif (args.length == 1) && args[0].is_a?(Hash)
        options = args[0]
        opts = options.map { |key, value| "#{key}=\"#{value}\"" }.join ' '
        tag = "<#{name} #{opts}>#{inner}</#{name}>"
      end

      @inner_content << tag
      tag
    end

    def root
      @page.root
    end

    def request_js(path)
      @page.request_js(path)
    end

    def request_css(path)
      @page.request_css(path)
    end

    def on_page_load(script)
      @page.on_page_load(script)
    end

    def write_script_once(script)
      @page.write_script_once(script)
    end

    def background(&block)
      @page.background(block)
    end

    def on_page_load(script)
      @page.on_page_load(script)
    end

    def icon(type)
      iconname = type.to_s.tr('_', '-')
      if type.is_a? Symbol
        i class: "fa fa-#{iconname}" do
        end
      else
        i class: 'fa' do
          text type
        end
      end
    end

    def wform(options = {}, &block)
      theform = Form.new(@page, @anchors, options, &block)
      @inner_content << theform.generate
      @page.scripts << theform.generate_script
    end

    def ibox(options = {}, &block)
      panel = Panel.new(@page, @anchors, options)
      panel.instance_eval(&block)
      @inner_content << panel.generate
    end

    def center(content = nil, options = {}, &block)
      options[:style] = '' unless options[:style]

      options[:style] += '; text-align: center;'
      if !content
        div options, &block
      else
        div content, options, &block
      end
    end

    def panel(title, &block)
      div class: 'panel panel-default' do
        div class: 'panel-heading' do
          h5 title
        end
        div class: 'panel-body', &block
      end
    end

    def tabs(&block)
      tabs = Tabs.new(@page, @anchors)
      tabs.instance_eval(&block)

      @inner_content << tabs.generate
    end

    def syntax(lang = :javascript, &block)
      code = Code.new(@page, @anchors, lang)
      code.instance_eval(&block)

      @inner_content << code.generate

      @page.scripts << code.generate_script
    end

    def image(name, options = {})
      style = (options[:style]).to_s
      if options[:rounded_corners] == true
        style += ' border-radius: 8px'
      elsif options[:rounded_corners] == :top
        style += ' border-radius: 8px 8px 0px 0px'
      else
        style += " border-radius: #{options[:rounded_corners]}px" if options[:rounded_corners]

      end

      img_options = {
        class: "img-responsive #{options[:class]}",
        src: "#{@page.root}images/#{name}",
        style: style
      }
      img_options[:id] = options[:id] if options[:id]

      img img_options
    end

    def crossfade_image(image_normal, image_hover)
      div class: 'crossfade' do
        image image_hover, class: 'bottom'
        image image_normal, class: 'top'
      end
      image image_hover
      @page.request_css 'css/crossfade_style.css'
    end

    def gallery(images, thumbnails = images, options = {})
      @page.request_css 'css/plugins/blueimp/css/blueimp-gallery.min.css'

      div class: 'lightBoxGallery' do
        (0...images.length).to_a.each do |index|
          title = options[:titles][index] if options[:titles]

          a href: (images[index]).to_s, title: title.to_s, "data-gallery": '' do
            img src: (thumbnails[index]).to_s, style: 'margin: 5px;'
          end
        end

        div id: 'blueimp-gallery', class: 'blueimp-gallery' do
          div class: 'slides' do end
          h3 class: 'title' do end
          a class: 'prev' do end
          a class: 'next' do end
          a class: 'close' do end
          a class: 'play-pause' do end
          ol class: 'indicator' do end
        end
      end

      @page.request_js 'js/plugins/blueimp/jquery.blueimp-gallery.min.js'
    end

    def breadcrumb(patharray)
      ol class: 'breadcrumb' do
        patharray.each do |path|
          li path
        end
      end
    end

    def p(*args, &block)
      method_missing(:p, *args, &block)
    end

    def text(theText)
      @inner_content << theText
    end

    def badge(label, options = {})
      options[:type] ||= 'plain'

      kind = 'label'
      kind = 'badge' if options[:rounded]
      tag_options = options.clone
      tag_options[:class] = "#{kind} #{kind}-#{options[:type]}"

      span tag_options do
        text label
      end
    end

    def hyperlink(url, title = nil, &block)
      title ||= url

      if url.start_with? '/'
        url.sub!(%r{^/}, @page.root)
        if block
          a href: url, &block
        else
          a title, href: url
        end
      else

        if block
          a href: url, target: '_blank' do
            span do
              span &block
              icon :external_link
            end
          end
        else
          a href: url, target: '_blank' do
            span do
              text title
              text ' '
              icon :external_link
            end
          end
        end
      end
    end

    def accordion(&block)
      acc = Accordion.new(@page, @anchors)
      acc.instance_eval(&block)

      @inner_content << acc.generate
    end

    def widget(options = {}, &block)
      # gray-bg
      # white-bg
      # navy-bg
      # blue-bg
      # lazur-bg
      # yellow-bg
      # red-bg
      # black-bg

      color = "#{options[:color]}-bg" || 'navy-bg'

      div class: "widget style1 #{color}", &block
    end

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

    def jumbotron(options = {}, &block)
      additional_style = ''

      if options[:background]
        additional_style += " background-image: url('#{@page.root}images/#{options[:background]}'); background-position: center center; background-size: cover;"
      end

      additional_style += " height: #{options[:height]}px;" if options[:height]

      if options[:min_height]
        additional_style += " min-height: #{options[:min_height]}px;"
      end

      if options[:max_height]
        additional_style += " max-height: #{options[:max_height]}px;"
      end

      div class: 'jumbotron', style: additional_style, &block
    end

    def modal(id = nil, &block)
      mm = ModalDialog.new(@page, @anchors, id, &block)
      @inner_content << mm.generate
    end

    def _button(options = {}, &block)
      anIcon = options[:icon]
      title = options[:title]

      if title.is_a? Hash
        options.merge! title
        title = anIcon
        anIcon = nil
      end

      style = options[:style] || :primary
      size = "btn-#{options[:size]}" if options[:size]
      blockstyle = 'btn-block' if options[:block]
      outline = 'btn-outline' if options[:outline]
      dim = 'dim' if options[:threedee]
      dim = 'dim btn-large-dim' if options[:bigthreedee]
      dim = 'btn-rounded' if options[:rounded]
      dim = 'btn-circle' if options[:circle]

      buttonOptions = {
        type: options[:type] || 'button',
        class: "btn btn-#{style} #{size} #{blockstyle} #{outline} #{dim}",
        id: options[:id]
      }

      if block
        closer = ''

        closer = '; return false;' if options[:nosubmit]

        action = Action.new(@page, @anchors, &block)
        buttonOptions[:onclick] = "#{action.name}(this)"
        buttonOptions[:onclick] = "#{action.name}(this, #{options[:data]})#{closer}" if options[:data]
        @page.scripts << action.generate
      end

      type = :button

      buttonOptions[:"data-toggle"] = 'button' if options[:toggle]
      type = :a if options[:toggle]

      method_missing type, buttonOptions do
        if title.is_a? Symbol
          icon title
        else
          icon anIcon if anIcon
          text ' ' if anIcon
          text title
        end
      end
    end

    def normal_button(anIcon, title = {}, options = {}, &block)
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def block_button(anIcon, title = {}, options = {}, &block)
      options[:block] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def outline_button(anIcon, title = {}, options = {}, &block)
      options[:outline] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def big_button(anIcon, title = {}, options = {}, &block)
      options[:size] = :lg
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def small_button(anIcon, title = {}, options = {}, &block)
      options[:size] = :sm
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def tiny_button(anIcon, title = {}, options = {}, &block)
      options[:size] = :xs
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def embossed_button(anIcon, title = {}, options = {}, &block)
      options[:threedee] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def big_embossed_button(anIcon, title = {}, options = {}, &block)
      options[:bigthreedee] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def rounded_button(anIcon, title = {}, options = {}, &block)
      options[:rounded] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def circle_button(anIcon, title = {}, options = {}, &block)
      options[:circle] = true
      options[:icon] = anIcon
      options[:title] = title
      _button(options, &block)
    end

    def math(string)
      text "$$$MATH$$$#{string}$$$ENDMATH$$$"
    end

    def table(options = {}, &block)
      table_name = options[:id] || @page.create_anchor('table')
      table_style = ''

      table_style = options[:style] unless options[:style].nil?

      classname = 'table'

      classname += ' table-bordered' if options[:bordered]
      classname += ' table-hover' if options[:hover]
      classname += ' table-striped' if options[:striped]

      table_options = {
        class: classname,
        id: table_name,
        style: table_style
      }

      if options[:system] == :data_table
        @page.request_js 'js/plugins/dataTables/jquery.dataTables.js'
        @page.request_js 'js/plugins/dataTables/dataTables.bootstrap.js'
        @page.request_js 'js/plugins/dataTables/dataTables.responsive.js'
        @page.request_js 'js/plugins/dataTables/dataTables.tableTools.min.js'

        @page.request_css 'css/plugins/dataTables/dataTables.bootstrap.css'
        @page.request_css 'css/plugins/dataTables/dataTables.responsive.css'
        @page.request_css 'css/plugins/dataTables/dataTables.tableTools.min.css'

        @page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').DataTable();
        DATATABLE_SCRIPT
      end

      if options[:system] == :foo_table
        table_options[:"data-filtering"] = true
        table_options[:"data-sorting"] = true
        table_options[:"data-paging"] = true
        table_options[:"data-show-toggle"] = true
        table_options[:"data-toggle-column"] = 'last'

        table_options[:"data-paging-size"] = (options[:max_items_per_page] || 8).to_i.to_s
        table_options[:class] = table_options[:class] + ' toggle-arrow-tiny'

        @page.request_js 'js/plugins/footable/footable.all.min.js'

        @page.request_css 'css/plugins/footable/footable.core.css'

        @page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').footable({
			paging: {
				size: #{(options[:max_items_per_page] || 8).to_i}
			}
		});
		$('##{table_name}').append(this.html).trigger('footable_redraw');



        DATATABLE_SCRIPT

        @page.onload_scripts << <<-SCRIPT
        				SCRIPT
      end

      method_missing(:table, table_options, &block)
      ul class: 'pagination'
    end

    def table_from_source(url, options = {}, &block)
      dyn_table = DynamicTable.new(@page, @anchors, url, options, &block)

      text dyn_table.generate_table

      @page.scripts << dyn_table.generate_script
    end

    def table_from_hashes(hashes, options = {})
      keys = {}
      hashes.each do |hash|
        hash.each do |key, _value|
          keys[key] = ''
        end
      end

      table options do
        thead do
          keys.each do |key, _|
            th key.to_s
          end
        end

        tbody do
          hashes.each do |hash|
            tr do
              keys.each do |key, _|
                td (hash[key]).to_s || '&nbsp;'
              end
            end
          end
        end
      end
    end

    def generate
      @inner_content.join
    end
  end
end
