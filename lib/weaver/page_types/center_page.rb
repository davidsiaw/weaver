# frozen_string_literal: true

module Weaver
  # Page where all content is centered
  class CenterPage < Page
    def initialize(title, global_settings, options, &block)
      super
    end

    def generate(level)
      elem = Elements.new(self, {})
      elem.instance_eval(&@block)

      @body_class = 'gray-bg'
      @content = <<-CONTENT
	<div class="middle-box text-center animated fadeInDown">
		<div>
			#{elem.generate}
		</div>
	</div>
      CONTENT
      super
    end
  end
end

Weaver::Weave.register_page_type(:center_page, Weaver::CenterPage)
