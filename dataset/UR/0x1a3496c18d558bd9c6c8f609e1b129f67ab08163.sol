 

 

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



contract GroupLockup is Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) public lockup_list;  
	mapping(uint256 => bool) public lockup_list_flag;
	address[] public user_list;  

	event UpdateLockupList(address indexed owner, address indexed user_address, uint256 lockup_date);
	event UpdateLockupTime(address indexed owner, uint256 indexed old_lockup_date, uint256 new_lockup_date);
	event LockupTimeList(uint256 indexed lockup_date, bool active);

	 
	function getLockupTime(address user_address)public view returns (uint256){
		return lockup_list[user_address];
	}

	 
	function isLockup(uint256 lockup_date) public view returns(bool){
		return (now < lockup_date);
	}

	 
	function inLockupList(address user_address)public view returns(bool){
		if(lockup_list[user_address] == 0){
			return false;
		}
		return true;
	}

	 
	function updateLockupList(address user_address, uint256 lockup_date)onlyOwner public returns(bool){
		if(lockup_date == 0){
			delete lockup_list[user_address];

			for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
				if(user_list[user_list_index] == user_address){
					delete user_list[user_list_index];
					break;
				}
			}
		}else{
			bool user_is_exist = inLockupList(user_address);

			if(!user_is_exist){
				user_list.push(user_address);
			}

			lockup_list[user_address] = lockup_date;

			 
			if(!lockup_list_flag[lockup_date]){
				lockup_list_flag[lockup_date] = true;
				emit LockupTimeList(lockup_date, true);
			}
			
		}
		emit UpdateLockupList(msg.sender, user_address, lockup_date);

		return true;
	}

	 
	function updateLockupTime(uint256 old_lockup_date, uint256 new_lockup_date)onlyOwner public returns(bool){
		require(old_lockup_date != 0);
		require(new_lockup_date != 0);
		require(new_lockup_date != old_lockup_date);

		address user_address;
		uint256 user_lockup_time;

		 
		for(uint256 user_list_index = 0; user_list_index < user_list.length; user_list_index++) {
			if(user_list[user_list_index] != 0){
				user_address = user_list[user_list_index];
				user_lockup_time = getLockupTime(user_address);
				if(user_lockup_time == old_lockup_date){
					lockup_list[user_address] = new_lockup_date;
					emit UpdateLockupList(msg.sender, user_address, new_lockup_date);
				}
			}
		}

		 
		if(lockup_list_flag[old_lockup_date]){
			lockup_list_flag[old_lockup_date] = false;
			emit LockupTimeList(old_lockup_date, false);
		}

		 
		if(!lockup_list_flag[new_lockup_date]){
			lockup_list_flag[new_lockup_date] = true;
			emit LockupTimeList(new_lockup_date, true);
		}

		emit UpdateLockupTime(msg.sender, old_lockup_date, new_lockup_date);
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

 

pragma solidity ^0.4.21;




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
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

 

pragma solidity ^0.4.18;


contract ERC223Token is MintableToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}

 

pragma solidity ^0.4.18;

contract ERC223ContractInterface{
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}

 

pragma solidity ^0.4.18;





contract DEAPCoin is ERC223Token{
	using SafeMath for uint256;

	string public constant name = 'DEAPCOIN';
	string public constant symbol = 'DEP';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 30000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_SALE_SUPPLY = 12000000000 * (10 ** uint256(decimals));
	uint256 public constant INITIAL_UNSALE_SUPPLY = INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

	address public owner_wallet;
	address public unsale_owner_wallet;

	GroupLockup public group_lockup;

	event BatchTransferFail(address indexed from, address indexed to, uint256 value, string msg);

	 
	constructor(address _sale_owner_wallet, address _unsale_owner_wallet, GroupLockup _group_lockup) public {
		group_lockup = _group_lockup;
		owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;

		mint(owner_wallet, INITIAL_SALE_SUPPLY);
		mint(unsale_owner_wallet, INITIAL_UNSALE_SUPPLY);

		finishMinting();
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

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		 
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
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

		bool inLockupList = group_lockup.inLockupList(msg.sender);

		 
		if(inLockupList){
			uint256 lockupTime = group_lockup.getLockupTime(msg.sender);
			require( group_lockup.isLockup(lockupTime) == false );
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


	 
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner public returns (bool) {

		address to;
		uint256 value;
		bool isUserAddress;
		bool canTransfer;
		string memory transferFailMsg;

		for(uint i = 0; i < _users.length; i++) {

			to = _users[i];
			value = _values[i];
			isUserAddress = false;
			canTransfer = false;
			transferFailMsg = "";

			 
		     
		    assembly {
		      isUserAddress := iszero(extcodesize(to))
		    }

		     
			if(!isUserAddress){
				transferFailMsg = "try to send token to contract";
			}else if(value <= 0){
				transferFailMsg = "try to send wrong token amount";
			}else if(to == address(0)){
				transferFailMsg = "try to send token to empty address";
			}else if(value > balances[_from]){
				transferFailMsg = "token amount is larger than giver holding";
			}else{
				canTransfer = true;
			}

			if(canTransfer){
			    balances[_from] = balances[_from].sub(value);
			    balances[to] = balances[to].add(value);
			    emit Transfer(_from, to, value);
			}else{
				emit BatchTransferFail(_from, to, value, transferFailMsg);
			}

        }

        return true;
	}
}