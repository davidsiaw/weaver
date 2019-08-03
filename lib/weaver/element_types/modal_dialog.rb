# frozen_string_literal: true

module Weaver
  # Modal dialog feature
  class ModalDialog
    def initialize(page, anchors, id, &block)
      @page = page
      @anchors = anchors
      @id = id || @page.create_anchor('modal')

      @header_content = Elements.new(@page, @anchors)
      @body_content = Elements.new(@page, @anchors)
      @footer_content = Elements.new(@page, @anchors)

      instance_eval(&block) if block
    end

    attr_reader :id

    def header(&block)
      @header_content.instance_eval(&block)
    end

    def body(&block)
      @body_content.instance_eval(&block)
    end

    def footer(&block)
      @footer_content.instance_eval(&block)
    end

    def generate
      elem = Elements.new(@page, @anchors)

      id = @id
      header_content = @header_content
      body_content = @body_content
      footer_content = @footer_content

      elem.instance_eval do
        div class: 'modal fade', id: id, tabindex: -1, role: 'dialog' do
          div class: 'modal-dialog', role: 'document' do
            div class: 'modal-content' do
              div class: 'modal-header' do
                button '&times;', type: 'button', class: 'close', "data-dismiss": 'modal', "aria-label": 'Close'
                text header_content.generate
              end
              div class: 'modal-body' do
                text body_content.generate
              end
              div class: 'modal-footer' do
                text footer_content.generate
              end
            end
          end
        end
      end

      elem.generate
    end
  end

  # add modal dialog to elements
  class Elements
    def modal(id = nil, &block)
      mm = ModalDialog.new(@page, @anchors, id, &block)
      @inner_content << mm.generate
    end
  end
end
