 

pragma solidity ^0.4.18;

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a * b;
  	assert(a == 0 || c / a == b);
  	return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
  	 
    uint256 c = a / b;
     
    return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  	assert(b <= a);
  	return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a + b;
  	assert(c >= a);
  	return c;
	}
}

 
contract Ownable {
	address public owner;
  address public AD = 0xf77F9D99dB407f8dA9131D15e385785923F65473;

	 
	function Ownable() public {
  	owner = msg.sender;
	}

	 

	modifier onlyAD(){
  	require(msg.sender == AD);
  	_;
	}

	 
	function transferOwnership(address newOwner) onlyAD public;

   
  function transferCommissionReceiver(address newTokenCommissionReceiver) onlyAD public;
}

 
contract ERC20Basic {
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract StandardToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

	mapping(address => uint256) balances;

   
  uint public commissionPercentForCreator = 1;

   
  uint256 public decimals = 18;

   
  uint256 public oneCoin = 10 ** decimals;

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
  	balances[_to] = balances[_to].add(_value);
  	Transfer(msg.sender, _to, _value);
  	return true;
	}

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
  	return balances[_owner];
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
  	require(_to != address(0));
  	balances[_to] = balances[_to].add(_value);
  	balances[_from] = balances[_from].sub(_value);
  	Transfer(_from, _to, _value);
  	return true;
	}

  function isTransferable(address _sender, address _receiver, uint256 value) public returns (bool) {
    uint256 actualValue = value;
     
     
    if (_sender == owner) {
      uint cm = (value * oneCoin * commissionPercentForCreator).div(100);
      actualValue = actualValue + cm;
    }

     
    if (balances[_sender] < actualValue) return false;
    
     
    if (balances[_receiver] + value < balances[_receiver]) return false;
    return true;
  }

	 
  function() public {
     
    revert();
  }
}

 
contract ATLToken is StandardToken {
   
	uint256 public totalSupply = 10 * (10**6) * oneCoin;

   
	address public tokenCommissionReceiver = 0xEa8867Ce34CC66318D4A055f43Cac6a88966C43f; 
	
	string public name = "ATON";
	string public symbol = "ATL";
	
	function ATLToken() public {
		balances[msg.sender] = totalSupply;
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool) {
    _value = _value.div(oneCoin);
    if (!isTransferable(msg.sender, _to, _value)) revert();
    if (_to == owner || msg.sender == owner) {
       
      uint cm = (_value * oneCoin * commissionPercentForCreator).div(100);
       
      super.transferFrom(owner, tokenCommissionReceiver, cm);
    }
  	return super.transfer(_to, _value * oneCoin);
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    _value = _value.div(oneCoin);
    if (!isTransferable(_from, _to, _value)) revert();
  	if (_from == owner || _to == owner) {
       
      uint cm = (_value  * oneCoin * commissionPercentForCreator).div(100);
       
      super.transferFrom(owner, tokenCommissionReceiver, cm);
    }
    return super.transferFrom(_from, _to, _value * oneCoin);
	}

   
  function transferOwnership(address newOwner) onlyAD public {
    if (newOwner != address(0)) {
      uint256 totalTokenOfOwner = balances[owner];
       
      super.transferFrom(owner, newOwner, totalTokenOfOwner);
      owner = newOwner;
    }
  }

   
  function transferCommissionReceiver(address newTokenCommissionReceiver) onlyAD public {
    if (newTokenCommissionReceiver != address(0)) {
      tokenCommissionReceiver = newTokenCommissionReceiver;
    }
  }

	function emergencyERC20Drain( ERC20Basic oddToken, uint256 amount ) public {
  	oddToken.transfer(owner, amount);
	}
}