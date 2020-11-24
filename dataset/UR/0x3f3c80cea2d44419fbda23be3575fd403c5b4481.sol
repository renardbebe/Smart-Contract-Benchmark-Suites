 

pragma solidity ^0.4.23;

 
 
 
 
 
 
 
 
 
contract owned {
    constructor() public { owner = msg.sender; }
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
 
 
 
 
 
 
 
 
contract consumerRegistry is owned {
    event consumerRegistered(address indexed consumer);
    event consumerDeregistered(address indexed consumer);

     
    mapping(address => uint32) public consumers;

    modifier onlyRegisteredConsumers {
        require(consumers[msg.sender] > 0);
        _;
    }

     
     
     
     
     
     
    function registerConsumer(address aconsumer, uint32 auserID) onlyOwner external {
        if (auserID != 0) {
            emit consumerRegistered(aconsumer);
        } else {
            emit consumerDeregistered(aconsumer);
        }
        consumers[aconsumer] = auserID;
    }
}

 
 
 
 
 
 
 
 
contract producerRegistry is owned {
    event producerRegistered(address indexed producer);
    event producerDeregistered(address indexed producer);
    
     
    mapping(address => bool) public producers;

    modifier onlyRegisteredProducers {
        require(producers[msg.sender]);
        _;
    }
    
     
     
    function registerProducer(address aproducer) onlyOwner external {
        emit producerRegistered(aproducer);
        producers[aproducer] = true;
    }

     
     
     
    function deregisterProducer(address aproducer) onlyOwner external {
        emit producerDeregistered(aproducer);
        producers[aproducer] = false;
    }
}

 
 
 
 
 
 
 
 
contract EnergyStore is owned, consumerRegistry, producerRegistry {

    event BidMade(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event BidRevoked(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event Deal(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);
    event DealRevoked(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);
    
    uint64 constant mWh = 1;
    uint64 constant  Wh = 1000 * mWh;
    uint64 constant kWh = 1000 * Wh;
    uint64 constant MWh = 1000 * kWh;
    uint64 constant GWh = 1000 * MWh;
    uint64 constant TWh = 1000 * GWh;
    uint64 constant maxEnergy = 18446 * GWh;
  
    struct Bid {
         
        address producer;
        
         
        uint32 day;
        
         
        uint32 price;
        
         
        uint64 energy;
        
         
        uint64 timestamp;
    }
    
    struct Ask {
        address producer;
        uint32 day;
        uint32 price;
        uint64 energy;
        uint32 userID;
        uint64 timestamp;
    }

     
    Bid[] public bids;

     
    Ask[] public asks;
    
     
    mapping(address => mapping(uint32 => uint)) public bidsIndex;
    
     
    mapping(uint32 => uint) public asksIndex;
    
     
     
     
     
     
     
     
     
     
     
     
     
    function offer_energy(uint32 aday, uint32 aprice, uint64 aenergy, uint64 atimestamp) onlyRegisteredProducers external {
         
        require(aenergy >= kWh);
        
        uint idx = bidsIndex[msg.sender][aday];
        
         
        if ((bids.length > idx) && (bids[idx].producer == msg.sender) && (bids[idx].day == aday)) {
             
            require(atimestamp > bids[idx].timestamp);
            
             
             
             

            emit BidRevoked(bids[idx].producer, bids[idx].day, bids[idx].price, bids[idx].energy);   
        }
        
         
        idx = bids.length;
        bidsIndex[msg.sender][aday] = idx; 
        bids.push(Bid({
            producer: msg.sender,
            day: aday,
            price: aprice,
            energy: aenergy,
            timestamp: atimestamp
        }));
        emit BidMade(bids[idx].producer, bids[idx].day, bids[idx].price, bids[idx].energy);
    }
    
    function getBidsCount() external view returns(uint count) {
        return bids.length;
    }

    function getBidByProducerAndDay(address producer, uint32 day) external view returns(uint32 price, uint64 energy) {
        uint idx = bidsIndex[producer][day];
        require(bids.length > idx);
        require(bids[idx].producer == producer);
        require(bids[idx].day == day);
        return (bids[idx].price, bids[idx].energy);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function buy_energy(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) onlyOwner external {
        buy_energy_core(aproducer, aday, aprice, aenergy, auserID, atimestamp);
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function buy_energy(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy) onlyRegisteredConsumers external {
        buy_energy_core(aproducer, aday, aprice, aenergy, consumers[msg.sender], 0);
    }

    function buy_energy_core(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) internal {
         
        uint idx = bidsIndex[aproducer][aday];
        
         
        if ((bids.length > idx) && (bids[idx].producer == aproducer) && (bids[idx].day == aday)) {
             
            require(bids[idx].price == aprice);
            
             
             
             
             
             
             
             
            uint asksIdx = asksIndex[auserID];
            if ((asks.length > asksIdx) && (asks[asksIdx].day == aday)) {
                require((atimestamp == 0) || (asks[asksIdx].timestamp < atimestamp));
                emit DealRevoked(asks[asksIdx].producer, asks[asksIdx].day, asks[asksIdx].price, asks[asksIdx].energy, asks[asksIdx].userID);
            }
            
             
            asksIndex[auserID] = asks.length;
            asks.push(Ask({
                producer: aproducer,
                day: aday,
                price: aprice,
                energy: aenergy,
                userID: auserID,
                timestamp: atimestamp
            }));
            emit Deal(aproducer, aday, aprice, aenergy, auserID);
        } else {
             
            revert();
        }
    }

    function getAsksCount() external view returns(uint count) {
        return asks.length;
    }
        
    function getAskByUserID(uint32 userID) external view returns(address producer, uint32 day, uint32 price, uint64 energy) {
        uint idx = asksIndex[userID];
        require(asks[idx].userID == userID);
        return (asks[idx].producer, asks[idx].day, asks[idx].price, asks[idx].energy);
    }
}