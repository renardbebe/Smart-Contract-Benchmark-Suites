 

contract GameRegistry {

     
    struct Record {
         
        address owner;
         
        uint time;
         
        uint keysIndex;
        string description;
        string url;
    }

     
    mapping(address => Record) private records;

     
    uint private numRecords;

     
    address[] private keys;

     
    address private owner;

    uint private KEY_HOLDER_SHARE  = 50;
    uint private REGISTRATION_COST = 500 finney;
    uint private TRANSFER_COST     = 0;

     
    function GameRegistry() {
        owner = msg.sender;
    }
    
     
    function theGames(uint rindex) constant returns(address contractAddress, string description, string url, address submittedBy, uint time) {
        Record record = records[keys[rindex]];
        contractAddress = keys[rindex];
        description = record.description;
        url = record.url;
        submittedBy = record.owner;
        time = record.time;
    }

    function settings() constant public returns(uint registrationCost, uint percentSharedWithKeyHolders) {
        registrationCost            = REGISTRATION_COST / 1 finney;
        percentSharedWithKeyHolders = KEY_HOLDER_SHARE;
    }

    function distributeValue() private {
        if (msg.value == 0) {
            return;
        }
         
        uint ownerPercentage  = 100 - KEY_HOLDER_SHARE;
        uint valueForRegOwner = (ownerPercentage * msg.value) / 100;
        owner.send(valueForRegOwner);
        uint valueForEachOwner = (msg.value - valueForRegOwner) / numRecords;
        if (valueForEachOwner <= 0) {
            return;
        }
        for (uint k = 0; k < numRecords; k++) {
            records[keys[k]].owner.send(valueForEachOwner);
        }
    }

     
    function addGame(address key, string description, string url) {
         
        if (msg.value < REGISTRATION_COST) {
             
            if (msg.value > 0) {
                msg.sender.send(msg.value);
            }
            return;
        }
        distributeValue();
        if (records[key].time == 0) {
            records[key].time = now;
            records[key].owner = msg.sender;
            records[key].keysIndex = keys.length;
            keys.length++;
            keys[keys.length - 1] = key;
            records[key].description = description;
            records[key].url = url;

            numRecords++;
        }
    }

    function () { distributeValue(); }

     
    function update(address key, string description, string url) {
         
        if (records[key].owner == msg.sender) {
            records[key].description = description;
            records[key].url = url;
        }
    }

 

     
    function isRegistered(address key) private constant returns(bool) {
        return records[key].time != 0;
    }

    function getRecord(address key) private constant returns(address owner, uint time, string description, string url) {
        Record record = records[key];
        owner = record.owner;
        time = record.time;
        description = record.description;
        url = record.url;
    }

     
     
     
    function getOwner(address key) private constant returns(address) {
        return records[key].owner;
    }

     
     
     
    function getTime(address key) private constant returns(uint) {
        return records[key].time;
    }

     
     
    function maintain(uint value, uint cost) {
        if (msg.sender == owner) {
            msg.sender.send(value);
            REGISTRATION_COST = cost;
        }
    }

     
    function getTotalRecords() private constant returns(uint) {
        return numRecords;
    }

     
     
    function returnValue() internal {
        if (msg.value > 0) {
            msg.sender.send(msg.value);
        }
    }

}