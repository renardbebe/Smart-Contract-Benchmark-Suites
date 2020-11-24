 

pragma solidity ^0.4.18;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool);

   
  function balanceOf(address _owner) public view returns (uint256);

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }                           
}   contract kn0Token is StandardToken {
  string public name;  
  string public symbol;  
  uint8 public decimals;  
  string public constant version = "k1.05";
  uint256 public aDropedThisWeek;
  uint256 lastWeek;
  uint256 decimate;
  uint256 weekly_limit;
  uint256 air_drop;
  mapping(address => uint256) airdroped;
  address control;
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  uint256 public Market;  
  uint256 public AvailableTokenPool;  
  
   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == control);
    _;
  }
  modifier onlyControl() {
    require(msg.sender == control);
    _;
  }
  
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
	OwnershipTransferred(owner, newOwner);
	if(owner != newOwner) {
	  uint256 t = balances[owner] / 10;
	  balances[newOwner] += balances[owner] - t;
	  balances[owner] = t;
    }	
    owner = newOwner;
	update();
  }  
  function transferControl(address newControl) public onlyControl {
    require(newControl != address(0) && newControl != address(this));
	control = newControl;
  }
   
  function kn0Token(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {  
	control = msg.sender;
	owner = address(this);
	OwnershipTransferred(address(0), owner);
	symbol = _tokenSymbol;   
	name = _tokenName;                                   
    decimals = _decimalUnits;                            
	totalSupply_ = _initialAmount;
	balances[owner] = totalSupply_;
	Transfer(0x0, owner, totalSupply_);
	decimate = (10 ** uint256(decimals));
	weekly_limit = 100000 * decimate;
	air_drop = 1018 * decimate;
	if(((totalSupply_  *2)/decimate) > 1 ether) coef = 1;
	else coef = 1 ether / ((totalSupply_  *2)/decimate);
	update();
  }  
  function transfererc20(address tokenAddress, address _to, uint256 _value) external onlyControl returns (bool) {
    require(_to != address(0));
	return ERC20(tokenAddress).transfer(_to, _value);
  }  
  function destroy() onlyControl external {
    require(owner != address(this)); selfdestruct(owner);
  }  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
	update();
    return true;
  }  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
	 
    if(balances[msg.sender] == 0) { 
      uint256 qty = availableAirdrop(msg.sender);
	  if(qty > 0) {   
	    balances[owner] -= qty;
	    balances[msg.sender] += qty;
		Transfer(owner, _to, _value);
		update();
		airdroped[msg.sender] = qty;
		aDropedThisWeek += qty;
		 
		return true;
	  }	
	  revert();  
	}
  
     
    if(balances[msg.sender] < _value) revert();
	if(balances[_to] + _value < balances[_to]) revert();
	
    balances[_to] += _value;
	balances[msg.sender] -= _value;
    Transfer(msg.sender, _to, _value);
	update();
	return true;
  }  
  function balanceOf(address who) public view returns (uint256 balance) {
    balance = balances[who];
	if(balance == 0) 
	  return availableAirdrop(who);
	
    return balance;
  }  
     
  function availableAirdrop(address who) internal constant returns (uint256) {
    if(balances[owner] == 0) return 0;
	if(airdroped[who] > 0) return 0;  
	
	if (thisweek() > lastWeek || aDropedThisWeek < weekly_limit) {
	  if(balances[owner] > air_drop) return air_drop;
	  else return balances[owner];
	}
	return 0;
  }  function thisweek() internal view returns (uint256) {
    return now / 1 weeks;
  }  function getAirDropedToday() public view returns (uint256) {
    if (thisweek() > lastWeek) return 0;
	else return aDropedThisWeek;
  }  
  function transferBalance(address upContract) external onlyControl {
    require(upContract != address(0) && upContract.send(this.balance));
  }
  function () payable public {
    uint256 qty = calc(msg.value);
	if(qty > 0) {
	  balances[msg.sender] += qty;
	  balances[owner] -= qty;
	  Transfer(owner, msg.sender, qty);
	  update();
	} else revert();
  } 
  uint256 coef;
  function update() internal {
    if(balances[owner] != AvailableTokenPool) {
	  Market = (((totalSupply_ - balances[owner]) ** 2) / coef);
	  AvailableTokenPool = balances[owner];
	}
  }
  function calc(uint256 value) public view returns (uint256) {
    if(balances[owner] == 0 || value < 15000000000000000) return 0;
	uint256 x = (coef * (value + Market)); 
	uint256 qty = x;
	uint256 z = (x + 1) / 2;
    while (z < qty) {
        qty = z;
        z = (x / z + z) / 2;
    }   
	uint256 worth = (qty - (totalSupply_ - balances[owner])) + (air_drop * (1 + (value / 12500000000000000)));
	if(worth > balances[owner]) return balances[owner];
	return worth;
  }  
}