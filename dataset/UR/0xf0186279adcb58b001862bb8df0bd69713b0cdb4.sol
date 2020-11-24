 

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



contract ETH888CrowdsaleS1 {

	using SafeMath for uint256;
	
	 
	MintableToken public token;
	
	 
	address public wallet;
	
	 
	uint256 public rate = 1250;
	
	 
	uint public startTimestamp;
	uint public endTimestamp;
	
	 
	uint256 public weiRaised;
	
	 
	uint256 public cap;
	
	  
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	function ETH888CrowdsaleS1(address _wallet) {
		
		require(_wallet != 0x0);
		
		 
		startTimestamp = 1502409600;
		
		 
		endTimestamp = 1506815999;
		
		token = createTokenContract();
		
		 
		cap = 8000 ether;
		
		wallet = _wallet;
	}
		
	 
	function () payable {
	    buyTokens(msg.sender);
	}
	
	 
	function buyTokens(address beneficiary) payable {
		require(beneficiary != 0x0);
		require(validPurchase());

		uint256 weiAmount = msg.value;

		 
		uint256 tokens = weiAmount.mul(rate);

		 
		weiRaised = weiRaised.add(weiAmount);

		token.mint(beneficiary, tokens);
		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	 
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}	
	
	 
	function validPurchase() internal constant returns (bool) {
		bool withinCap = weiRaised.add(msg.value) <= cap;
		
		uint current = now;
		bool withinPeriod = current >= startTimestamp && current <= endTimestamp;
		bool nonZeroPurchase = msg.value != 0;
		
		return withinPeriod && nonZeroPurchase && withinCap && msg.value >= 1000 szabo;
	}

	 
	function hasEnded() public constant returns (bool) {
		bool capReached = weiRaised >= cap;
		
		return now > endTimestamp || capReached;
	}
	
	 
	function createTokenContract() internal returns (MintableToken) {
		return new VanilCoin();
	}
	
}