 

pragma solidity ^0.5.0;

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
    
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract dominance {
    using SafeMath for uint;
    
    address public admin = 0xCf5BB540e63d87A104C071770eBfAEF40392aC95;
    address public dev = 0x0b60946a9C39B7b1ab220562b0638244beD3f958;
    uint public hardcap1 = 720 ether;
    uint public hardcap2 = 2800 ether;
    uint public currentcap = 0;
    uint public currentround = 1;
    bool open = true;
    uint public hardcap = hardcap1;
    
    constructor() public{
    }
    
    function deposit(address _referredBy) payable public {
        require(open);
        require(msg.value >= 0.33 ether);
        uint value = msg.value;
         
        currentcap += msg.value;
        if (currentcap >= hardcap && currentround == 1) {
                currentcap = 0;
                hardcap = hardcap2;
                currentround = 2;
        }
        else if(currentcap >= hardcap && currentround == 2){
            open = false;
        }
        
        uint referbalance = value.div(4);
        address payable _referral = address(uint160(_referredBy));
        _referral.transfer(referbalance);
        value -= referbalance;
        
        uint devbalance = msg.value.div(100);
        address payable _dev = address(uint160(dev));
        _dev.transfer(devbalance);
        value -= devbalance;
        
        address payable _admin = address(uint160(admin));
        _admin.transfer(value);
       
    }
    
    function () payable external {
       require(false);
    }
}