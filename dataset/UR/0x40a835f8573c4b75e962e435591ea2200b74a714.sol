 

pragma solidity ^0.4.16;
    contract MyEtherTeller  {
        
         
         
         
        
        address public owner;

       
         
         
        struct EscrowStruct
        {    
            address buyer;           
            address seller;          
            address escrow_agent;    
                                       
            uint escrow_fee;         
            uint amount;             

            bool escrow_intervention;  
            bool release_approval;    
            bool refund_approval;     

            bytes32 notes;              
            
        }

        struct TransactionStruct
        {                        
             
            address buyer;           
            uint buyer_nounce;          
        }


        
         
        mapping(address => EscrowStruct[]) public buyerDatabase;

         
        mapping(address => TransactionStruct[]) public sellerDatabase;        
        mapping(address => TransactionStruct[]) public escrowDatabase;
               
         
        mapping(address => uint) public Funds;

        mapping(address => uint) public escrowFee;



         
        function MyEtherTeller() {
            owner = msg.sender;
        }

        function() payable
        {
             
        }

        function setEscrowFee(uint fee) {

             
            require (fee >= 1 && fee <= 100);
            escrowFee[msg.sender] = fee;
        }

        function getEscrowFee(address escrowAddress) constant returns (uint) {
            return (escrowFee[escrowAddress]);
        }

        
        function newEscrow(address sellerAddress, address escrowAddress, bytes32 notes) payable returns (bool) {

            require(msg.value > 0 && msg.sender != escrowAddress);
        
             
            EscrowStruct memory currentEscrow;
            TransactionStruct memory currentTransaction;
            
            currentEscrow.buyer = msg.sender;
            currentEscrow.seller = sellerAddress;
            currentEscrow.escrow_agent = escrowAddress;

             
            currentEscrow.escrow_fee = getEscrowFee(escrowAddress)*msg.value/1000;
            
             
            uint dev_fee = msg.value/400;
            Funds[owner] += dev_fee;   

             
            currentEscrow.amount = msg.value - dev_fee - currentEscrow.escrow_fee;

             
              
            
            currentEscrow.notes = notes;
 
             
            currentTransaction.buyer = msg.sender;
            currentTransaction.buyer_nounce = buyerDatabase[msg.sender].length;

            sellerDatabase[sellerAddress].push(currentTransaction);
            escrowDatabase[escrowAddress].push(currentTransaction);
            buyerDatabase[msg.sender].push(currentEscrow);
            
            return true;

        }

         
        function getNumTransactions(address inputAddress, uint switcher) constant returns (uint)
        {

            if (switcher == 0) return (buyerDatabase[inputAddress].length);

            else if (switcher == 1) return (sellerDatabase[inputAddress].length);

            else return (escrowDatabase[inputAddress].length);
        }

         
        function getSpecificTransaction(address inputAddress, uint switcher, uint ID) constant returns (address, address, address, uint, bytes32, uint, bytes32)

        {
            bytes32 status;
            EscrowStruct memory currentEscrow;
            if (switcher == 0)
            {
                currentEscrow = buyerDatabase[inputAddress][ID];
                status = checkStatus(inputAddress, ID);
            } 
            
            else if (switcher == 1)

            {  
                currentEscrow = buyerDatabase[sellerDatabase[inputAddress][ID].buyer][sellerDatabase[inputAddress][ID].buyer_nounce];
                status = checkStatus(currentEscrow.buyer, sellerDatabase[inputAddress][ID].buyer_nounce);
            }

                        
            else if (switcher == 2)
            
            {        
                currentEscrow = buyerDatabase[escrowDatabase[inputAddress][ID].buyer][escrowDatabase[inputAddress][ID].buyer_nounce];
                status = checkStatus(currentEscrow.buyer, escrowDatabase[inputAddress][ID].buyer_nounce);
            }

            return (currentEscrow.buyer, currentEscrow.seller, currentEscrow.escrow_agent, currentEscrow.amount, status, currentEscrow.escrow_fee, currentEscrow.notes);
        }   


        function buyerHistory(address buyerAddress, uint startID, uint numToLoad) constant returns (address[], address[],uint[], bytes32[]){


            uint length;
            if (buyerDatabase[buyerAddress].length < numToLoad)
                length = buyerDatabase[buyerAddress].length;
            
            else 
                length = numToLoad;
            
            address[] memory sellers = new address[](length);
            address[] memory escrow_agents = new address[](length);
            uint[] memory amounts = new uint[](length);
            bytes32[] memory statuses = new bytes32[](length);
           
            for (uint i = 0; i < length; i++)
            {
  
                sellers[i] = (buyerDatabase[buyerAddress][startID + i].seller);
                escrow_agents[i] = (buyerDatabase[buyerAddress][startID + i].escrow_agent);
                amounts[i] = (buyerDatabase[buyerAddress][startID + i].amount);
                statuses[i] = checkStatus(buyerAddress, startID + i);
            }
            
            return (sellers, escrow_agents, amounts, statuses);
        }


                 
        function SellerHistory(address inputAddress, uint startID , uint numToLoad) constant returns (address[], address[], uint[], bytes32[]){

            address[] memory buyers = new address[](numToLoad);
            address[] memory escrows = new address[](numToLoad);
            uint[] memory amounts = new uint[](numToLoad);
            bytes32[] memory statuses = new bytes32[](numToLoad);

            for (uint i = 0; i < numToLoad; i++)
            {
                if (i >= sellerDatabase[inputAddress].length)
                    break;
                buyers[i] = sellerDatabase[inputAddress][startID + i].buyer;
                escrows[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID +i].buyer_nounce].escrow_agent;
                amounts[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID + i].buyer_nounce].amount;
                statuses[i] = checkStatus(buyers[i], sellerDatabase[inputAddress][startID + i].buyer_nounce);
            }
            return (buyers, escrows, amounts, statuses);
        }

        function escrowHistory(address inputAddress, uint startID, uint numToLoad) constant returns (address[], address[], uint[], bytes32[]){
        
            address[] memory buyers = new address[](numToLoad);
            address[] memory sellers = new address[](numToLoad);
            uint[] memory amounts = new uint[](numToLoad);
            bytes32[] memory statuses = new bytes32[](numToLoad);

            for (uint i = 0; i < numToLoad; i++)
            {
                if (i >= escrowDatabase[inputAddress].length)
                    break;
                buyers[i] = escrowDatabase[inputAddress][startID + i].buyer;
                sellers[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID +i].buyer_nounce].seller;
                amounts[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID + i].buyer_nounce].amount;
                statuses[i] = checkStatus(buyers[i], escrowDatabase[inputAddress][startID + i].buyer_nounce);
            }
            return (buyers, sellers, amounts, statuses);
    }

        function checkStatus(address buyerAddress, uint nounce) constant returns (bytes32){

            bytes32 status = "";

            if (buyerDatabase[buyerAddress][nounce].release_approval){
                status = "Complete";
            } else if (buyerDatabase[buyerAddress][nounce].refund_approval){
                status = "Refunded";
            } else if (buyerDatabase[buyerAddress][nounce].escrow_intervention){
                status = "Pending Escrow Decision";
            } else
            {
                status = "In Progress";
            }
       
            return (status);
        }

        
         
         
        function buyerFundRelease(uint ID)
        {
            require(ID < buyerDatabase[msg.sender].length && 
            buyerDatabase[msg.sender][ID].release_approval == false &&
            buyerDatabase[msg.sender][ID].refund_approval == false);
            
             
            buyerDatabase[msg.sender][ID].release_approval = true;

            address seller = buyerDatabase[msg.sender][ID].seller;
            address escrow_agent = buyerDatabase[msg.sender][ID].escrow_agent;

            uint amount = buyerDatabase[msg.sender][ID].amount;
            uint escrow_fee = buyerDatabase[msg.sender][ID].escrow_fee;

             
            Funds[seller] += amount;
            Funds[escrow_agent] += escrow_fee;


        }

         
        function sellerRefund(uint ID)
        {
            address buyerAddress = sellerDatabase[msg.sender][ID].buyer;
            uint buyerID = sellerDatabase[msg.sender][ID].buyer_nounce;

            require(
            buyerDatabase[buyerAddress][buyerID].release_approval == false &&
            buyerDatabase[buyerAddress][buyerID].refund_approval == false); 

            address escrow_agent = buyerDatabase[buyerAddress][buyerID].escrow_agent;
            uint escrow_fee = buyerDatabase[buyerAddress][buyerID].escrow_fee;
            uint amount = buyerDatabase[buyerAddress][buyerID].amount;
        
             
            buyerDatabase[buyerAddress][buyerID].refund_approval = true;

            Funds[buyerAddress] += amount;
            Funds[escrow_agent] += escrow_fee;
            
        }
        
        

         
         

         
        function EscrowEscalation(uint switcher, uint ID)
        {
             
             
             
             

             
            address buyerAddress;
            uint buyerID;  
            if (switcher == 0)  
            {
                buyerAddress = msg.sender;
                buyerID = ID;
            } else if (switcher == 1)  
            {
                buyerAddress = sellerDatabase[msg.sender][ID].buyer;
                buyerID = sellerDatabase[msg.sender][ID].buyer_nounce;
            }

            require(buyerDatabase[buyerAddress][buyerID].escrow_intervention == false  &&
            buyerDatabase[buyerAddress][buyerID].release_approval == false &&
            buyerDatabase[buyerAddress][buyerID].refund_approval == false);

             
            buyerDatabase[buyerAddress][buyerID].escrow_intervention = true;

            
        }
        
         
         
        function escrowDecision(uint ID, uint Decision)
        {
             
             
             
             
             

            address buyerAddress = escrowDatabase[msg.sender][ID].buyer;
            uint buyerID = escrowDatabase[msg.sender][ID].buyer_nounce;
            

            require(
            buyerDatabase[buyerAddress][buyerID].release_approval == false &&
            buyerDatabase[buyerAddress][buyerID].escrow_intervention == true &&
            buyerDatabase[buyerAddress][buyerID].refund_approval == false);
            
            uint escrow_fee = buyerDatabase[buyerAddress][buyerID].escrow_fee;
            uint amount = buyerDatabase[buyerAddress][buyerID].amount;

            if (Decision == 0)  
            {
                buyerDatabase[buyerAddress][buyerID].refund_approval = true;    
                Funds[buyerAddress] += amount;
                Funds[msg.sender] += escrow_fee;
                
            } else if (Decision == 1)  
            {                
                buyerDatabase[buyerAddress][buyerID].release_approval = true;
                Funds[buyerDatabase[buyerAddress][buyerID].seller] += amount;
                Funds[msg.sender] += escrow_fee;
            }  
        }
        
        function WithdrawFunds()
        {
            uint amount = Funds[msg.sender];
            Funds[msg.sender] = 0;
            if (!msg.sender.send(amount))
                Funds[msg.sender] = amount;
        }


        function CheckBalance(address fromAddress) constant returns (uint){
            return (Funds[fromAddress]);
        }
     
    }