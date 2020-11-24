 

pragma solidity 0.5.10;

 
 
 
 
contract BatchSendTokens {
    
     
     
     
     
     
     
    function sendTokensBySameAmount(
        ERC20Interface token, 
        address[] memory addressArray, 
        uint256 amountToEachAddress,
        uint256 totalAmount
    ) public {
        token.transferFrom(msg.sender, address(this), totalAmount);
        uint256 lengthOfArray = addressArray.length;
        for(uint256 i = 0; i < lengthOfArray; i++) {
            token.transfer(addressArray[i], amountToEachAddress);
        }
    }
    
     
     
     
     
     
     
    function sendTokensByDifferentAmount(
        ERC20Interface token, 
        address[] memory addressArray, 
        uint256[] memory amountArray,
        uint256 totalAmount
    ) public {
        token.transferFrom(msg.sender, address(this), totalAmount);
        uint256 lengthOfArray = addressArray.length;
        for(uint256 i = 0; i < lengthOfArray; i++) {
            token.transfer(addressArray[i], amountArray[i]);
        }
    }
}

 
 
 
 
contract ERC20Interface {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}