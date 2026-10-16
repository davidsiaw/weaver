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
end
