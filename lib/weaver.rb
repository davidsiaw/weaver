require "weaver/version"

require 'fileutils'

module Weaver


	class Page

		def initialize(title)
			@title = title
			@rows = []
		end

		def row
		end

		def generate

			row_gen = @rows.map { |row| row.generate }.join

			<<-SKELETON
<!DOCTYPE html>
<html>

<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>#{@title}</title>

    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="font-awesome/css/font-awesome.css" rel="stylesheet">

    <link href="css/animate.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">

</head>

<body class="gray-bg">

#{row_gen}

    <!-- Mainly scripts -->
    <script src="js/jquery-2.1.1.js"></script>
    <script src="js/bootstrap.min.js"></script>

</body>

</html>

			SKELETON
		end
	end

	class Site
		def initialize(folder)
			@pages = {}
			@folder = folder
		end

		def page(path, title, &block)
			p = Page.new(title)
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

				File.write(@folder + "/" + path + "/index.html", page.generate)
			end
		end
	end

	def Weaver.site(folder, &block)
		site = Site.new(folder)
		site.instance_eval(&block)

		site.generate
	end

end
