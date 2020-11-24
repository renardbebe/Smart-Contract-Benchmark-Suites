 

pragma solidity ^0.4.11;

 

 
contract GointoMigration {

    struct Manager {
        bool isAdmin;
        bool isManager;
        address addedBy;
    }

    mapping (address => Manager) internal managers;
    mapping (string => address) internal contracts;

    event EventSetContract(address by, string key, address contractAddress);
    event EventAddAdmin(address by, address admin);
    event EventRemoveAdmin(address by, address admin);
    event EventAddManager(address by, address manager);
    event EventRemoveManager(address by, address manager);

     
    modifier onlyAdmin() { 
        require(managers[msg.sender].isAdmin == true);
        _; 
    }

     
    modifier onlyManager() { 
        require(managers[msg.sender].isManager == true);
        _; 
    }

    function GointoMigration(address originalAdmin) {
        managers[originalAdmin] = Manager(true, true, msg.sender);
    }

     
    function setContract(string key, address contractAddress) external onlyManager {

         
        require(bytes(key).length <= 32);

         
        contracts[key] = contractAddress;

         
        EventSetContract(msg.sender, key, contractAddress);

    }

     
    function getContract(string key) external constant returns (address) {

         
        require(bytes(key).length <= 32);

         
        return contracts[key];

    }

     
    function getPermissions(address who) external constant returns (bool, bool) {
        return (managers[who].isAdmin, managers[who].isManager);
    }

     
    function addAdmin(address adminAddress) external onlyAdmin {

         
        managers[adminAddress] = Manager(true, true, msg.sender);

         
        EventAddAdmin(msg.sender, adminAddress);

    }

     
    function removeAdmin(address adminAddress) external onlyAdmin {

         
        require(adminAddress != msg.sender);

         
        managers[adminAddress] = Manager(false, false, msg.sender);

         
        EventRemoveAdmin(msg.sender, adminAddress);

    }

     
    function addManager(address manAddress) external onlyAdmin {

         
        managers[manAddress] = Manager(false, true, msg.sender);

         
        EventAddManager(msg.sender, manAddress);

    }

     
    function removeManager(address manAddress) external onlyAdmin {

         
        managers[manAddress] = Manager(false, false, msg.sender);

         
        EventRemoveManager(msg.sender, manAddress);

    }

}