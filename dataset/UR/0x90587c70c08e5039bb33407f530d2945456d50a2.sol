 

 

pragma solidity ^0.4.26;

interface CompoundERC20 {
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  function redeem(uint redeemTokens) external returns (uint);
  function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function exchangeRateStored() public view returns (uint256 exchangeRate);
}
interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) external payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns (uint);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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




interface ERC20 {
    function totalSupply() public view returns(uint supply);

    function balanceOf(address _owner) public view returns(uint balance);

    function transfer(address _to, uint _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint _value) public returns(bool success);

    function approve(address _spender, uint _value) public returns(bool success);

    function allowance(address _owner, address _spender) public view returns(uint remaining);

    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract GiftOfCompound {
    
    using SafeMath for uint256;
    address theRecipient;
    address theSender;
    bytes PERM_HINT;
    uint256 initialCDaiAmount;
    uint256 theInterestRecipient;
    uint256 theInterestSender;

    uint256 initialDaiAmount;
    uint256 initialcDaiDaiRate;
    
    uint256 startedWithGiftAmount;
    uint256 internal PRECISION;
    
    uint256 valueChange2Result;
     
    CompoundERC20 cdai;
    
     modifier onlyGiftGroup() {
        if (msg.sender != theSender && msg.sender != theRecipient) {
            throw;
        }
        _;
    }
    
     
    function() payable {
        throw;
    }
    
    
    
    
    
    

    constructor(address recipient, uint256 interestRecipient, uint256 interestSender) public payable {
        
        if(msg.value <= 0){
            throw;
        }
        
        theSender = msg.sender;
        theRecipient = recipient;
        
        PRECISION = 10 ** 27;
        theInterestSender = interestSender;
        theInterestRecipient = interestRecipient;
        
         
        if(theInterestRecipient.add(theInterestSender) != 100){
            throw;
        }
        
        startedWithGiftAmount = 0;
        
        initialCDaiAmount = giftWrap();
      
        
        
    }
    
    function transfer(address _to, uint256 _value) onlyGiftGroup  returns(bool)  {
        
           uint256  userHasAccessTo = amountEntitledTo(msg.sender);
            ERC20 dai = ERC20(0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359);
              
            if(_value > userHasAccessTo){
                
                throw;
            }
            
          
            
          
            else{
                 cdai.redeem(_value);
                uint256 currentDai = dai.balanceOf(this);
                require(dai.transfer(_to, currentDai));
            }
            
             
            initialCDaiAmount = cdai.balanceOf(this);
            
        
            return true;
    }
        
    
    function giftWrap() internal returns (uint256){
      
        ERC20 dai = ERC20(0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359);
        address kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
        IKyberNetworkProxy kyberProxy = IKyberNetworkProxy(kyberProxyAddress);
        cdai = CompoundERC20(0xf5dce57282a584d2746faf1593d3121fcac444dc);
        
        theRecipient.send(1500000000000000);
        
        uint256 ethAmount1 = msg.value.sub(1500000000000000);
        
        PERM_HINT = "PERM";
        ERC20 eth = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
        uint daiAmount = kyberProxy.tradeWithHint.value(ethAmount1)(eth, ethAmount1, dai, this, 8000000000000000000000000000000000000000000000000000000000000000, 0, 0x0000000000000000000000000000000000000004, PERM_HINT);
        dai.approve(address(cdai), 8000000000000000000000000000000000000000000000000000000);
        cdai.mint(daiAmount);
        
        uint256 cdaiAmount = cdai.balanceOf(this);
        startedWithGiftAmount = cdaiAmount;
        initialDaiAmount = daiAmount;
        initialcDaiDaiRate = cdai.exchangeRateStored();
        return cdaiAmount;
    }
    
    function amountEntitledTo(address qAddress) constant  returns (uint256){
           
           
           
          
           
           
           
          
          
          uint256 initialExchangeRate  =  initialcDaiDaiRate;
          uint multiplier = 10000000;
          uint256 currentExchangeRate  = cdai.exchangeRateStored().mul(multiplier); 
          
          uint256 valueChange = currentExchangeRate.div(initialExchangeRate);
          uint256 valueChange2 = initialCDaiAmount.mul(valueChange).div(multiplier);
          
          valueChange2Result = valueChange2;
          
          uint256 totalInterestEarned = valueChange2.sub(initialCDaiAmount);
          
           uint256 usersPercentage;
            if(qAddress== theRecipient){
                usersPercentage = theInterestSender;
            }
            else if (qAddress == theSender){
                usersPercentage = theInterestSender;
                
            }
            else{
                return 0;
            }
            
            uint256 tInterestEntitledTo = totalInterestEarned.mul(usersPercentage).div(100);
            
            uint256 amountITo;
            
            if(qAddress== theRecipient){
                amountITo = initialCDaiAmount.sub(tInterestEntitledTo);
            }
            if(qAddress== theSender){
                if(initialCDaiAmount == startedWithGiftAmount){
                     
                    amountITo = initialCDaiAmount;
                }
                else{
                    amountITo = tInterestEntitledTo;
                }
              
            }
            
           uint256 responseAmount = amountITo;
            
            return responseAmount;
          
    }
    
    function getStartedWithGiftAmount() constant external returns (uint256){
        return startedWithGiftAmount;
    }
    
    function getStartedWithDaiValueAmount() constant external returns (uint256){
        return initialDaiAmount;
    }
    function getStartedWithCDaiDaiRate() constant external returns (uint256){
        return initialcDaiDaiRate;
    }
    
    
    
    function getRecipient() constant external returns (address){
        return theRecipient;
    }
    
    function getSender() constant external returns (address){
        return theSender;
    }
    
    function percentageInterestEntitledTo(address qAddress) constant external returns (uint256){
            uint256 usersPercentage;
            if(qAddress== theRecipient){
                usersPercentage = theInterestRecipient;
            }
            else if (qAddress == theSender){
                usersPercentage = theInterestSender;
                
            }
            else{
                return 0;
            }
            
           return usersPercentage;
    }
    
    function valueChangeVal() constant external returns (uint256){
      
        uint256 initialExchangeRate  =  initialcDaiDaiRate;
          uint multiplier = 10000000;
          uint256 currentExchangeRate  = cdai.exchangeRateStored().mul(multiplier); 
          
          uint256 valueChange = currentExchangeRate.div(initialExchangeRate);
          uint256 valueChange2 = initialCDaiAmount.mul(valueChange).div(multiplier);
          uint256 totalInterestEarned = valueChange2.sub(initialCDaiAmount);
          
          return totalInterestEarned;
    }
    
   
    
    function currentGiftAmount() constant external returns (uint256){
        uint256 cDaiMinted = cdai.balanceOf(this);
        return cDaiMinted;
    }
}