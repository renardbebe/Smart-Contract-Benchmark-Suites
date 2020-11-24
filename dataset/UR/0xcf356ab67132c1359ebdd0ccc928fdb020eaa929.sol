 

pragma solidity ^0.4.16;
    contract EscrowMyEtherEntityDB  {
        
         
         
         
        
        address public owner;
        

         
         


        struct Entity{
            string name;
            string info;      
        }


        
               
        mapping(address => Entity) public buyerList;
        mapping(address => Entity) public sellerList;
        mapping(address => Entity) public escrowList;

      
         
        function EscrowMyEtherEntityDB() {
            owner = msg.sender;


        }



        function() payable
        {
             
        }

        
        function registerBuyer(string _name, string _info)
        {
           
            buyerList[msg.sender].name = _name;
            buyerList[msg.sender].info = _info;

        }

    
       
        function registerSeller(string _name, string _info)
        {
            sellerList[msg.sender].name = _name;
            sellerList[msg.sender].info = _info;

        }

        function registerEscrow(string _name, string _info)
        {
            escrowList[msg.sender].name = _name;
            escrowList[msg.sender].info = _info;
            
        }

        function getBuyerFullInfo(address buyerAddress) constant returns (string, string)
        {
            return (buyerList[buyerAddress].name, buyerList[buyerAddress].info);
        }

        function getSellerFullInfo(address sellerAddress) constant returns (string, string)
        {
            return (sellerList[sellerAddress].name, sellerList[sellerAddress].info);
        }

        function getEscrowFullInfo(address escrowAddress) constant returns (string, string)
        {
            return (escrowList[escrowAddress].name, escrowList[escrowAddress].info);
        }
        
    }