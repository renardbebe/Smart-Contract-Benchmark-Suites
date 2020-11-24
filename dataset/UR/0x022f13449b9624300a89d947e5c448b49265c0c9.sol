 

 
 
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
  event PausePublic(bool newState);
  event PauseOwnerAdmin(bool newState);

  bool public pausedPublic = true;
  bool public pausedOwnerAdmin = false;
  uint public endDate;

   
  modifier whenNotPaused() {
    if(pausedPublic) {
      if(!pausedOwnerAdmin) {
        require(msg.sender == owner);
      } else {
        revert();
      }
    }
    _;
  }

   
  function pause(bool newPausedPublic, bool newPausedOwnerAdmin) onlyOwner public {
    require(!(newPausedPublic == false && newPausedOwnerAdmin == true));

    pausedPublic = newPausedPublic;
    pausedOwnerAdmin = newPausedOwnerAdmin;

    emit PausePublic(newPausedPublic);
    emit PauseOwnerAdmin(newPausedOwnerAdmin);
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

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
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

contract BGToken is StandardToken , BurnableToken  {
    using SafeMath for uint256;
    string public constant name = "BlueGold";
    string public constant symbol = "BG";
    uint8 public constant decimals = 18;	
	
	 
	address public Bounties_Wallet = 0x2805C02FE839210E194Fc4a12DaB683a34Ad95EF;  
	address public Team_Wallet = 0x6C42c4EC37d0F45E2d9C2287f399E14Ea2b3B77d;  
	address public OEM_Wallet = 0x278cB54ae3B7851D3262A307cb6780b642A29485;  
	address public LA_wallet = 0x1669e7910e27b1400B5567eE360de2c5Ee964859;  
		
	address public tokenWallet = 0xDb3D4293981adeEC2A258c0b8046eAdb20D3ff13;     
	uint256 public constant INITIAL_SUPPLY = 100000000 ether;	
	
	 
	uint256 tokenRate = 460; 	
	
    function BGToken() public {
        totalSupply_ = INITIAL_SUPPLY;

		 
		 
		balances[Bounties_Wallet] = INITIAL_SUPPLY.mul(5).div(100) ;
		balances[Team_Wallet] = INITIAL_SUPPLY.mul(8).div(100);
		balances[OEM_Wallet] = INITIAL_SUPPLY.mul(10).div(100) ;
		balances[LA_wallet] = INITIAL_SUPPLY.mul(8).div(100) ;
		
		 
        balances[tokenWallet] = INITIAL_SUPPLY.mul(69).div(100);
				
        emit Transfer(0x0, Bounties_Wallet, balances[Bounties_Wallet]);
        emit Transfer(0x0, Team_Wallet, balances[Team_Wallet]);
		emit Transfer(0x0, OEM_Wallet, balances[OEM_Wallet]);
        emit Transfer(0x0, LA_wallet, balances[LA_wallet]);
				
		emit Transfer(0x0, tokenWallet, balances[tokenWallet]);
        endDate = _endDate;			
    }
	
    uint constant _endDate = 1546297199;  
	uint256 Bonus = 30; 	
	uint256 extraBonus = 20; 		

    struct Stat {
        uint currentFundraiser;
        uint otherAmount;
        uint ethAmount;
        uint txCounter;
    }    
    Stat public stat;    	

	 
    uint256 IcoCap = INITIAL_SUPPLY;
	
	  
	modifier isRunning {
        require (endDate >= now);
        _;
    }
	
     
    function () payable isRunning public {
        if (msg.value < 0.001 ether) revert();
        buyTokens();
    }	

     
    function buyTokens() internal {		
		 
        require(msg.value >= 0.001 ether);
        uint256 tokens ;
		uint256 xAmount = msg.value;
		uint256 toReturnEth;
		uint256 toTokensReturn;
		uint256 balanceIco ;	
		uint256 AllBonus = 0; 
		
		balanceIco = IcoCap;
		balanceIco = balanceIco.sub(stat.currentFundraiser);	
		
		AllBonus= Bonus.add(extraBonus);
		tokens = xAmount.mul(tokenRate);
		tokens = (tokens.mul(100)).div(100 - (AllBonus));
		
		if (balanceIco < tokens) {
			toTokensReturn = tokens.sub(balanceIco);
			toReturnEth = toTokensReturn.mul(tokenRate);
		}			

		if (tokens > 0 )
		{
			if (balanceIco < tokens) {	
				 
				if (toReturnEth <= xAmount) 
				{
					msg.sender.transfer(toReturnEth);									
					_EnvoisTokens(balanceIco, xAmount - toReturnEth);
				}
				
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
	
	 
     
	 
	 
    function _sendTokensManually(address _to, uint _amount, uint _otherAmount) public onlyOwner {
        require(_to != address(0));
		sendTokens(_to, _amount);		
		stat.currentFundraiser += _amount;
        stat.otherAmount += _otherAmount;
        stat.txCounter += 1;
    }	

	 
	 
    function setIcoCap(uint256 newIcoCap) public onlyOwner {
        IcoCap = newIcoCap;
    }
	
	 
	function getIcoCap() public constant returns (uint256) {
        return (IcoCap);
    }    	
		
	 
	 
    function setTokenRate(uint newTokenRate) public onlyOwner {
        tokenRate = newTokenRate;
    }
	
	 
	function getTokenRate() public constant returns (uint) {
        return (tokenRate);
    }    	
	
	 
	 
    function setBonus(uint newBonus) public onlyOwner {
        Bonus = newBonus;		
    }
	
	 
	function getBonus() public constant returns (uint) {
        return (Bonus);
    } 	
	
	 
	 
    function setExtraBonus(uint newExtraBonus) public onlyOwner {
        extraBonus = newExtraBonus;
    }
	
	 
	function getExtraBonus() public constant returns (uint) {
        return (extraBonus);
    } 	
	
	 
	 
    function setEndDate(uint newEndDate) public onlyOwner {
        endDate = newEndDate;
    }		
	
}