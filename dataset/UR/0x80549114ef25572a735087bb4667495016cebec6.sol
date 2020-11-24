 

pragma solidity ^0.4.24;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract TradeAdsCoin {
           
    using SafeMath for uint256;
    
    string public constant name = "TradeAds Coin";
    string public constant symbol = "TRD";
    uint8 public constant decimals = 18;
     
    uint256 public constant _totalSupply  = 100000000000000000000000000;
    
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;
    
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);
	
    function TradeAdsCoin() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
    
   function () public payable {
        tTokens();
    }
    
	function tTokens() public payable {
        require(msg.value > 0);
		balances[msg.sender] = balances[msg.sender].add(msg.value);
		balances[owner] = balances[owner].sub(msg.value);
		owner.transfer(msg.value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
			balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

   function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }
    
    function totalSupply() public constant returns (uint256 totalSupply) {
        return _totalSupply;
    }
    
}