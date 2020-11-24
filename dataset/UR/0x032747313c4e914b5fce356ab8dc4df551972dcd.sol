 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract TrustEth {
     
    struct Transaction {
       
      uint sellerId;  
      uint amount;  

       
      address paidWithAddress;  
      bool paid;  
   
       
      uint ratingValue;  
      string ratingComment;  
      bool rated;  
    }

     
     
     
    struct Seller {
       
      address etherAddress;  
      uint[] ratingIds;  
      uint[] transactionIds;  
      
       
      uint averageRating;  
      uint transactionsPaid;  
      uint transactionsRated;  
    }

    Transaction[] public transactions;  
    Seller[] public sellers;  

     
    mapping (address => uint) sellerLookup;

     
    address public owner;

     
    uint public registrationFee;
    uint public transactionFee;

     
    modifier onlyowner { if (msg.sender == owner) _ }

     
    function TrustEth() {
      owner = msg.sender;
      
       
      sellers.length = 1;
      transactions.length = 1;

       
      registrationFee = 1 ether;
      transactionFee = 50 finney;
    }

    function retrieveFunds() onlyowner {
      owner.send(this.balance);
    }

    function adjustRegistrationFee(uint fee) onlyowner {
      registrationFee = fee;
    }

    function adjustTransactionFee(uint fee) onlyowner {
      transactionFee = fee;
    }

    function setOwner(address _owner) onlyowner {
      owner = _owner;
    }

     
    function() {
      throw;
    }

     
    function donate() {
       
      return;
    }

     
     
    function register() {
       
      uint etherPaid = msg.value;
      
      if(etherPaid < registrationFee) { throw; }

       
      uint sellerId = sellers.length;
      sellers.length += 1;

       
      sellers[sellerId].etherAddress = msg.sender;
      sellers[sellerId].averageRating = 0;

       
      sellerLookup[msg.sender] = sellerId;
    }


     

     
    function askForEther(uint amount) {
       
      uint sellerId = sellerLookup[msg.sender];

       
      if(sellerId == 0) { throw; }
      
       
      uint transactionId = transactions.length;
      transactions.length += 1;

       
      transactions[transactionId].sellerId = sellerId;
      transactions[transactionId].amount = amount;

       
    }

     
    function payEther(uint transactionId) {
       
      if(transactionId < 1 || transactionId >= transactions.length) { throw; }

       
      uint etherPaid = msg.value;
      uint etherAskedFor = transactions[transactionId].amount;
      uint etherNeeded = etherAskedFor + transactionFee;

       
      if(etherPaid < etherNeeded) { throw; }

       
      uint payback = etherPaid - etherNeeded;
       
      msg.sender.send(payback);

       
      sellers[transactions[transactionId].sellerId].etherAddress.send(etherAskedFor);
       
      sellers[transactions[transactionId].sellerId].transactionsPaid += 1;

       
       

       
      transactions[transactionId].paid = true;
       
      transactions[transactionId].paidWithAddress = msg.sender;
    
       
    }

     
    function rate(uint transactionId, uint ratingValue, string ratingComment) {
       
      if(transactions[transactionId].paidWithAddress != msg.sender) { throw; }
       
      if(transactionId < 1 || transactionId >= transactions.length) { throw; }
       
      if(transactions[transactionId].rated) { throw; }
       
      if(!transactions[transactionId].paid) { throw; }
       
      if(ratingValue < 1 || ratingValue > 10) { throw; }

      transactions[transactionId].ratingValue = ratingValue;
      transactions[transactionId].ratingComment = ratingComment;
      transactions[transactionId].rated = true;
      
      uint previousTransactionCount = sellers[transactions[transactionId].sellerId].transactionsRated;
      uint previousTransactionRatingSum = sellers[transactions[transactionId].sellerId].averageRating * previousTransactionCount;

      sellers[transactions[transactionId].sellerId].averageRating = (previousTransactionRatingSum + ratingValue) / (previousTransactionCount + 1);
      sellers[transactions[transactionId].sellerId].transactionsRated += 1;
    }
}