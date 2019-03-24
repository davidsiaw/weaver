module Weaver
  # Handles .weave file
  class Weave
    attr_accessor :pages
    def initialize(file, options = {})
      @pages = {}
      @file = file
      @global_settings = options

      @global_settings[:root] = @global_settings[:root] || '/'
      unless @global_settings[:root].end_with? '/'
        @global_settings[:root] = "#{@global_settings[:root]}/"
      end
      instance_eval(File.read(file), file)
    end

    def set_global(key, value)
      @global_settings[key] = value
    end

    def include(file)
      dir = File.dirname(@file)
      filename = File.join([dir, file])
      File.read(filename)
      load filename
    end

    class << self
      def register_page_type(symbol, class_constant)
        define_method symbol,
                      (proc do |path = '', title = nil, options = {}, &block|
                        if title.nil?
                          title = path
                          path = ''
                        end

                        p = class_constant.new(title, @global_settings, options,
                                               &block)
                        @pages[path] = p
                      end)
      end
    end
  end
end
