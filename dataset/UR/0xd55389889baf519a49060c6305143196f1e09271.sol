 

pragma solidity ^0.4.11;

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


interface SKWInterface {
     
    function transfer(address _to, uint256 _value) external returns (bool success);

}

contract SKWVesting2 {
    
    using SafeMath for uint256;
    
    address public _beneficiary = 0x0; 
    
    uint256 public unLockTime_1;
    
    uint256 public unLockTime_2;
    
    uint256 public unLockTime_3;
    
    uint256 public unLockTime_4;
    
    uint256 public unLockTime_5;
    
    uint256 public unLockTime_6;
    
    uint256 public released; 
    
    uint256 public totalBalance; 
    
    bool public test = false;
    
    SKWInterface constant _token = SKWInterface(0x007ac2F589eb9d4Fe1cEA9f46B5f4f52DaB73dd4);
    
    event Released(uint256 amount);
    
    event TsetReleased(uint256 amount);
    
    constructor() public {
       _beneficiary = 0xe00E02E84B6C223495e864308B6CcBB16106671a;
       unLockTime_1 = 1543075200; 
       unLockTime_2 = 1545667200; 
       unLockTime_3 = 1548345600; 
       unLockTime_4 = 1551024000; 
       unLockTime_5 = 1553443200; 
       unLockTime_6 = 1556121600; 
       totalBalance = 5000000000000000; 
       released = 0;
    }
    
    function release() public { 
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);
        released = released.add(unreleased);
        _token.transfer(_beneficiary, unreleased);
        emit Released(unreleased);
    }
    
    function releasableAmount() public view returns (uint256){
        uint num = getUnLockNum();
        if(num > 0 ){
            uint256 currentBalance = totalBalance.div(6).mul(num) - released;
            return currentBalance;
        }else{
            return 0;
        }
    }
    
    function getUnLockNum() public view returns (uint){
        uint256 n = now;
        if(n < unLockTime_1){
            return 0;
        }else if(n >= unLockTime_1 && n < unLockTime_2){
            return 1;
        }else if(n >= unLockTime_2 && n < unLockTime_3){
            return 2;
        }else if(n >= unLockTime_3 && n < unLockTime_4){
            return 3;
        }else if(n >= unLockTime_4 && n < unLockTime_5){
            return 4;
        }else if(n >= unLockTime_5 && n < unLockTime_6){
            return 5;
        }else {
            return 6;
        }
    }
    
    function testRelease() public { 
        require(!test);
        uint256 unreleased = 1000000;
        test = true;
        _token.transfer(_beneficiary, unreleased);
        emit TsetReleased(unreleased);
    }
    
}