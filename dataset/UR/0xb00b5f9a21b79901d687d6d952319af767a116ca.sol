 

pragma solidity ^0.4.0;
contract FileHost {
    uint256 version;
    uint256[] data;  
    address master;
    string motd;
    string credit;
    bool lock;
    
    function FileHost() public {
         
        master = msg.sender;
        version = 5;
        motd = "";
        credit = "to 63e190e32fcae9ffcca380cead85247495cc53ffa32669d2d298ff0b0dbce524 for creating the contract";
        lock = false;
    }
    function newMaster(address newMaster) public {
        require(msg.sender == master);
        master = newMaster;
    }
    function addData(uint256[] newData) public {
         
        require(msg.sender == master);
        require(!lock);
        for (var i = 0; i < newData.length; i++) {
            data.push(newData[i]);
        }
    }
    function resetData() public {
         
        require(msg.sender == master);
        require(!lock);
        delete data;
    }
    function setMotd(string newMotd) public {
         
        require(msg.sender == master);
        motd = newMotd;
    }
    function getData() public returns (uint256[]) {
         
        return data;
    }
    function getSize() public returns (uint) {
         
        return data.length;
    }
    function getMotd() public returns (string) {
         
        return motd;
    }
    function getVersion() public returns (uint) {
         
        return version;
    }
    function getCredit() public returns (string) {
         
        return credit;
    }
    function lockFile() public {
         
        assert(msg.sender == master);
        lock = true;
    }
    function withdraw() public {
         
        assert(msg.sender == master);
        master.transfer(this.balance);
    }
}