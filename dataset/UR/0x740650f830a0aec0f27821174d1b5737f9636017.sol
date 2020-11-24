 

pragma solidity ^0.4.11;


 
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


pragma solidity ^0.4.11;


 
 
contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

 
 
pragma solidity ^0.4.11;

contract ERC20Protocol {
     
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


pragma solidity ^0.4.11;

 
 

contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}




pragma solidity ^0.4.11;


 

 
 
 
 
 
 
 



 
 


 
 
 
contract WanToken is StandardToken {
    using SafeMath for uint;

     
    string public constant name = "WanCoin";
    string public constant symbol = "WAN";
    uint public constant decimals = 18;

     
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 210000000 ether;

     
     
    address public minter;
     
    uint public startTime;
     
    uint public endTime;

     
    mapping (address => uint) public lockedBalances;
     

    modifier onlyMinter {
    	  assert(msg.sender == minter);
    	  _;
    }

    modifier isLaterThan (uint x){
    	  assert(now > x);
    	  _;
    }

    modifier maxWanTokenAmountNotReached (uint amount){
    	  assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }

     
    function WanToken(address _minter, uint _startTime, uint _endTime){
    	  minter = _minter;
    	  startTime = _startTime;
    	  endTime = _endTime;
    }

     
    function mintToken(address receipent, uint amount)
        external
        onlyMinter
        maxWanTokenAmountNotReached(amount)
        returns (bool)
    {
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
}


pragma solidity ^0.4.11;

 

 
 
 
 
 
 
 

 
 
 
 
contract WanchainContribution is Owned {
    using SafeMath for uint;

     
     
    uint public constant WAN_TOTAL_SUPPLY = 210000000 ether;
    uint public constant MAX_CONTRIBUTION_DURATION = 3 days;

     
    uint public constant PRICE_RATE_FIRST = 880;
     
    uint public constant PRICE_RATE_SECOND = 790;
     
    uint public constant PRICE_RATE_LAST = 750;

     
     
     
     
     
       
      uint public constant OPEN_SALE_STAKE = 459;   
      uint public constant PRESALE_STAKE = 51;      

       
      uint public constant DEV_TEAM_STAKE = 200;    
      uint public constant FOUNDATION_STAKE = 190;  
      uint public constant MINERS_STAKE = 100;      

      uint public constant DIVISOR_STAKE = 1000;

       
       
      address public constant PRESALE_HOLDER = 0xca8f76fd9597e5c0ea5ef0f83381c0635271cd5d;

       
      address public constant DEV_TEAM_HOLDER = 0x1631447d041f929595a9c7b0c9c0047de2e76186;
      address public constant FOUNDATION_HOLDER = 0xe442408a5f2e224c92b34e251de48f5266fc38de;
      address public constant MINERS_HOLDER = 0x38b195d2a18a4e60292868fa74fae619d566111e;

      uint public MAX_OPEN_SOLD = WAN_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE;

     
     
    address public wanport;
     
    uint public startTime;
     
    uint public endTime;

     
     
    uint openSoldTokens;
     
    uint normalSoldTokens;
     
    uint public partnerReservedSum;
     
    bool public halted;
     
    WanToken public wanToken;

     
    mapping (address => uint256) public partnersLimit;
     
    mapping (address => uint256) public partnersBought;

    uint256 public normalBuyLimit = 65 ether;

     

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event PartnerAddressQuota(address indexed partnerAddress, uint quota);

     

    modifier onlyWallet {
        require(msg.sender == wanport);
        _;
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier initialized() {
        require(address(wanport) != 0x0);
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
        require(openSoldTokens < MAX_OPEN_SOLD);
        _;
    }

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_OPEN_SOLD);
        _;
    }


     
    function WanchainContribution(address _wanport, uint _startTime){
    	require(_wanport != 0x0);

        halted = false;
    	wanport = _wanport;
    	startTime = _startTime;
    	endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
        partnerReservedSum = 0;
        normalSoldTokens = 0;
         
    	wanToken = new WanToken(this,startTime, endTime);

         
    	uint stakeMultiplier = WAN_TOTAL_SUPPLY / DIVISOR_STAKE;

    	wanToken.mintToken(PRESALE_HOLDER, PRESALE_STAKE * stakeMultiplier);
        wanToken.mintToken(DEV_TEAM_HOLDER, DEV_TEAM_STAKE * stakeMultiplier);
        wanToken.mintToken(FOUNDATION_HOLDER, FOUNDATION_STAKE * stakeMultiplier);
        wanToken.mintToken(MINERS_HOLDER, MINERS_STAKE * stakeMultiplier);
    }

     
    function () public payable notHalted ceilingNotReached{
    	buyWanCoin(msg.sender);
    }

     

   function setNormalBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        normalBuyLimit = limit;
    }

     
     
     
     
     
     
     
    function setPartnerQuota(address setPartnerAddress, uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        require(limit > 0 && limit <= MAX_OPEN_SOLD);
        partnersLimit[setPartnerAddress] = limit;
        partnerReservedSum += limit;
        PartnerAddressQuota(setPartnerAddress, limit);
    }

     
     
    function buyWanCoin(address receipient)
        public
        payable
        notHalted
        initialized
        ceilingNotReached
        notEarlierThan(startTime)
        earlierThan(endTime)
        returns (bool)
    {
    	require(receipient != 0x0);
    	require(msg.value >= 0.1 ether);

    	if (partnersLimit[receipient] > 0)
    		buyFromPartner(receipient);
    	else {
    		require(msg.value <= normalBuyLimit);
    		buyNormal(receipient);
    	}

    	return true;
    }

     
     
    function halt() public onlyWallet{
        halted = true;
    }

     
     
    function unHalt() public onlyWallet{
        halted = false;
    }

     
    function changeWalletAddress(address newAddress) onlyWallet {
        wanport = newAddress;
    }

     
    function saleStarted() constant returns (bool) {
        return now >= startTime;
    }

     
    function saleEnded() constant returns (bool) {
        return now > endTime || openSoldTokens >= MAX_OPEN_SOLD;
    }

     
     
    function priceRate() public constant returns (uint) {
         
        if (startTime <= now && now < startTime + 1 days)
            return PRICE_RATE_FIRST;
        if (startTime + 1 days <= now && now < startTime + 2 days)
            return PRICE_RATE_SECOND;
        if (startTime + 2 days <= now && now < endTime)
            return PRICE_RATE_LAST;
         
        assert(false);
    }


    function claimTokens(address receipent)
      public
      isSaleEnded
    {

      wanToken.claimTokens(receipent);

    }

     

     
    function buyFromPartner(address receipient) internal {
    	uint partnerAvailable = partnersLimit[receipient].sub(partnersBought[receipient]);
	    uint allAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
      partnerAvailable = partnerAvailable.min256(allAvailable);

    	require(partnerAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund,  toCollect)= costAndBuyTokens(partnerAvailable);

    	partnersBought[receipient] = partnersBought[receipient].add(toCollect);

    	buyCommon(receipient, toFund, toCollect);

    }

     
    function buyNormal(address receipient) internal {
         
        require(!isContract(msg.sender));

         
        uint tokenAvailable;
        if(startTime <= now && now < startTime + 1 days) {
            uint totalNormalAvailable = MAX_OPEN_SOLD.sub(partnerReservedSum);
            tokenAvailable = totalNormalAvailable.sub(normalSoldTokens);
        } else {
            tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        }

        require(tokenAvailable > 0);

    	uint toFund;
    	uint toCollect;
    	(toFund, toCollect) = costAndBuyTokens(tokenAvailable);
        buyCommon(receipient, toFund, toCollect);
        normalSoldTokens += toCollect;
    }

     
    function buyCommon(address receipient, uint toFund, uint wanTokenCollect) internal {
        require(msg.value >= toFund);  

        if(toFund > 0) {
            require(wanToken.mintToken(receipient, wanTokenCollect));
            wanport.transfer(toFund);
            openSoldTokens = openSoldTokens.add(wanTokenCollect);
            NewSale(receipient, toFund, wanTokenCollect);
        }

        uint toReturn = msg.value.sub(toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

     
    function costAndBuyTokens(uint availableToken) constant internal returns (uint costValue, uint getTokens){
    	 
    	uint exchangeRate = priceRate();
    	getTokens = exchangeRate * msg.value;

    	if(availableToken >= getTokens){
    		costValue = msg.value;
    	} else {
    		costValue = availableToken / exchangeRate;
    		getTokens = availableToken;
    	}

    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}