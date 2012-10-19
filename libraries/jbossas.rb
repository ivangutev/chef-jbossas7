#
# Cookbook Name:: wharton-jboss-eap6
# Library:: jbossas
#
# Copyright 2012
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/search/query'

class Chef::Recipe::JBossEAP6
  class JBossAS
    def self.add_domain_slaves_mgmt_users(master)
      domain_slaves(master).each do |slave|
        add_hostname_mgmt_user(master,slave)
      end
    end

    def self.add_hostname_mgmt_user(node,node2)
      node["jboss-eap6"]["jbossas"]["mgmt-users"]["#{node2["jboss-eap6"]["jbossas"]["hostname"]}"] = hostname_mgmt_user(node2)
    end

    def self.create_hostname_mgmt_user(node)
      Chef::Log.info("Creating JBoss AS mgmt-user for domain authentication")
      require 'base64'
      require 'digest'
      require 'securerandom'
      password = SecureRandom.urlsafe_base64(16)
      new_hostname_mgmt_user = {
        "password" => Digest::MD5.hexdigest(password),
        "secret" => Base64.strict_encode64(password)
      }
      node["jboss-eap6"]["jbossas"]["mgmt-users"]["#{node["jboss-eap6"]["jbossas"]["hostname"]}"] = new_hostname_mgmt_user
      new_hostname_mgmt_user
    end

    def self.domain_master?(node)
      domain_mode?(node) && node["jboss-eap6"]["jbossas"]["domain"]["host_type"] == "master"
    end

    def self.domain_mode?(node)
      node["jboss-eap6"]["jbossas"]["mode"] == "domain"
    end
    
    def self.domain_slave?(node)
      domain_mode?(node) && node["jboss-eap6"]["jbossas"]["domain"]["host_type"] == "slave"
    end

    def self.domain_slaves(master)
      slave_nodes = []
      search(:node, "chef_environment:#{master.chef_environment} AND recipes:wharton-jboss-eap6") do |jboss_node|
        slave_nodes << jboss_node if domain_slave?(jboss_node) && in_same_domain?(master,jboss_node)
      end
      slave_nodes
    end

    def self.has_domain_master?(node)
      domain_slave?(node) && @node["jboss-eap6"]["jbossas"]["domain"]["master"]["address"]
    end

    def self.hostname_mgmt_user(node)
      node["jboss-eap6"]["jbossas"]["mgmt-users"]["#{node["jboss-eap6"]["jbossas"]["hostname"]}"]
    end

    def self.in_same_domain?(node,node2)
      node["jboss-eap6"]["jbossas"]["domain"]["name"] == node2["jboss-eap6"]["jbossas"]["domain"]["name"]
    end
  end
end
