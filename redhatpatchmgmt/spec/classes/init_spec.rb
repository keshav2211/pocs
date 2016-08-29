require 'spec_helper'
describe 'redhatpatchmgmt' do

  context 'with defaults for all parameters' do
    it { should contain_class('redhatpatchmgmt') }
  end
end
