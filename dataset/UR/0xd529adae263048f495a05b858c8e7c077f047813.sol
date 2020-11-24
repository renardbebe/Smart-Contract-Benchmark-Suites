 

pragma solidity ^0.4.24;

contract FUNDS {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract FUNDSDividends {
    FUNDS fundsContract = FUNDS(0x7E0529Eb456a7C806B5Fe7B3d69a805339A06180);
    
     
    function () public payable {
    }
    
     
     
     
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                 
                break;
            }
            
            fundsContract.buy.value(address(this).balance)(0x0);
            fundsContract.exit();
        }
    }
}