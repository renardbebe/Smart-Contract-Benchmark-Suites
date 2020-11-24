 

pragma solidity ^0.4.25;

 

contract Pandora {
    using SafeMath for uint256;
     
    uint constant DAY_PERC = 2;
     
    address constant MARKETING = 0xf3b7229fD298031C39D4368066cc7995649f321b;
     
    uint constant RETURN_DEPOSIT = 0.000911 ether;
     
    uint constant RETURN_PERCENT = 60;
    
    struct Investor {
        uint invested;
        uint paid;
        address referral;
        uint lastBlockReward;
    }
    
    mapping (address => Investor) public investors;
    
    function() public payable {
        
        if(msg.value == 0) {
            payReward();
        }else{
            
            if (msg.value == RETURN_DEPOSIT){
                returnDeposit();
            }else {
                
                if (investors[msg.sender].invested == 0){
                    addInvestor();
                }else{
                    payReward();
                }
                payToMarketingReferral();
            }
        }
    }
    
    function addInvestor() internal   {
        
        address ref;
        
        if (msg.data.length != 0){
            address referrer = bytesToAddress(msg.data); 
        }
        
        if(investors[referrer].invested > 0){
            ref = referrer;
        }else{
            ref = MARKETING;
        }
        
        Investor memory investor;
        
        investor = Investor({
            invested : msg.value,
            paid : 0,
            referral : ref,
            lastBlockReward : block.number
        });
        
        investors[msg.sender] = investor;
        
    }
    
    function payReward() internal {
        Investor memory investor;
        investor = investors[msg.sender];
        
        if (investor.invested != 0) {
            uint getPay = investor.invested*DAY_PERC/100*(block.number-investor.lastBlockReward)/5900;
            uint sumPay = getPay.add(investor.paid);
            
            if (sumPay > investor.invested.mul(2)) {
                getPay = investor.invested.mul(2).sub(investor.paid);
                investor.paid = 0;
                investor.lastBlockReward = block.number;
                investor.invested = msg.value;  
            }else{
                investor.paid += getPay;
                investor.lastBlockReward = block.number;
                investor.invested += msg.value;  
            }
            
            investors[msg.sender] = investor;
            
            if(address(this).balance < getPay){
                getPay = address(this).balance;
            }
            
            msg.sender.transfer(getPay);
        }
    }
    
    function returnDeposit() internal {
        
            if (msg.value == RETURN_DEPOSIT){

                Investor memory investor;
                investor = investors[msg.sender];
                
                if (investor.invested != 0){
                    uint getPay = ((investor.invested.sub(investor.paid)).mul(RETURN_PERCENT).div(100)).sub(msg.value);
                    msg.sender.transfer(getPay);
                    investor.paid = 0;
                    investor.invested = 0;
                    investors[msg.sender] = investor;
                }
            }
    }
    
    function payToMarketingReferral() internal  {
        
        address referral = investors[msg.sender].referral;
        
        if (referral == MARKETING)    {
            MARKETING.send(msg.value / 10); 
        }else{
            MARKETING.send(msg.value / 20); 
            referral.send(msg.value / 20); 
        }
        
    }
    
    function bytesToAddress(bytes _b) private pure returns (address addr) {
        assembly {
            addr := mload(add(_b, 20))
        }
     }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}