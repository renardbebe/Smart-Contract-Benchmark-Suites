 

pragma solidity ^0.4.18;
 

 
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
     
    uint256 c = a / b;
     
    return c;
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
   
  function Ownable() public{
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

contract token {

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);

}


contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  token public token_reward;
   
  
  uint256 public start_time = now;  
   
  uint256 public end_Time = 1524355200;  

  uint256 public phase_1_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_2_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_3_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_4_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_5_remaining_tokens  = 50000000 * (10 ** uint256(8));

  uint256 public phase_1_bonus  = 40;
  uint256 public phase_2_bonus  = 20;
  uint256 public phase_3_bonus  = 15;
  uint256 public phase_4_bonus  = 10;
  uint256 public phase_5_bonus  = 5;

  uint256 public token_price  = 2; 

   
  address public wallet;
   
  uint256 public eth_to_usd = 1000;
   
  uint256 public weiRaised;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  event EthToUsdChanged(address indexed owner, uint256 old_eth_to_usd, uint256 new_eth_to_usd);
  
   
  function Crowdsale(address tokenContractAddress) public{
    wallet = 0x1aC024482b91fa9AaF22450Ff60680BAd60bF8D3; 
    token_reward = token(tokenContractAddress);
  }
  
 function tokenBalance() constant public returns (uint256){
    return token_reward.balanceOf(this);
  }

  function getRate() constant public returns (uint256){
    return eth_to_usd.mul(100).div(token_price);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool allPhaseFinished = phase_5_remaining_tokens > 0;
    bool nonZeroPurchase = msg.value != 0;
    bool minPurchase = eth_to_usd*msg.value >= 100;  
    return withinPeriod && nonZeroPurchase && allPhaseFinished && minPurchase;
  }

   
  function validPurchaseForManual() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool allPhaseFinished = phase_5_remaining_tokens > 0;
    return withinPeriod && allPhaseFinished;
  }


   
  function checkAndUpdateTokenForManual(uint256 _tokens) internal returns (bool){
    if(phase_1_remaining_tokens > 0){
      if(_tokens > phase_1_remaining_tokens){
        uint256 tokens_from_phase_2 = _tokens.sub(phase_1_remaining_tokens);
        phase_1_remaining_tokens = 0;
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(tokens_from_phase_2);
      }else{
        phase_1_remaining_tokens = phase_1_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_2_remaining_tokens > 0){
      if(_tokens > phase_2_remaining_tokens){
        uint256 tokens_from_phase_3 = _tokens.sub(phase_2_remaining_tokens);
        phase_2_remaining_tokens = 0;
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(tokens_from_phase_3);
      }else{
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_3_remaining_tokens > 0){
      if(_tokens > phase_3_remaining_tokens){
        uint256 tokens_from_phase_4 = _tokens.sub(phase_3_remaining_tokens);
        phase_3_remaining_tokens = 0;
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(tokens_from_phase_4);
      }else{
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_4_remaining_tokens > 0){
      if(_tokens > phase_4_remaining_tokens){
        uint256 tokens_from_phase_5 = _tokens.sub(phase_4_remaining_tokens);
        phase_4_remaining_tokens = 0;
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(tokens_from_phase_5);
      }else{
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_5_remaining_tokens > 0){
      if(_tokens > phase_5_remaining_tokens){
        return false;
      }else{
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(_tokens);
       }
    }else{
      return false;
    }
  }

   
  function transferManually(uint256 _tokens, address to_address) onlyOwner public returns (bool){
    require(to_address != 0x0);
    require(validPurchaseForManual());
    require(checkAndUpdateTokenForManual(_tokens));
    token_reward.transfer(to_address, _tokens);
    return true;
  }


   
  function transferIfTokenAvailable(uint256 _tokens, uint256 _weiAmount, address _beneficiary) internal returns (bool){

    uint256 total_token_to_transfer = 0;
    uint256 bonus = 0;
    if(phase_1_remaining_tokens > 0){
      if(_tokens > phase_1_remaining_tokens){
        uint256 tokens_from_phase_2 = _tokens.sub(phase_1_remaining_tokens);
        bonus = (phase_1_remaining_tokens.mul(phase_1_bonus).div(100)).add(tokens_from_phase_2.mul(phase_2_bonus).div(100));
        phase_1_remaining_tokens = 0;
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(tokens_from_phase_2);
      }else{
        phase_1_remaining_tokens = phase_1_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_1_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_2_remaining_tokens > 0){
      if(_tokens > phase_2_remaining_tokens){
        uint256 tokens_from_phase_3 = _tokens.sub(phase_2_remaining_tokens);
        bonus = (phase_2_remaining_tokens.mul(phase_2_bonus).div(100)).add(tokens_from_phase_3.mul(phase_3_bonus).div(100));
        phase_2_remaining_tokens = 0;
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(tokens_from_phase_3);
      }else{
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_2_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_3_remaining_tokens > 0){
      if(_tokens > phase_3_remaining_tokens){
        uint256 tokens_from_phase_4 = _tokens.sub(phase_3_remaining_tokens);
        bonus = (phase_3_remaining_tokens.mul(phase_3_bonus).div(100)).add(tokens_from_phase_4.mul(phase_4_bonus).div(100));
        phase_3_remaining_tokens = 0;
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(tokens_from_phase_4);
      }else{
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_3_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_4_remaining_tokens > 0){
      if(_tokens > phase_4_remaining_tokens){
        uint256 tokens_from_phase_5 = _tokens.sub(phase_4_remaining_tokens);
        bonus = (phase_4_remaining_tokens.mul(phase_4_bonus).div(100)).add(tokens_from_phase_5.mul(phase_5_bonus).div(100));
        phase_4_remaining_tokens = 0;
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(tokens_from_phase_5);
      }else{
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_4_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_5_remaining_tokens > 0){
      if(_tokens > phase_5_remaining_tokens){
        total_token_to_transfer = 0;
      }else{
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_5_bonus).div(100);
        total_token_to_transfer = _tokens + bonus;
      }
    }else{
      total_token_to_transfer = 0;
    }
    if(total_token_to_transfer > 0){
      token_reward.transfer(_beneficiary, total_token_to_transfer);
      TokenPurchase(msg.sender, _beneficiary, _weiAmount, total_token_to_transfer);
      return true;
    }else{
      return false;
    }
    
  }

   
  function () payable public{
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    uint256 tokens = (weiAmount.mul(getRate())).div(10 ** uint256(10));
     
    require(transferIfTokenAvailable(tokens, weiAmount, beneficiary));
     
    weiRaised = weiRaised.add(weiAmount);
    
    forwardFunds();
  }
  
   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
   
  function hasEnded() public constant returns (bool) {
    return now > end_Time;
  }
   
  function transferBack(uint256 tokens, address to_address) onlyOwner public returns (bool){
    token_reward.transfer(to_address, tokens);
    return true;
  }
   
  function changeEth_to_usd(uint256 _eth_to_usd) onlyOwner public returns (bool){
    EthToUsdChanged(msg.sender, eth_to_usd, _eth_to_usd);
    eth_to_usd = _eth_to_usd;
    return true;
  }
}