# frozen_string_literal: true

require 'spec_helper'

describe 'sonamp commands' do
  describe '#initialize' do
    it 'works' do
      Seriamp::Cmd.new(module_name: 'sonamp')
    end
  end
end
