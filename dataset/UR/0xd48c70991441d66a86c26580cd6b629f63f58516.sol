 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

  
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract SVGCrowdsale {
    
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public weiRaised;
  
   
  uint256 public currentRound;
  
   
  uint startTime = now;
  
   
  uint256 public completedAt;
  
   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  
  event LogFundingSuccessful(
      uint _totalRaised
    );

   
  constructor(address _wallet, ERC20 _token) public {
    require(_wallet != address(0));
    require(_token != address(0));

    wallet = _wallet;
    token = _token;
  }
  
   
    uint[5] tablePrices = [
        13334,
        11429,
        10000,
        9091,
        8000
    ];  
  
   
    uint256[5] caps = [
        10000500e18,
        10000375e18,
        10000000e18,
        10000100e18,
        10000000e18
    ];  
  
   
  enum Tranches {
        Round1,
        Round2,
        Round3,
        Round4,
        Round5,
        Successful
  }
  
  Tranches public tranches = Tranches.Round1;  
  

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    processPurchase(_beneficiary, tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    updatePurchasingState(_beneficiary, weiAmount);

    forwardFunds();
    
    checkIfFundingCompleteOrExpired();
    
    postValidatePurchase(_beneficiary, weiAmount);
  }
  
   
  
  function checkIfFundingCompleteOrExpired() internal {
      
    if(tranches != Tranches.Successful){
        
        if(currentRound > caps[0] && tranches == Tranches.Round1){ 
            tranches = Tranches.Round2;
            currentRound = 0;    
        }
        else if(currentRound > caps[1] && tranches == Tranches.Round2){  
            tranches = Tranches.Round3;
            currentRound = 0;    
        }
        else if(currentRound > caps[2] && tranches == Tranches.Round3){  
            tranches = Tranches.Round4;
            currentRound = 0;    
        }
        else if(currentRound > caps[3] && tranches == Tranches.Round4){  
            tranches = Tranches.Round5;
            currentRound = 0; 
        }
    }
    else {
        tranches = Tranches.Successful;
        completedAt = now;
    }
      
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal{
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function processPurchase(address _beneficiary, uint256 _tokenAmount )internal{
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    
    uint256 tokenBought;
    
    if(tranches == Tranches.Round1){
        
        tokenBought = _weiAmount.mul(tablePrices[0]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[0]);
        
    }else if(tranches == Tranches.Round2){
        
        tokenBought = _weiAmount.mul(tablePrices[1]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[1]);            
        
    }else if(tranches == Tranches.Round3){
        
        tokenBought = _weiAmount.mul(tablePrices[2]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[2]);
        
    }else if(tranches == Tranches.Round4){
        
        tokenBought = _weiAmount.mul(tablePrices[3]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[3]);
        
    }else if(tranches == Tranches.Round5){
        
        tokenBought = _weiAmount.mul(tablePrices[4]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[4]); 
        
    }else{
        revert();
    }
    
    return tokenBought;    
    
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
}