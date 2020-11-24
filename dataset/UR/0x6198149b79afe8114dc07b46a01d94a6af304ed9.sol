 

pragma solidity 0.5.6;

 
 
contract Whitelist {
     
    mapping (uint => address) subscriberIndexToAddress;

     
    mapping (address => uint) subscriberAddressToSubscribed;

     
     
     
     
    uint subscriberIndex = 1;

     
    event OnSubscribed(address subscriberAddress);

     
    event OnUnsubscribed(address subscriberAddress);

     
    modifier isNotAContract(){
        require (msg.sender == tx.origin, "Contracts are not allowed to interact.");
        _;
    }
    
     
    function() external {
        subscribe();
    }
    
     
    function getSubscriberList() external view returns (address[] memory) {
        uint subscriberListAmount = getSubscriberAmount();
        
        address[] memory subscriberList = new address[](subscriberListAmount);
        uint subscriberListCounter = 0;
        
         
        for (uint i = 1; i < subscriberIndex; i++) {
            address subscriberAddress = subscriberIndexToAddress[i];

             
            if (isSubscriber(subscriberAddress) == true) {
                subscriberList[subscriberListCounter] = subscriberAddress;
                subscriberListCounter++;
            }
        }

        return subscriberList;
    }

     
    function getSubscriberAmount() public view returns (uint) {
        uint subscriberListAmount = 0;

         
        for (uint i = 1; i < subscriberIndex; i++) {
            address subscriberAddress = subscriberIndexToAddress[i];
            
             
            if (isSubscriber(subscriberAddress) == true) {
                subscriberListAmount++;
            }
        }

        return subscriberListAmount;
    }

     
    function subscribe() public isNotAContract {
        require(isSubscriber(msg.sender) == false, "You already subscribed.");
        
         
        subscriberAddressToSubscribed[msg.sender] = subscriberIndex;
        subscriberIndexToAddress[subscriberIndex] = msg.sender;
        subscriberIndex++;

        emit OnSubscribed(msg.sender);
    }

     
    function unsubscribe() external isNotAContract {
        require(isSubscriber(msg.sender) == true, "You have not subscribed yet.");

        uint index = subscriberAddressToSubscribed[msg.sender];
        delete subscriberIndexToAddress[index];

        emit OnUnsubscribed(msg.sender);
    }
    
     
    function isSubscriber() external view returns (bool) {
        return isSubscriber(tx.origin);
    }

     
    function isSubscriber(address subscriberAddress) public view returns (bool) {
        return subscriberIndexToAddress[subscriberAddressToSubscribed[subscriberAddress]] != address(0);
    }
}