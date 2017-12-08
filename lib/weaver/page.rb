module Weaver

	class Page
	
		attr_accessor :scripts, :onload_scripts, :doctype

		def initialize(global_settings, options, &block)
			@content = ""
			@global_settings = global_settings
			@options = options
			@anchors = {}
			@doctype = :html5
			@outer_self = options[:outer_self]

			@block = Proc.new &block
		end

		def create_anchor(name)

			if !@anchors[name]
				@anchors[name] = []
			end

			anchor_array = @anchors[name]

			anchor_name = "#{name}#{anchor_array.length}"
			anchor_array << anchor_name

			anchor_name
		end

		def root
			return @global_settings[:root]
		end

		def apply_doctype

			doctypes = {}
			doctypes[:html5] = '<!DOCTYPE html>'
			doctypes[:html401_strict] = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
			doctypes[:html401_transitional] = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
			doctypes[:html401_frameset] = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">'

			text = ""

			if doctypes.has_key?(@doctype)
				text = doctypes[@doctype]
			end

			@content = text + "\n" + @content
		end

		def generate(folder_level, options={})

			if @options[:cache_file] 
				expired = @options[:cache_expired]
				cache_exist = File.exist?("cache/cachedpage#{@options[:cache_file]}")

				if cache_exist and !expired
					puts "Weaver Hit cache for file: #{@options[:cache_file]}"
					puts "- expired: #{expired}"
					puts "- cache_exist: #{cache_exist}"
					return File.read("cache/cachedpage#{@options[:cache_file]}");
				end
				puts "Weaver Miss cache for file: #{@options[:cache_file]}"
				puts "- expired: #{expired}"
				puts "- cache_exist: #{cache_exist}"
			end

			elem = Elements.new(self, @anchors, folder_level, @outer_self)
			elem.instance_eval(&@block)

			@content = elem.generate

			apply_doctype

			result = @content

			if @options[:cache_file]
				FileUtils.mkdir_p "cache"
				File.write("cache/cachedpage#{@options[:cache_file]}", result);
			end

			return result

		end

	end
end