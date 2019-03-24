require 'weaver/version'

require 'fileutils'
require 'json'
require 'active_support/core_ext/object/to_query'

require 'weaver/weave'

require 'weaver/elements'

require 'weaver/page_types/page'
require 'weaver/page_types/center_page'
require 'weaver/page_types/empty_page'
require 'weaver/page_types/raw_page'
require 'weaver/page_types/nonnav_page'
require 'weaver/page_types/sidenav_page'
require 'weaver/page_types/topnav_page'

module Weaver
  class ModalDialog
    def initialize(page, anchors, id, &block)
      @page = page
      @anchors = anchors
      @id = id || @page.create_anchor('modal')

      @header_content = Elements.new(@page, @anchors)
      @body_content = Elements.new(@page, @anchors)
      @footer_content = Elements.new(@page, @anchors)

      instance_eval(&block) if block
    end

    attr_reader :id

    def header(&block)
      @header_content.instance_eval(&block)
    end

    def body(&block)
      @body_content.instance_eval(&block)
    end

    def footer(&block)
      @footer_content.instance_eval(&block)
    end

    def generate
      elem = Elements.new(@page, @anchors)

      id = @id
      header_content = @header_content
      body_content = @body_content
      footer_content = @footer_content

      elem.instance_eval do
        div class: 'modal fade', id: id, tabindex: -1, role: 'dialog' do
          div class: 'modal-dialog', role: 'document' do
            div class: 'modal-content' do
              div class: 'modal-header' do
                button '&times;', type: 'button', class: 'close', "data-dismiss": 'modal', "aria-label": 'Close'
                text header_content.generate
              end
              div class: 'modal-body' do
                text body_content.generate
              end
              div class: 'modal-footer' do
                text footer_content.generate
              end
            end
          end
        end
      end

      elem.generate
    end
  end

  class DynamicTableCell < Elements
    attr_accessor :transform_script

    def data_button(anIcon, title = {}, options = {}, &block)
      options[:icon] = anIcon
      options[:title] = title
      options[:data] = "$(this).closest('td').data('object')"
      _button(options, &block)
    end

    def transform(script)
      @transform_script = script
    end
  end

  class JavaScriptObject
    def initialize(&block)
      @object = {}
      instance_eval(&block) if block
    end

    def string(name, string)
      @object[name] = { type: :string, value: string }
    end

    def variable(name, var_name)
      @object[name] = { type: :var, value: var_name }
    end

    def generate
      result = @object.map do |key, value|
        value_expression = value[:value]

        value_expression = "\"#{value[:value]}\"" if value[:type] == :string

        "#{key}: #{value_expression}"
      end.join ','

      "{#{result}}"
    end
  end

  class DynamicTable
    def initialize(page, anchors, url, options = {}, &block)
      @page = page
      @anchors = anchors
      @url = url
      @options = options
      @columns = nil
      @query_object = nil

      instance_eval(&block) if block

      @options[:id] ||= @page.create_anchor 'dyn_table'
      @table_name = @options[:id]
      @head_name = "#{@table_name}_head"
      @body_name = "#{@table_name}_body"
    end

    def column(name, options = {}, &block)
      @columns = [] if @columns.nil?

      title = options[:title] || name
      format = nil
      transform = nil

      if options[:icon]
        elem = Elements.new(@page, @anchors)
        elem.instance_eval do
          icon options[:icon]
          text " #{title}"
        end
        title = elem.generate
      end

      if block
        elem = DynamicTableCell.new(@page, @anchors)
        elem.instance_eval(&block)
        format = elem.generate
        if elem.transform_script
          func_name = @page.create_anchor 'transform'
          @page.write_script_once <<-SCRIPT
document.transform_#{func_name} = function (input)
{
#{elem.transform_script}
}
          SCRIPT

          transform = func_name
         end
      end

      @columns << { name: name, title: title, format: format, transform: transform }
    end

    def generate_table
      table_name = @table_name
      head_name = @head_name
      body_name = @body_name
      options = @options

      columns = @columns || [{ title: 'Key' }, { title: 'Value' }]

      elem = Elements.new(@page, @anchors)
      elem.instance_eval do
        table options do
          thead id: head_name do
            columns.each do |column, _|
              if column.is_a? Hash
                th column[:title].to_s
              else
                th column.to_s
              end
            end
          end

          tbody id: body_name do
          end
        end
      end

      elem.generate
    end

    def query(&block)
      @query_object = JavaScriptObject.new(&block)
    end

    def generate_script
      query_object_declaration = '{}'
      query_string = ''

      if @query_object
        query_object_declaration = @query_object.generate
        query_string = '+ "?" + $.param(query_object)'
      end

      member_expr = ''
      member_expr = ".#{@options[:member]}" if @options[:member]

      <<-DATATABLE_SCRIPT

	function refresh_table_#{@table_name}()
	{
		var query_object = #{query_object_declaration};

		$.get( "#{@url}" #{query_string}, function( returned_data )
		{
			var data = returned_data#{member_expr};
			var data_object = {};
			if (data !== null && typeof data === 'object')
			{
				data_object = data;
			}
			else
			{
				data_object = JSON.parse(data);
			}

			var head = $("##{@head_name}")
			var body = $("##{@body_name}")

			if($.isPlainObject(data_object))
			{
				for (var key in data_object)
				{
					var row = $('<tr>');
					row.append($('<td>').text(key));
					row.append($('<td>').text(data_object[key]));
					body.append(row);
				}
			}

			if ($.isArray(data_object))
			{

				var columnData = JSON.parse(#{@columns.to_json.inspect});
				var columns = {};
				var columnTitles = [];
				head.empty();
				if (#{@columns.nil?})
				{
					// Set up columns
					for (var index in data_object)
					{
						for (var key in data_object[index])
						{
							columns[key] = Object.keys(columns).length;
						}
					}
					for (var key in columns)
					{
						columnTitles.push(key);
					}
				}
				else
				{
					for (var key in columnData)
					{
						columns[columnData[key]["name"]] = Object.keys(columns).length;
						columnTitles.push(columnData[key]["title"]);
					}
				}

				var row = $('<tr>');
				for (var key in columnTitles)
				{
					var columnTitle = $('<th>').html(columnTitles[key]);
					row.append(columnTitle);
				}
				head.append(row);

				for (var index in data_object)
				{
					var row = $('<tr>');
					for (var columnIndex = 0; columnIndex < Object.keys(columns).length; columnIndex++) {
						var cell_data = data_object[index][ Object.keys(columns)[columnIndex] ];

						if (columnData && columnData[columnIndex]["format"])
						{
							var format = columnData[columnIndex]["format"];
							var matches = format.match(/###.+?###/g)

							var result = format;
							for (var matchIndex in matches)
							{
								var member_name = matches[matchIndex].match(/[^#]+/)[0];
								result = result.replaceAll(matches[matchIndex], data_object[index][member_name]);
							}

							if (columnData && columnData[columnIndex]["transform"])
							{
								result = document["transform_" + columnData[columnIndex]["transform"]](result);
							}
							row.append($('<td>').html( result ).data("object", data_object[index]) );
						}
						else
						{
							if (columnData && columnData[columnIndex]["transform"])
							{
								cell_data = document["transform_" + columnData[columnIndex]["transform"]](cell_data);
							}
							row.append($('<td>').text( cell_data ).data("object", data_object[index]) );
						}
					}
					body.append(row);
				}
			}

		});
	}

	refresh_table_#{@table_name}();

      DATATABLE_SCRIPT
    end
  end

  class Action
    def initialize(page, anchors, &block)
      @page = page
      @anchors = anchors

      actionsArray = @anchors['action']

      @anchors['action'] = [] unless @anchors['action']

      actionsArray = @anchors['action']

      @actionName = "action#{actionsArray.length}"
      actionsArray << @actionName

      @code = ''

      instance_eval(&block)
    end

    def script(code)
      @code = code
    end

    def generate
      # puts @code
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
      @content = ''
      @options = {}

      codeArray = @anchors['code']

      @anchors['code'] = [] unless @anchors['code']

      codeArray = @anchors['code']

      @codeName = "code#{codeArray.length}"
      codeArray << @codeName

      @page.request_css 'css/plugins/codemirror/codemirror.css'
      @page.request_js 'js/plugins/codemirror/codemirror.js'

      language lang
    end

    def language(lang)
      # TODO: improve langmap
      langmap = {
        javascript: { mime: 'text/javascript', file: 'javascript/javascript' }
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
      @options[:mode] ||= 'javascript'
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

  class TextfieldJavascript
    def initialize(id)
      @id = id
    end

    def onchange(script)
      @change_script = script
    end

    def validate(script)
      @validate_script = script
    end

    def generate(&block)
      if block
        instance_eval(&block)
        <<-SCRIPT

if (!document.validators)
{
	document.validators = {};
}

document.validators["##{@id}"] = function()
{
	var valid = function(data) {
		#{@validate_script};
		return true;
	}($("##{@id}").val());

	var object = $("##{@id}");
	#{@change_script};

	if (valid)
	{
		object.removeClass("required");
		object.removeClass("error");
		object.removeAttr("aria-invalid");
	}
	else
	{
		object.addClass("required");
		object.addClass("error");
		object.attr("aria-required", "true");
		object.attr("aria-invalid", "true");
	}
}

$("##{@id}").keyup(function() { document.validators["##{@id}"](); })
$("##{@id}").blur(function() { document.validators["##{@id}"](); })
$("##{@id}").focusout(function() { document.validators["##{@id}"](); })

        SCRIPT
      end
    end
  end

  class FormElements < Elements
    attr_accessor :options, :scripts

    def initialize(page, anchors, formName, options = {})
      super(page, anchors)
      @formName = formName
      @options = options
      @scripts = []
    end

    def passwordfield(name, textfield_label = nil, options = {}, &block)
      if textfield_label.is_a? Hash
        options = textfield_label
        textfield_label = nil
      end

      options[:type] = 'password'
      textfield(name, textfield_label, options, &block)
    end

    def textfield(name, textfield_label = nil, options = {}, &block)
      if textfield_label.is_a? Hash
        options = textfield_label
        textfield_label = nil
      end

      textfield_name = options[:id] || @page.create_anchor('textfield')
      options[:type] ||= 'text'
      options[:placeholder] ||= ''
      options[:name] = name

      input_options = {}
      input_options[:type] = options[:type]
      input_options[:placeholder] = options[:placeholder]
      input_options[:id] = textfield_name
      input_options[:name] = options[:name]
      input_options[:rows] = options[:rows]
      input_options[:class] = 'form-control'
      input_options[:value] = options[:value]
      input_options[:style] = options[:style]

      input_options[:autocomplete] = options[:autocomplete] || 'on'
      input_options[:autocorrect] = options[:autocorrect] || 'on'
      input_options[:autocapitalize] = options[:autocapitalize] || 'off'

      if options[:mask]
        @page.request_css 'css/plugins/jasny/jasny-bootstrap.min.css'
        @page.request_js 'js/plugins/jasny/jasny-bootstrap.min.js'

        input_options[:"data-mask"] = options[:mask]
      end

      div class: "form-group #{options[:extra_class]}", id: "#{input_options[:id]}-group" do
        label textfield_label if textfield_label

        div_class = ' '
        if options[:front_text] || options[:back_text]
          div_class = 'input-group m-b'
         end

        div "class": div_class do
          span (options[:front_text]).to_s, class: 'input-group-addon' if options[:front_text]
          if input_options[:rows] && (input_options[:rows] > 1)
            textarea input_options do
            end
          else
            input input_options
          end
          span (options[:back_text]).to_s, class: 'input-group-addon' if options[:back_text]
        end
      end

      textjs = TextfieldJavascript.new(input_options[:id])

      @page.on_page_load textjs.generate(&block) if block

      @scripts << <<-SCRIPT
	object["#{name}"] = $('##{textfield_name}').val();
      SCRIPT
    end

    def hiddenfield(name, value, options = {})
      hiddenfield_name = options[:id] || @page.create_anchor('hiddenfield')

      input_options = {}
      input_options[:type] = 'hidden'
      input_options[:value] = value
      input_options[:id] = hiddenfield_name
      input_options[:name] = name

      input input_options

      @scripts << <<-SCRIPT
	object["#{name}"] = $('##{hiddenfield_name}').val();
      SCRIPT
    end

    def dropdown(name, dropdown_label, choice_array, options = {})
      select_name = options[:id] || @page.create_anchor('select')

      options[:class] = 'form-control'
      options[:name] = name
      options[:id] = select_name
      options[:placeholder] ||= ' '

      form_options = options.clone

      if options[:multiple]

        if options[:multiple_style] == :chosen
          @page.request_css 'css/plugins/chosen/chosen.css'
          @page.request_js 'js/plugins/chosen/chosen.jquery.js'

          @page.write_script_once <<-SCRIPT
	var config = {
		'.chosen-select'           : {placeholder_text_multiple: "#{options[:placeholder]}"},
		'.chosen-select-deselect'  : {allow_single_deselect:true},
		'.chosen-select-no-single' : {disable_search_threshold:10},
		'.chosen-select-no-results': {no_results_text:'Oops, nothing found!'},
		'.chosen-select-width'     : {width:"95%"}
	}
	for (var selector in config) {
		$(selector).chosen(config[selector]);
	}
          SCRIPT

          form_options[:class] = 'chosen-select'
          form_options[:style] = 'width: 100%'
        end

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

      div class: 'form-group' do
        label dropdown_label, class: 'control-label'

        div class: 'input-group', style: 'width: 100%' do
          method_missing :select, form_options do
            choice_array.each do |choice|
              if (options[:value]).to_s == choice.to_s
                option choice, selected: true
              else
                option choice
              end
            end
          end
        end
      end
    end

    def knob(name, options = {})
      knob_name = @page.create_anchor 'knob'

      @page.request_js 'js/plugins/jsKnob/jquery.knob.js'
      @page.write_script_once <<-SCRIPT
	$(".dial").knob();
      SCRIPT

      knob_options = {}

      knob_options[:id] = knob_name
      knob_options[:type] = 'text'
      knob_options[:value] = options[:value] || '0'
      knob_options[:class] = 'dial'

      options.each do |key, value|
        knob_options["data-#{key}".to_sym] = value
      end

      knob_options[:"data-fgColor"] = '#1AB394'
      knob_options[:"data-width"] = '85'
      knob_options[:"data-height"] = '85'

      input knob_options

      @scripts << <<-SCRIPT
	object["#{name}"] = $('##{knob_name}').val();
      SCRIPT
    end

    def radio(name, choice_array, options = {})
      radio_name = @page.create_anchor 'radio'

      choice_array = choice_array.map do |choice|
        if choice.is_a? Hash
          { value: choice[:value], label: choice[:label] }
        else
          { value: choice, label: choice }
        end
      end

      active = choice_array[0][:value]
      if options[:value] && (choice_array.index { |x| x[:value] == options[:value] } != nil)
        active = options[:value]
      end

      div_options = {}
      curobject = self
      div_options[:"data-toggle"] = 'buttons' if options[:form] == :button
      div div_options do
        choice_array.each do |choice|
          value = choice[:value]
          label = choice[:label]

          the_options = Hash.new(options)

          the_options[:checked] = '' if active == value

          if options[:form] == :button
            the_options[:type] = 'radio'
            the_options[:value] = value
            the_options[:name] = name
            the_options[:form] = :button
            text curobject.boolean_element(label, the_options)
          else
            the_options[:type] = 'radio'
            the_options[:value] = value
            the_options[:name] = name
            text curobject.boolean_element(label, the_options)
          end
        end
      end

      @scripts << <<-SCRIPT
	object["#{name}"] = $('input[name=#{name}]:checked', '##{@formName}').val()
      SCRIPT
    end

    def checkbox(name, checkbox_label, options = {})
      checkbox_name = options[:id] || @page.create_anchor('checkbox')
      options[:type] = 'checkbox'
      options[:name] = name
      options[:id] = checkbox_name
      text boolean_element(checkbox_label, options)
      @scripts << <<-SCRIPT
	object["#{name}"] = $('##{checkbox_name}').is(":checked");
      SCRIPT
    end

    def submit(anIcon, title = {}, options = {}, &block)
      options[:icon] = anIcon
      options[:title] = title
      options[:type] = 'submit'
      options[:data] = "get_#{@formName}_object()"
      options[:nosubmit] = true if block
      _button(options, &block)
    end

    def boolean_element(checkbox_label, options = {})
      @page.request_css 'css/plugins/iCheck/custom.css'
      @page.request_js 'js/plugins/iCheck/icheck.min.js'

      @page.write_script_once <<-SCRIPT
$(document).ready(function () {
    $('.i-checks').iCheck({
        checkboxClass: 'icheckbox_square-green',
        radioClass: 'iradio_square-green',
    });
});
      SCRIPT

      label_options = {}
      elem = Elements.new(@page, @anchors)
      elem.instance_eval do
        if options[:form] == :button
          options.delete(:form)
          label class: 'btn btn-primary btn-block btn-outline' do
            input options
            text checkbox_label.to_s
          end
        else
          div class: 'i-checks' do
            label label_options do
              input options do
                text " #{checkbox_label}"
              end
            end
          end
        end
      end

      elem.generate
    end
  end

  class Form
    def initialize(page, anchors, options = {}, &block)
      @formName = options[:id] || page.create_anchor('form')

      @form_element = FormElements.new(page, anchors, @formName, options)

      @form_element.instance_eval(&block)
    end

    def generate_script
      <<-SCRIPT
function get_#{@formName}_object()
{
	var object = {}
#{@form_element.scripts.join "\n"}
	return object;
}
      SCRIPT
    end

    def generate
      inner = @form_element.generate
      formName = @formName
      options = @form_element.options

      elem = Elements.new(@page, @anchors)
      elem.instance_eval do
        form_opts = {
          id: formName,
          role: 'form'
        }

        form_opts[:action] = options[:action] if options[:action]
        form_opts[:method] = options[:method] if options[:method]
        form_opts[:class] = options[:class] if options[:class]

        method_missing :form, form_opts do
          text inner
        end
      end

      elem.generate
    end
  end

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
