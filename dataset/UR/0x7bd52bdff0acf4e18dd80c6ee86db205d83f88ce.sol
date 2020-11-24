 

pragma solidity ^0.4.18;
 
contract HodlerInvestmentClub {
    uint public hodl_interval= 1 years;
    uint public m_hodlers = 1;
    
    struct Hodler {
        uint value;
        uint time;
    }
    
    mapping(address => Hodler) public hodlers;
    
    modifier onlyHodler {
        require(hodlers[msg.sender].value > 0);
        _;
    }
    
     
    function HodlerInvestmentClub() payable public {
        if (msg.value > 0)  {
            hodlers[msg.sender].value = msg.value;
            hodlers[msg.sender].time = now + hodl_interval;
        }
    }
    
     
     
     
    function deposit(address _to) payable public {
        require(msg.value > 0);
        if (_to == 0) _to = msg.sender;
         
        if (hodlers[_to].time == 0) {
            hodlers[_to].time = now + hodl_interval;
            m_hodlers++;
        } 
        hodlers[_to].value += msg.value;
    }
    
     
    function withdraw() public onlyHodler {
        require(hodlers[msg.sender].time <= now);
        uint256 value = hodlers[msg.sender].value;
        delete hodlers[msg.sender];
        m_hodlers--;
        require(msg.sender.send(value));
    }
    
     
     
    function() payable public {
        require(msg.value > 0);
        hodlers[msg.sender].value += msg.value;
         
        if (hodlers[msg.sender].time == 0) {
            hodlers[msg.sender].time = now + hodl_interval;
            m_hodlers++;
        }
    }

}