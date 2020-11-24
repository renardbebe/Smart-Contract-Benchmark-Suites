 

pragma solidity ^0.4.18;

interface OysterPearl {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public;
}

contract PearlBonus {
    address public pearlContract = 0x1844b21593262668B7248d0f57a220CaaBA46ab9;
    OysterPearl pearl = OysterPearl(pearlContract);
    
    address public director;
    address public partner;
    uint8 public share;
    uint256 public funds;
    bool public saleClosed;
    
    function PearlBonus() public {
        director = msg.sender;
        partner = 0x36B786f3EC7DE8aC4878980f4B021DE62DDDFF41;
        share = 4;
        funds = 0;
        saleClosed = false;
    }
    
    modifier onlyDirector {
         
        require(msg.sender == director);
        _;
    }
    
     
    function closeSale() public onlyDirector returns (bool success) {
         
        require(!saleClosed);
        
         
        saleClosed = true;
        return true;
    }

     
    function openSale() public onlyDirector returns (bool success) {
         
        require(saleClosed);
        
         
        saleClosed = false;
        return true;
    }
    
    function transfer(address _send, uint256 _amount) public onlyDirector {
        pearl.transfer(_send, _amount);
    }
    
     
    function transferDirector(address newDirector) public onlyDirector {
        director = newDirector;
    }
    
     
    function withdrawFunds() public onlyDirector {
        director.transfer(this.balance);
    }

      
    function () public payable {
         
        require(!saleClosed);
        
         
        require(msg.value >= 1 finney);
        
         
        uint256 amount = msg.value * 6000;
        
        require(amount <= pearl.balanceOf(this));
        
        pearl.transfer(msg.sender, amount);
        
         
        funds += msg.value;
        
         
        uint256 partnerShare = (this.balance / 100) * share;
        director.transfer(this.balance - partnerShare);
        partner.transfer(partnerShare);
    }
}