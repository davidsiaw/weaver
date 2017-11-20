
module Weaver

	class Elements

		def initialize(page, anchors, folder_level)
			@inner_content = []
			@anchors = anchors
			@page = page
			@folder_level = folder_level
		end

		def method_missing(name, *args, &block)
			tag = "<#{name} />"

			if args[0].is_a? String
				inner = args.shift
			end
			if block
				elem = Elements.new(@page, @anchors, @folder_level)
				elem.instance_eval(&block)
				inner = elem.generate
			end

			if !inner

				options = args[0] || []
				opts = options.map { |key,value| "#{key}=\"#{value}\"" }.join " "

				tag = "<#{name} #{opts} />"
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

		def doctype(value)
			@page.doctype = value
		end

		def para(*args, &block)
			method_missing(:p, *args, &block)
		end

		def text(theText)
			@inner_content << theText
		end

		def root
			@page.root
		end

		def generate
			@inner_content.join
		end
	end
end
