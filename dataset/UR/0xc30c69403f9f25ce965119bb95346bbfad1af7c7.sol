 

 

pragma solidity ^0.4.26;

interface CompoundERC20 {
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
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

    uint256 startedWithGiftAmount;
    
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
        
        theInterestSender = interestSender;
        theInterestRecipient = interestRecipient;
        
         
        if(theInterestRecipient.add(theInterestSender) != 100){
            throw;
        }
        
        startedWithGiftAmount = 0;
        
        initialCDaiAmount = giftWrap();
      
        
        
    }
    
    function transfer(address _to, uint256 _value) onlyGiftGroup external  returns(bool)  {
        
             
            uint256 usersPercentage;
            if(msg.sender == theRecipient){
                usersPercentage = theInterestRecipient;
            }
            else{
                usersPercentage = theInterestSender;
                
            }
            
            
            uint256 daiSurplus= cdai.balanceOf(this).sub(initialCDaiAmount);
            uint256 amountDaiSurplusUserCanSend  = daiSurplus.mul(usersPercentage).div(100);
            
            uint256 requestedSurplus = _value.sub(initialCDaiAmount);
           
            if(_value <= initialCDaiAmount){
                require(cdai.transfer(_to, _value));
            }
            
             
            else if(requestedSurplus > amountDaiSurplusUserCanSend){
                
                throw;
            }
            else{
                 require(cdai.transfer(_to, _value));
            }
            
             
            initialCDaiAmount = cdai.balanceOf(this);
            
        
            return true;
    }
        
    
    function giftWrap() internal returns (uint256){
      
        ERC20 dai = ERC20(0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359);
        address kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
        IKyberNetworkProxy kyberProxy = IKyberNetworkProxy(kyberProxyAddress);
        cdai = CompoundERC20(0xf5dce57282a584d2746faf1593d3121fcac444dc);
        uint256 ethAmount1 = msg.value;
        PERM_HINT = "PERM";
        ERC20 eth = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
        uint daiAmount = kyberProxy.tradeWithHint.value(ethAmount1)(eth, ethAmount1, dai, this, 8000000000000000000000000000000000000000000000000000000000000000, 0, 0x0000000000000000000000000000000000000004, PERM_HINT);
        dai.approve(address(cdai), 8000000000000000000000000000000000000000000000000000000);
        cdai.mint(daiAmount);
        
        uint256 cdaiAmount = cdai.balanceOf(this);
        startedWithGiftAmount = cdaiAmount;
        return cdaiAmount;
    }
    
    function amountEntitledTo(address qAddress) constant external returns (uint256){
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
            
            
            uint256 daiSurplus= cdai.balanceOf(this).sub(initialCDaiAmount);
            uint256 amountDaiSurplusUserCanSend  = daiSurplus.mul(usersPercentage).div(100);
            
            uint256 amountEntitledTo = initialCDaiAmount.add(daiSurplus);
            return amountEntitledTo;
    }
    
    function getStartedWithGiftAmount() constant external returns (uint256){
        return startedWithGiftAmount;
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
    
    
   
    
    function currentGiftAmount() constant external returns (uint256){
        uint256 cDaiMinted = cdai.balanceOf(this);
        return cDaiMinted;
    }
}