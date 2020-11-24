 

pragma solidity ^0.4.21;
 
 
contract Hourglass {
    function buyPrice() public {}
    function sellPrice() public {}
    function reinvest() public {}
    function myTokens() public view returns(uint256) {}
    function myDividends(bool) public view returns(uint256) {}
}

contract RewardHoDLers {
    Hourglass H4D;
    address public H4DAddress = 0xeB0b5FA53843aAa2e636ccB599bA4a8CE8029aA1;

    function RewardHoDLers() public {
        H4D = Hourglass(H4DAddress);
    }

    function makeItRain() public {
        H4D.reinvest();
    }

    function myTokens() public view returns(uint256) {
        return H4D.myTokens();
    }
    
    function myDividends() public view returns(uint256) {
        return H4D.myDividends(true);
    }
    
    
}