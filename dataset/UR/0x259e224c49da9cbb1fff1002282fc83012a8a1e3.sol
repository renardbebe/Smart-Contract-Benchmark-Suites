 

pragma solidity ^0.4.15;

 

contract DLBXCrowdsale {
  using DirectCrowdsaleLib for DirectCrowdsaleLib.DirectCrowdsaleStorage;

  DirectCrowdsaleLib.DirectCrowdsaleStorage sale;
  uint256 public discountEndTime;

  function DLBXCrowdsale(
                address owner,
                uint256[] saleData,            
                uint256 fallbackExchangeRate,  
                uint256 capAmountInCents,      
                uint256 endTime,               
                uint8 percentBurn,             
                uint256 _discountEndTime,      
                CrowdsaleToken token)          
  {
  	sale.init(owner, saleData, fallbackExchangeRate, capAmountInCents, endTime, percentBurn, token);
    discountEndTime = _discountEndTime;
  }

   
  event LogTokensBought(address indexed buyer, uint256 amount);
  event LogAddressCapExceeded(address indexed buyer, uint256 amount, string Msg);
  event LogErrorMsg(uint256 amount, string Msg);
  event LogTokenPriceChange(uint256 amount, string Msg);
  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);
  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);
  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);
  event LogNoticeMsg(address _buyer, uint256 value, string Msg);

   
  function () payable {
    sendPurchase();
  }

  function sendPurchase() payable returns (bool) {
    if (now > discountEndTime){
      if(msg.value < 17480000000000000000){
        sale.base.saleData[sale.base.milestoneTimes[0]][0] = 75;
      } else {
        sale.base.saleData[sale.base.milestoneTimes[0]][0] = 50;
      }
    } else {
      if(msg.value < 15035000000000000000){
        sale.base.saleData[sale.base.milestoneTimes[0]][0] = 65;
      } else {
        sale.base.saleData[sale.base.milestoneTimes[0]][0] = 43;
      }
    }
  	return sale.receivePurchase(msg.value);
  }

  function withdrawTokens() returns (bool) {
  	return sale.withdrawTokens();
  }

  function withdrawLeftoverWei() returns (bool) {
    return sale.withdrawLeftoverWei();
  }

  function withdrawOwnerEth() returns (bool) {
    return sale.withdrawOwnerEth();
  }

  function crowdsaleActive() constant returns (bool) {
    return sale.crowdsaleActive();
  }

  function crowdsaleEnded() constant returns (bool) {
    return sale.crowdsaleEnded();
  }

  function setTokenExchangeRate(uint256 _exchangeRate) returns (bool) {
    return sale.setTokenExchangeRate(_exchangeRate);
  }

  function setTokens() returns (bool) {
    return sale.setTokens();
  }

  function getOwner() constant returns (address) {
    return sale.base.owner;
  }

  function getTokensPerEth() constant returns (uint256) {
    if (now > discountEndTime){
      return 382;
    } else {
      return 440;
    }
  }

  function getExchangeRate() constant returns (uint256) {
    return sale.base.exchangeRate;
  }

  function getCapAmount() constant returns (uint256) {
      return sale.base.capAmount;
  }

  function getStartTime() constant returns (uint256) {
    return sale.base.startTime;
  }

  function getEndTime() constant returns (uint256) {
    return sale.base.endTime;
  }

  function getEthRaised() constant returns (uint256) {
    return sale.base.ownerBalance;
  }

  function getContribution(address _buyer) constant returns (uint256) {
  	return sale.base.hasContributed[_buyer];
  }

  function getTokenPurchase(address _buyer) constant returns (uint256) {
  	return sale.base.withdrawTokensMap[_buyer];
  }

  function getLeftoverWei(address _buyer) constant returns (uint256) {
    return sale.base.leftoverWei[_buyer];
  }

  function getSaleData() constant returns (uint256) {
    if (now > discountEndTime){
      return 75;
    } else {
      return 65;
    }
  }

  function getTokensSold() constant returns (uint256) {
    return sale.base.startingTokenBalance - sale.base.withdrawTokensMap[sale.base.owner];
  }

  function getPercentBurn() constant returns (uint256) {
    return sale.base.percentBurn;
  }
}

library DirectCrowdsaleLib {
  using BasicMathLib for uint256;
  using CrowdsaleLib for CrowdsaleLib.CrowdsaleStorage;

  struct DirectCrowdsaleStorage {

  	CrowdsaleLib.CrowdsaleStorage base;  

  }

  event LogTokensBought(address indexed buyer, uint256 amount);
  event LogAddressCapExceeded(address indexed buyer, uint256 amount, string Msg);
  event LogErrorMsg(uint256 amount, string Msg);
  event LogTokenPriceChange(uint256 amount, string Msg);


   
   
   
   
   
   
   
   
   
   
   
  function init(DirectCrowdsaleStorage storage self,
                address _owner,
                uint256[] _saleData,
                uint256 _fallbackExchangeRate,
                uint256 _capAmountInCents,
                uint256 _endTime,
                uint8 _percentBurn,
                CrowdsaleToken _token)
  {
  	self.base.init(_owner,
                _saleData,
                _fallbackExchangeRate,
                _capAmountInCents,
                _endTime,
                _percentBurn,
                _token);
  }

   
   
   
   
  function receivePurchase(DirectCrowdsaleStorage storage self, uint256 _amount) returns (bool) {
    require(msg.sender != self.base.owner);
  	require(self.base.validPurchase());

    require((self.base.ownerBalance + _amount) <= self.base.capAmount);

  	 
  	if ((self.base.milestoneTimes.length > self.base.currentMilestone + 1) &&
        (now > self.base.milestoneTimes[self.base.currentMilestone + 1]))
    {
        while((self.base.milestoneTimes.length > self.base.currentMilestone + 1) &&
              (now > self.base.milestoneTimes[self.base.currentMilestone + 1]))
        {
          self.base.currentMilestone += 1;
        }

        self.base.changeTokenPrice(self.base.saleData[self.base.milestoneTimes[self.base.currentMilestone]][0]);
        LogTokenPriceChange(self.base.tokensPerEth,"Token Price has changed!");
    }

  	uint256 _numTokens;  
    uint256 _newBalance;  
    uint256 _weiTokens;  
    uint256 _zeros;  
    uint256 _leftoverWei;  
    uint256 _remainder;  
    bool err;

     
    (err,_weiTokens) = _amount.times(self.base.tokensPerEth);
    require(!err);

    if(self.base.tokenDecimals <= 18){
      _zeros = 10**(18-uint256(self.base.tokenDecimals));
      _numTokens = _weiTokens/_zeros;
      _leftoverWei = _weiTokens % _zeros;
      self.base.leftoverWei[msg.sender] += _leftoverWei;
    } else {
      _zeros = 10**(uint256(self.base.tokenDecimals)-18);
      _numTokens = _weiTokens*_zeros;
    }

     
    self.base.hasContributed[msg.sender] += _amount - _leftoverWei;

    require(_numTokens <= self.base.token.balanceOf(this));

     
    (err,_newBalance) = self.base.ownerBalance.plus(_amount-_leftoverWei);
    require(!err);

    self.base.ownerBalance = _newBalance;    

     
	  self.base.withdrawTokensMap[msg.sender] += _numTokens;

     
    (err,_remainder) = self.base.withdrawTokensMap[self.base.owner].minus(_numTokens);
    self.base.withdrawTokensMap[self.base.owner] = _remainder;

	  LogTokensBought(msg.sender, _numTokens);

    return true;
  }

   

  function setTokenExchangeRate(DirectCrowdsaleStorage storage self, uint256 _exchangeRate) returns (bool) {
    return self.base.setTokenExchangeRate(_exchangeRate);
  }

  function setTokens(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.setTokens();
  }

  function getSaleData(DirectCrowdsaleStorage storage self, uint256 timestamp) returns (uint256[3]) {
    return self.base.getSaleData(timestamp);
  }

  function getTokensSold(DirectCrowdsaleStorage storage self) constant returns (uint256) {
    return self.base.getTokensSold();
  }

  function withdrawTokens(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawTokens();
  }

  function withdrawLeftoverWei(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawLeftoverWei();
  }

  function withdrawOwnerEth(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawOwnerEth();
  }

  function crowdsaleActive(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.crowdsaleActive();
  }

  function crowdsaleEnded(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.crowdsaleEnded();
  }

  function validPurchase(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.validPurchase();
  }
}

library CrowdsaleLib {
  using BasicMathLib for uint256;

  struct CrowdsaleStorage {
  	address owner;      

  	uint256 tokensPerEth;   
  	uint256 capAmount;  
  	uint256 startTime;  
  	uint256 endTime;  
    uint256 exchangeRate;  
    uint256 ownerBalance;  
    uint256 startingTokenBalance;  
    uint256[] milestoneTimes;  
    uint8 currentMilestone;  
    uint8 tokenDecimals;  
    uint8 percentBurn;  
    bool tokensSet;  
    bool rateSet;  

     
    mapping (uint256 => uint256[2]) saleData;

     
  	mapping (address => uint256) hasContributed;

     
  	mapping (address => uint256) withdrawTokensMap;

     
    mapping (address => uint256) leftoverWei;

  	CrowdsaleToken token;  
  }

   
  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);

   
  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);

   
  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);

   
  event LogNoticeMsg(address _buyer, uint256 value, string Msg);

   
  event LogErrorMsg(string Msg);

   
   
   
   
   
   
   
   
   
   
   
  function init(CrowdsaleStorage storage self,
                address _owner,
                uint256[] _saleData,
                uint256 _fallbackExchangeRate,
                uint256 _capAmountInCents,
                uint256 _endTime,
                uint8 _percentBurn,
                CrowdsaleToken _token)
  {
  	require(self.capAmount == 0);
  	require(self.owner == 0);
    require(_saleData.length > 0);
    require((_saleData.length%3) == 0);  
    require(_saleData[0] > (now + 3 days));
    require(_endTime > _saleData[0]);
    require(_capAmountInCents > 0);
    require(_owner > 0);
    require(_fallbackExchangeRate > 0);
    require(_percentBurn <= 100);
    self.owner = _owner;
    self.capAmount = ((_capAmountInCents/_fallbackExchangeRate) + 1)*(10**18);
    self.startTime = _saleData[0];
    self.endTime = _endTime;
    self.token = _token;
    self.tokenDecimals = _token.decimals();
    self.percentBurn = _percentBurn;
    self.exchangeRate = _fallbackExchangeRate;

    uint256 _tempTime;
    for(uint256 i = 0; i < _saleData.length; i += 3){
      require(_saleData[i] > _tempTime);
      require(_saleData[i + 1] > 0);
      require((_saleData[i + 2] == 0) || (_saleData[i + 2] >= 100));
      self.milestoneTimes.push(_saleData[i]);
      self.saleData[_saleData[i]][0] = _saleData[i + 1];
      self.saleData[_saleData[i]][1] = _saleData[i + 2];
      _tempTime = _saleData[i];
    }
    changeTokenPrice(self, _saleData[1]);
  }

   
   
   
  function crowdsaleActive(CrowdsaleStorage storage self) constant returns (bool) {
  	return (now >= self.startTime && now <= self.endTime);
  }

   
   
   
  function crowdsaleEnded(CrowdsaleStorage storage self) constant returns (bool) {
  	return now > self.endTime;
  }

   
   
   
  function validPurchase(CrowdsaleStorage storage self) internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    if (crowdsaleActive(self) && nonZeroPurchase) {
      return true;
    } else {
      LogErrorMsg("Invalid Purchase! Check send time and amount of ether.");
      return false;
    }
  }

   
   
   
  function withdrawTokens(CrowdsaleStorage storage self) returns (bool) {
    bool ok;

    if (self.withdrawTokensMap[msg.sender] == 0) {
      LogErrorMsg("Sender has no tokens to withdraw!");
      return false;
    }

    if (msg.sender == self.owner) {
      if(!crowdsaleEnded(self)){
        LogErrorMsg("Owner cannot withdraw extra tokens until after the sale!");
        return false;
      } else {
        if(self.percentBurn > 0){
          uint256 _burnAmount = (self.withdrawTokensMap[msg.sender] * self.percentBurn)/100;
          self.withdrawTokensMap[msg.sender] = self.withdrawTokensMap[msg.sender] - _burnAmount;
          ok = self.token.burnToken(_burnAmount);
          require(ok);
        }
      }
    }

    var total = self.withdrawTokensMap[msg.sender];
    self.withdrawTokensMap[msg.sender] = 0;
    ok = self.token.transfer(msg.sender, total);
    require(ok);
    LogTokensWithdrawn(msg.sender, total);
    return true;
  }

   
   
   
  function withdrawLeftoverWei(CrowdsaleStorage storage self) returns (bool) {
    require(self.hasContributed[msg.sender] > 0);
    if (self.leftoverWei[msg.sender] == 0) {
      LogErrorMsg("Sender has no extra wei to withdraw!");
      return false;
    }

    var total = self.leftoverWei[msg.sender];
    self.leftoverWei[msg.sender] = 0;
    msg.sender.transfer(total);
    LogWeiWithdrawn(msg.sender, total);
    return true;
  }

   
   
   
  function withdrawOwnerEth(CrowdsaleStorage storage self) returns (bool) {
    if ((!crowdsaleEnded(self)) && (self.token.balanceOf(this)>0)) {
      LogErrorMsg("Cannot withdraw owner ether until after the sale!");
      return false;
    }

    require(msg.sender == self.owner);
    require(self.ownerBalance > 0);

    uint256 amount = self.ownerBalance;
    self.ownerBalance = 0;
    self.owner.transfer(amount);
    LogOwnerEthWithdrawn(msg.sender,amount,"Crowdsale owner has withdrawn all funds!");

    return true;
  }

   
   
   
   
  function changeTokenPrice(CrowdsaleStorage storage self,uint256 _newPrice) internal returns (bool) {
  	require(_newPrice > 0);

    uint256 result;
    uint256 remainder;

    result = self.exchangeRate / _newPrice;
    remainder = self.exchangeRate % _newPrice;
    if(remainder > 0) {
      self.tokensPerEth = result + 1;
    } else {
      self.tokensPerEth = result;
    }
    return true;
  }

   
   
   
   
  function setTokenExchangeRate(CrowdsaleStorage storage self, uint256 _exchangeRate) returns (bool) {
    require(msg.sender == self.owner);
    require((now > (self.startTime - 3 days)) && (now < (self.startTime)));
    require(!self.rateSet);    
    require(self.token.balanceOf(this) > 0);
    require(_exchangeRate > 0);

    uint256 _capAmountInCents;
    uint256 _tokenBalance;
    bool err;

    (err, _capAmountInCents) = self.exchangeRate.times(self.capAmount);
    require(!err);

    _tokenBalance = self.token.balanceOf(this);
    self.withdrawTokensMap[msg.sender] = _tokenBalance;
    self.startingTokenBalance = _tokenBalance;
    self.tokensSet = true;

    self.exchangeRate = _exchangeRate;
    self.capAmount = (_capAmountInCents/_exchangeRate) + 1;
    changeTokenPrice(self,self.saleData[self.milestoneTimes[0]][0]);
    self.rateSet = true;

    LogNoticeMsg(msg.sender,self.tokensPerEth,"Owner has sent the exchange Rate and tokens bought per ETH!");
    return true;
  }

   
   
   
  function setTokens(CrowdsaleStorage storage self) returns (bool) {
    require(msg.sender == self.owner);
    require(!self.tokensSet);

    uint256 _tokenBalance;

    _tokenBalance = self.token.balanceOf(this);
    self.withdrawTokensMap[msg.sender] = _tokenBalance;
    self.startingTokenBalance = _tokenBalance;
    self.tokensSet = true;

    return true;
  }

   
   
   
   
  function getSaleData(CrowdsaleStorage storage self, uint256 timestamp) constant returns (uint256[3]) {
    uint256[3] memory _thisData;
    uint256 index;

    while((index < self.milestoneTimes.length) && (self.milestoneTimes[index] < timestamp)) {
      index++;
    }
    if(index == 0)
      index++;

    _thisData[0] = self.milestoneTimes[index - 1];
    _thisData[1] = self.saleData[_thisData[0]][0];
    _thisData[2] = self.saleData[_thisData[0]][1];
    return _thisData;
  }

   
   
   
  function getTokensSold(CrowdsaleStorage storage self) constant returns (uint256) {
    return self.startingTokenBalance - self.token.balanceOf(this);
  }
}

contract CrowdsaleToken {
  using TokenLib for TokenLib.TokenStorage;

  TokenLib.TokenStorage public token;

  function CrowdsaleToken(address owner,
                                string name,
                                string symbol,
                                uint8 decimals,
                                uint256 initialSupply,
                                bool allowMinting)
  {
    token.init(owner, name, symbol, decimals, initialSupply, allowMinting);
  }

  function name() constant returns (string) {
    return token.name;
  }

  function symbol() constant returns (string) {
    return token.symbol;
  }

  function decimals() constant returns (uint8) {
    return token.decimals;
  }

  function totalSupply() constant returns (uint256) {
    return token.totalSupply;
  }

  function initialSupply() constant returns (uint256) {
    return token.INITIAL_SUPPLY;
  }

  function balanceOf(address who) constant returns (uint256) {
    return token.balanceOf(who);
  }

  function allowance(address owner, address spender) constant returns (uint256) {
    return token.allowance(owner, spender);
  }

  function transfer(address to, uint value) returns (bool ok) {
    return token.transfer(to, value);
  }

  function transferFrom(address from, address to, uint value) returns (bool ok) {
    return token.transferFrom(from, to, value);
  }

  function approve(address spender, uint value) returns (bool ok) {
    return token.approve(spender, value);
  }

  function changeOwner(address newOwner) returns (bool ok) {
    return token.changeOwner(newOwner);
  }

  function burnToken(uint256 amount) returns (bool ok) {
    return token.burnToken(amount);
  }
}

library BasicMathLib {
  event Err(string typeErr);

   
   
   
   
   
   
  function times(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := mul(a,b)
      switch or(iszero(b), eq(div(res,b), a))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("times func overflow");
  }

   
   
   
   
   
   
  function dividedBy(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      switch iszero(b)
      case 0 {
        res := div(a,b)
        mstore(add(mload(0x40),0x20),res)
        return(mload(0x40),0x40)
      }
    }
    Err("tried to divide by zero");
    return (true, 0);
  }

   
   
   
   
   
   
  function plus(uint256 a, uint256 b) constant returns (bool err, uint256 res) {
    assembly{
      res := add(a,b)
      switch and(eq(sub(res,b), a), or(gt(res,b),eq(res,b)))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("plus func overflow");
  }

   
   
   
   
   
   
  function minus(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := sub(a,b)
      switch eq(and(eq(add(res,b), a), or(lt(res,a), eq(res,a))), 1)
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("minus func underflow");
  }
}

library TokenLib {
  using BasicMathLib for uint256;

  struct TokenStorage {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string name;
    string symbol;
    uint256 totalSupply;
    uint256 INITIAL_SUPPLY;
    address owner;
    uint8 decimals;
    bool stillMinting;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event OwnerChange(address from, address to);
  event Burn(address indexed burner, uint256 value);
  event MintingClosed(bool mintingClosed);

   
   
   
   
   
   
   
  function init(TokenStorage storage self,
                address _owner,
                string _name,
                string _symbol,
                uint8 _decimals,
                uint256 _initial_supply,
                bool _allowMinting)
  {
    require(self.INITIAL_SUPPLY == 0);
    self.name = _name;
    self.symbol = _symbol;
    self.totalSupply = _initial_supply;
    self.INITIAL_SUPPLY = _initial_supply;
    self.decimals = _decimals;
    self.owner = _owner;
    self.stillMinting = _allowMinting;
    self.balances[_owner] = _initial_supply;
  }

   
   
   
   
   
  function transfer(TokenStorage storage self, address _to, uint256 _value) returns (bool) {
    bool err;
    uint256 balance;

    (err,balance) = self.balances[msg.sender].minus(_value);
    require(!err);
    self.balances[msg.sender] = balance;
     
    self.balances[_to] = self.balances[_to] + _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
   
  function transferFrom(TokenStorage storage self,
                        address _from,
                        address _to,
                        uint256 _value)
                        returns (bool)
  {
    var _allowance = self.allowed[_from][msg.sender];
    bool err;
    uint256 balanceOwner;
    uint256 balanceSpender;

    (err,balanceOwner) = self.balances[_from].minus(_value);
    require(!err);

    (err,balanceSpender) = _allowance.minus(_value);
    require(!err);

    self.balances[_from] = balanceOwner;
    self.allowed[_from][msg.sender] = balanceSpender;
    self.balances[_to] = self.balances[_to] + _value;

    Transfer(_from, _to, _value);
    return true;
  }

   
   
   
   
  function balanceOf(TokenStorage storage self, address _owner) constant returns (uint256 balance) {
    return self.balances[_owner];
  }

   
   
   
   
   
  function approve(TokenStorage storage self, address _spender, uint256 _value) returns (bool) {
    self.allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
   
  function allowance(TokenStorage storage self, address _owner, address _spender) constant returns (uint256 remaining) {
    return self.allowed[_owner][_spender];
  }

   
   
   
   
   
   
  function approveChange (TokenStorage storage self, address _spender, uint256 _valueChange, bool _increase)
                          returns (bool)
  {
    uint256 _newAllowed;
    bool err;

    if(_increase) {
      (err, _newAllowed) = self.allowed[msg.sender][_spender].plus(_valueChange);
      require(!err);

      self.allowed[msg.sender][_spender] = _newAllowed;
    } else {
      if (_valueChange > self.allowed[msg.sender][_spender]) {
        self.allowed[msg.sender][_spender] = 0;
      } else {
        _newAllowed = self.allowed[msg.sender][_spender] - _valueChange;
        self.allowed[msg.sender][_spender] = _newAllowed;
      }
    }

    Approval(msg.sender, _spender, _newAllowed);
    return true;
  }

   
   
   
   
  function changeOwner(TokenStorage storage self, address _newOwner) returns (bool) {
    require((self.owner == msg.sender) && (_newOwner > 0));

    self.owner = _newOwner;
    OwnerChange(msg.sender, _newOwner);
    return true;
  }

   
   
   
   
  function mintToken(TokenStorage storage self, uint256 _amount) returns (bool) {
    require((self.owner == msg.sender) && self.stillMinting);
    uint256 _newAmount;
    bool err;

    (err, _newAmount) = self.totalSupply.plus(_amount);
    require(!err);

    self.totalSupply =  _newAmount;
    self.balances[self.owner] = self.balances[self.owner] + _amount;
    Transfer(0x0, self.owner, _amount);
    return true;
  }

   
   
   
  function closeMint(TokenStorage storage self) returns (bool) {
    require(self.owner == msg.sender);

    self.stillMinting = false;
    MintingClosed(true);
    return true;
  }

   
   
   
   
  function burnToken(TokenStorage storage self, uint256 _amount) returns (bool) {
      uint256 _newBalance;
      bool err;

      (err, _newBalance) = self.balances[msg.sender].minus(_amount);
      require(!err);

      self.balances[msg.sender] = _newBalance;
      self.totalSupply = self.totalSupply - _amount;
      Burn(msg.sender, _amount);
      Transfer(msg.sender, 0x0, _amount);
      return true;
  }
}