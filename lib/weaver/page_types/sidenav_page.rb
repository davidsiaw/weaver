# frozen_string_literal: true

require 'weaver/page_types/nav_page'
module Weaver
  class SideNavPage < NavPage
    def initialize(title, global_settings, options, &block)
      super
      @body_class = "#{@body_class} fixed-sidebar"
    end

    def keep_icons_when_hidden
      arr = @body_class.to_s.split(' ')
      @body_class = arr.reject { |x| x == 'fixed-sidebar' }.join(' ')
    end

    def generate(level)
      instance_eval &@block
      rows = @rows.map do |row|
        <<~ENDROW
          	<div class="row #{row.extra_classes}" style="#{row.style}">
          #{row.generate}
          	</div>
        ENDROW
      end.join

      menu = @menu

      navigation = Elements.new(self, @anchors)
      navigation.instance_eval do
        menu.items.each do |item|
          li item[:options] do
            if item.key? :menu

              hyperlink '/#' do
                icon item[:icon]
                span class: 'nav-label' do
                  text item[:name]
                end
                span class: 'fa arrow' do
                  text ''
                end
              end

              open = ''
              open = 'collapse in' if item[:options][:open]
              ul class: "nav nav-second-level #{open}" do
                item[:menu].items.each do |inneritem|
                  li inneritem[:options] do
                    if inneritem.key?(:menu)
                      raise 'Second level menu not supported'
                    else
                      hyperlink (inneritem[:link]).to_s do
                        icon inneritem[:icon]
                        span class: 'nav-label' do
                          text inneritem[:name]
                        end
                      end
                    end
                  end
                end
              end
            elsif
              hyperlink (item[:link]).to_s do
                icon item[:icon]
                span class: 'nav-label' do
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

	                <li>
	                    <a href="#{root}"><i class="fa fa-home"></i> <span class="nav-label">#{@brand}</span> <span class="label label-primary pull-right"></span></a>
	                </li>
        BRAND_CONTENT
      end

      @loading_bar_visible = true
      @content =
        <<~ENDBODY
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
end

Weaver::Weave.register_page_type(:sidenav_page, Weaver::SideNavPage)
