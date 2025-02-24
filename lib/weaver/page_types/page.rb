# frozen_string_literal: true

module Weaver
  # Base page class
  class Page
    attr_accessor :scripts, :onload_scripts

    def initialize(title, global_settings, options, &block)
      @title = title
      @content = ''
      @body_class = nil
      @anchors = {}
      @global_settings = global_settings
      @options = options
      @scripts = []
      @top_content = ''

      @scripts_once = {}
      @onload_scripts = []

      @requested_scripts = {}
      @requested_css = {}

      @background = Elements.new(self, @anchors)

      @block = Proc.new &block
    end

    def create_anchor(name)
      @anchors[name] = [] unless @anchors[name]

      anchor_array = @anchors[name]

      anchor_name = "#{name}#{anchor_array.length}"
      anchor_array << anchor_name

      anchor_name
    end

    def root
      @global_settings[:root]
    end

    def request_js(path)
      @requested_scripts[path] = true
    end

    def request_css(path)
      @requested_css[path] = true
    end

    def on_page_load(script)
      @onload_scripts << script
    end

    def write_script_once(script)
      @scripts_once[script] = true
    end

    def background(&block)
      @background.instance_eval(&block)
    end

    def top(&block)
      elem = Elements.new(self, @anchors)
      elem.instance_eval(&block)

      @top_content = elem.generate
    end

    def generate(back_folders, options = {})
      if @options[:cache_file]
        expired = @options[:cache_expired]
        cache_exist = File.exist?("cache/cachedpage#{@options[:cache_file]}")

        if cache_exist && !expired
          puts "Weaver Hit cache for file: #{@options[:cache_file]}"
          puts "- expired: #{expired}"
          puts "- cache_exist: #{cache_exist}"
          return File.read("cache/cachedpage#{@options[:cache_file]}")
        end
        puts "Weaver Miss cache for file: #{@options[:cache_file]}"
        puts "- expired: #{expired}"
        puts "- cache_exist: #{cache_exist}"
      end

      scripts = @scripts.join("\n")

      mod = '../' * back_folders

      style = <<-ENDSTYLE
	<link href="#{mod}css/style.css" rel="stylesheet">
      ENDSTYLE
      if !@options[:theme].nil?
        style = <<-ENDSTYLE
  <link href="#{mod}css/style-#{@options[:theme]}.css" rel="stylesheet">
      ENDSTYLE
      end

      style = '' if options[:style] == :empty

      body_tag = '<body>'

      body_tag = "<body class='#{@body_class}'>" if @body_class

      loading_bar = ''
      if @loading_bar_visible
        loading_bar = "<script src='#{mod}js/plugins/pace/pace.min.js'></script>"
      end

      extra_scripts = @requested_scripts.map do |key, _value|
        <<-SCRIPT_DECL
    <script src="#{mod}#{key}"></script>
        SCRIPT_DECL
      end.join "\n"

      extra_css = @requested_css.map do |key, _value|
        <<-STYLESHEET_DECL
    <link href="#{mod}#{key}" rel="stylesheet">
        STYLESHEET_DECL
      end.join "\n"

      extra_one_time_scripts = @scripts_once.map do |key, _value|
        <<~SCRIPT_DECL
          #{key}
        SCRIPT_DECL
      end.join "\n"

      onload_scripts = @onload_scripts.map do |value|
        <<~SCRIPT_DECL
          #{value}
        SCRIPT_DECL
      end.join "\n"

      extra_stuff = ''

      if @global_settings[:mixpanel_token]
        extra_stuff += '<!-- start Mixpanel --><script type="text/javascript">(function(e,a){if(!a.__SV){var b=window;try{var c,l,i,j=b.location,g=j.hash;c=function(a,b){return(l=a.match(RegExp(b+"=([^&]*)")))?l[1]:null};g&&c(g,"state")&&(i=JSON.parse(decodeURIComponent(c(g,"state"))),"mpeditor"===i.action&&(b.sessionStorage.setItem("_mpcehash",g),history.replaceState(i.desiredHash||"",e.title,j.pathname+j.search)))}catch(m){}var k,h;window.mixpanel=a;a._i=[];a.init=function(b,c,f){function e(b,a){var c=a.split(".");2==c.length&&(b=b[c[0]],a=c[1]);b[a]=function(){b.push([a].concat(Array.prototype.slice.call(arguments,
0)))}}var d=a;"undefined"!==typeof f?d=a[f]=[]:f="mixpanel";d.people=d.people||[];d.toString=function(b){var a="mixpanel";"mixpanel"!==f&&(a+="."+f);b||(a+=" (stub)");return a};d.people.toString=function(){return d.toString(1)+".people (stub)"};k="disable time_event track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config reset opt_in_tracking opt_out_tracking has_opted_in_tracking has_opted_out_tracking clear_opt_in_out_tracking people.set people.set_once people.unset people.increment people.append people.union people.track_charge people.clear_charges people.delete_user".split(" ");
for(h=0;h<k.length;h++)e(d,k[h]);a._i.push([b,c,f])};a.__SV=1.2;b=e.createElement("script");b.type="text/javascript";b.async=!0;b.src="undefined"!==typeof MIXPANEL_CUSTOM_LIB_URL?MIXPANEL_CUSTOM_LIB_URL:"file:"===e.location.protocol&&"//cdn4.mxpnl.com/libs/mixpanel-2-latest.min.js".match(/^\/\//)?"https://cdn4.mxpnl.com/libs/mixpanel-2-latest.min.js":"//cdn4.mxpnl.com/libs/mixpanel-2-latest.min.js";c=e.getElementsByTagName("script")[0];c.parentNode.insertBefore(b,c)}})(document,window.mixpanel||[]);
mixpanel.init("' + @global_settings[:mixpanel_token] + '");</script><!-- end Mixpanel -->'
      end

      if @global_settings[:google_tracking_code]
        extra_stuff += <<~GOOGLE
          <!-- Global site tag (gtag.js) - Google Analytics -->
          <script async src="https://www.googletagmanager.com/gtag/js?id=#{@global_settings[:google_tracking_code]}"></script>
          <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());

            gtag('config', '#{@global_settings[:google_tracking_code]}');
          </script>
        GOOGLE
      end

      result = <<~SKELETON
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

        #{extra_css}

        #{extra_stuff}

        </head>

        #{body_tag}

        <div id="background" style="z-index: -999; position:absolute; left:0px; right:0px; width:100%; height:100%">
        #{@background.generate}
        </div>

        <div id="content" style="z-index: 0">
        #{@top_content}
        #{@content}
        </div>

            <!-- Mainly scripts -->
            <script src="#{mod}js/jquery-3.1.1.min.js"></script>
            <script src="#{mod}js/jquery-ui-1.10.4.min.js"></script>
            <script src="#{mod}js/bootstrap.min.js"></script>
            <script src="#{mod}js/plugins/metisMenu/jquery.metisMenu.js"></script>
            <script src="#{mod}js/plugins/slimscroll/jquery.slimscroll.min.js"></script>
        	<script type="text/x-mathjax-config">
        		MathJax.Hub.Config({
        			asciimath2jax: {
        				delimiters: [['$$$MATH$$$','$$$ENDMATH$$$']]
        			}
        		});
        	</script>
            <script src="#{mod}js/MathJax/MathJax.js?config=AM_HTMLorMML-full" async></script>

        #{extra_scripts}


            <!-- Custom and plugin javascript -->
            <script src="#{mod}js/weaver.js"></script>
            #{loading_bar}

            <script>
        #{scripts}
        #{extra_one_time_scripts}

        $( document ).ready(function() {

        #{onload_scripts}

        });
            </script>



        </body>

        </html>

      SKELETON

      if @options[:cache_file]
        FileUtils.mkdir_p 'cache'
        File.write("cache/cachedpage#{@options[:cache_file]}", result)
      end

      result
    end
  end
end
