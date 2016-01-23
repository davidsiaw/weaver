require "weaver/version"

require 'fileutils'
require 'sinatra'
require 'json'

module Weaver

	class Elements

		def initialize(page, anchors)
			@inner_content = []
			@anchors = anchors
			@page = page
		end

		def method_missing(name, *args, &block)
			tag = "<#{name} />"

			if args[0].is_a? String
				inner = args.shift
			end
			if block
				elem = Elements.new(@page, @anchors)
				elem.instance_eval(&block)
				inner = elem.generate
			end

			if !inner

				options = args[0] || []
				opts = options.map { |key,value| "#{key}=\"#{value}\"" }.join " "

				tag = "<#{name} #{opts} />"
			elsif args.length == 0
				tag = "<#{name}>#{inner}</#{name}>"
			elsif args.length == 1 and args[0].is_a? Hash
				options = args[0]
				opts = options.map { |key,value| "#{key}=\"#{value}\"" }.join " "
				tag = "<#{name} #{opts}>#{inner}</#{name}>"
			end

			@inner_content << tag
			tag
		end

		def icon(type)
			iconname = type.to_s.gsub(/_/, "-")
			i class: "fa fa-#{iconname}" do
			end
		end

		def form(options={}, &block)
        	theform = Form.new(@page, @anchors, options)
        	theform.instance_eval(&block)
        	@inner_content << theform.generate
        	@page.scripts << theform.generate_script
		end

        def ibox(options={}, &block)
        	panel = Panel.new(@page, @anchors, options)
        	panel.instance_eval(&block)
        	@inner_content << panel.generate
        end

        def panel(title, &block)
        	div class: "panel panel-default" do
        		div class: "panel-heading" do
	    				h5 title
	    			end 
        		div class: "panel-body", &block
        	end
        end

		def tabs(&block)
			tabs = Tabs.new(@page, @anchors)
			tabs.instance_eval(&block)

        	@inner_content << tabs.generate
		end

		def syntax(lang=:javascript, &block)
			code = Code.new(@page, @anchors, lang)
			code.instance_eval(&block)

			@inner_content << code.generate

			@page.scripts << code.generate_script
		end

        def image(name, options={})

        	style = ""
        	if options[:rounded_corners] == true
        		style += " border-radius: 8px"
        	elsif options[:rounded_corners] == :top
        		style += " border-radius: 8px 8px 0px 0px"
        	else
        		style += " border-radius: #{options[:rounded_corners]}px"

        	end

        	img class: "img-responsive #{options[:class]}", src: "#{@page.root}images/#{name}", style: style
        end

        def crossfade_image(image_normal, image_hover)
			div class: "crossfade" do
				image image_hover, class: "bottom"
				image image_normal, class: "top"
			end
			image image_hover
			@page.request_css "css/crossfade_style.css"
        end

		def breadcrumb(patharray)
			ol class: "breadcrumb" do
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

		def link(url, title=nil, &block)
			if !title
				title = url
			end

			if url.start_with? "/"
				url.sub!(/^\//, @page.root)
				if block
					a href: url, &block
				else
					a title, href: url
				end
			else

				if block
					a href: url, target: "_blank" do
						span do
							span &block
							icon :external_link
						end
					end
				else
					a href: url, target: "_blank" do
						span do
							text title
							text " "
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

		def widget(options={}, &block)
			#gray-bg
			#white-bg
			#navy-bg
			#blue-bg
			#lazur-bg
			#yellow-bg
			#red-bg
			#black-bg

			color = "#{options[:color]}-bg" || "navy-bg"

			div :class => "widget style1 #{color}", &block
		end

		def row(options={}, &block)
			r = Row.new(@page, @anchors, options)
			r.instance_eval(&block)

			@inner_content << <<-ENDROW
	<div class="row">
		#{r.generate}
	</div>
ENDROW
		end

		def jumbotron(options={}, &block)

			additional_style = ""

			if options[:background]
				additional_style += " background-image: url('#{@page.root}images/#{options[:background]}'); background-position: center center; background-size: cover;"
			end

			if options[:height]
				additional_style += " height: #{options[:height]}px;"
			end

			if options[:min_height]
				additional_style += " min-height: #{options[:min_height]}px;"
			end

			if options[:max_height]
				additional_style += " max-height: #{options[:max_height]}px;"
			end

			div :class => "jumbotron", style: additional_style, &block
		end

		def _button(options={}, &block)

			anIcon = options[:icon]
			title = options[:title]

			if title.is_a? Hash
				options.merge! title
				title = anIcon
				anIcon = nil
			end

			style = options[:style] || :primary
			size = "btn-#{options[:size]}" if options[:size]
			blockstyle = "btn-block" if options[:block]
			outline = "btn-outline" if options[:outline]
			dim = "dim" if options[:threedee]
			dim = "dim btn-large-dim" if options[:bigthreedee]
			dim = "btn-rounded" if options[:rounded]
			dim = "btn-circle" if options[:circle]

			buttonOptions = {
				:type => "button",
				:class => "btn btn-#{style} #{size} #{blockstyle} #{outline} #{dim}"
			}

			if block
				action = Action.new(@page, @anchors, &block)
				buttonOptions[:onclick] = "#{action.name}(this)"
				buttonOptions[:onclick] = "#{action.name}(this, #{options[:data]})" if options[:data]
				@page.scripts << action.generate
			end

			type = :button

			buttonOptions[:"data-toggle"] = "button" if options[:toggle]
			type = :a if options[:toggle]


			method_missing type, buttonOptions do
				if title.is_a? Symbol
					icon title
				else
					icon anIcon if anIcon
					text " " if anIcon
					text title
				end
			end
		end

		def button(anIcon, title={}, options={}, &block)
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def block_button(anIcon, title={}, options={}, &block)
			options[:block] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def outline_button(anIcon, title={}, options={}, &block)
			options[:outline] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def big_button(anIcon, title={}, options={}, &block)
			options[:size] = :lg
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def small_button(anIcon, title={}, options={}, &block)
			options[:size] = :sm
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def tiny_button(anIcon, title={}, options={}, &block)
			options[:size] = :xs
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def embossed_button(anIcon, title={}, options={}, &block)
			options[:threedee] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def big_embossed_button(anIcon, title={}, options={}, &block)
			options[:bigthreedee] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def rounded_button(anIcon, title={}, options={}, &block)
			options[:rounded] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def circle_button(anIcon, title={}, options={}, &block)
			options[:circle] = true
			options[:icon] = anIcon
			options[:title] = title
			_button(options, &block)
		end

		def table(options={}, &block)

			if !@anchors["tables"]
				@anchors["tables"] = []
			end

			tableArray = @anchors["tables"]

			table_name = "table#{tableArray.length}"
			if options[:id] != nil
				table_name = options[:id]
			end
			tableArray << table_name

			classname = "table"

			classname += " table-bordered" if options[:bordered]
			classname += " table-hover" if options[:hover]
			classname += " table-striped" if options[:striped]

			if options[:system] == :data_table
				@page.request_js "js/plugins/dataTables/jquery.dataTables.js"
				@page.request_js "js/plugins/dataTables/dataTables.bootstrap.js"
				@page.request_js "js/plugins/dataTables/dataTables.responsive.js"
				@page.request_js "js/plugins/dataTables/dataTables.tableTools.min.js"

				@page.request_css "css/plugins/dataTables/dataTables.bootstrap.css"
				@page.request_css "css/plugins/dataTables/dataTables.responsive.css"
				@page.request_css "css/plugins/dataTables/dataTables.tableTools.min.css"

				@page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').DataTable();
				DATATABLE_SCRIPT
			end

			if options[:system] == :foo_table
				classname += " toggle-arrow-tiny"
				@page.request_js "js/plugins/footable/footable.all.min.js"

				@page.request_css "css/plugins/footable/footable.core.css"

				@page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').footable();
				DATATABLE_SCRIPT
			end


			method_missing(:table, :class => classname, id: table_name, &block)
		end

		def table_from_hashes(hashes, options={})

			keys = {}
			hashes.each do |hash|
				hash.each do |key,value|
					keys[key] = ""
				end
			end

			table options do

				thead do
					keys.each do |key, _| 
						th key.to_s
					end
				end

				hashes.each do |hash|

					tr do
						keys.each do |key, _|
							td "#{hash[key]}" || "&nbsp;"
						end
					end
				end

			end
		end

		def generate
			@inner_content.join
		end
	end

	class Action
		def initialize(page, anchors, &block)
			@page = page
			@anchors = anchors

			actionsArray = @anchors["action"]

			if !@anchors["action"]
				@anchors["action"] = []
			end

			actionsArray = @anchors["action"]

			@actionName = "action#{actionsArray.length}"
			actionsArray << @actionName

			@code = ""

			self.instance_eval(&block)
		end

		def script(code)
			@code = code
		end

		def generate
			puts @code
			<<-FUNCTION
function #{@actionName}(caller, data) {
	#{@code}
}
			FUNCTION
		end

		def name
			@actionName
		end
	end

	class Code
		def initialize(page, anchors, lang)
			@page = page
			@anchors = anchors
			@content = ""
			@options = {}

			codeArray = @anchors["code"]

			if !@anchors["code"]
				@anchors["code"] = []
			end

			codeArray = @anchors["code"]

			@codeName = "code#{codeArray.length}"
			codeArray << @codeName

			@page.request_css "css/plugins/codemirror/codemirror.css"
			@page.request_js "js/plugins/codemirror/codemirror.js"

			language lang

		end

		def language(lang)
			# TODO improve langmap
			langmap = {
				javascript: {mime: "text/javascript", file: "javascript/javascript"}
			}

			if langmap[lang]
				@options[:mode] = langmap[lang][:mime]
				@page.request_js "js/plugins/codemirror/mode/#{langmap[lang][:file]}.js"
			else
				@options[:mode] = "text/x-#{lang}"
				@page.request_js "js/plugins/codemirror/mode/#{lang}/#{lang}.js"
			end

		end

		def content(text)
			@content = text
		end

		def theme(name)
			@options[:theme] = name

			@page.request_css "css/plugins/codemirror/#{name}.css"
		end

		def generate_script

			@options[:lineNumbers] ||= true
			@options[:matchBrackets] ||= true
			@options[:styleActiveLine] ||= true
			@options[:mode] ||= "javascript"
			@options[:readOnly] ||= true

			<<-CODESCRIPT
		$(document).ready(function()
		{
			CodeMirror.fromTextArea(document.getElementById("#{@codeName}"), 
				JSON.parse('#{@options.to_json}')
			);
	    });
	        CODESCRIPT
		end

		def generate

			content = @content
			codeName = @codeName

        	elem = Elements.new(@page, @anchors)

        	elem.instance_eval do
				textarea id: codeName do
					text content
				end
        	end

        	elem.generate
		end
	end

	class Form < Elements
		def initialize(page, anchors, options)
			super(page, anchors)
			@options = options
			@scripts = []

			@formName = @page.create_anchor "form"
		end

		def passwordfield(name, textfield_label, options={})
			options[:type] = "password"
			textfield(name, textfield_label, options)
		end

		def textfield(name, textfield_label, options={})

			textfield_name = @page.create_anchor "textfield"
			options[:type] ||= "text"
			options[:placeholder] ||= ""
			options[:name] = name

			input_options = {}
			input_options[:type] = options[:type]
			input_options[:placeholder] = options[:placeholder]
			input_options[:id] = textfield_name
			input_options[:name] = options[:name]
			input_options[:class] = "form-control"

			if options[:mask]
				@page.request_css "css/plugins/jasny/jasny-bootstrap.min.css"
				@page.request_js "js/plugins/jasny/jasny-bootstrap.min.js"

				input_options[:"data-mask"] = options[:mask]

			end

			div :class => "form-group" do
				label textfield_label
				input input_options
			end

			@scripts << <<-SCRIPT
	object["#{name}"] = $('##{textfield_name}').val();
			SCRIPT
		end

	
		def dropdown(name, dropdown_label, choice_array, options={})
			select_name = @page.create_anchor "select"

			div :class => "form-group" do
				label dropdown_label, :class => "control-label"

				options[:class] = "form-control"
				options[:name] = name
				options[:id] = select_name

				method_missing :select, options do
					choice_array.each do |choice|
						option choice
					end
				end
			end

			if options[:multiple]
				@scripts << <<-SCRIPT
	var selections = []; 
	$("##{select_name} option:selected").each(function(i, selected){ 
  		selections[i] = $(selected).text(); 
	});
	object["#{name}"] = selections;
				SCRIPT
			else
				@scripts << <<-SCRIPT
	object["#{name}"] = $( "##{select_name} option:selected" ).text();
				SCRIPT
			end

		end

		def knob(name, options={})

			knob_name = @page.create_anchor "knob"

			@page.request_js "js/plugins/jsKnob/jquery.knob.js"
			@page.write_script_once <<-SCRIPT
	$(".dial").knob();
			SCRIPT

			knob_options = {}

			knob_options[:id] = knob_name
			knob_options[:type] = "text"
			knob_options[:value] = options[:value] || "0"
			knob_options[:class] = "dial"

			options.each do |key,value|
				knob_options["data-#{key}".to_sym] = value
			end

			knob_options[:"data-fgColor"] = "#1AB394"
			knob_options[:"data-width"] = "85"
			knob_options[:"data-height"] = "85"

			input knob_options

			@scripts << <<-SCRIPT
	object["#{name}"] = $('##{knob_name}').val();
			SCRIPT
		end

		def radio(name, choice_array, options={})

			radio_name = @page.create_anchor "radio"

			first = true
			choice_array.each do |choice|

				value = choice
				label = choice
				if choice.is_a? Hash
					value = choice[:value]
					label = choice[:label]
				end

				the_options = Hash.new(options)
				if first
					the_options[:checked] = ""
					first = false
				end
				the_options[:type] = "radio"
				the_options[:value] = value
				the_options[:name] = name
				text boolean_element(label, the_options)
			end
			@scripts << <<-SCRIPT
	object["#{name}"] = $('input[name=#{name}]:checked', '##{@formName}').val()
			SCRIPT
			
		end

		def checkbox(name, checkbox_label, options={})
			checkbox_name = @page.create_anchor "checkbox"
			options[:type] = "checkbox"
			options[:name] = name
			options[:id] = checkbox_name
			text boolean_element(checkbox_label, options)
			@scripts << <<-SCRIPT
	object["#{name}"] = $('##{checkbox_name}').is(":checked");
			SCRIPT
		end


		def submit(anIcon, title={}, options={}, &block)
			options[:icon] = anIcon
			options[:title] = title
			options[:data] = "get_#{@formName}_object()"
			_button(options, &block)
		end

		def generate_script
			<<-SCRIPT
function get_#{@formName}_object()
{
	var object = {}
#{@scripts.join "\n"}
	return object;
}
			SCRIPT
		end

		def boolean_element(checkbox_label, options={})

			@page.request_css "css/plugins/iCheck/custom.css"
			@page.request_js "js/plugins/iCheck/icheck.min.js"

			@page.write_script_once <<-SCRIPT
$(document).ready(function () {
    $('.i-checks').iCheck({
        checkboxClass: 'icheckbox_square-green',
        radioClass: 'iradio_square-green',
    });
});
			SCRIPT

			elem = Elements.new(@page, @anchors)
			elem.instance_eval do
				div class: "i-checks" do
					label do
						input options do
							text " #{checkbox_label}"
						end
					end
				end
			end

			elem.generate
		end

		def generate
			inner = super
			formName = @formName

			elem = Elements.new(@page, @anchors)
			elem.instance_eval do
				method_missing :form, id: formName, role: "form" do
					text inner
				end
			end

			elem.generate
		end
	end

	class Panel < Elements
		def initialize(page, anchors, options)
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
        		:ibox  => 	{ outer: "ibox float-e-margins",header: "ibox-title",    body: "ibox-content" , footer: "ibox-footer"},
        		:panel => 	{ outer: "panel panel-default", header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:primary => { outer: "panel panel-primary", header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:success => { outer: "panel panel-success", header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:info => 	{ outer: "panel panel-info",  	header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:warning => { outer: "panel panel-warning", header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:danger => 	{ outer: "panel panel-danger",  header: "panel-heading", body: "panel-body"   , footer: "panel-footer"},
        		:blank => 	{ outer: "panel blank-panel",   header: "panel-heading", body: "panel-body"   , footer: "panel-footer"}
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

        	if options[:collapsed]
        		outer_class = "ibox collapsed"
        	end

        	elem.instance_eval do
				div class: outer_class do
					if title
						div class: classNames[:header] do
							h5 title

							div class: "ibox-tools" do
								if options[:collapsible] or options[:collapsed]
									a class: "collapse-link" do
										icon :"chevron-up"
									end
								end
								if options[:expandable]
									a class: "fullscreen-link" do
										icon :expand
									end
								end
								if options[:closable]
									a class: "close-link" do
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
					if extra
						text extra
					end
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

		def title(title=nil, &block)
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

		def footer(footer=nil, &block)
			@footer = footer
			if block
				elem = Elements.new(@page, @anchors)
				elem.instance_eval(&block)
				@footer = elem.generate
			end
		end

	end

	class Accordion
		def initialize(page, anchors)
			@anchors = anchors
			@tabs = {}
			@paneltype = :panel
			@is_collapsed = false
			@page = page

			if !@anchors["accordia"]
				@anchors["accordia"] = []
			end

			accArray = @anchors["accordia"]

			@accordion_name = "accordion#{accArray.length}"
			accArray << @accordion_name
		end

		def collapsed(isCollapsed)
			@is_collapsed = isCollapsed
		end

		def type(type)
			@paneltype = type
		end

		def tab(title, &block)
			
			if !@anchors["tabs"]
				@anchors["tabs"] = []
			end

			tabArray = @anchors["tabs"]

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

		def generate
			tabbar = Elements.new(@page, @anchors)

			tabs = @tabs
			paneltype = @paneltype
			accordion_name = @accordion_name
			is_collapsed = @is_collapsed

			tabbar.instance_eval do

				div :class => "panel-group", id: accordion_name do

					cls = "panel-collapse collapse in"
					cls = "panel-collapse collapse" if is_collapsed
					tabs.each do |anchor, value|

						ibox do
							type paneltype
							body false
							title do
								div :class => "panel-title" do
									a :"data-toggle" => "collapse", :"data-parent" => "##{accordion_name}", href: "##{anchor}" do
										if value[:title].is_a? Symbol
											icon value[:title]
										else
											text value[:title]
										end
									end
								end
							end

							extra do 
								div id: anchor, :class => cls do
									div :class => "panel-body" do
										text value[:elem].generate
									end
								end
							end
						end

						cls = "panel-collapse collapse"
					end

				end

			end

			tabbar.generate
		end

	end

	class Tabs
		def initialize(page, anchors)
			@anchors = anchors
			@tabs = {}
			@page = page
			@orientation = :normal # :left, :right
		end

		def tab(title, &block)
			
			if !@anchors["tabs"]
				@anchors["tabs"] = []
			end

			tabArray = @anchors["tabs"]

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

				div :class => "tabs-container" do

					div :class => "tabs-#{orientation}" do

						ul :class => "nav nav-tabs" do
							cls = "active"
							tabs.each do |anchor, value|
								li :class => cls do
									a :"data-toggle" => "tab", href: "##{anchor}" do
										if value[:title].is_a? Symbol
											icon value[:title]
										else
											text value[:title]
										end
									end
								end

								cls = ""
							end
						end

						div :class => "tab-content" do

							cls = "tab-pane active"
							tabs.each do |anchor, value|
								div id: "#{anchor}", :class => cls do
									div :class => "panel-body" do
										text value[:elem].generate
									end
								end
								cls = "tab-pane"
							end
						end
					end

				end
			end

			tabbar.generate
		end
	end

	class Page

		attr_accessor :scripts

		def initialize(title, options)
			@title = title
			@content = ""
			@body_class = nil
			@anchors = {}
			@options = options
			@scripts = []
			@top_content = ""

			@scripts_once = {}

			@requested_scripts = {}
			@requested_css = {}
		end

		def create_anchor(name)

			if !@anchors[name]
				@anchors[name] = []
			end

			anchor_array = @anchors[name]

			anchor_name = "#{name}#{anchor_array.length}"
			anchor_array << anchor_name

			anchor_name
		end

		def root
			return @options[:root]
		end

		def request_js(path)
			@requested_scripts[path] = true
		end

		def request_css(path)
			@requested_css[path] = true
		end

		def write_script_once(script)
			@scripts_once[script] = true
		end

		def top(&block)
			elem = Elements.new(@page, @anchors)
			elem.instance_eval(&block)

			@top_content = elem.generate
		end

		def generate(back_folders, options={})

			scripts = @scripts.join("\n")

			mod = "../" * back_folders

			style = <<-ENDSTYLE
	<link href="#{mod}css/style.css" rel="stylesheet">
			ENDSTYLE

			if options[:style] == :empty
				style = ""
			end

			body_tag = "<body>"

			body_tag = "<body class='#{@body_class}'>" if @body_class

			loading_bar = ""
			loading_bar = '<script src="#{mod}js/plugins/pace/pace.min.js"></script>' if @loading_bar_visible

			extra_scripts = @requested_scripts.map {|key,value| <<-SCRIPT_DECL
    <script src="#{mod}#{key}"></script>
				SCRIPT_DECL
			}.join "\n"

			extra_css = @requested_css.map {|key,value| <<-STYLESHEET_DECL
    <link href="#{mod}#{key}" rel="stylesheet">
				STYLESHEET_DECL
			}.join "\n"

			extra_one_time_scripts = @scripts_once.map {|key,value| <<-SCRIPT_DECL
#{key}
				SCRIPT_DECL
			}.join "\n"

			<<-SKELETON
<!DOCTYPE html>
<html>
<!-- Generated using weaver: https://github.com/davidsiaw/weaver -->
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>#{@title}</title>

    <link href="#{mod}css/bootstrap.min.css" rel="stylesheet">
    <link href="#{mod}font-awesome/css/font-awesome.css" rel="stylesheet">
    <link href="#{mod}css/plugins/iCheck/custom.css" rel="stylesheet">
    <link href="#{mod}css/plugins/blueimp/css/blueimp-gallery.min.css" rel="stylesheet">

#{extra_css}

    #{style}
    <link href="#{mod}css/animate.css" rel="stylesheet">
    
</head>

#{body_tag}
#{@top_content}
#{@content}

    <!-- Mainly scripts -->
    <script src="#{mod}js/jquery-2.1.1.js"></script>
    <script src="#{mod}js/jquery-ui-1.10.4.min.js"></script>
    <script src="#{mod}js/bootstrap.min.js"></script>
    <script src="#{mod}js/plugins/metisMenu/jquery.metisMenu.js"></script>
    <script src="#{mod}js/plugins/slimscroll/jquery.slimscroll.min.js"></script>

#{extra_scripts}

    <!-- blueimp gallery -->
    <script src="#{mod}js/plugins/blueimp/jquery.blueimp-gallery.min.js"></script>

    <style>
        /* Local style for demo purpose */

        .lightBoxGallery {
            text-align: center;
        }

        .lightBoxGallery img {
            margin: 5px;
        }

    </style>


    <!-- Custom and plugin javascript -->
    <script src="#{mod}js/inspinia.js"></script>
    #{loading_bar}

    <script>
#{scripts}
#{extra_one_time_scripts}
    </script>

    <div id="blueimp-gallery" class="blueimp-gallery">
                                <div class="slides"></div>
                                <h3 class="title"></h3>
                                <a class="prev">‹</a>
                                <a class="next">›</a>
                                <a class="close">×</a>
                                <a class="play-pause"></a>
                                <ol class="indicator"></ol>
                            </div>
    

</body>

</html>

			SKELETON
		end
	end

	class Row
		attr_accessor :extra_classes

		def initialize(page, anchors, options)
			@columns = []
			@free = 12
			@extra_classes = options[:class] || ""
			@anchors = anchors
			@page = page
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


		def col(occupies, options={}, &block)
			raise "Not enough columns!" if @free < occupies
			elem = Elements.new(@page, @anchors)
			elem.instance_eval(&block)

			@columns << { occupy: occupies, elem: elem, options: options }
			@free -= occupies 
		end

		def generate
			@columns.map { |col|

				xs = col[:options][:xs] || col[:occupy]
				sm = col[:options][:sm] || col[:occupy]
				md = col[:options][:md] || col[:occupy]
				lg = col[:options][:lg] || col[:occupy]

				<<-ENDCOLUMN
		<div class="col-xs-#{xs} col-sm-#{sm} col-md-#{md} col-lg-#{lg}">
			#{col[:elem].generate}
		</div>
				ENDCOLUMN
			}.join
		end
	end

	class Menu
		attr_accessor :items
		def initialize()
			@items = []
		end

		def nav(name, icon=:question, url=nil, &block)
			if url 
				@items << { name: name, link: url, icon: icon }
			else
				@items << { name: name, link: "#", icon: icon }
			end
			if block
				menu = Menu.new
				menu.instance_eval(&block)
				@items << { name: name, menu: menu, icon: icon }
			end
		end
	end

	class NavPage < Page
		def initialize(title, options)
			super
			@menu = Menu.new
		end

		def menu(&block)
			@menu.instance_eval(&block)
		end

	end


	class SideNavPage < NavPage
		def initialize(title, options)
			@rows = []
			super
		end

		def header(&block)
			row(class: "wrapper border-bottom white-bg page-heading", &block)
		end

		def brand(text, link="/")
			@brand = text
			@brand_link = link
		end

		def row(options={}, &block)
			r = Row.new(self, @anchors, options)
			r.instance_eval(&block)
			@rows << r
		end

		def generate(level)
			rows = @rows.map { |row|
				<<-ENDROW
	<div class="row #{row.extra_classes}">
#{row.generate}
	</div>
				ENDROW
			}.join

			menu = @menu

			navigation = Elements.new(@page, @anchors)
			navigation.instance_eval do

				menu.items.each do |item|
					li do
						if item.has_key? :menu


							a href:"#" do
								icon item[:icon]
								span :class => "nav-label" do
									text item[:name]
								end
								span :class => "fa arrow" do
									text ""
								end
							end

            				ul :class => "nav nav-second-level" do
            					item[:menu].items.each do |inneritem|
            						li do
            							if inneritem.has_key?(:menu)
            								raise "Second level menu not supported"
            							else
                							link inneritem[:name], href:inneritem[:link]
            							end
            						end
            					end
                    		end
						elsif
							a href: "#" do
								span :class => "nav-label" do
									text item[:name]
								end
							end
						end
					end
				end

			end

			brand_content = "" 

			if @brand
				brand_content = <<-BRAND_CONTENT

	                <li>
	                    <a href="#"><i class="fa fa-home"></i> <span class="nav-label">X</span> <span class="label label-primary pull-right"></span></a>
	                </li>
				BRAND_CONTENT
			end

			@loading_bar_visible = true
			@content =
			<<-ENDBODY
	<div id="wrapper">

		<nav class="navbar-default navbar-static-side" role="navigation">
			<div class="sidebar-collapse">
				<ul class="nav" id="side-menu">

#{brand_content}
#{navigation.generate}

				</ul>
			</div>
		</nav>
		<div id="page-wrapper" class="gray-bg">
			<div class="row border-bottom">
		        <nav class="navbar navbar-static-top  " role="navigation" style="margin-bottom: 0">
					<div class="navbar-header">
					    <a class="navbar-minimalize minimalize-styl-2 btn btn-primary " href="#"><i class="fa fa-bars"></i> </a>
					</div>
		            <ul class="nav navbar-top-links navbar-right">
		                <!-- NAV RIGHT -->
		            </ul>
		        </nav>
	        </div>
#{rows}
		</div>
	</div>
			ENDBODY

			super
		end
	end

	class TopNavPage < NavPage
		def initialize(title, options)
			@rows = []
			super
		end

		def header(&block)
			row(class: "wrapper border-bottom white-bg page-heading", &block)
		end

		def brand(text, link="/")
			@brand = text
			@brand_link = link
		end

		def row(options={}, &block)
			r = Row.new(self, @anchors, options)
			r.instance_eval(&block)
			@rows << r
		end

		def generate(level)
			rows = @rows.map { |row|
				<<-ENDROW
	<div class="row #{row.extra_classes}">
#{row.generate}
	</div>
				ENDROW
			}.join

			@body_class = "top-navigation"
			@loading_bar_visible = true

			menu = @menu

			navigation = Elements.new(self, @anchors)
			navigation.instance_eval do

				menu.items.each do |item|
					li do
						if item.has_key? :menu

                    		li :class => "dropdown" do
                    			a :"aria-expanded" => "false", 
                    				role: "button", 
                    				href: "#", 
                    				:class => "dropdown-toggle", 
                    				:"data-toggle" => "dropdown" do

									icon item[:icon]
                    				text item[:name]
                    				span :class => "caret" do
                    					text ""
                    				end

                    			end
                				ul role: "menu", :class => "dropdown-menu" do
                					item[:menu].items.each do |inneritem|
                						li do
                							if inneritem.has_key?(:menu)
                								raise "Second level menu not supported"
                							else
	                							link inneritem[:name], href:inneritem[:link]
                							end
                						end
                					end
                				end
                    		end
						elsif
							link "#{item[:link]}" do
								span :class => "nav-label" do
									icon item[:icon]
									text item[:name]
								end
							end
						end
					end
				end

			end

			brand_content = "" 

			if @brand
				brand_content = <<-BRAND_CONTENT

				    <div class="navbar-header">

						<a href="#" class="navbar-brand">X</a>
		            </div>
				BRAND_CONTENT
			end

			@content =
			<<-ENDBODY
	<div id="wrapper">

        <div id="page-wrapper" class="gray-bg">
	        <div class="row border-bottom white-bg">

				<nav class="navbar navbar-static-top" role="navigation">
	                <button aria-controls="navbar" aria-expanded="false" data-target="#navbar" data-toggle="collapse" class="navbar-toggle collapsed" type="button">
	                    <i class="fa fa-reorder"></i>
	                </button>
#{brand_content}

		            <div class="navbar-collapse collapse" id="navbar">
		                <ul class="nav navbar-nav">
#{navigation.generate}
		                </ul>
		                <ul class="nav navbar-top-links navbar-right">
		                	<!-- NAV RIGHT -->
		                </ul>
		            </div>



				</nav>
			</div>


	        <div class="wrapper-content">
	            <div class="container">
#{rows}
	            </div>
			</div>
		</div>
	</div>
			ENDBODY

			super
		end
	end


	class CenterPage < Page
		def initialize(title, options)
			@element = Elements.new(self, {})
			super
		end

		def element=(value)
			@element = value
		end

		def generate(level)
			@body_class = "gray-bg"
			@content = <<-CONTENT
	<div class="middle-box text-center animated fadeInDown">
		<div>
			#{@element.generate}
		</div>
	</div>
			CONTENT
			super
		end
	end

	class Weave
		attr_accessor :pages
		def initialize(file, options={})
			@pages = {}
			@file = file
			@options = options

			@options[:root] = @options[:root] || "/"
			@options[:root] = "#{@options[:root]}/" unless @options[:root].end_with? "/"
			instance_eval(File.read(file), file)
		end

		def center_page(path, title=nil, &block)

			if title == nil
				title = path
				path = ""
			end

			p = CenterPage.new(title, @options)

			elem = Elements.new(p, {})
			elem.instance_eval(&block) if block

			p.element=elem

			@pages[path] = p
		end

		def sidenav_page(path, title=nil, &block)

			if title == nil
				title = path
				path = ""
			end

			p = SideNavPage.new(title, @options)
			p.instance_eval(&block) if block
			@pages[path] = p
		end

		def topnav_page(path, title=nil, &block)

			if title == nil
				title = path
				path = ""
			end

			p = TopNavPage.new(title, @options)
			p.instance_eval(&block) if block
			@pages[path] = p
		end

		def include(file)
			dir = File.dirname(@file)
			filename = File.join([dir, file])
			File.read(filename)
			load filename
		end
	end
end
