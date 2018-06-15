require 'spec_helper'
describe 'vsts_agent' do
  context 'with default values for all parameters' do
    it { should contain_class('vsts_agent') }
  end
end
