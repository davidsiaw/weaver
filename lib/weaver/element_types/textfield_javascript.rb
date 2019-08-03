# frozen_string_literal: true

module Weaver
  class TextfieldJavascript
    def initialize(id)
      @id = id
    end

    def onchange(script)
      @change_script = script
    end

    def validate(script)
      @validate_script = script
    end

    def generate(&block)
      if block
        instance_eval(&block)
        <<~SCRIPT

          if (!document.validators)
          {
          	document.validators = {};
          }

          document.validators["##{@id}"] = function()
          {
          	var valid = function(data) {
          		#{@validate_script};
          		return true;
          	}($("##{@id}").val());

          	var object = $("##{@id}");
          	#{@change_script};

          	if (valid)
          	{
          		object.removeClass("required");
          		object.removeClass("error");
          		object.removeAttr("aria-invalid");
          	}
          	else
          	{
          		object.addClass("required");
          		object.addClass("error");
          		object.attr("aria-required", "true");
          		object.attr("aria-invalid", "true");
          	}
          }

          $("##{@id}").keyup(function() { document.validators["##{@id}"](); })
          $("##{@id}").blur(function() { document.validators["##{@id}"](); })
          $("##{@id}").focusout(function() { document.validators["##{@id}"](); })

        SCRIPT
      end
    end
  end
end
