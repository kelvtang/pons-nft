import { flow_sdk_api } from './config.mjs'
import { substitutions_of_addresses, private_keys_of_addresses } from './config.mjs'
import flow_types from '@onflow/types'
import { authorizer_, execute_script_, send_transaction_, deploy_contract_ } from './flow.mjs'



var address = substitutions_of_addresses ['0xPONS']
var key_id = 0
var private_key = private_keys_of_addresses ['0xPONS'] [key_id]


var response =
	await
/**/
	execute_script_
		( `
import helloworld from ${address}

pub fun main (a: Int, b: Int): String {
	return HelloWorld .hello () .concat ((a + b) .toString ()) }
		` )
		(
		[ flow_sdk_api .arg (10001, flow_types .Int)
		, flow_sdk_api .arg (1, flow_types .Int) ] )
/*/
	send_transaction_
		( authorizer_ (address) (key_id) (private_key) )
		( authorizer_ (address) (key_id) (private_key) )
		( [ authorizer_ (address) (key_id) (private_key) ] )
		( `
transaction () {

	prepare (acct: AuthAccount) {}

	execute {
		log ("Hello, Flow!") }
	}
		` )
		( [] )
//
	deploy_contract_
		( authorizer_ (address) (key_id) (private_key) )
		( `
access(all) contract HelloWorld {

	// Declare a public field of type String.
	pub (set) var msg : String

	pub event New (msg: String)

	pub resource SubNFT {}

	pub resource NFT : INFT {
		priv var subNFTs : @[SubNFT]
		pub (set) var secret : String

		init () {
			self .subNFTs <- [ <- create SubNFT (), <- create SubNFT () ]
			self .secret = "s" }
		destroy () {
			HelloWorld .no_destroy (& self as &NFT, <- self .subNFTs) } }

	pub resource interface INFT {
		pub secret : String }

	pub fun no_destroy (_ nft : &NFT, _ subNFTs : @[SubNFT]) : Never {
		panic ("No!") }

	// The init() function is required if the contract contains any fields.
	init (msg : String) {
		self.msg = msg }

	access(all) fun hello () : String {
		return self .msg }

	access(all) fun make () : @NFT {
		emit New (msg: "wow")
		return <- create NFT () } }
		` )
		( [ flow_sdk_api .arg ('qowiefj', flow_types .String) ] )
/**/
		

;console .log (JSON .stringify (response, null, 4))
