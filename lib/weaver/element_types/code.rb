# frozen_string_literal: true

module Weaver
  class Code
    def initialize(page, anchors, lang, options={})
      @page = page
      @anchors = anchors
      @content = ''
      @options = options

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
end
