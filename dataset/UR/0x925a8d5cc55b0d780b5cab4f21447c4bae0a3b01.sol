 

pragma solidity 0.4.15;

 
 
 
contract Ownable {

   

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   

   
  function Ownable() {
    owner = msg.sender;
  }

   
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   

  address public owner;
}


contract DaoOwnable is Ownable{

    address public dao = address(0);

    event DaoOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyDao() {
        require(msg.sender == dao);
        _;
    }

    modifier onlyDaoOrOwner() {
        require(msg.sender == dao || msg.sender == owner);
        _;
    }


     
    function transferDao(address newDao) onlyOwner {
        require(newDao != address(0));
        dao = newDao;
        DaoOwnershipTransferred(owner, newDao);
    }

}

contract SSPTypeAware {
    enum SSPType { Gate, Direct }
}

contract SSPRegistry is SSPTypeAware{
     
    function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner);

     
    function updatePublisherFee(address key, uint16 newFee, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

     
    function unregister(address key, address sender);

     
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

     
    function isRegistered(address key) constant returns(bool);

    function getSSP(address key) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner);

    function getAllSSP() constant returns(address[] addresses, SSPType[] sspTypes, uint16[] publisherFees, uint256[2][] karmas, address[] recordOwners);

    function kill();
}


contract SSPRegistryImpl is SSPRegistry, DaoOwnable {

    uint public creationTime = now;

     
    struct SSP {
         
        address owner;
         
        uint time;
         
        uint keysIndex;
         
        address sspAddress;

        SSPType sspType;

        uint16 publisherFee;

        uint256[2] karma;
    }

     
    mapping(address => SSP) records;

     
    uint public numRecords;

     
    address[] public keys;

     
    function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner) onlyDaoOrOwner {
        require(records[key].time == 0);
        records[key].time = now;
        records[key].owner = recordOwner;
        records[key].keysIndex = keys.length;
        records[key].sspAddress = key;
        records[key].sspType = sspType;
        records[key].publisherFee = publisherFee;
        keys.length++;
        keys[keys.length - 1] = key;
        numRecords++;
    }

     
    function updatePublisherFee(address key, uint16 newFee, address sender) onlyDaoOrOwner {
         
        require(records[key].owner == sender);
        records[key].publisherFee = newFee;
    }

    function applyKarmaDiff(address key, uint256[2] diff) onlyDaoOrOwner {
        SSP storage ssp = records[key];
        ssp.karma[0] += diff[0];
        ssp.karma[1] += diff[1];
    }

     
    function unregister(address key, address sender) onlyDaoOrOwner {
        require(records[key].owner == sender);
        uint keysIndex = records[key].keysIndex;
        delete records[key];
        numRecords--;
        keys[keysIndex] = keys[keys.length - 1];
        records[keys[keysIndex]].keysIndex = keysIndex;
        keys.length--;
    }

     
    function transfer(address key, address newOwner, address sender) onlyDaoOrOwner {
        require(records[key].owner == sender);
        records[key].owner = newOwner;
    }

     
    function isRegistered(address key) constant returns(bool) {
        return records[key].time != 0;
    }

    function getSSP(address key) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner) {
        SSP storage record = records[key];
        sspAddress = record.sspAddress;
        sspType = record.sspType;
        publisherFee = record.publisherFee;
        karma = record.karma;
        recordOwner = owner;
    }

     
     
     
    function getOwner(address key) constant returns(address) {
        return records[key].owner;
    }

    function getAllSSP() constant returns(address[] addresses, SSPType[] sspTypes, uint16[] publisherFees, uint256[2][] karmas, address[] recordOwners) {
        addresses = new address[](numRecords);
        sspTypes = new SSPType[](numRecords);
        publisherFees = new uint16[](numRecords);
        karmas = new uint256[2][](numRecords);
        recordOwners = new address[](numRecords);
        uint i;
        for(i = 0; i < numRecords; i++) {
            SSP storage ssp = records[keys[i]];
            addresses[i] = ssp.sspAddress;
            sspTypes[i] = ssp.sspType;
            publisherFees[i] = ssp.publisherFee;
            karmas[i] = ssp.karma;
            recordOwners[i] = ssp.owner;
        }
    }

     
     
     
    function getTime(address key) constant returns(uint) {
        return records[key].time;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}