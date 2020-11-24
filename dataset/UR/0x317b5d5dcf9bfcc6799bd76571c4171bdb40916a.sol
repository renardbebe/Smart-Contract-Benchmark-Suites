 

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}
















 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    public returns (bool success) {
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







 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 

contract DmlToken is StandardToken, Pausable{
	using SafeMath for uint;

 	string public constant name = "DML Token";
	uint8 public constant decimals = 18;
	string public constant symbol = 'DML';

	uint public constant MAX_TOTAL_TOKEN_AMOUNT = 330000000 ether;
	address public minter;
	uint public endTime;

	mapping (address => uint) public lockedBalances;

	modifier onlyMinter {
    	  assert(msg.sender == minter);
    	  _;
    }

    modifier maxDmlTokenAmountNotReached (uint amount){
    	  assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }

     
	function DmlToken(address _minter, uint _endTime){
    	  minter = _minter;
    	  endTime = _endTime;
    }

     
    function mintToken(address receipent, uint amount)
        external
        onlyMinter
        maxDmlTokenAmountNotReached(amount)
        returns (bool)
    {
        require(now <= endTime);
      	lockedBalances[receipent] = lockedBalances[receipent].add(amount);
      	totalSupply = totalSupply.add(amount);
      	return true;
    }

     
    function claimTokens(address receipent)
        public
        onlyMinter
    {
      	balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
      	lockedBalances[receipent] = 0;
    }

    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }

	 
	function transfer(address _to, uint _value)
		public
		validRecipient(_to)
		returns (bool success)
	{
		return super.transfer(_to, _value);
	}

	 
	function approve(address _spender, uint256 _value)
		public
		validRecipient(_spender)
		returns (bool)
	{
		return super.approve(_spender,  _value);
	}

	 
	function transferFrom(address _from, address _to, uint256 _value)
		public
		validRecipient(_to)
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}

	 

 	modifier validRecipient(address _recipient) {
    	require(_recipient != address(this));
    	_;
  	}
}



 
contract DmlContribution is Ownable {
    using SafeMath for uint;

     
     
    uint public constant DML_TOTAL_SUPPLY = 330000000 ether;
    uint public constant EARLY_CONTRIBUTION_DURATION = 24 hours;
    uint public constant MAX_CONTRIBUTION_DURATION = 5 days;

     
    uint public constant PRICE_RATE_FIRST = 3780;
    uint public constant PRICE_RATE_SECOND = 4158;

     
     
     
     
     
    uint public constant SALE_STAKE = 360;   

     
    uint public constant ECO_SYSTEM_STAKE = 99;    
    uint public constant COMMUNITY_BOUNTY_STAKE = 83;  
    uint public constant OPERATION_STAKE = 308;      
    uint public constant RESERVES_STAKE = 150;      

    uint public constant DIVISOR_STAKE = 1000;

    uint public constant PRESALE_RESERVERED_AMOUNT = 56899342578812412860512236;
    
     
    address public constant ECO_SYSTEM_HOLDER = 0x2D8C705a66b2E87A9249380d4Cdfe9D80BBF826B;
    address public constant COMMUNITY_BOUNTY_HOLDER = 0x68500ffEfb57D88A600E2f1c63Bb5866e7107b6B;
    address public constant OPERATION_HOLDER = 0xC7b6DFf52014E59Cb88fAc3b371FA955D0A9249F;
    address public constant RESERVES_HOLDER = 0xab376b3eC2ed446444911E549c7C953fB086070f;
    address public constant PRESALE_HOLDER = 0xcB52583D19fd42c0f85a0c83A45DEa6C73B9EBfb;
    
    uint public MAX_PUBLIC_SOLD = DML_TOTAL_SUPPLY * SALE_STAKE / DIVISOR_STAKE - PRESALE_RESERVERED_AMOUNT;

     
     
    address public dmlwallet;
    uint public earlyWhitelistBeginTime;
    uint public startTime;
    uint public endTime;

     
     
    uint public openSoldTokens;
     
    bool public halted; 
     
    DmlToken public dmlToken; 

    mapping (address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;

    struct WhitelistUser {
      uint256 quota;
      uint index;
      uint level;
    }
     
     
     

    uint256 public maxBuyLimit = 68 ether;

     

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event ToFundAmount(uint ethCost);
    event ValidFundAmount(uint ethCost);
    event Debug(uint number);
    event UserCallBuy();
    event ShowTokenAvailable(uint);
    event NowTime(uint, uint, uint, uint);

     

    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier initialized() {
        require(address(dmlwallet) != 0x0);
        _;
    }    

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_PUBLIC_SOLD);
        _;
    }  

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_PUBLIC_SOLD);
        _;
    }


     
    function DmlContribution(address _dmlwallet, uint _bootTime){
        require(_dmlwallet != 0x0);

        halted = false;
        dmlwallet = _dmlwallet;
        earlyWhitelistBeginTime = _bootTime;
        startTime = earlyWhitelistBeginTime + EARLY_CONTRIBUTION_DURATION;
        endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
        dmlToken = new DmlToken(this, endTime);

        uint stakeMultiplier = DML_TOTAL_SUPPLY / DIVISOR_STAKE;
        
        dmlToken.mintToken(ECO_SYSTEM_HOLDER, ECO_SYSTEM_STAKE * stakeMultiplier);
        dmlToken.mintToken(COMMUNITY_BOUNTY_HOLDER, COMMUNITY_BOUNTY_STAKE * stakeMultiplier);
        dmlToken.mintToken(OPERATION_HOLDER, OPERATION_STAKE * stakeMultiplier);
        dmlToken.mintToken(RESERVES_HOLDER, RESERVES_STAKE * stakeMultiplier);

        dmlToken.mintToken(PRESALE_HOLDER, PRESALE_RESERVERED_AMOUNT);      
        
    }

     
    function () public payable {
        buyDmlCoin(msg.sender);
         
    }

     

     
     
    function buyDmlCoin(address receipient) 
        public 
        payable 
        notHalted 
        initialized 
        ceilingNotReached 
        notEarlierThan(earlyWhitelistBeginTime)
        earlierThan(endTime)
        returns (bool) 
    {
        require(receipient != 0x0);
        require(isWhitelisted(receipient));

         
        require(!isContract(msg.sender));        
        require( tx.gasprice <= 99000000000 wei );

        if( now < startTime && now >= earlyWhitelistBeginTime)
        {
            if (whitelisted[receipient].level >= 2)
            {
                require(msg.value >= 1 ether);
            }
            else
            {
                require(msg.value >= 0.5 ether);
            }
            buyEarlyWhitelist(receipient);
        }
        else
        {
            require(msg.value >= 0.1 ether);
            require(msg.value <= maxBuyLimit);
            buyRemaining(receipient);
        }

        return true;
    }

    function setMaxBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        maxBuyLimit = limit;
    }


     
    function addWhiteListUsers(address[] userAddresses, uint256[] quota, uint[] level)
        public
        onlyOwner
        earlierThan(endTime)
    {
        for( uint i = 0; i < userAddresses.length; i++) {
            addWhiteListUser(userAddresses[i], quota[i], level[i]);
        }
    }

    function addWhiteListUser(address userAddress, uint256 quota, uint level)
        public
        onlyOwner
        earlierThan(endTime)
    {
        if (!isWhitelisted(userAddress)) {
            whitelisted[userAddress].quota = quota;
            whitelisted[userAddress].level = level;
            whitelisted[userAddress].index = whitelistedIndex.push(userAddress) - 1;
        }
    }

     
    function isWhitelisted (address userAddress) public constant returns (bool isIndeed) {
        if (whitelistedIndex.length == 0) return false;
        return (whitelistedIndex[whitelisted[userAddress].index] == userAddress);
    }

     
    function getWhitelistUser (address userAddress) public constant returns (uint256 quota, uint index, uint level) {
        require(isWhitelisted(userAddress));
        return(whitelisted[userAddress].quota, whitelisted[userAddress].index, whitelisted[userAddress].level);
    }


     
     
    function halt() public onlyOwner{
        halted = true;
    }

     
     
    function unHalt() public onlyOwner{
        halted = false;
    }

     
    function changeWalletAddress(address newAddress) onlyOwner{ 
        dmlwallet = newAddress; 
    }

     
    function saleNotEnd() constant returns (bool) {
        return now < endTime && openSoldTokens < MAX_PUBLIC_SOLD;
    }

     
     
    function priceRate() public constant returns (uint) {
         
        if (earlyWhitelistBeginTime <= now && now < startTime)
        {
            if (whitelisted[msg.sender].level >= 2)
            {
                return PRICE_RATE_SECOND;
            }
            else
            {
                return PRICE_RATE_FIRST;
            }
        }
        if (startTime <= now && now < endTime)
        {
            return PRICE_RATE_FIRST;
        }
         
        assert(false);
    }
    function claimTokens(address receipent)
        public
        isSaleEnded
    {
        dmlToken.claimTokens(receipent);
    }

     

     
    function buyEarlyWhitelist(address receipient) internal {
        uint quotaAvailable = whitelisted[receipient].quota;
        require(quotaAvailable > 0);

        uint tokenAvailable = MAX_PUBLIC_SOLD.sub(openSoldTokens);
        ShowTokenAvailable(tokenAvailable);
        require(tokenAvailable > 0);

        uint validFund = quotaAvailable.min256(msg.value);
        ValidFundAmount(validFund);

        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, validFund);

        whitelisted[receipient].quota = whitelisted[receipient].quota.sub(toFund);
        buyCommon(receipient, toFund, toCollect);
    }

     
    function buyRemaining(address receipient) internal {
        uint tokenAvailable = MAX_PUBLIC_SOLD.sub(openSoldTokens);
        ShowTokenAvailable(tokenAvailable);
        require(tokenAvailable > 0);

        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, msg.value);
        
        buyCommon(receipient, toFund, toCollect);
    }

     
    function buyCommon(address receipient, uint toFund, uint dmlTokenCollect) internal {
        require(msg.value >= toFund);  

        if(toFund > 0) {
            require(dmlToken.mintToken(receipient, dmlTokenCollect));
            ToFundAmount(toFund);
            dmlwallet.transfer(toFund);
            openSoldTokens = openSoldTokens.add(dmlTokenCollect);
            NewSale(receipient, toFund, dmlTokenCollect);            
        }

        uint toReturn = msg.value.sub(toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

     
    function costAndBuyTokens(uint availableToken, uint validFund) constant internal returns (uint costValue, uint getTokens){
         
        uint exchangeRate = priceRate();
        getTokens = exchangeRate * validFund;

        if(availableToken >= getTokens){
            costValue = validFund;
        } else {
            costValue = availableToken / exchangeRate;
            getTokens = availableToken;
        }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}