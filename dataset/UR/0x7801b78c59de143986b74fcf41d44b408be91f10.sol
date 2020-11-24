 

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

pragma solidity ^0.4.18;

 
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

contract Haltable is Ownable {
	bool public halted;

	modifier stopInEmergency {
		require(!halted);
		_;
	}

	modifier onlyInEmergency {
		require(halted);
		_;
	}

	 
	function halt() public onlyOwner {
		halted = true;
	}

	 
	function unhalt() public onlyOwner onlyInEmergency {
		halted = false;
	}
}


pragma solidity ^0.4.18;

 
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

pragma solidity ^0.4.18;

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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



 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}


 
contract MeritToken is CappedToken {
	event NewCap(uint256 value);

	string public constant name = "Merit Token";  
	string public constant symbol = "MERIT";  
	uint8 public constant decimals = 18;  
	bool public tokensReleased;

	function MeritToken(uint256 _cap) public CappedToken(_cap * 10**uint256(decimals)) { }

    modifier released {
        require(mintingFinished);
        _;
    }
    
    modifier notReleased {
        require(!mintingFinished);
        _;
    }
    
     
     
     
    function transfer(address _to, uint256 _value) public released returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public released returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public released returns (bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public released returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public released returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    
     
	 
    function balanceOf(address _owner) public view released returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

     
     
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }
    
     
     
    function revoke(address _owner) public onlyOwner notReleased returns (uint256 balance) {
         
        balance = balances[_owner];
        balances[_owner] = 0;
        totalSupply_ = totalSupply_.sub(balance);
    }
  }


contract MeritICO is Ownable, Haltable {
	using SafeMath for uint256;

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
		
	 
	MeritToken public token;
	address public reserveVault;
	address public restrictedVault;
	 

	enum Stage 		{ None, Closed, PrivateSale, PreSale, Round1, Round2, Round3, Round4, Allocating, Done }
	Stage public currentStage;

	uint256 public tokenCap;
	uint256 public icoCap;
	uint256 public marketingCap;
	uint256 public teamCap;
	uint256 public reserveCap;

     
	uint public exchangeRate;
	uint public bonusRate;
	uint256 public currentSaleCap;

	uint256 public weiRaised;
	uint256 public baseTokensAllocated;
	uint256 public bonusTokensAllocated;
	bool public saleAllocated;
	
	struct Contribution {
	    uint256 base;
	    uint256 bonus;
	}
	 
	mapping (address => Contribution) contributionBalance;

	 
	mapping (address => bool) blacklist;

	modifier saleActive {
		require(currentStage > Stage.Closed && currentStage < Stage.Allocating);
		_;
	}

	modifier saleAllocatable {
		require(currentStage > Stage.Closed && currentStage <= Stage.Allocating);
		_;
	}
	
	modifier saleNotDone {
		require(currentStage != Stage.Done);
		_;
	}

	modifier saleAllocating {
		require (currentStage == Stage.Allocating);
		_;
	}
	
	modifier saleClosed {
	    require (currentStage == Stage.Closed);
	    _;
	}
	
	modifier saleDone {
	    require (currentStage == Stage.Done);
	    _;
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function MeritICO() public {
		 
		currentStage = Stage.Closed;
	}

	function updateToken(address _token) external onlyOwner saleNotDone {
		require(_token != address(0));
		
	    token = MeritToken(_token); 
	    
	    tokenCap = token.cap();
	    
	    require(MeritToken(_token).owner() == address(this));
	}

	function updateCaps(uint256 _icoPercent, uint256 _marketingPercent, uint256 _teamPercent, uint256 _reservePercent) external onlyOwner saleNotDone {
		require(_icoPercent + _marketingPercent + _teamPercent + _reservePercent == 100);

		uint256 max = tokenCap;
        
		marketingCap = max.mul(_marketingPercent).div(100);
		icoCap = max.mul(_icoPercent).div(100);
		teamCap = max.mul(_teamPercent).div(100);
		reserveCap = max.mul(_reservePercent).div(100);

		require (marketingCap + icoCap + teamCap + reserveCap == max);
	}

	function setStage(Stage _stage) public onlyOwner saleNotDone {
		 
		require (_stage != Stage.Done || saleAllocated == true);
		currentStage = _stage;
	}

	function startAllocation() public onlyOwner saleActive {
		require (!saleAllocated);
		currentStage = Stage.Allocating;
	}
    
	 
	function updateExchangeRate(uint _rateTimes1000) public onlyOwner saleNotDone {
		exchangeRate = _rateTimes1000;
	}

	 
	 
	function updateICO(uint _bonusRate, uint256 _cap, Stage _stage) external onlyOwner saleNotDone {
		require (_bonusRate <= 100);
		require(_cap <= icoCap);
		require(_stage != Stage.None);
		
		bonusRate = _bonusRate;
		currentSaleCap = _cap;	
		currentStage = _stage;
	}
	
	function updateVaults(address _reserve, address _restricted) external onlyOwner saleNotDone {
		require(_reserve != address(0));
		require(_restricted != address(0));
		
		reserveVault = _reserve;
		restrictedVault = _restricted;
		
	    require(Ownable(_reserve).owner() == address(this));
	    require(Ownable(_restricted).owner() == address(this));
	}
	
	function updateReserveVault(address _reserve) external onlyOwner saleNotDone {
		require(_reserve != address(0));

		reserveVault = _reserve;

	    require(Ownable(_reserve).owner() == address(this));
	}
	
	function updateRestrictedVault(address _restricted) external onlyOwner saleNotDone {
		require(_restricted != address(0));
		
		restrictedVault = _restricted;
		
	    require(Ownable(_restricted).owner() == address(this));
	}
	
	 
	 
	 
	 
	 

	function bookkeep(address _beneficiary, uint256 _base, uint256 _bonus) internal returns(bool) {
		uint256 newBase = baseTokensAllocated.add(_base);
		uint256 newBonus = bonusTokensAllocated.add(_bonus);

		if (newBase > currentSaleCap || newBonus > marketingCap) {
			return false;
		}

		baseTokensAllocated = newBase;
		bonusTokensAllocated = newBonus;

		Contribution storage c = contributionBalance[_beneficiary];
		c.base = c.base.add(_base);
		c.bonus = c.bonus.add(_bonus);

		return true;
	}
    
	function computeTokens(uint256 _weiAmount, uint _bonusRate) external view returns (uint256 base, uint256 bonus) {
		base = _weiAmount.mul(exchangeRate).div(1000);
		bonus = base.mul(_bonusRate).div(100);
	}
    
	 
	function () public payable saleActive stopInEmergency {
	    revert();
	    
		 
	}

	 
		 
		 
		 

		 
		 
		 
		
		 

         
        
		 

         
        
		 
		 
	 

	 
	 
	 
	 
	function buyTokensFor(address _beneficiary, uint256 _baseTokens, uint _bonusTokens) external onlyOwner saleAllocatable {
		require(_beneficiary != 0x0);
		require(_baseTokens != 0 || _bonusTokens != 0);
		require(blacklist[_beneficiary] == false);
		
        require(bookkeep(_beneficiary, _baseTokens, _bonusTokens));

        uint256 total = _baseTokens.add(_bonusTokens);

        TokenPurchase(msg.sender, _beneficiary, 0, total);
        
		token.mint(_beneficiary, total);
	}
    
	 
	function giftTokens(address _beneficiary, uint256 _giftAmount) external onlyOwner saleAllocatable {
		require(_beneficiary != 0x0);
		require(_giftAmount != 0);
		require(blacklist[_beneficiary] == false);

        require(bookkeep(_beneficiary, 0, _giftAmount));
        
        TokenPurchase(msg.sender, _beneficiary, 0, _giftAmount);
        
		token.mint(_beneficiary, _giftAmount);
	}
	function balanceOf(address _beneficiary) public view returns(uint256, uint256) {
		require(_beneficiary != address(0));

        Contribution storage c = contributionBalance[_beneficiary];
		return (c.base, c.bonus);
	}

	
	 
	 
	function ban(address _owner) external onlyOwner saleAllocatable returns (uint256 total) {
	    require(_owner != address(0));
	    require(!blacklist[_owner]);
	    
	    uint256 base;
	    uint256 bonus;
	    
	    (base, bonus) = balanceOf(_owner);
	    
	    delete contributionBalance[_owner];
	    
		baseTokensAllocated = baseTokensAllocated.sub(base);
		bonusTokensAllocated = bonusTokensAllocated.sub(bonus);
		
	    blacklist[_owner] = true;

	    total = token.revoke(_owner);
	}

     
	function unban(address _beneficiary) external onlyOwner saleAllocatable {
	    require(_beneficiary != address(0));
	    require(blacklist[_beneficiary] == true);

        delete blacklist[_beneficiary];
	}
	
	 
	function releaseTokens() external onlyOwner saleAllocating {
		require(reserveVault != address(0));
		require(restrictedVault != address(0));
		require(saleAllocated == false);

		saleAllocated = true;
		
         
	    token.mint(reserveVault, reserveCap); 
		token.mint(restrictedVault, teamCap); 
	}

	
	 
	 
	function endICO() external onlyOwner saleAllocating {
	    require(saleAllocated);
	    
	    currentStage = Stage.Done;
	    
         
	    token.finishMinting();  
	    
	     
	    token.transferOwnership(owner);
	    Ownable(reserveVault).transferOwnership(owner);
	    Ownable(restrictedVault).transferOwnership(owner);
	}
	
	function giveBack() public onlyOwner {
	    if (address(token) != address(0))
	        token.transferOwnership(owner);
        if (reserveVault != address(0))
	        Ownable(reserveVault).transferOwnership(owner);
        if (restrictedVault != address(0))
	        Ownable(restrictedVault).transferOwnership(owner);
	}
}