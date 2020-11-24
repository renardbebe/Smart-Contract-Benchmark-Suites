 

pragma solidity ^0.4.24;

 
contract ZethrProxy {
    ZethrInterface zethr = ZethrInterface(address(0x573e869cA9355299cDdb3a912D444F137ded397c));
    address owner = msg.sender;
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint incomingEthereum,
        uint tokensMinted,
        address indexed referredBy
    );
    
    function buyTokensWithProperEvent(address _referredBy, uint8 divChoice) public payable {
         
        uint balanceBefore = zethr.balanceOf(msg.sender);
        
         
        zethr.buyAndTransfer.value(msg.value)(_referredBy, msg.sender, "", divChoice);
        
         
        uint balanceAfter = zethr.balanceOf(msg.sender);
        
        emit onTokenPurchase(
            msg.sender,
            msg.value,
            balanceAfter - balanceBefore,
            _referredBy
        );
    }
    
    function () public payable {
        
    }
    
     
     
    function withdrawMicroDivs() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}

contract ZethrInterface {
    function buyAndTransfer(address _referredBy, address target, bytes _data, uint8 divChoice) public payable;
    function balanceOf(address _owner) view public returns(uint);
}