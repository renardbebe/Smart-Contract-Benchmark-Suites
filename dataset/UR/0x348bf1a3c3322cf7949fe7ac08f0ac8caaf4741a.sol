 

pragma solidity ^0.4.25;

contract Escrow {
    uint256 public balance;
    address public buyer;
    address public seller;
    address public escrow;
    uint private start;
    bool buyerOk;
    bool sellerOk;

function Escrow(address buyer_address, address seller_address) public {
         
        buyer = buyer_address;
        seller = seller_address;
        escrow = seller;
        start = now;  
    }
    
    function accept() public {
        if (msg.sender == buyer){
            buyerOk = true;
        } else if (msg.sender == seller){
            sellerOk = true;
        }
        if (buyerOk && sellerOk){
            payBalance();
        } else if (buyerOk && !sellerOk && now > start + 7 days) {
             
            selfdestruct(buyer);
        }
    }
    
    function payBalance() private {
         
         
         
        if (seller.send(balance)) {
            balance = 0;
        } else {
            throw;
        }
    }
    
    function deposit() public payable {
        if (msg.sender == buyer) {
            balance += msg.value;
        }
    }
    
    function cancel() public {
        if (msg.sender == buyer){
            buyerOk = false;
        } else if (msg.sender == seller){
            sellerOk = false;
        }
         
        if (!buyerOk && !sellerOk){
            selfdestruct(buyer);
        }
    }
    
    function kill() public {
        if (msg.sender == escrow) {
            selfdestruct(buyer);
        }
    }
}