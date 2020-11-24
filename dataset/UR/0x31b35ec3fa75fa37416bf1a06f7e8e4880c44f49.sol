 

 


pragma solidity ^0.4.24;

contract DiamondDividendsMain {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract DiamondDividends {
    DiamondDividendsMain DiamondDividendsMainContract = DiamondDividendsMain(0x84CC06edDB26575A7F0AFd7eC2E3e98D31321397);
    
     
    function () public payable {
    }
    
     
     
     
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                 
                break;
            }
            
            DiamondDividendsMainContract.buy.value(address(this).balance)(0x0);
            DiamondDividendsMainContract.exit();
        }
    }
}