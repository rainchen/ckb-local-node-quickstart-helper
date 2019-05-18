#!/usr/bin/env ruby

require "bundler/setup"
require "ckb"

privkey = File.read("wallet_prikey").strip
api_url = "http://127.0.0.1:8114"
api = CKB::API.new(host: api_url)
wallet = CKB::Wallet.from_hex(api, privkey)
cmd = ARGV[0]

allowed_cms = %w{get_block_hash get_tip_block_number get_block_assembler_config wallet_get_balance}
case cmd
when "get_block_hash"
  puts api.get_block_hash("0")
when "get_tip_block_number"
  puts api.get_tip_block_number
when "get_block_assembler_config"
  puts wallet.block_assembler_config
when "wallet_get_balance"
  puts "wallet.address: #{wallet.address}"
  puts "wallet.get_unspent_cells.length: #{wallet.get_unspent_cells.length}"

  balance = wallet.get_balance
  balance = balance.to_f / 10**8
  puts "wallet.get_balance: #{balance}"
else
  p "wallet_helper.rb [#{allowed_cms.join("|")}] is required"
  exit
end
