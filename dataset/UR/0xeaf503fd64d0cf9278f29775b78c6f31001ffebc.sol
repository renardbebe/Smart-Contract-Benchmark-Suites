 

pragma solidity ^0.4.13;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Drainable is Ownable {
	function withdrawToken(address tokenaddr) 
		onlyOwner 
	{
		ERC20 token = ERC20(tokenaddr);
		uint bal = token.balanceOf(address(this));
		token.transfer(msg.sender, bal);
	}

	function withdrawEther() 
		onlyOwner
	{
	    require(msg.sender.send(this.balance));
	}
}


contract ADXRegistry is Ownable, Drainable {
	string public name = "AdEx Registry";

	 
	 
	 
	 
	 
	 

	mapping (address => Account) public accounts;

	 
	enum ItemType { AdUnit, AdSlot, Campaign, Channel }

	 
	mapping (uint => uint) public counts;
	mapping (uint => mapping (uint => Item)) public items;

	 
	struct Account {		
		address addr;
		address wallet;

		bytes32 ipfs;  
		bytes32 name;  
		bytes32 meta;  

		bytes32 signature;  
		
		 
		mapping (uint => uint[]) items;
	}

	 
	struct Item {
		uint id;
		address owner;

		ItemType itemType;

		bytes32 ipfs;  
		bytes32 name;  
		bytes32 meta;  
	}

	modifier onlyRegistered() {
		var acc = accounts[msg.sender];
		require(acc.addr != 0);
		_;
	}

	 
	 
	function register(bytes32 _name, address _wallet, bytes32 _ipfs, bytes32 _sig, bytes32 _meta)
		external
	{
		require(_wallet != 0);
		 
		
		require(_name != 0);

		var isNew = accounts[msg.sender].addr == 0;

		var acc = accounts[msg.sender];

		if (!isNew) require(acc.signature == _sig);
		else acc.signature = _sig;

		acc.addr = msg.sender;
		acc.wallet = _wallet;
		acc.ipfs = _ipfs;
		acc.name = _name;
		acc.meta = _meta;

		if (isNew) LogAccountRegistered(acc.addr, acc.wallet, acc.ipfs, acc.name, acc.meta, acc.signature);
		else LogAccountModified(acc.addr, acc.wallet, acc.ipfs, acc.name, acc.meta, acc.signature);
	}

	 
	function registerItem(uint _type, uint _id, bytes32 _ipfs, bytes32 _name, bytes32 _meta)
		onlyRegistered
	{
		 
		var item = items[_type][_id];

		if (_id != 0)
			require(item.owner == msg.sender);
		else {
			 
			var newId = ++counts[_type];

			item = items[_type][newId];
			item.id = newId;
			item.itemType = ItemType(_type);
			item.owner = msg.sender;

			accounts[msg.sender].items[_type].push(item.id);
		}

		item.name = _name;
		item.meta = _meta;
		item.ipfs = _ipfs;

		if (_id == 0) LogItemRegistered(
			item.owner, uint(item.itemType), item.id, item.ipfs, item.name, item.meta
		);
		else LogItemModified(
			item.owner, uint(item.itemType), item.id, item.ipfs, item.name, item.meta
		);
	}

	 
	 
	 
	 

	 
	 
	 
	function isRegistered(address who)
		public 
		constant
		returns (bool)
	{
		var acc = accounts[who];
		return acc.addr != 0;
	}

	 
	 
	function getAccount(address _acc)
		constant
		public
		returns (address, bytes32, bytes32, bytes32)
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return (acc.wallet, acc.ipfs, acc.name, acc.meta);
	}

	function getAccountItems(address _acc, uint _type)
		constant
		public
		returns (uint[])
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return acc.items[_type];
	}

	function getItem(uint _type, uint _id) 
		constant
		public
		returns (address, bytes32, bytes32, bytes32)
	{
		var item = items[_type][_id];
		require(item.id != 0);
		return (item.owner, item.ipfs, item.name, item.meta);
	}

	function hasItem(uint _type, uint _id)
		constant
		public
		returns (bool)
	{
		var item = items[_type][_id];
		return item.id != 0;
	}

	 
	event LogAccountRegistered(address addr, address wallet, bytes32 ipfs, bytes32 accountName, bytes32 meta, bytes32 signature);
	event LogAccountModified(address addr, address wallet, bytes32 ipfs, bytes32 accountName, bytes32 meta, bytes32 signature);
	
	event LogItemRegistered(address owner, uint itemType, uint id, bytes32 ipfs, bytes32 itemName, bytes32 meta);
	event LogItemModified(address owner, uint itemType, uint id, bytes32 ipfs, bytes32 itemName, bytes32 meta);
}