 

pragma solidity ^0.4.18;


  
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
 
contract SilentNotary is Ownable {
	uint public price;
	ERC20 public token;

	struct Entry {
		uint blockNumber;
		uint timestamp;
	}

	mapping (bytes32 => Entry) public entryStorage;

	event EntryAdded(bytes32 hash, uint blockNumber, uint timestamp);
	event EntryExistAlready(bytes32 hash, uint timestamp);

	 
	function () public {
	  	 
	  	revert();
	}

	 
	 
	function setRegistrationPrice(uint _price) public onlyOwner {
		price = _price;
	}

	 
	 
		function setTokenAddress(address _token) public onlyOwner {
		    token = ERC20(_token);
	}

	 
	 
	function makeRegistration(bytes32 hash) onlyOwner public {
			makeRegistrationInternal(hash);
	}

	 
	 
	function makePayableRegistration(bytes32 hash) public {
		address sender = msg.sender;
	    uint allowed = token.allowance(sender, owner);
	    assert(allowed >= price);

	    if(!token.transferFrom(sender, owner, price))
          revert();
			makeRegistrationInternal(hash);
	}

	 
	 
	function makeRegistrationInternal(bytes32 hash) internal {
			uint timestamp = now;
	     
	    if (exist(hash)) {
	        EntryExistAlready(hash, timestamp);
	        revert();
	    }
	     
	    entryStorage[hash] = Entry(block.number, timestamp);
	     
	    EntryAdded(hash, block.number, timestamp);
	}

	 
	 
	 
	function exist(bytes32 hash) internal constant returns (bool) {
	    return entryStorage[hash].blockNumber != 0;
	}
}