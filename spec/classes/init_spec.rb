require 'spec_helper'
describe 'azure_pipelines' do
  context 'with default values for all parameters' do
    it { should contain_class('azure_pipelines') }
  end
end
