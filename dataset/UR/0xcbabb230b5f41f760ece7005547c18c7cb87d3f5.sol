 

pragma solidity ^0.4.11;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract VanilCoin is MintableToken {
  	
	string public name = "Vanil";
  	string public symbol = "VAN";
  	uint256 public decimals = 18;
  
  	 
  	uint public releaseTime = 1507420800;
  
	modifier canTransfer(address _sender, uint256 _value) {
		require(_value <= transferableTokens(_sender, now));
	   	_;
	}
	
	function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
		return super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}
	
	function transferableTokens(address holder, uint time) constant public returns (uint256) {
		
		uint256 result = 0;
				
		if(time > releaseTime){
			result = balanceOf(holder);
		}
		
		return result;
	}
	
}

contract ETH888CrowdsaleS2 {

	using SafeMath for uint256;
	
	 
	address public vanilAddress;
	VanilCoin public vanilCoin;
	
	 
	address public wallet;
	
	 
	uint256 public rate = 400;
	
	 
	uint public startTimestamp;
	uint public endTimestamp;
	
	 
	uint256 public weiRaised;
	
	mapping(uint8 => uint64) public rates;
	 
	uint public timeTier1 = 1525478400;
	 
	uint public timeTier2 = 1526083200;
	 
	uint public timeTier3 = 1526688000;

	  
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function ETH888CrowdsaleS2(address _wallet, address _vanilAddress) {
		
		require(_wallet != 0x0 && _vanilAddress != 0x0);
		
		 
		startTimestamp = 1524873600;
		
		 
		endTimestamp = 1527465600;
		
		rates[0] = 400;
		rates[1] = 300;
		rates[2] = 200;
		rates[3] = 100;

		wallet = _wallet;
		vanilAddress = _vanilAddress;
		vanilCoin = VanilCoin(vanilAddress);
	}
		
	 
	function () payable {
	    buyTokens(msg.sender);
	}
	
	 
	function buyTokens(address beneficiary) payable {
		require(beneficiary != 0x0 && validPurchase() && validAmount());

		if(now < timeTier1)
			rate = rates[0];
		else if(now < timeTier2)
			rate = rates[1];
		else if(now < timeTier3)
			rate = rates[2];
		else
			rate = rates[3];

		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		 
		weiRaised = weiRaised.add(weiAmount);
		vanilCoin.transfer(beneficiary, tokens);

		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	function totalSupply() public constant returns (uint)
	{
		return vanilCoin.totalSupply();
	}

	function vanilAddress() public constant returns (address)
	{
		return vanilAddress;
	}

	 
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}	
	
	function validAmount() internal constant returns (bool)
	{
		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		return (vanilCoin.balanceOf(this) >= tokens);
	}

	 
	function validPurchase() internal constant returns (bool) {
		
		uint current = now;
		bool withinPeriod = current >= startTimestamp && current <= endTimestamp;
		bool nonZeroPurchase = msg.value != 0;
		
		return withinPeriod && nonZeroPurchase && msg.value >= 1000 szabo;
	}

	 
	function hasEnded() public constant returns (bool) {
		
		return now > endTimestamp;
	}
	
}