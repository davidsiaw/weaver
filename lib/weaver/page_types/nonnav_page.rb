# frozen_string_literal: true

require 'weaver/page_types/structured_page'
module Weaver
  # Page with no navigation bar
  class NonNavPage < StructuredPage
    def initialize(title, global_settings, options, &block)
      super
    end

    def generate(level)
      instance_eval &@block
      rows = @rows.map do |row|
        <<~ENDROW
              <div class="row #{row.extra_classes}">
          #{row.generate}
          	</div>
        ENDROW
      end.join

      @body_class = 'gray-bg'

      @content = <<~CONTENT
            <div id="wrapper">
        	        <div class="wrapper-content">
        	            <div class="container">
        #{rows}
        	            </div>
        			</div>
        		</div>
      CONTENT
      super
    end
  end
end

Weaver::Weave.register_page_type(:nonnav_page, Weaver::NonNavPage)
