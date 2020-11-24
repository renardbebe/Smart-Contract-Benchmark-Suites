 

 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
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

 

pragma solidity ^0.4.21;


 
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

 

pragma solidity ^0.4.18;



contract Lockup is Ownable{
	using SafeMath for uint256;

	uint256 public lockupTime;
	mapping(address => bool) public lockup_list;

	event UpdateLockup(address indexed owner, uint256 lockup_date);

	event UpdateLockupList(address indexed owner, address indexed user_address, bool flag);

	constructor(uint256 _lockupTime ) public
	{
		lockupTime = _lockupTime;

		emit UpdateLockup(msg.sender, lockupTime);
	}

	 
	function getLockup()public view returns (uint256){
		return lockupTime;
	}

	 
	function isLockup() public view returns(bool){
		return (now < lockupTime);
	}

	 
	function updateLockup(uint256 _newLockUpTime) onlyOwner public returns(bool){

		lockupTime = _newLockUpTime;

		emit UpdateLockup(msg.sender, lockupTime);
		
		return true;
	}

	 
	function inLockupList(address _add)public view returns(bool){
		return lockup_list[_add];
	}

	 
	function updateLockupList(address _add, bool _flag)onlyOwner public returns(bool){
		lockup_list[_add] = _flag;

		emit UpdateLockupList(msg.sender, _add, _flag);

		return true;
	}

}

 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.21;




 
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

 

pragma solidity ^0.4.21;



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.21;




 
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

 

pragma solidity ^0.4.18;


contract ERC223Token is StandardToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}

 

pragma solidity ^0.4.18;

contract ERC223ContractInterface{
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}

 

pragma solidity ^0.4.18;






contract CIMCoin is ERC223Token, Ownable{
	using SafeMath for uint256;

	string public constant name = 'CIMTOKEN';
	string public constant symbol = 'CIM';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 25000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_SALE_SUPPLY = 11250000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_UNSALE_SUPPLY = INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

	address public owner_wallet;
	address public unsale_owner_wallet;

	Lockup public lockup;

	 
	constructor(address _sale_owner_wallet, address _unsale_owner_wallet, Lockup _lockup) public {
		lockup = _lockup;
		owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;
		totalSupply_ = INITIAL_SUPPLY;

		balances[owner_wallet] = INITIAL_SALE_SUPPLY;
		emit Transfer(0x0, owner_wallet, INITIAL_SALE_SUPPLY);

		balances[unsale_owner_wallet] = INITIAL_UNSALE_SUPPLY;
		emit Transfer(0x0, unsale_owner_wallet, INITIAL_UNSALE_SUPPLY);
	}

	 
	function sendTokens(address _to, uint256 _value) onlyOwner public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[owner_wallet]);

		bytes memory empty;
		
		 
		balances[owner_wallet] = balances[owner_wallet].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	     
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(owner_wallet, _to, _value);
		return true;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bytes memory empty;

		bool inLockupList = lockup.inLockupList(msg.sender);

		 
		if(inLockupList){
			require( lockup.isLockup() == false );
		}

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	     
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, empty);
	    }

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(_value > 0);

		bool inLockupList = lockup.inLockupList(msg.sender);

		 
		if(inLockupList){
			require( lockup.isLockup() == false );
		}

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

	    bool isUserAddress = false;
	     
	    assembly {
	      isUserAddress := iszero(extcodesize(_to))
	    }

	    if (isUserAddress == false) {
	      ERC223ContractInterface receiver = ERC223ContractInterface(_to);
	      receiver.tokenFallback(msg.sender, _value, _data);
	    }

	    emit Transfer(msg.sender, _to, _value);
		emit TransferERC223(msg.sender, _to, _value, _data);
		return true;
	}	
}