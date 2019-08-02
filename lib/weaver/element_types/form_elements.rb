module Weaver
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

    def credit_card(options = {})
      request_js 'js/plugins/skeuocard/javascripts/skeuocard.min.js'
      request_js 'js/plugins/skeuocard/javascripts/vendor/cssua.min.js'
      request_css 'js/plugins/skeuocard/styles/skeuocard.css'
      request_css 'js/plugins/skeuocard/styles/skeuocard.reset.css'

      card_input_name = options[:id] || @page.create_anchor('credit_card')

      div id: card_input_name, class: 'credit-card-input no-js' do
        p 'Javascript unavailable', class: 'no-support-warning'

        brands = {
          visa:           'Visa',
          discover:       'Discover',
          mastercard:     'MasterCard',
          maestro:        'Maestro',
          jcb:            'JCB',
          unionpay:       'UnionPay',
          amex:           'American Express',
          dinersclubintl: 'Diners Club'
        }

        elements = {
          number: 'Card Number',
          exp_month: 'Expiration Month',
          exp_year: 'Expiration Year',
          name: 'Cardholder Name',
          cvc: 'Card Validation Code'
        }

        label 'Card Type', for: :"#{card_input_name}_type"
        method_missing(:select,
                       name: :"#{card_input_name}_type",
                       id: "#{card_input_name}_type") do
          brands.each do |k, v|
            option v, value: k
          end
        end

        elements.each do |k, v|
          label v, for: :"#{card_input_name}_#{k}"
          input type: :text, name: :"#{card_input_name}_#{k}",
                class: k.to_sym,
                id: "#{card_input_name}_#{k}"
        end
      end

      @page.on_page_load <<~SCRIPT
        var card = new Skeuocard($("##{card_input_name}"), {
          typeInputSelector: '[name="#{card_input_name}_type"]',
          numberInputSelector: '[name="#{card_input_name}_number"]',
          expMonthInputSelector: '[name="#{card_input_name}_exp_month"]',
          expYearInputSelector: '[name="#{card_input_name}_exp_year"]',
          nameInputSelector: '[name="#{card_input_name}_name"]',
          cvcInputSelector: '[name="#{card_input_name}_cvc"]'
        });
      SCRIPT

      @scripts << <<~SCRIPT
        object["#{card_input_name}_type"] = $('##{card_input_name}_type').val();
        object["#{card_input_name}_number"] = $('##{card_input_name}_number').val();
        object["#{card_input_name}_exp_month"] = $('##{card_input_name}_exp_month').val();
        object["#{card_input_name}_exp_year"] = $('##{card_input_name}_exp_year').val();
        object["#{card_input_name}_name"] = $('##{card_input_name}_name').val();
        object["#{card_input_name}_cvc"] = $('##{card_input_name}_cvc').val();
      SCRIPT
    end
  end
end
