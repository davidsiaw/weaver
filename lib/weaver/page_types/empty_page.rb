# frozen_string_literal: true

module Weaver
  # Empty page
  class EmptyPage < Page
    def initialize(title, global_settings, options, &block)
      super
    end

    def generate(level)
      elem = Elements.new(self, {})
      elem.instance_eval(&@block)
      @body_class = 'gray-bg'
      @content = <<~CONTENT
                <div id="wrapper">
        	        <div class="wrapper-content">
        	            <div class="container">
        #{elem.generate}
        	            </div>
        			</div>
        		</div>
      CONTENT
      super
    end
  end
end

Weaver::Weave.register_page_type(:empty_page, Weaver::EmptyPage)
