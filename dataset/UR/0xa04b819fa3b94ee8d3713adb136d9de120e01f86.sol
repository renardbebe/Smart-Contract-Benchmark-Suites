 

 

pragma solidity ^0.4.21;

contract CreativesStorage {

	uint public constant ROLE_BIDDER = 1;
	uint public constant ROLE_ADVERTISER = 2;
	uint public constant ROLE_PUBLISHER = 3;
	uint public constant ROLE_VOTER = 4;

	address public CONTRACT_MEMBERS;
	address public CONTRACT_TOKEN;
	address public VOTER_POOL;

	uint public INITIAL_THRESHOLD = 50;
	uint public THRESHOLD_STEP = 10;
	uint public BLOCK_DEPOSIT = 10000000000000000;  
	uint public MAJORITY = 666;  

	mapping (address => address) creativeOwner;
	mapping (address => address[]) creatives;
	mapping (address => uint) threshold;
	mapping (address => bool) blocked;
}

 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

pragma solidity ^0.4.21;



contract CreativesRegistry is CreativesStorage, Ownable {

	address private CONTRACT_ADDRESS;

	function setContractAddress(address newContractAddress) public onlyOwner {
		CONTRACT_ADDRESS = newContractAddress;
	}

	function () payable public {
		address target = CONTRACT_ADDRESS;
		assembly {
			 
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize)
			 
			let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)
			 
			let size := returndatasize
			returndatacopy(ptr, 0, size)
			 
			switch result
			case 0 { revert(ptr, size) }
			case 1 { return(ptr, size) }
		}
	}
}