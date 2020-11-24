 

pragma solidity 0.4.19;

 

contract Token {
    
     
     
    function balanceOf(address _owner) constant returns (uint balance) {}
    
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success) {}

     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success) {}
    
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}
}

library SafeMath {
    
    function safeMul(uint a, uint b) internal constant returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal constant returns (uint256) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal constant returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

contract EtherToken is Token {

     
    function deposit()
        public
        payable
    {}

     
     
    function withdraw(uint amount)
        public
    {}
}

contract Exchange {

     
     
     
     
     
     
     
     
     
    function fillOrder(
          address[5] orderAddresses,
          uint[6] orderValues,
          uint fillTakerTokenAmount,
          bool shouldThrowOnInsufficientBalanceOrAllowance,
          uint8 v,
          bytes32 r,
          bytes32 s)
          public
          returns (uint filledTakerTokenAmount)
    {}

     
    
     
     
     
     
    function getOrderHash(address[5] orderAddresses, uint[6] orderValues)
        public
        constant
        returns (bytes32)
    {}
    
     
     
     
     
    function getUnavailableTakerTokenAmount(bytes32 orderHash)
        public
        constant
        returns (uint)
    {}
}

contract EtherDelta {
  address public feeAccount;  
  uint public feeTake;  
  
  function deposit() public payable {}

  function withdraw(uint amount) public {}

  function depositToken(address token, uint amount) public {}

  function withdrawToken(address token, uint amount) public {}

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {}

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {}
}

library EtherDeltaTrader {

  address constant public ETHERDELTA_ADDR = 0x8d12a197cb00d4747a1fe03395095ce2a5cc6819;  
  
   
   
  function getEtherDeltaAddresss() internal returns(address) {
      return ETHERDELTA_ADDR;
  }
   
   
   
   
   
   
   
   
   
   
  function fillSellOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint fillTakerTokenAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) {
    
     
    deposit(fillTakerTokenAmount);
    
    uint amountToTrade;
    uint fee;
      
     
    (amountToTrade, fee) = substractFee(exchangeFee, fillTakerTokenAmount);
    
     
    trade(
      orderAddresses,
      orderValues, 
      amountToTrade,
      v, 
      r, 
      s
    );
    
     
    withdrawToken(orderAddresses[1], getPartialAmount(orderValues[0], orderValues[1], amountToTrade));
    
     
    return getPartialAmount(orderValues[0], orderValues[1], amountToTrade);
 
  }
  
   
   
   
   
   
   
   
   
   
  function fillBuyOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint fillTakerTokenAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) {
    
     
    depositToken(orderAddresses[2], fillTakerTokenAmount);
    
    uint amountToTrade;
    uint fee;
      
     
    (amountToTrade, fee) = substractFee(exchangeFee, fillTakerTokenAmount);

     
    trade(
      orderAddresses,
      orderValues, 
      amountToTrade,
      v, 
      r, 
      s
    );
    
     
    withdraw(getPartialAmount(orderValues[0], orderValues[1], amountToTrade));
    
     
    return getPartialAmount(orderValues[0], orderValues[1], amountToTrade);
  }
  
   
   
   
   
   
   
   
  function trade(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint amountToTrade,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
      
      
     EtherDelta(ETHERDELTA_ADDR).trade(
      orderAddresses[2], 
      orderValues[1], 
      orderAddresses[1], 
      orderValues[0], 
      orderValues[2], 
      orderValues[3], 
      orderAddresses[0], 
      v, 
      r, 
      s, 
      amountToTrade
    );
  }
  
   
   
   
   
   
   
   
   
  function getAvailableAmount(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) {
      
     
    if(block.number > orderValues[2])
      return 0;
      
     
    uint availableVolume = EtherDelta(ETHERDELTA_ADDR).availableVolume(
      orderAddresses[2], 
      orderValues[1], 
      orderAddresses[1], 
      orderValues[0], 
      orderValues[2], 
      orderValues[3], 
      orderAddresses[0], 
      v, 
      r, 
      s
    );
    
     
    return getPartialAmount(availableVolume, SafeMath.safeSub(1 ether, exchangeFee), 1 ether);
  }
  
   
   
   
  function substractFee(uint feePercentage, uint amount) constant internal returns(uint, uint) {
    uint fee = getPartialAmount(amount, 1 ether, feePercentage);
    return (SafeMath.safeSub(amount, fee), fee);
  }
  
   
   
  function deposit(uint amount) internal {
    EtherDelta(ETHERDELTA_ADDR).deposit.value(amount)();
  }
  
   
   
   
  function depositToken(address token, uint amount) internal {
    Token(token).approve(ETHERDELTA_ADDR, amount);
    EtherDelta(ETHERDELTA_ADDR).depositToken(token, amount);
  }
  
   
   
  function withdraw(uint amount) internal { 
    EtherDelta(ETHERDELTA_ADDR).withdraw(amount);
  }
   
   
   
   
  function withdrawToken(address token, uint amount) internal { 
    EtherDelta(ETHERDELTA_ADDR).withdrawToken(token, amount);
  }
  
  
   
   
   
   
   
  function getPartialAmount(uint numerator, uint denominator, uint target)
    public
    constant
    returns (uint)
  {
    return SafeMath.safeDiv(SafeMath.safeMul(numerator, target), denominator);
  }

}

library ZrxTrader {
    
  uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;     

  address constant public ZRX_EXCHANGE_ADDR = 0x12459c951127e0c374ff9105dda097662a027093;  
  address constant public TOKEN_TRANSFER_PROXY_ADDR = 0x8da0d80f5007ef1e431dd2127178d224e32c2ef4;  
  address constant public WETH_ADDR = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;  
  address constant public ZRX_TOKEN_ADDR = 0xe41d2489571d322189246dafa5ebde1f4699f498;
  
   
   
  function getWethAddress() internal returns(address) {
      return WETH_ADDR;
  }
  
   
   
   
   
   
   
   
   
  function fillSellOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint fillTakerTokenAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) 
  {
     
     
    depositWeth(fillTakerTokenAmount);
    
     
    aproveToken(WETH_ADDR, fillTakerTokenAmount);
    
     
    aproveToken(ZRX_TOKEN_ADDR, getPartialAmount(fillTakerTokenAmount, orderValues[1], orderValues[3]));
    
    uint ethersSpent = Exchange(ZRX_EXCHANGE_ADDR).fillOrder(
      orderAddresses,
      orderValues,
      fillTakerTokenAmount,
      true,
      v,
      r,
      s
    );
    
     
    return getPartialAmount(orderValues[0], orderValues[1], ethersSpent);
    
  }
  
   
   
   
   
   
   
   
   
  function fillBuyOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint fillTakerTokenAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) 
  {
    
     
    aproveToken(orderAddresses[3], fillTakerTokenAmount);
    
     
    aproveToken(ZRX_TOKEN_ADDR, getPartialAmount(fillTakerTokenAmount, orderValues[1], orderValues[3]));
    
     
    uint tokensSold = Exchange(ZRX_EXCHANGE_ADDR).fillOrder(
      orderAddresses,
      orderValues,
      fillTakerTokenAmount,
      true,
      v,
      r,
      s
    );
    
    uint ethersObtained = getPartialAmount(orderValues[0], orderValues[1], tokensSold);
    
     
    withdrawWeth(ethersObtained);
    
    return ethersObtained;
  }
  
   
   
   
   
   
   
   
  function getAvailableAmount(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) {
      
       
      if(block.timestamp >= orderValues[4])
        return 0;
          
      bytes32 orderHash = Exchange(ZRX_EXCHANGE_ADDR).getOrderHash(orderAddresses, orderValues);
      
      uint unAvailable = Exchange(ZRX_EXCHANGE_ADDR).getUnavailableTakerTokenAmount(orderHash);
  
       
      uint availableByContract = SafeMath.safeSub(orderValues[1], unAvailable);
      
       
      uint availableByBalance =  getPartialAmount(getBalance(orderAddresses[2], orderAddresses[0]), orderValues[0], orderValues[1]);
      
       
      uint availableByAllowance = getPartialAmount(getAllowance(orderAddresses[2], orderAddresses[0]), orderValues[0], orderValues[1]);
    
       
      uint zrxAmount = getAllowance(ZRX_TOKEN_ADDR, orderAddresses[0]);
      uint availableByZRX = getPartialAmount(zrxAmount, orderValues[2], orderValues[1]);
      
       
      return SafeMath.min256(SafeMath.min256(SafeMath.min256(availableByContract, availableByBalance), availableByAllowance), availableByZRX);
  }
    
   
   
  function depositWeth(uint amount) internal {
    EtherToken(WETH_ADDR).deposit.value(amount)();
  }
  
   
   
   
  function aproveToken(address token, uint amount) internal {
    Token(token).approve(TOKEN_TRANSFER_PROXY_ADDR, amount);
  }
  
   
   
  function withdrawWeth(uint amount) internal { 
    EtherToken(WETH_ADDR).withdraw(amount);
  }
  
   
   
   
   
   
  function getPartialAmount(uint numerator, uint denominator, uint target) internal constant returns (uint)
  {
    return SafeMath.safeDiv(SafeMath.safeMul(numerator, target), denominator);
  }

   
   
   
   
  function getBalance(address token, address owner) internal constant returns (uint)
  {
    return Token(token).balanceOf.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner);  
  }

   
   
   
   
  function getAllowance(address token, address owner) internal constant returns (uint)
  {
    return Token(token).allowance.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner, TOKEN_TRANSFER_PROXY_ADDR);  
  }
  
 
}

contract EasyTrade {
    
  string constant public VERSION = "1.0.0";
  address constant public ZRX_TOKEN_ADDR = 0xe41d2489571d322189246dafa5ebde1f4699f498;
  
  address public admin;  
  address public feeAccount;  
  uint public serviceFee;  
  uint public collectedFee = 0;  
 
  event FillSellOrder(address account, address token, uint tokens, uint ethers, uint tokensSold, uint ethersObtained, uint tokensRefunded);
  event FillBuyOrder(address account, address token, uint tokens, uint ethers, uint tokensObtained, uint ethersSpent, uint ethersRefunded);
  
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }
  
  modifier onlyFeeAccount() {
    require(msg.sender == feeAccount);
    _;
  }
 
  function EasyTrade(
    address admin_,
    address feeAccount_,
    uint serviceFee_) 
  {
    admin = admin_;
    feeAccount = feeAccount_;
    serviceFee = serviceFee_;
  } 
    
   
  function() public payable { 
       
      require(msg.sender == ZrxTrader.getWethAddress() || msg.sender == EtherDeltaTrader.getEtherDeltaAddresss());
  }

   
   
  function changeAdmin(address admin_) public onlyAdmin {
    admin = admin_;
  }
  
   
   
  function changeFeeAccount(address feeAccount_) public onlyAdmin {
    feeAccount = feeAccount_;
  }

   
   
  function changeFeePercentage(uint serviceFee_) public onlyAdmin {
    require(serviceFee_ < serviceFee);
    serviceFee = serviceFee_;
  }
  
   
   
   
   
   
   
   
   
   
   
   
   
   
  function createSellOrder(
    address token, 
    uint tokensTotal, 
    uint ethersTotal,
    uint8[] exchanges,
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] exchangeFees,
    uint8[] v,
    bytes32[] r,
    bytes32[] s
  ) public
  {
    
     
    require(Token(token).transferFrom(msg.sender, this, tokensTotal));
    
    uint ethersObtained;
    uint tokensSold;
    uint tokensRefunded = tokensTotal;
    
    (ethersObtained, tokensSold) = fillOrdersForSellRequest(
      tokensTotal,
      exchanges,
      orderAddresses,
      orderValues,
      exchangeFees,
      v,
      r,
      s
    );
    
     
    require(ethersObtained > 0 && tokensSold >0);
    
     
    require(SafeMath.safeDiv(ethersTotal, tokensTotal) <= SafeMath.safeDiv(ethersObtained, tokensSold));
    
     
    tokensRefunded = SafeMath.safeSub(tokensTotal, tokensSold);
    
     
    if(tokensRefunded > 0) 
     require(Token(token).transfer(msg.sender, tokensRefunded));
    
     
    transfer(msg.sender, ethersObtained);
    
    FillSellOrder(msg.sender, token, tokensTotal, ethersTotal, tokensSold, ethersObtained, tokensRefunded);
  }
  
   
   
   
   
   
   
   
   
   
   
  function fillOrdersForSellRequest(
    uint tokensTotal,
    uint8[] exchanges,
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] exchangeFees,
    uint8[] v,
    bytes32[] r,
    bytes32[] s
  ) internal returns(uint, uint)
  {
    uint totalEthersObtained = 0;
    uint tokensRemaining = tokensTotal;
    
    for (uint i = 0; i < orderAddresses.length; i++) {
   
      (totalEthersObtained, tokensRemaining) = fillOrderForSellRequest(
         totalEthersObtained,
         tokensRemaining,
         exchanges[i],
         orderAddresses[i],
         orderValues[i],
         exchangeFees[i],
         v[i],
         r[i],
         s[i]
      );

    }
    
     
    if(totalEthersObtained > 0) {
      uint fee =  SafeMath.safeMul(totalEthersObtained, serviceFee) / (1 ether);
      totalEthersObtained = collectServiceFee(SafeMath.min256(fee, totalEthersObtained), totalEthersObtained);
    }
    
     
    return (totalEthersObtained, SafeMath.safeSub(tokensTotal, tokensRemaining));
  }
  
   
   
   
   
   
   
   
   
   
   
   
  function fillOrderForSellRequest(
    uint totalEthersObtained,
    uint initialTokensRemaining,
    uint8 exchange,
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) internal returns(uint, uint)
  {
    uint ethersObtained = 0;
    uint tokensRemaining = initialTokensRemaining;
    
     
    require(exchangeFee < 10000000000000000);
    
     
    uint fillAmount = getFillAmount(
      tokensRemaining,
      exchange,
      orderAddresses,
      orderValues,
      exchangeFee,
      v,
      r,
      s
    );
    
    if(fillAmount > 0) {
          
       
      tokensRemaining = SafeMath.safeSub(tokensRemaining, fillAmount);
    
      if(exchange == 0) {
         
        ethersObtained = EtherDeltaTrader.fillBuyOrder(
          orderAddresses,
          orderValues,
          exchangeFee,
          fillAmount,
          v,
          r,
          s
        );    
      } 
      else {
         
        ethersObtained = ZrxTrader.fillBuyOrder(
          orderAddresses,
          orderValues,
          fillAmount,
          v,
          r,
          s
        );
        
         
        uint fee = SafeMath.safeMul(ethersObtained, exchangeFee) / (1 ether);
        ethersObtained = collectServiceFee(fee, ethersObtained);
    
      }
    }
         
     
    return (SafeMath.safeAdd(totalEthersObtained, ethersObtained), ethersObtained==0? initialTokensRemaining: tokensRemaining);
   
  }
  
   
   
   
   
   
   
   
   
   
   
  function createBuyOrder(
    address token, 
    uint tokensTotal,
    uint8[] exchanges,
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] exchangeFees,
    uint8[] v,
    bytes32[] r,
    bytes32[] s
  ) public payable 
  {
    
    
    uint ethersTotal = msg.value;
    uint tokensObtained;
    uint ethersSpent;
    uint ethersRefunded = ethersTotal;
     
    require(tokensTotal > 0 && msg.value > 0);
    
    (tokensObtained, ethersSpent) = fillOrdersForBuyRequest(
      ethersTotal,
      exchanges,
      orderAddresses,
      orderValues,
      exchangeFees,
      v,
      r,
      s
    );
    
     
    require(ethersSpent > 0 && tokensObtained >0);
    
     
    require(SafeMath.safeDiv(ethersTotal, tokensTotal) >= SafeMath.safeDiv(ethersSpent, tokensObtained));

     
    ethersRefunded = SafeMath.safeSub(ethersTotal, ethersSpent);
    
     
    if(ethersRefunded > 0)
     require(msg.sender.call.value(ethersRefunded)());
   
     
    transferToken(token, msg.sender, tokensObtained);
    
    FillBuyOrder(msg.sender, token, tokensTotal, ethersTotal, tokensObtained, ethersSpent, ethersRefunded);
  }
  
   
   
   
   
   
   
   
   
   
   
   
  function fillOrdersForBuyRequest(
    uint ethersTotal,
    uint8[] exchanges,
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] exchangeFees,
    uint8[] v,
    bytes32[] r,
    bytes32[] s
  ) internal returns(uint, uint)
  {
    uint totalTokensObtained = 0;
    uint ethersRemaining = ethersTotal;
    
    for (uint i = 0; i < orderAddresses.length; i++) {
    
      if(ethersRemaining > 0) {
        (totalTokensObtained, ethersRemaining) = fillOrderForBuyRequest(
          totalTokensObtained,
          ethersRemaining,
          exchanges[i],
          orderAddresses[i],
          orderValues[i],
          exchangeFees[i],
          v[i],
          r[i],
          s[i]
        );
      }
    
    }
    
     
    return (totalTokensObtained, SafeMath.safeSub(ethersTotal, ethersRemaining));
  }
  
   
   
   
   
   
   
   
   
   
   
   
   
  function fillOrderForBuyRequest(
    uint totalTokensObtained,
    uint initialEthersRemaining,
    uint8 exchange,
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint, uint)
  {
    uint tokensObtained = 0;
    uint ethersRemaining = initialEthersRemaining;
       
     
    require(exchangeFee < 10000000000000000);
     
     
    uint fillAmount = getFillAmount(
      ethersRemaining,
      exchange,
      orderAddresses,
      orderValues,
      exchangeFee,
      v,
      r,
      s
    );
   
    if(fillAmount > 0) {
     
       
      ethersRemaining = SafeMath.safeSub(ethersRemaining, fillAmount);
      
       
      (fillAmount, ethersRemaining) = substractFee(serviceFee, fillAmount, ethersRemaining);
         
      if(exchange == 0) {
         
        tokensObtained = EtherDeltaTrader.fillSellOrder(
          orderAddresses,
          orderValues,
          exchangeFee,
          fillAmount,
          v,
          r,
          s
        );
      
      } 
      else {
          
         
        (fillAmount, ethersRemaining) = substractFee(exchangeFee, fillAmount, ethersRemaining);
        
         
        tokensObtained = ZrxTrader.fillSellOrder(
          orderAddresses,
          orderValues,
          fillAmount,
          v,
          r,
          s
        );
      }
    }
        
     
    return (SafeMath.safeAdd(totalTokensObtained, tokensObtained), tokensObtained==0? initialEthersRemaining: ethersRemaining);
  }
  
  
   
   
   
   
   
   
   
   
   
  function getFillAmount(
    uint amount,
    uint8 exchange,
    address[5] orderAddresses,
    uint[6] orderValues,
    uint exchangeFee,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal returns(uint) 
  {
    uint availableAmount;
    if(exchange == 0) {
      availableAmount = EtherDeltaTrader.getAvailableAmount(
        orderAddresses,
        orderValues,
        exchangeFee,
        v,
        r,
        s
      );    
    } 
    else {
      availableAmount = ZrxTrader.getAvailableAmount(
        orderAddresses,
        orderValues,
        v,
        r,
        s
      );
    }
     
    return SafeMath.min256(amount, availableAmount);
  }
  
   
   
   
   
   
  function substractFee(
    uint feePercentage,
    uint fillAmount,
    uint ethersRemaining
  ) internal returns(uint, uint) 
  {       
      uint fee = SafeMath.safeMul(fillAmount, feePercentage) / (1 ether);
       
      if(ethersRemaining >= fee)
         ethersRemaining = collectServiceFee(fee, ethersRemaining);
      else {
         fillAmount = collectServiceFee(fee, SafeMath.safeAdd(fillAmount, ethersRemaining));
         ethersRemaining = 0;
      }
      return (fillAmount, ethersRemaining);
  }
  
   
   
   
   
  function collectServiceFee(uint fee, uint amount) internal returns(uint) {
    collectedFee = SafeMath.safeAdd(collectedFee, fee);
    return SafeMath.safeSub(amount, fee);
  }
  
   
   
   
  function transfer(address account, uint amount) internal {
    require(account.send(amount));
  }
    
   
   
   
   
  function transferToken(address token, address account, uint amount) internal {
    require(Token(token).transfer(account, amount));
  }
   
   
   
  function withdrawFees(uint amount) public onlyFeeAccount {
    require(collectedFee >= amount);
    collectedFee = SafeMath.safeSub(collectedFee, amount);
    require(feeAccount.send(amount));
  }
  
   
   
   
  function withdrawZRX(uint amount) public onlyAdmin {
    require(Token(ZRX_TOKEN_ADDR).transfer(admin, amount));
  }
}