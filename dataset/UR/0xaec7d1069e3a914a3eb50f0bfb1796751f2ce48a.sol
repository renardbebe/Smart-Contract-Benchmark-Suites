 

pragma solidity ^0.4.24;

 

 
contract Migratable {
   
  event Migrated(string contractName, string migrationId);

   
  mapping (string => mapping (string => bool)) internal migrated;

   
  string constant private INITIALIZED_ID = "initialized";


   
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

   
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

   
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

   
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

   
  function validateMigrationIsPending(string contractName, string migrationId) private {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract DetailedERC20 is Migratable, ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function initialize(string _name, string _symbol, uint8 _decimals) public isInitializer("DetailedERC20", "1.9.0") {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract MintableToken is Migratable, Ownable, StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function initialize(address _sender) isInitializer("MintableToken", "1.9.0")  public {
    Ownable.initialize(_sender);
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract DetailedPremintedToken is Migratable, DetailedERC20, StandardToken {
  function initialize(
    address _sender,
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _initialBalance
  )
    isInitializer("DetailedPremintedToken", "1.9.0")
    public
  {
    DetailedERC20.initialize(_name, _symbol, _decimals);

    _premint(_sender, _initialBalance);
  }

  function _premint(address _to, uint256 _value) internal {
    totalSupply_ += _value;
    balances[_to] += _value;
    emit Transfer(0, _to, _value);
  }
}

 

 
contract S4FE is Ownable, DetailedPremintedToken {
	uint256 public INITIAL_SUPPLY;

	bool public transferLocked;
	mapping (address => bool) public transferWhitelist;

	 
	constructor() public {

	}

	 
	function initializeS4FE(address _owner) isInitializer('S4FE', '0') public {
		INITIAL_SUPPLY = 1000000000 * (10 ** uint256(18));

		Ownable.initialize(_owner);
		DetailedPremintedToken.initialize(_owner, "S4FE", "S4F", 18, INITIAL_SUPPLY);
	}

	 
	function () public {
		revert();
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(msg.sender == owner || transferLocked == false || transferWhitelist[msg.sender] == true);

		bool result = super.transfer(_to , _value);
		return result;
	}

	 
	function setTransferLocked(bool _transferLocked) onlyOwner public returns (bool) {
		transferLocked = _transferLocked;
		return transferLocked;
	}

	 
	function setTransferWhitelist(address _address, bool _transferLocked) onlyOwner public returns (bool) {
		transferWhitelist[_address] = _transferLocked;
		return _transferLocked;
	}

	 
	function whitelist(address[] _addresses) onlyOwner public {
		for(uint i = 0; i < _addresses.length ; i ++) {
			transferWhitelist[_addresses[i]] = true;
		}
	}

	 
	function blacklist(address[] _addresses) onlyOwner public {
		for(uint i = 0; i < _addresses.length ; i ++) {
			transferWhitelist[_addresses[i]] = false;
		}
	}
}