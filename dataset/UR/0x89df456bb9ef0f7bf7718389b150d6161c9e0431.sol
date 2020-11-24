 

pragma solidity ^0.4.25;

contract Exchange {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract DICEDividends {
    Exchange diceContract = Exchange(0xda548e0AD6c88652FD21c38F46eDb58bE3a7B1dA);

     
    function () public payable {
    }

     
     
     
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                 
                break;
            }

            diceContract.buy.value(address(this).balance)(0x0);
            diceContract.exit();
        }
    }
}