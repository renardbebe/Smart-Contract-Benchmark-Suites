 

pragma solidity ^0.4.21;

interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function decimals() public returns (uint256);
}

contract TokenSale {
    IERC20Token public tokenContract;   
    address owner;
    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor(IERC20Token _tokenContract) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
    }

     
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function () public payable {

        uint256 scaledAmount = safeMultiply(msg.value, 5000000);

        require(tokenContract.balanceOf(this) >= scaledAmount);


        tokenContract.transfer(msg.sender, scaledAmount);
    }


    function endSale() public {
        require(msg.sender == owner);

         
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        msg.sender.transfer(address(this).balance);
    }
}