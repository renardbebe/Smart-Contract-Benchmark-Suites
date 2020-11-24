 

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
}

 
 
 
 
contract WanchainContribution is Owned {
    using SafeMath for uint;

     
     
    uint public constant WAN_TOTAL_SUPPLY = 210000000 ether;
    uint public constant EARLY_CONTRIBUTION_DURATION = 24 hours;
    uint public constant MAX_CONTRIBUTION_DURATION = 3 weeks;

     
    uint public constant PRICE_RATE_FIRST = 880;
     
    uint public constant PRICE_RATE_SECOND = 790;
     
    uint public constant PRICE_RATE_LAST = 750;

     
     
     
     
     
       
    uint public constant OPEN_SALE_STAKE = 510;   

     
    uint public constant DEV_TEAM_STAKE = 200;    
    uint public constant FOUNDATION_STAKE = 190;  
    uint public constant MINERS_STAKE = 100;      

    uint public constant DIVISOR_STAKE = 1000;

    uint public constant PRESALE_RESERVERED_AMOUNT = 41506655 ether;  
  
     
     

     
    address public constant DEV_TEAM_HOLDER = 0x0001cdC69b1eb8bCCE29311C01092Bdcc92f8f8F;
    address public constant FOUNDATION_HOLDER = 0x00dB4023b32008C45E62Add57De256a9399752D4;
    address public constant MINERS_HOLDER = 0x00f870D11eA43AA1c4C715c61dC045E32d232787;
    address public constant PRESALE_HOLDER = 0x00577c25A81fA2401C5246F4a7D5ebaFfA4b00Aa;
  
    uint public MAX_OPEN_SOLD = WAN_TOTAL_SUPPLY * OPEN_SALE_STAKE / DIVISOR_STAKE - PRESALE_RESERVERED_AMOUNT;

     
     
    address public wanport;
     
    uint public earlyReserveBeginTime;
     
    uint public startTime;
     
    uint public endTime;

     
     
    uint public openSoldTokens;
     
    bool public halted; 
     
    WanToken public wanToken; 

     
    mapping (address => uint256) public earlyUserQuotas;
     
    mapping (address => uint256) public fullWhiteList;

    uint256 public normalBuyLimit = 65 ether;

     

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
     

     

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


     
    function WanchainContribution(address _wanport, uint _bootTime){
      require(_wanport != 0x0);

        halted = false;
      wanport = _wanport;
        earlyReserveBeginTime = _bootTime;
      startTime = earlyReserveBeginTime + EARLY_CONTRIBUTION_DURATION;
      endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
         
      wanToken = new WanToken(this,startTime, endTime);

         
      uint stakeMultiplier = WAN_TOTAL_SUPPLY / DIVISOR_STAKE;
    
        wanToken.mintToken(DEV_TEAM_HOLDER, DEV_TEAM_STAKE * stakeMultiplier);
        wanToken.mintToken(FOUNDATION_HOLDER, FOUNDATION_STAKE * stakeMultiplier);
        wanToken.mintToken(MINERS_HOLDER, MINERS_STAKE * stakeMultiplier);
    
        wanToken.mintToken(PRESALE_HOLDER, PRESALE_RESERVERED_AMOUNT);    
    
    }

     
    function () public payable {
      buyWanCoin(msg.sender);
    }

     

     
     
    function buyWanCoin(address receipient) 
        public 
        payable 
        notHalted 
        initialized 
        ceilingNotReached 
        notEarlierThan(earlyReserveBeginTime)
        earlierThan(endTime)
        returns (bool) 
    {
        require(receipient != 0x0);
        require(msg.value >= 0.1 ether);

         
        require(!isContract(msg.sender));        

        if( now < startTime && now >= earlyReserveBeginTime)
            buyEarlyAdopters(receipient);
        else {
            require( tx.gasprice <= 50000000000 wei );
            require(msg.value <= normalBuyLimit);
            buyNormal(receipient);
        }

        return true;
    }

    function setNormalBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        normalBuyLimit = limit;
    }


     
    function setEarlyWhitelistQuotas(address[] users, uint earlyCap, uint openTag)
        public
        onlyOwner
        earlierThan(earlyReserveBeginTime)
    {
        for( uint i = 0; i < users.length; i++) {
            earlyUserQuotas[users[i]] = earlyCap;
            fullWhiteList[users[i]] = openTag;
        }
    }

     
    function setLaterWhiteList(address[] users, uint openTag)
        public
        onlyOwner
        earlierThan(endTime)
    {
        require(saleNotEnd());
        for( uint i = 0; i < users.length; i++) {
            fullWhiteList[users[i]] = openTag;
        }
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

     
    function saleNotEnd() constant returns (bool) {
        return now < endTime && openSoldTokens < MAX_OPEN_SOLD;
    }

     
     
    function priceRate() public constant returns (uint) {
         
        if (earlyReserveBeginTime <= now && now < startTime + 1 weeks)
            return PRICE_RATE_FIRST;
        if (startTime + 1 weeks <= now && now < startTime + 2 weeks)
            return PRICE_RATE_SECOND;
        if (startTime + 2 weeks <= now && now < endTime)
            return PRICE_RATE_LAST;
         
        assert(false);
    }

    function claimTokens(address receipent)
        public
        isSaleEnded
    {
        wanToken.claimTokens(receipent);
    }

     

     
    function buyEarlyAdopters(address receipient) internal {
      uint quotaAvailable = earlyUserQuotas[receipient];
      require(quotaAvailable > 0);

        uint toFund = quotaAvailable.min256(msg.value);
        uint tokenAvailable4Adopter = toFund.mul(PRICE_RATE_FIRST);

      earlyUserQuotas[receipient] = earlyUserQuotas[receipient].sub(toFund);
      buyCommon(receipient, toFund, tokenAvailable4Adopter);
    }

     
    function buyNormal(address receipient) internal {
        uint inWhiteListTag = fullWhiteList[receipient];
        require(inWhiteListTag > 0);

         
        uint tokenAvailable = MAX_OPEN_SOLD.sub(openSoldTokens);
        require(tokenAvailable > 0);

      uint toFund;
      uint toCollect;
      (toFund, toCollect) = costAndBuyTokens(tokenAvailable);
        buyCommon(receipient, toFund, toCollect);
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