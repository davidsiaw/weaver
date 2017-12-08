require "weaver/page"

module Weaver

	class Weave
		attr_accessor :pages
		def initialize(file, options={})
			@pages = {}
			@file = file
			@global_settings = options

			@global_settings[:root] = @global_settings[:root] || "/"
			@global_settings[:root] = "#{@global_settings[:root]}/" unless @global_settings[:root].end_with? "/"
			instance_eval(File.read(file), file)
		end

		def page(path="", options={}, &block)
			options[:outer_self] = self
			p = Page.new(@global_settings, options, &block)
			@pages[path] = p
		end
	end
end
