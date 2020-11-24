 

pragma solidity >= 0.5.11;

 
interface ChainValidator {
     
    function validateNewValidator(uint256 vesting, address acc, bool mining, uint256 actNumOfValidators) external returns (bool);
    
     
    function validateNewTransactor(uint256 deposit, address acc, uint256 actNumOfTransactors) external returns (bool);
}

 
contract EnergyChainValidator is ChainValidator {
    
     
     
     
    
     
    uint256 constant LIT_PRECISION               = 10**18;
    
     
    uint256 constant MIN_DEPOSIT                 = 1000*LIT_PRECISION;
    
     
    uint256 constant MIN_VESTING                 = 1000*LIT_PRECISION;
    
     
    uint256 constant MAX_VESTING                 = 500000*LIT_PRECISION;
    
    
     
     
     
    
    
     
    struct IterableMap {
         
         
        mapping(address => uint256) listIndex;
         
        address[]                   list;        
    }    
    
     
    function insertAcc(IterableMap storage map, address acc) internal {
        map.list.push(acc);
         
        map.listIndex[acc] = map.list.length;
    }
    
     
    function removeAcc(IterableMap storage map, address acc) internal {
        uint256 index = map.listIndex[acc];
        require(index > 0 && index <= map.list.length, "RemoveAcc invalid index");
        
         
        uint256 foundIndex = index - 1;
        uint256 lastIndex  = map.list.length - 1;
    
        map.listIndex[map.list[lastIndex]] = foundIndex + 1;
        map.list[foundIndex] = map.list[lastIndex];
        map.list.length--;
    
         
        map.listIndex[acc] = 0;
    }
    
     
    function existAcc(IterableMap storage map, address acc) internal view returns (bool) {
        return map.listIndex[acc] != 0;
    }
    
    
     
     
     


     
    IterableMap private admins;
    
     
    IterableMap private whitelistedUsers;
    
     
    uint256     public  maxNumOfValidators;
    
    constructor() public {
        insertAcc(admins, msg.sender);
    }


     
     
     

    
     
    function validateNewValidator(uint256 vesting, address acc, bool mining, uint256 actNumOfValidators) external returns (bool) {
        if (vesting < MIN_VESTING || vesting > MAX_VESTING) {
            return false;
        }
        if (maxNumOfValidators != 0 && mining == true && actNumOfValidators >= maxNumOfValidators) {
            return false;
        }
        
        return true;
    }
    
     
    function validateNewTransactor(uint256 deposit, address acc, uint256 actNumOfTransactors) external returns (bool) {
        if (existAcc(whitelistedUsers, acc) == true && deposit >= MIN_DEPOSIT) {
            return  true;
        }
        
        return false;
    }
    
     
    function setMaxNumOfValidators(uint256 num) external {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        maxNumOfValidators = num;
    }
    
     
    function addWhitelistedUsers(address[] calldata accounts) external {
        addUsers(whitelistedUsers, accounts);
    }
    
     
    function removeWhitelistedUsers(address[] calldata accounts) external {
        require(whitelistedUsers.list.length > 0, "There are no whitelisted users to be removed");
        
        removeUsers(whitelistedUsers, accounts);
    }

     
    function addAdmins(address[] calldata accounts) external {
        addUsers(admins, accounts);
    }
    
     
    function removeAdmin(address account) external {
        require(admins.list.length > 1, "Cannot remove all admins, at least one must be always present");
        require(existAcc(admins, account) == true, "Trying to remove non-existing admin");
        
        removeAcc(admins, account);
    }
    
     
    function getAdmins(uint256 batch) external view returns (address[100] memory accounts, uint256 count, bool end) {
        return getUsers(admins, batch);
    }
    
     
    function getWhitelistedUsers(uint256 batch) external view returns (address[100] memory accounts, uint256 count, bool end) {
        return getUsers(whitelistedUsers, batch);
    }
    
    
     
     
     

    
     
    function getUsers(IterableMap storage internalUsersGroup, uint256 batch) internal view returns (address[100] memory users, uint256 count, bool end) {
        count = 0;
        uint256 usersTotalCount = internalUsersGroup.list.length;
        
        uint256 i;
        for(i = batch * 100; i < (batch + 1)*100 && i < usersTotalCount; i++) {
            users[count] = internalUsersGroup.list[i];
            count++;
        }
        
        if (i >= usersTotalCount) {
            end = true;
        }
        else {
            end = false;
        }
    }
    
    function addUsers(IterableMap storage internalUsersGroup, address[] memory users) internal {
        require(existAcc(admins, msg.sender) == true, "Only admins can do internal changes");
        require(users.length <= 100, "Max number of processed users is 100");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (existAcc(internalUsersGroup, users[i]) == false) {
                insertAcc(internalUsersGroup, users[i]);
            }    
        }
    }
    
    function removeUsers(IterableMap storage internalUsersGroup, address[] memory users) internal {
        require(existAcc(admins, msg.sender) == true, "Only admins can remove whitelisted users");
        require(users.length <= 100, "Max number of processed users is 100");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (existAcc(internalUsersGroup, users[i]) == true) {
                removeAcc(internalUsersGroup, users[i]);
            }    
        }
    }
}