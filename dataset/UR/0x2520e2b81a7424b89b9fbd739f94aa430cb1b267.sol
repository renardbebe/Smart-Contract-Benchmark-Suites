 

pragma solidity ^0.4.18;

 
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
library Math {
  function max(uint a, uint b) pure internal returns (uint) {
    if (a > b) return a;
    else return b;
  }
  function min(uint a, uint b) pure internal returns (uint) {
    if (a < b) return a;
    else return b;
  }
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
    require(_value <= balances[_from]);
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

 

contract BuronCoin is MintableToken {
    
    string public constant name = "Buron Coin";
    
    string public constant symbol = "BURC";
    
    uint32 public constant decimals = 4;
    
}

contract Crowdsale is Ownable {
    
	struct tier {
        uint cap;
        uint rate;
    }
	
    using SafeMath for uint;
	using Math for uint;
    
	BuronCoin public token = new BuronCoin();
	
    address multisig; 		
	uint restrictedAmount; 	
    address restricted;		
	uint price;				
	bool saleOn;		
	uint public sold;	
    
	tier[7] tiers; 
  
	function bytesToAddress(bytes source) internal pure returns(address) {
		uint result;
		uint mul = 1;
		for(uint i = 20; i > 0; i--) {
		  result += uint8(source[i-1])*mul;
		  mul = mul*256;
		}
		return address(result);
	}
  
    function Crowdsale(address _multisig, address _restricted) public {
        multisig = _multisig;
        restricted = _restricted;
		restrictedAmount=231000000000; 		
        price = 17700000000; 
		
		tiers[0]=tier(10000000000,50);
		tiers[1]=tier(30000000000,30);
		tiers[2]=tier(60000000000,25);
		tiers[3]=tier(110000000000,20);
		tiers[4]=tier(190000000000,15);
		tiers[5]=tier(320000000000,10);
		tiers[6]=tier(530000000000,5);
		
		sold=0;
		saleOn=true;
		
		token.mint(restricted, restrictedAmount);	
    }

    modifier saleIsOn() {
    	require(saleOn && sold<tiers[6].cap);
    	_;
    }
	
    function buyTokens(address to, address referer) public saleIsOn payable {
		require(msg.value>0);
	
		if (to==address(0x0))
			to=msg.sender;
	
        multisig.transfer(msg.value);	
		
		
        uint tokensBase = msg.value.div(price);
		
		uint tokensForBonus=tokensBase;
		uint tmpSold=sold;
		uint currentTier=0;
		uint bonusTokens=0;
		
		
		while(tiers[currentTier].cap<tmpSold)
			currentTier++;
		
		uint currentTierTokens=0;
		while((tokensForBonus>0) && (currentTier<7))
		{
			currentTierTokens=Math.min(tiers[currentTier].cap.sub(tmpSold), tokensForBonus); 		
			bonusTokens=bonusTokens.add(currentTierTokens.mul(tiers[currentTier].rate).div(100));   
			tmpSold=tmpSold.add(currentTierTokens);									   			
			
			tokensForBonus=tokensForBonus.sub(currentTierTokens);					   			
			currentTier++;
		}
		
		
		token.mint(to, tokensBase.add(bonusTokens));  						   			
		sold=sold.add(tokensBase);											   		
		
	
		if (referer != address(0x0))
		if (referer != msg.sender)	
		{
		  uint refererTokens = tokensBase.mul(3).div(100);	
		  token.mint(referer, refererTokens);				
		}		
		
		if (sold>=tiers[6].cap)													   	  
		{
			saleOn=false;
			token.finishMinting();
		}
    }
	
    function() external payable {
		
		
		address referer;
		if(msg.data.length == 20)
			referer = bytesToAddress(bytes(msg.data));
		else
			referer=address(0x0);
			
        buyTokens(address(0x0), referer);
    }
}