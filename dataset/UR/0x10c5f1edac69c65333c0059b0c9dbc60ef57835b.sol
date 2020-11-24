 

 
 
pragma solidity ^0.4.21;

 
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
     
     
     
    return a / b;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract Pausable is Ownable {

  uint public endDate;

   
  modifier whenNotPaused() {
    require(now >= endDate);
    _;
  }

}

contract StandardToken is ERC20, BasicToken, Pausable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
 

 
contract BurnableToken is StandardToken {

     
    function burn(uint256  _value)
        public onlyOwner
    {
        require(_value > 0);
		require(balances[msg.sender] >= _value);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
    event Burn(address indexed burner, uint256  indexed value);
} 
   
contract AFWToken is StandardToken , BurnableToken  {
    using SafeMath for uint256;
    string public constant name = "All4FW";
    string public constant symbol = "AFW";
    uint8 public constant decimals = 18;	
	
	 
	address public Bounties_Wallet = 0xA7135CbD1281d477eef4FC7F0AB19566A47bE759;  
	address public Team_Wallet = 0xaA1582A5b00fDEc47FeD1CcDDe7e5fA3652B456b;  
	address public OEM_Wallet = 0x51e32712C65AEFAAea9d0b7336A975f400825309;  
	address public LA_wallet = 0xBaC4B80b6C74518bF31b5cE1be80926ffEEBB4db;  
    
	address public tokenWallet = 0x4CE38c5f44794d6173Dd3BBaf208EeEf2033370A;    
	uint256 public constant INITIAL_SUPPLY = 100000000 ether;	
	
	
	 
	uint256 tokenRate = 650; 
	
	
    function AFWToken() public {
        totalSupply_ = INITIAL_SUPPLY;
		
		 
		 
		balances[Bounties_Wallet] = INITIAL_SUPPLY.mul(5).div(100) ;
		balances[Team_Wallet] = INITIAL_SUPPLY.mul(8).div(100);
		balances[OEM_Wallet] = INITIAL_SUPPLY.mul(10).div(100) ;
		balances[LA_wallet] = INITIAL_SUPPLY.mul(8).div(100) ;
		
		 
        balances[tokenWallet] = INITIAL_SUPPLY.mul(69).div(100);
		
        endDate = _endDate;
				
        emit Transfer(0x0, Bounties_Wallet, balances[Bounties_Wallet]);
        emit Transfer(0x0, Team_Wallet, balances[Team_Wallet]);
		emit Transfer(0x0, OEM_Wallet, balances[OEM_Wallet]);
        emit Transfer(0x0, LA_wallet, balances[LA_wallet]);
				
		emit Transfer(0x0, tokenWallet, balances[tokenWallet]);
    }

	 
     
     
     
	 
	 
     
     
    

	 
    uint public constant startDate = 1524866399;  
    uint public constant endPreICO = 1526680799; 
	
	 
    uint constant preSale20 = startDate ;  
    uint constant preSale10 = 1525039200;  
    uint constant preSale5 = 1525471200;  
	uint constant preSale3 = 1525989600;  
			
    uint public constant startICO = 1526680800;  
    uint public constant _endDate = 1529186399;  

    struct Stat {
        uint currentFundraiser;
        uint btcAmount;
        uint ethAmount;
        uint txCounter;
    }    
    Stat public stat;    
	
	 
    uint public constant preIcoCap = 5000000 ether;
    uint public constant IcoCap = 64000000 ether;

	 
	uint256[4] private StepCaps = [
        750000 ether, 	 
        900000 ether, 	 
        1500000 ether, 	 
        1850000 ether 	 
    ];	
	uint8[4] private StepDiscount = [20, 10, 5, 3];
		
     
    modifier isFinished() {
        require(now >= endDate);
        _;
    }
	
	 
    function currentStepIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= endPreICO); 
        if(now > preSale3) return 3;
        if(now > preSale5) return 2;
        if(now > preSale10) return 1;
        if(now > preSale20) return 0;
        else return 0;
    }
	

     
    function currentStepIndex() internal view returns (uint8 roundNum) {
        roundNum = currentStepIndexByDate();
         
        while(roundNum < 3 && stat.currentFundraiser > StepCaps[roundNum]) {
            roundNum++;
        }
    }

	 
	 
     
    function computeTokenAmount( uint256 ethAmount) internal view returns (uint256) {
        uint256 tokenBase = ethAmount.mul(tokenRate);
		uint8 roundNum = currentStepIndex();
        uint256 tokens = tokenBase.mul(100)/(100 - (StepDiscount[roundNum]));
		return tokens;
    }

	
	 
    function isPreSale() internal view returns (bool) {
        if (now >= startDate && now < endPreICO && preIcoCap.sub(stat.currentFundraiser) > 0) {
            return true;
        } else {
            return false;
        }
    }

	 
    function isMainSale() internal view returns (bool) {
        if (now >= startICO && now < endDate) {
            return true;
        } else {
            return false;
        }
    }

     
    function () payable public {
        if (msg.value < 0.001 ether || (!isPreSale() && !isMainSale())) revert();
        buyTokens();
    }
	
	 
    function currentStepIndexAll() internal view returns (uint8 roundNum) {
        roundNum = currentStepIndexByDate();
         
        while(roundNum < 3 && StepCaps[roundNum]<= 0) {
            roundNum++;
        }
    }
	
	 
     
	function computeTokenAmountAll(uint256 ethAmount) internal returns (uint256) {
        uint256 tokenBase = ethAmount.mul(tokenRate);
		uint8 roundNum = currentStepIndexAll();
		uint256 tokens = tokenBase.mul(100)/(100 - (StepDiscount[roundNum]));
				
		if (roundNum == 3 && (StepCaps[0] > 0 || StepCaps[1] > 0 || StepCaps[2] > 0))
		{
			 
			StepCaps[3] = StepCaps[3] + StepCaps[0] + StepCaps[1] + StepCaps[2];
			StepCaps[0] = 0;
			StepCaps[1] = 0;
			StepCaps[2] = 0;
		}				
		uint256 balancePreIco = StepCaps[roundNum];		
		
		if (balancePreIco == 0 && roundNum == 3) {

		} else {
			 
			if (balancePreIco < tokens) {			
				uint256 toEthCaps = (balancePreIco.mul((100 - (StepDiscount[roundNum]))).div(100)).div(tokenRate);			
				uint256 toReturnEth = ethAmount - toEthCaps ;
				tokens= balancePreIco;
				StepCaps[roundNum]=StepCaps[roundNum]-balancePreIco;		
				tokens = tokens + computeTokenAmountAll(toReturnEth);			
			} else {
				StepCaps[roundNum] = StepCaps[roundNum] - tokens;
			}	
		}		
		return tokens ;
    }
	
     
    function buyTokens() internal {		
		 
        require(msg.value >= 0.001 ether);
        uint256 tokens ;
		uint256 xAmount = msg.value;
		uint256 toReturnEth;
		uint256 toTokensReturn;
		uint256 balanceIco ;
		
		if(isPreSale()){	
			balanceIco = preIcoCap.sub(stat.currentFundraiser);
			tokens =computeTokenAmountAll(xAmount);
			if (balanceIco < tokens) {	
				uint8 roundNum = currentStepIndexAll();
				toTokensReturn = tokens.sub(balanceIco);	 
				toReturnEth = (toTokensReturn.mul((100 - (StepDiscount[roundNum]))).div(100)).div(tokenRate);			
			}			
		} else if (isMainSale()) {
			balanceIco = IcoCap.add(preIcoCap);
 			balanceIco = balanceIco.sub(stat.currentFundraiser);	
			tokens = xAmount.mul(tokenRate);
			if (balanceIco < tokens) {
				toTokensReturn = tokens.sub(balanceIco);
				toReturnEth = toTokensReturn.mul(tokenRate);
			}			
		} else {
            revert();
        }

		if (tokens > 0 )
		{
			if (balanceIco < tokens) {	
				 
				msg.sender.transfer(toReturnEth);
				_EnvoisTokens(balanceIco, xAmount - toReturnEth);
			} else {
				_EnvoisTokens(tokens, xAmount);
			}
		} else {
            revert();
		}
    }

	 
	 
     
	 
    function _EnvoisTokens(uint _amount, uint _ethers) internal {
		 
        sendTokens(msg.sender, _amount);
        stat.currentFundraiser += _amount;
		 
        tokenWallet.transfer(_ethers);
        stat.ethAmount += _ethers;
        stat.txCounter += 1;
    }
    
	 
	 
     
	 
    function sendTokens(address _to, uint _amount) internal {
        require(_amount <= balances[tokenWallet]);
        balances[tokenWallet] -= _amount;
        balances[_to] += _amount;
        emit Transfer(tokenWallet, _to, _amount);
    }

	 
     
	 
	 
    function _sendTokensManually(address _to, uint _amount, uint _btcAmount) public onlyOwner {
        require(_to != address(0));
        sendTokens(_to, _amount);
        stat.currentFundraiser += _amount;
        stat.btcAmount += _btcAmount;
        stat.txCounter += 1;
    }
	
	 
	 
    function setTokenRate(uint newTokenRate) public onlyOwner {
        tokenRate = newTokenRate;
    }
	
	 
	function getTokenRate() public constant returns (uint) {
        return (tokenRate);
    }    
	
	 
    function price() public view returns (uint256 tokens) {
		uint _amount = 1 ether;
		
		if(isPreSale()){	
			return computeTokenAmount(_amount);
		} else if (isMainSale()) {
			return _amount.mul(tokenRate);
		} else {
            return 0;
        }
    }
	 
	 
    function EthToAFW(uint _amount) public view returns (uint256 tokens) {
		if(isPreSale()){	
			return computeTokenAmount(_amount);
		} else if (isMainSale()) {
			return _amount.mul(tokenRate);
		} else {
            return 0;
        }
    }      

	 
    function GetSale() public constant returns (uint256 tokens) {
		if(isPreSale()){	
			return 1;
		} else if (isMainSale()) {
			return 2;
		} else {
            return 0;
        }
    }        
	
	 
	 
	function getCapTab(uint _roundNum) public view returns (uint) {			
		return (StepCaps[_roundNum]);
    }
	
	 
	 
	 
    function setCapTab(uint _roundNum,uint _value) public onlyOwner {
        require(_value > 0);
		StepCaps[_roundNum] = _value;
    }	

	 
	function getBalanceIco() public constant returns (uint) {
		uint balanceIco = IcoCap.add(preIcoCap);
		balanceIco = balanceIco.sub(stat.currentFundraiser);	
        return(balanceIco);
    } 
	
	  
    
    function AFWBurn(uint256 _value) public onlyOwner {
        require(msg.sender == owner);
        require(balances[msg.sender] >= _value *10**18);
        super.burn(_value *10**18);
    }

}