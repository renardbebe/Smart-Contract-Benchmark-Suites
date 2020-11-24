 

pragma solidity ^0.4.20;


 
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}


 
contract MintableToken is StandardToken, Ownable, BurnableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  string public name = "VinCoin";
  string public symbol = "VNC";
  uint public decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 30000000 * (10 ** 18);
  
  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }	
	
  function MintableToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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

contract Crowdsale is Ownable {
using SafeMath for uint256;

 
MintableToken public token;

 
uint256 public startTime;
uint256 public endTime;

 
address public wallet;

 
uint256 public weiRaised;

 
uint256 public tokensSold;

 
uint256 constant public hardCap = 24000000 * (10**18);

 
event TokenPurchase(address indexed purchaser, address indexed beneficiary, 
uint256 value, uint256 amount);


function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet, MintableToken tokenContract) public {
require(_startTime >= now);
require(_endTime >= _startTime);
require(_wallet != 0x0);

startTime = _startTime;
endTime = _endTime;
wallet = _wallet;
token = tokenContract;
}

function setNewTokenOwner(address newOwner) public onlyOwner {
    token.transferOwnership(newOwner);
}

function createTokenOwner() internal returns (MintableToken) {
    return new MintableToken();
}

function () external payable {
    buyTokens(msg.sender);
  }

   
    function getRate() internal view returns (uint256) {
        if(now < (startTime + 5 weeks)) {
            return 7000;
        }

        if(now < (startTime + 9 weeks)) {
            return 6500;
        }

        if(now < (startTime + 13 weeks)) {
            return 6000;
        }
		
        if(now < (startTime + 15 weeks)) {
            return 5500;
        }
        return 5000;
    }
   
   
 function buyTokens(address beneficiary) public payable {
 require(beneficiary != 0x0);
 require(validPurchase());
 require(msg.value >= 0.05 ether);

 uint256 weiAmount = msg.value;
 uint256 updateWeiRaised = weiRaised.add(weiAmount);
 uint256 rate = getRate();
 uint256 tokens = weiAmount.mul(rate);
 require ( tokens <= token.balanceOf(this));
 
weiRaised = updateWeiRaised;

token.transfer(beneficiary, tokens);

tokensSold = tokensSold.add(tokens);

emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

forwardFunds();
}

 
function hasEnded() public view returns (bool) {
return now > endTime || tokensSold >= hardCap;
}

 
function tokenResend() public onlyOwner {
token.transfer(owner, token.balanceOf(this));
}

 
 
function forwardFunds() internal {
wallet.transfer(msg.value);
}

 
function validPurchase() internal view returns (bool) {
bool withinPeriod = now >= startTime && now <= endTime;
bool nonZeroPurchase = msg.value != 0;
bool hardCapNotReached = tokensSold < hardCap;
        return withinPeriod && nonZeroPurchase && hardCapNotReached;
}

}