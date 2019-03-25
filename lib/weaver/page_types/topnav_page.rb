require 'weaver/page_types/nav_page'
module Weaver
  class TopNavPage < NavPage
    def initialize(title, global_settings, options, &block)
      super
    end

    def generate(level)
      instance_eval &@block
      rows = @rows.map do |row|
        <<-ENDROW
	<div class="row #{row.extra_classes}" style="#{row.style}">
#{row.generate}
	</div>
        ENDROW
      end.join

      @body_class = 'top-navigation'
      @loading_bar_visible = true

      menu = @menu

      navigation = Elements.new(self, @anchors)
      navigation.instance_eval do
        menu.items.each do |item|
          next unless item[:options][:position] != :right

          li item[:options] do
            if item.key? :menu

              li class: 'dropdown' do
                a "aria-expanded": 'false',
                  role: 'button',
                  href: '#',
                  class: 'dropdown-toggle',
                  "data-toggle": 'dropdown' do

                  icon item[:icon]
                  text item[:name]
                  span class: 'caret' do
                    text ''
                  end
                end
                ul role: 'menu', class: 'dropdown-menu' do
                  item[:menu].items.each do |inneritem|
                    li inneritem[:options] do
                      if inneritem.key?(:menu)
                        raise 'Second level menu not supported'
                      else
                        hyperlink inneritem[:link], inneritem[:name]
                      end
                    end
                  end
                end
              end
            elsif
              hyperlink (item[:link]).to_s do
                span class: 'nav-label' do
                  icon item[:icon]
                  text item[:name]
                end
              end
            end
          end
        end
      end

      navigation_right = Elements.new(self, @anchors)
      navigation_right.instance_eval do
        menu.items.each do |item|
          next unless item[:options][:position] == :right

          li item[:options] do
            if item.key? :menu

              li class: 'dropdown' do
                a "aria-expanded": 'false',
                  role: 'button',
                  href: '#',
                  class: 'dropdown-toggle',
                  "data-toggle": 'dropdown' do

                  icon item[:icon]
                  text item[:name]
                  span class: 'caret' do
                    text ''
                  end
                end
                ul role: 'menu', class: 'dropdown-menu' do
                  item[:menu].items.each do |inneritem|
                    li inneritem[:options] do
                      if inneritem.key?(:menu)
                        raise 'Second level menu not supported'
                      else
                        hyperlink inneritem[:link], inneritem[:name]
                      end
                    end
                  end
                end
              end
            elsif
              hyperlink (item[:link]).to_s do
                span class: 'nav-label' do
                  icon item[:icon]
                  text item[:name]
                end
              end
            end
          end
        end
      end

      brand_content = ''

      if @brand
        brand_content = <<-BRAND_CONTENT

				    <div class="navbar-header">

						<a href="#{root}" class="navbar-brand">#{@brand}</a>
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
#{navigation_right.generate}
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
end

Weaver::Weave.register_page_type(:topnav_page, Weaver::TopNavPage)
