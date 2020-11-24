 

pragma solidity >=0.4.22 <0.6.0;

contract goldTrade {

    uint256 amount;
    
    uint256 gold_price_USD;
    
    string reason;

    event goldTransaction(string sender_name, string receiver_name, uint256 gold_price_USD, string reason);

    
    function transact( string memory sender_name, string memory receiver_name,  uint256 gold_oz, string memory acceptForm_Yes_No, string memory shipGold_Yes_No, string memory goldCert_Yes_No) public {
       
        amount = gold_oz * 1406;
        gold_price_USD = amount;
        
        if (keccak256(bytes(acceptForm_Yes_No)) == keccak256("Yes") && keccak256(bytes(shipGold_Yes_No)) == keccak256("Yes")&& keccak256(bytes(goldCert_Yes_No)) == keccak256("Yes")) {
            gold_price_USD = amount;
            reason = "Full amount has been paid off";
            emit goldTransaction(sender_name, receiver_name, gold_price_USD, reason);
        }
        
        if (keccak256(bytes(acceptForm_Yes_No)) == keccak256("Yes") && keccak256(bytes(shipGold_Yes_No)) == keccak256("Yes")) {
            gold_price_USD = amount * 2 / 3 ;
            reason = "2/3 of the amount has been paid off";
            emit goldTransaction(sender_name, receiver_name, gold_price_USD, reason);
        }
        
        if (keccak256(bytes(acceptForm_Yes_No)) == keccak256("Yes")) {
             gold_price_USD = amount * 1 / 3 ;
             reason = "1/3 of the amount has been paid off";
            emit goldTransaction(sender_name, receiver_name, gold_price_USD, reason);
        }
        
        else {
            revert ("Your order has been rejected !");
        }
        
    }
}