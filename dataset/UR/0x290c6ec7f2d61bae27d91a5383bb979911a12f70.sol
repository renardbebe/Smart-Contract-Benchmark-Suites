 

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
  uint256 public totalSupply;
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
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

}
 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract NationalMoney is MintableToken{
	string public constant name = "National Money";
	string public constant symbol = "RUBC";
	uint public constant decimals = 2;

	
}

 
contract RubleCoinCrowdsale is Ownable {
  string public constant name = "National Money Contract";
  using SafeMath for uint256;

   
  MintableToken public token;

  uint256 public startTime = 0;
  uint256 public discountEndTime = 0;
  uint256 public endTime = 0;
  
  bool public isDiscount = true;
  bool public isRunning = false;
  
  address public fundAddress = 0;
  
  address public fundAddress2 = 0;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;
  
  string public contractStatus = "Not started";
  
  uint public tokensMinted = 0;
  
  uint public minimumSupply = 2500;  

  event TokenPurchase(address indexed purchaser, uint256 value, uint integer_value, uint256 amount, uint integer_amount, uint256 tokensMinted);


  function RubleCoinCrowdsale(uint256 _rate, address _fundAddress, address _fundAddress2) public {
    require(_rate > 0);
	require (_rate < 1000);

    token = createTokenContract();
    startTime = now;
	
    rate = _rate;
	fundAddress = _fundAddress;
	fundAddress2 = _fundAddress2;
	
	contractStatus = "Sale with discount";
	isDiscount = true;
	isRunning = true;
  }
  
  function setRate(uint _rate) public onlyOwner {
	  require (isRunning);

	  require (_rate > 0);
	  require (_rate <=1000);
	  rate = _rate;
  }
  
    function fullPriceStage() public onlyOwner {
	  require (isRunning);

	  isDiscount = false;
	  discountEndTime = now;
	  contractStatus = "Full price sale";
  }

    function finishCrowdsale() public onlyOwner {
	  require (isRunning);

	  isRunning = false;
	  endTime = now;
	  contractStatus = "Crowdsale is finished";
	  
  }

  function createTokenContract() internal returns (NationalMoney) {
    return new NationalMoney();
  }


   
  function () external payable {
	require(isRunning);
	
    buyTokens();
  }

   
  function buyTokens() public payable {
    require(validPurchase());
    require (isRunning);

    uint256 weiAmount = msg.value;

	uint minWeiAmount = rate.mul(10 ** 18).div(10000);  
	if (isDiscount) {
		minWeiAmount = minWeiAmount.mul(3).div(4);
	}
	
	uint tokens = weiAmount.mul(2500).div(minWeiAmount).mul(100);
	uint tokensToOwner = tokens.mul(11).div(10000);

    
    weiRaised = weiRaised.add(weiAmount);

    token.mint(msg.sender, tokens);
	token.mint(owner, tokensToOwner);
	
	tokensMinted = tokensMinted.add(tokens);
	tokensMinted = tokensMinted.add(tokensToOwner);
    TokenPurchase(msg.sender, weiAmount, weiAmount.div(10**14), tokens, tokens.div(10**2), tokensMinted);

    forwardFunds();
  }
  

  function forwardFunds() internal {
	uint toOwner = msg.value.div(100);
	uint toFund = msg.value.mul(98).div(100);
	
    owner.transfer(toOwner);
	fundAddress.transfer(toFund);
	fundAddress2.transfer(toOwner);
	
  }
  

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = startTime > 0;
	
	uint minAmount = (rate - 1).mul(10 ** 18).div(10000);  
	if (isDiscount) {
		minAmount = minAmount.mul(3).div(4);
	}
	bool validAmount = msg.value > minAmount;
		
    return withinPeriod && validAmount;
  }


}