 

pragma solidity ^0.4.23;

 
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

contract NeolandsToken is StandardToken {
    
    string public constant name    = "Neolands Token";
    string public constant symbol  = "XNL";
    uint8 public constant decimals = 0;
    
    uint256 public constant INITIAL_SUPPLY = 100000000;
    
    constructor () public {
        totalSupply_         = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract DistributionTokens is Ownable {
    
    NeolandsToken private f_token;
    uint256       private f_price_one_token;
    bool          private f_trade_is_open;
    
    event PaymentOfTokens(address payer, uint256 number_token, uint256 value);
    
    constructor () public {
        f_token           = NeolandsToken(0x0);
        f_price_one_token = 0;
        f_trade_is_open   = true;
    }
    
    function () public payable {
        revert();
    }
    
    function setAddressToken(address _address_token) public onlyOwner {
        require(_address_token != 0x0);
        
        f_token = NeolandsToken(_address_token);
    }
    
    function getAddressToken() public view returns (address) {
        return address(f_token);
    }
    
    function setPriceOneToken(uint256 _price_token, uint256 _price_ether) public onlyOwner {
        require(_price_token > 0);
        require(_price_ether > 0);
        
        f_price_one_token = (_price_token * 1 ether) / _price_ether;
    }

    function getPriceOneToken() public view returns (uint256) {
        return f_price_one_token;
    }
    
    function setTradeIsOpen(bool _is_open) public onlyOwner {
        f_trade_is_open = _is_open;
    }
    
    function getTradeIsOpen() public view returns (bool) {
        return f_trade_is_open;
    }
    
    function buyToken(uint256 _number_token) public payable returns (bool) {
		require(f_trade_is_open);
		require(_number_token >  0);
		require(_number_token <= _number_token * f_price_one_token);
		require(msg.value >  0);
		require(msg.value == _number_token * f_price_one_token);
		
		f_token.transfer(msg.sender, _number_token);
		
		emit PaymentOfTokens(msg.sender, _number_token, msg.value);
		
		return true;
	}
	
	function getBalanceToken() public view returns (uint256) {
		return f_token.balanceOf(address(this));
    }
    
    function getBalance() public view returns (uint256) {
		return address(this).balance;
    }
    
    function outputMoney(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(address(this).balance >= _value);

        _from.transfer(_value);

        return true;
    }
}