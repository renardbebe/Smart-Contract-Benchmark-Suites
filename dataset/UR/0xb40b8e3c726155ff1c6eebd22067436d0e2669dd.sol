 

pragma solidity ^0.4.24;

contract BlueChipMain {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract BlueDividends {
    BlueChipMain BlueChipMainContract = BlueChipMain(0xabEFEc93451A2cD5D864fF7b0B1604dFC60e9688);
    
     
    function () public payable {
    }
    
     
     
     
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                 
                break;
            }
            
            BlueChipMainContract.buy.value(address(this).balance)(0x0);
            BlueChipMainContract.exit();
        }
    }
}