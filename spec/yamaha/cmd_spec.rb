# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Cmd do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  let(:args) { [] }
  let(:stdin_c) { '' }
  let(:stdin) { StringIO.new(stdin_c) }
  let (:cmd) { described_class.new(args, stdin) }

  describe '!status' do
    it 'works' do
      cmd.run
    end
  end
end
