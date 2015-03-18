#
# Author:: Christine Draper (<christine_draper@thirdwaveinsights.com>)
# Copyright:: Copyright (c) 2014 ThirdWave Insights LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#

require 'rspec'
require 'rspec/mocks'
require File.expand_path('../../spec_helper', __FILE__)
require 'chef/knife/topo_update'

#Chef::Knife::TopoCreate.load_deps

describe Chef::Knife::TopoUpdate do
  before :each do
    Chef::Config[:node_name]  = "christine_test"
    @cmd = Chef::Knife::TopoUpdate.new([ 'knife', 'topo', 'update', 'topo1' ])

    # setup test data bags
    @topobag_name = 'testsys_test'
    @topo1_name = "topo1"
    @cmd.config[:data_bag] = @topobag_name

    @topo1_origdata = {
      "id" => "topo1",
      "name" => "topo1",
      "nodes" => [
      {
      "name" => "node1"
      },
      {
      "name" => "node2",
      "chef_environment" => "test",
      "normal" => { "anotherAttr" => "anotherValue" }
      }]
    }
    @topo1_newdata = {
      "id" => "topo1",
      "name" => "topo1",
      "nodes" => [
      {
      "name" => "node1",
      "run_list" => [ 'recipe[apt]', 'role[ypo::db]'  ]
      },
      {
      "name" => "node2",
      "chef_environment" => "dev",
      "normal" => { "anotherAttr" => "newValue" }
      }]
    }

    @orig_item = Chef::DataBagItem.new
    @orig_item.raw_data = @topo1_origdata
    @orig_item.data_bag(@topobag_name)
    @topo1_item = Chef::DataBagItem.new
    @topo1_item.raw_data = @topo1_newdata
    @topo1_item.data_bag(@topobag_name)
 
    @exception_404 =   Net::HTTPServerException.new("404 Not Found", Net::HTTPNotFound.new("1.1", "404", "Not Found"))

  end
  describe "#run" do
    it "loads topology and updates objects on server" do
      @cmd.name_args = [@topo1_name]

      bag = Chef::DataBag.new
      allow(Chef::DataBag).to receive(:new) { bag }

      expect(@cmd).to receive(:load_from_file).with(@topobag_name, @topo1_name).and_return(@topo1_item)
      expect(@cmd).to receive(:load_from_server).with(@topobag_name, @topo1_name).and_return(@orig_item)
      expect(@cmd).to receive(:upload_cookbooks)

      expect(@topo1_item).to receive(:save)

      expect(@cmd).to receive(:update_node).with(@topo1_newdata['nodes'][0])
      expect(@cmd).to receive(:update_node).with(@topo1_newdata['nodes'][1])

      @cmd.run

    end
  end

  describe "#update_node" do
    it "updates an existing node" do

      node = Chef::Node.new
      expect(Chef::Node).to receive(:load).and_return(node)
      expect(node).to receive(:save)
      expect(@cmd).to receive(:check_chef_env).with("dev")
      
      @cmd.update_node(@topo1_newdata['nodes'][1])

    end
  end
  
end

