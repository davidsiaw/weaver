module Weaver
  class Action
    def initialize(page, anchors, &block)
      @page = page
      @anchors = anchors

      actionsArray = @anchors['action']

      @anchors['action'] = [] unless @anchors['action']

      actionsArray = @anchors['action']

      @actionName = "action#{actionsArray.length}"
      actionsArray << @actionName

      @code = ''

      instance_eval(&block)
    end

    def script(code)
      @code = code
    end

    def generate
      # puts @code
      <<-FUNCTION
function #{@actionName}(caller, data) {
	#{@code}
}
      FUNCTION
    end

    def name
      @actionName
    end
  end
end
