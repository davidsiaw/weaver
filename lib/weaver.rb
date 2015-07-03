require "weaver/version"

require 'fileutils'

module Weaver


	class Elements

		def initialize
			@inner_content = []
		end

		def method_missing(name, *args, &block)
			tag = "<#{name} />"

			if args[0].is_a? String
				inner = args.shift
			end
			if block
				elem = Elements.new
				elem.instance_eval(&block)
				inner = elem.generate
			end

			if !inner
				tag = "<#{name} />"
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

        def ibox(title=nil, &block)
    		div class: "ibox float-e-margins" do
    			if title
	    			div class: "ibox-title" do
	    				h5 title
	    			end
    			end
    			div class: "ibox-content", &block
    		end
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



		def generate
			@inner_content.join
		end

	end

	class Page

		def initialize(title)
			@title = title
			@content = ""
			@body_class = nil
		end

		def generate(back_folders, options={})

			mod = "../" * back_folders

			style = <<-ENDSTYLE
	<link href="#{mod}css/style.css" rel="stylesheet">
			ENDSTYLE

			if options[:style] == :empty
				style = ""
			end

			body_tag = "<body>"

			body_tag = "<body class='#{@body_class}'>" if @body_class

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
    #{style}
    <link href="#{mod}css/animate.css" rel="stylesheet">
    
</head>

#{body_tag}

#{@content}

    <!-- Mainly scripts -->
    <script src="#{mod}js/jquery-2.1.1.js"></script>
    <script src="#{mod}js/jquery-ui-1.10.4.min.js"></script>
    <script src="#{mod}js/bootstrap.min.js"></script>
    <script src="#{mod}js/plugins/metisMenu/jquery.metisMenu.js"></script>
    <script src="#{mod}js/plugins/slimscroll/jquery.slimscroll.min.js"></script>

    <!-- Custom and plugin javascript -->
    <script src="#{mod}js/inspinia.js"></script>
    

</body>

</html>

			SKELETON
		end
	end

	class Row
		attr_accessor :extra_classes

		def initialize(options)
			@columns = []
			@free = 12
			@extra_classes = options[:class] || ""
		end


		def col(occupies, options={}, &block)
			raise "Not enough columns!" if @free < occupies
			elem = Elements.new
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

	class GridPage < Page
		def initialize(title)
			@rows = []
			@has_sidebar = false
			@has_topnav = false
			super
		end

		def sidebar_nav(&block)
			@has_sidebar = true
		end

		def top_nav(&block)
			@has_topnav = true
		end

		def header(&block)
			row(class: "wrapper border-bottom white-bg page-heading", &block)
		end

		def row(options={}, &block)
			r = Row.new(options)
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

			topnav = ""

			if @has_topnav
				topnav = <<-ENDTOPNAV
			<nav class="navbar navbar-inverse">
			  <div class="container-fluid">
			    <div class="navbar-header">
			      <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
			        <span class="sr-only">Toggle navigation</span>
			        <span class="icon-bar"></span>
			        <span class="icon-bar"></span>
			        <span class="icon-bar"></span>
			      </button>
			      <a class="navbar-brand" href="#">Brand</a>
    			</div>
			  </div>
			</nav>
				ENDTOPNAV
			end

			if @has_sidebar
				@content =
					<<-ENDBODY
	<div id="wrapper">

		<nav class="navbar-default navbar-static-side" role="navigation">
			<div class="sidebar-collapse">
				<ul class="nav" id="side-menu">
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

		            </ul>
		        </nav>
	        </div>
#{topnav}
#{rows}
		</div>
	</div>
					ENDBODY
			else
				@body_class = "gray-bg"
				@content =
					<<-ENDBODY
	<div class="container">
#{topnav}
#{rows}
	</div>
					ENDBODY
			end

			super
		end
	end

	class CenterPage < Page
		def initialize(title, element)
			@element = element
			super(title)
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

	class Site
		def initialize(folder)
			@pages = {}
			@folder = folder
		end

		def center_page(path, title, &block)
			elem = Elements.new
			elem.instance_eval(&block) if block

			p = CenterPage.new(title, elem)

			@pages[path] = p
		end

		def grid_page(path, title, &block)
			p = GridPage.new(title)
			p.instance_eval(&block) if block

			@pages[path] = p
		end

		def generate
			FileUtils::mkdir_p @folder
			FileUtils.cp_r(Gem.datadir("weaver") + '/css', @folder + '/css')
			FileUtils.cp_r(Gem.datadir("weaver") + '/fonts', @folder + '/fonts')
			FileUtils.cp_r(Gem.datadir("weaver") + '/js', @folder + '/js')
			FileUtils.cp_r(Gem.datadir("weaver") + '/font-awesome', @folder + '/font-awesome')

			@pages.each do |path, page|
				FileUtils::mkdir_p @folder + "/" + path

				level = path.split(/\//, 0).length

				File.write(@folder + "/" + path + "/index.html", page.generate(level) )
			end
		end
	end

	def Weaver.site(folder, &block)
		site = Site.new(folder)
		site.instance_eval(&block)

		site.generate
	end

end
