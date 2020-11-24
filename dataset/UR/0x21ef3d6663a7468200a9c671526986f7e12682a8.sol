 

 

pragma solidity ^0.4.24;


library SafeMath {
    
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
  
}

contract Ownable {
    
	address public owner;
	address public ownerCandidat;

	 
	 constructor() public{
		owner = msg.sender;
		
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function  transferOwnership(address newOwner) onlyOwner  public{
		require(newOwner != address(0));      
		ownerCandidat = newOwner;
	}
	 
	function confirmOwnership() public{
		require(msg.sender == ownerCandidat);      
		owner = msg.sender;
	}

}

 
contract realestate is Ownable{
    
   using SafeMath for uint;
     
    enum statuses {
        created,canceled,signed,finished
    }
    
    struct _sdeal{
    
    address buyer;
    address seller;
    address signer;
    
    uint sum; 
    uint fee;
    
    address signBuyer;
    address signSeller;
    
    uint atCreated;
    uint atClosed;
    
    uint balance;
    
    statuses status;
    uint dealNumber;
    
    string comment;
    uint objectType;  
}

struct _sSigns{
    
   address finishSignBuyer;
   address finishSignSeller;
   address finishSignSigner;
}

   event MoneyTransfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
 
    
   
  
 address public agencyOwner;
 address public agencyReceiver;

 _sdeal[] public deals;
_sSigns[] public signs;
 
   
    
   
    modifier onlyAgency(){
        require(msg.sender == agencyOwner);
        _;
    }
    
    
    
    modifier onlySigner(uint _dealNumber){
        
        uint deal = dealNumbers[_dealNumber];
        require(msg.sender == deals[deal].signer);
        _;
    }
     
    
    constructor() public{
        
         
        agencyOwner = msg.sender;
        agencyReceiver = msg.sender;
    }
     
    function changeAgencyOwner(address newAgency) public {
            require(msg.sender == agencyOwner || msg.sender == owner);
         agencyOwner = newAgency;
         
     }
     function changeAgencyReceiver (address _agencyReceiver) public{
         
         require(msg.sender == agencyOwner || msg.sender == owner);
         agencyReceiver = _agencyReceiver;
     }
     
      
    

    function getSigns(uint _dealNumber) constant public returns (address signBuyer, 
    address signSeller){
        
        uint deal = dealNumbers[_dealNumber];
        
        return (
               deals[deal].signBuyer,
               deals[deal].signSeller
               
            );
        
    }
    
    function getDealByNumber(uint _dealNumber) constant public returns (address buyer, 
    address sender, 
    address agency,
    uint sum, 
    uint atCreated,
    statuses status,
    uint objectType) {
         
         uint deal = dealNumbers[_dealNumber];
        
        return (
            deals[deal].buyer,
            deals[deal].seller,
            deals[deal].signer,
            deals[deal].sum,
            deals[deal].atCreated,
            deals[deal].status,
            deals[deal].objectType
            );
    }
    
    function getDealsLength() onlyAgency  constant public returns (uint len){
        return deals.length;
    }
    
    function getDealById(uint deal) onlyAgency constant public returns (address buyer, 
    address sender, 
    address agency,
    uint sum, 
    uint atCreated,
    statuses status,
    uint objectType,
    uint dealID) {
         
        
        return (
            deals[deal].buyer,
            deals[deal].seller,
            deals[deal].signer,
            deals[deal].sum,
            deals[deal].atCreated,
            deals[deal].status,
            deals[deal].objectType,
            deal
            );
    }
    
     function getDealDataByNumber(uint _dealNumber)  constant public returns 
     (string comment, 
    uint fee, 
    uint atClosed) {
       
         uint deal = dealNumbers[_dealNumber];
        
        return (
            deals[deal].comment,
            deals[deal].fee,
            deals[deal].atClosed
            );
    }

    mapping (uint=>uint) public dealNumbers;
    
   function addDeal(address buyer, address seller, address signer, uint sum, uint fee, uint objectType, uint _dealNumber, string comment, uint whoPay) onlyAgency public{
      
        
      
       
        
       
      
       
       
      if(whoPay ==0){
        sum = sum.add(fee);  
      }
     
      
      
      uint  newIndex = deals.length++;
      signs.length ++;
      deals[newIndex].buyer = buyer;
      deals[newIndex].seller = seller;
       deals[newIndex].signer = signer;
      
      deals[newIndex].sum = sum;
      deals[newIndex].fee = fee;
       
      
     
      deals[newIndex].atCreated = now;
      
      deals[newIndex].signBuyer = 0x0;
      deals[newIndex].signSeller = 0x0;
      deals[newIndex].comment = comment;
      deals[newIndex].status = statuses.created;
       
      
      deals[newIndex].balance = 0;
      deals[newIndex].objectType = objectType;
     deals[newIndex].dealNumber = _dealNumber;
     
     dealNumbers[_dealNumber] = newIndex;
     
     signs[newIndex].finishSignSeller = 0x0;
     signs[newIndex].finishSignBuyer = 0x0;
     signs[newIndex].finishSignSigner = 0x0;
     
     
   }
   
    
   function signBuyer(uint _dealNumber) public payable{
       
       uint deal = dealNumbers[_dealNumber];
       
        
       require(deals[deal].signBuyer == 0x0 && msg.sender == deals[deal].buyer);
       require(deals[deal].signSeller == deals[deal].seller);
       
        
        
       require(deals[deal].sum == msg.value);
       
       deals[deal].signBuyer = msg.sender;
        deals[deal].balance =  msg.value;
       deals[deal].status = statuses.signed;
     
   }
   
     
   function signSeller(uint _dealNumber) public {
       
       uint deal = dealNumbers[_dealNumber];
       
        
       require(deals[deal].signSeller == 0x0 && msg.sender == deals[deal].seller);
       deals[deal].signSeller = msg.sender;
   }
   
    
   
   
   
    
  
   
    
   
   function finishDeal(uint _dealNumber)  public{
       
       uint deal = dealNumbers[_dealNumber];
       
       require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed );
       
        
       
       if(msg.sender == deals[deal].buyer){
           signs[deal].finishSignBuyer = msg.sender;
       }
        
      if(msg.sender == deals[deal].seller){
           signs[deal].finishSignSeller = msg.sender;
       }
       if(msg.sender ==deals[deal].signer){
            signs[deal].finishSignSigner = msg.sender;
       }
       
        
       
       
      uint signCount = 0;
       if(deals[deal].buyer == signs[deal].finishSignBuyer){
           signCount++;
       }
        if(deals[deal].seller == signs[deal].finishSignSeller){
           signCount++;
       }
        if(deals[deal].signer == signs[deal].finishSignSigner){
           signCount++;
       }
       
       if(signCount >= 2){
       
          
          deals[deal].seller.transfer(deals[deal].sum - deals[deal].fee);
           
           emit MoneyTransfer(this,deals[deal].seller,deals[deal].sum-deals[deal].fee);
          
            
           agencyReceiver.transfer(deals[deal].fee);
           
           emit MoneyTransfer(this,agencyReceiver,deals[deal].fee);
           
           deals[deal].balance = 0;
           deals[deal].status = statuses.finished;
           deals[deal].atClosed = now;
       }
   }
   
   
    
    function cancelDeal(uint _dealNumber) onlySigner(_dealNumber) public{
       
        uint deal = dealNumbers[_dealNumber];
       
       require(deals[deal].balance > 0 &&  deals[deal].status == statuses.signed);
       
       deals[deal].buyer.transfer(deals[deal].balance);
       
        
       
       deals[deal].balance = 0;
       deals[deal].status = statuses.canceled;
       deals[deal].atClosed = now;
       
   }
}