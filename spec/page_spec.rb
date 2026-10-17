# frozen_string_literal: true

require 'spec_helper'

describe Weaver::Page do
  let(:html) do
    page = Weaver::EmptyPage.new('Title', { root: '/' }, {}) { p 'hi' }
    page.generate(0)
  end

  it 'emits a viewport meta tag that browsers recognise' do
    expect(html).to include('<meta name="viewport" content="width=device-width, initial-scale=1.0" />')
  end

  it 'does not emit the non-standard contents attribute' do
    expect(html).not_to include('contents=')
  end

  describe 'MathJax' do
    def page_html(&block)
      Weaver::EmptyPage.new('Title', { root: '/' }, {}, &block).generate(0)
    end

    it 'is left out of pages without math' do
      html = page_html { p 'no maths here' }
      expect(html).not_to include('MathJax')
    end

    it 'is loaded on pages that use math' do
      html = page_html { math 'x^2 + y^2' }
      expect(html).to include('$$$MATH$$$x^2 + y^2$$$ENDMATH$$$')
      expect(html).to include('<script type="text/x-mathjax-config">')
      expect(html).to include('js/MathJax/MathJax.js?config=AM_HTMLorMML-full')
    end

    it 'is loaded when math sits in a nested element' do
      html = page_html { div { span { math '\\frac{1}{2}' } } }
      expect(html).to include('js/MathJax/MathJax.js')
    end
  end
end
