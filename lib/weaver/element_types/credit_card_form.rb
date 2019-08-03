# frozen_string_literal: true

module Weaver
  # Creates the credit card form
  class CreditCardForm < Elements
    def initialize(page, anchors, options = {}, &block)
      super(page, anchors)
      @options = options
      instance_eval(&block) if block
    end

    def apply_script(scripts)
      scripts << <<~SCRIPT
        object["#{card_input_name}_type"] = $('##{card_input_name}_type').val();
        object["#{card_input_name}_number"] = $('##{card_input_name}_number').val();
        object["#{card_input_name}_exp_month"] = $('##{card_input_name}_exp_month').val();
        object["#{card_input_name}_exp_year"] = $('##{card_input_name}_exp_year').val();
        object["#{card_input_name}_name"] = $('##{card_input_name}_name').val();
        object["#{card_input_name}_cvc"] = $('##{card_input_name}_cvc').val();
      SCRIPT
    end

    def generate
      setup!
      generate_html!
      super
    end

    private

    def background_for_issuer_bin(network, bin, image)
      style <<~STYLE
        ##{card_input_name}.skeuocard.product-#{network}.issuer-#{bin} .face.front {
          background-image: url(#{@page.root}images/#{image});
        }
      STYLE
      @page.on_page_load <<~SCRIPT
        var product = Skeuocard.prototype.CardProduct.firstMatchingShortname('#{network}');
        // register a new variation of the #{network} cards
        product.createVariation({
          pattern: /^#{bin}/,
          issuerShortname: "#{bin}"
        });
      SCRIPT
    end

    def card_input_name
      @card_input_name ||= @options[:id] || @page.create_anchor('credit_card')
    end

    def setup!
      @page.request_js 'js/plugins/skeuocard/javascripts/skeuocard.min.js'
      @page.request_js 'js/plugins/skeuocard/javascripts/vendor/cssua.min.js'
      @page.request_css 'js/plugins/skeuocard/styles/skeuocard.css'
      @page.request_css 'js/plugins/skeuocard/styles/skeuocard.reset.css'

      @page.on_page_load <<~SCRIPT
        var card = new Skeuocard($("##{card_input_name}"), {
          typeInputSelector: '[name="#{card_input_name}_type"]',
          numberInputSelector: '[name="#{card_input_name}_number"]',
          expMonthInputSelector: '[name="#{card_input_name}_exp_month"]',
          expYearInputSelector: '[name="#{card_input_name}_exp_year"]',
          nameInputSelector: '[name="#{card_input_name}_name"]',
          cvcInputSelector: '[name="#{card_input_name}_cvc"]'
        });

        var #{card_input_name}_content_width = $('##{card_input_name}').width();
        var #{card_input_name}_content_height = $('##{card_input_name}').height();
        function resize_#{card_input_name}() {
          var availableWidth = $('##{card_input_name}').parent().width();
          var contentWidth = #{card_input_name}_content_width;
          var contentHeight = #{card_input_name}_content_height;

          var scale = Math.min(availableWidth, contentWidth) / contentWidth;
          $("##{card_input_name}").css("transform","scale(" + scale + ")");
          $("##{card_input_name}").css("transform-origin","top left");
          $("##{card_input_name}").css("width", contentWidth * scale);
          $("##{card_input_name}").css("height", contentHeight * scale);
        }

        var resize_#{card_input_name}_id;
        $(window).resize( function() {
          clearTimeout(resize_#{card_input_name}_id);
          resize_#{card_input_name}_id = setTimeout(resize_#{card_input_name}, 500);
        });

        resize_#{card_input_name}();

      SCRIPT
    end

    def brands
      {
        visa: 'Visa',
        discover: 'Discover',
        mastercard: 'MasterCard',
        maestro: 'Maestro',
        jcb: 'JCB',
        unionpay: 'UnionPay',
        amex: 'American Express',
        dinersclubintl: 'Diners Club'
      }
    end

    def elements
      {
        number: 'Card Number',
        exp_month: 'Expiration Month',
        exp_year: 'Expiration Year',
        name: 'Cardholder Name',
        cvc: 'Card Validation Code'
      }
    end

    def generate_html!
      thebrands = brands
      theelements = elements
      input_name = card_input_name
      div id: input_name, class: 'credit-card-input no-js' do
        p 'Javascript unavailable', class: 'no-support-warning'

        label 'Card Type', for: :"#{input_name}_type"
        method_missing(:select,
                       name: :"#{input_name}_type",
                       id: "#{input_name}_type") do
          thebrands.each do |k, v|
            option v, value: k
          end
        end

        theelements.each do |k, v|
          label v, for: :"#{input_name}_#{k}"
          input type: :text, name: :"#{input_name}_#{k}",
                class: k.to_sym,
                id: "#{input_name}_#{k}"
        end
      end
    end
  end
end
