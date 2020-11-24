 

pragma solidity ^0.4.13;

library Sets {
     
    struct addressSet {
        address[] members;
        mapping (address => bool) memberExists;
        mapping (address => uint) memberIndex;
    }

    function insert(addressSet storage self, address other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(addressSet storage self, address other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(addressSet storage self, address other) returns (bool) {
        return self.memberExists[other];
    }

    function length(addressSet storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct uintSet {
        uint[] members;
        mapping (uint => bool) memberExists;
        mapping (uint => uint) memberIndex;
    }

    function insert(uintSet storage self, uint other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(uintSet storage self, uint other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(uintSet storage self, uint other) returns (bool) {
        return self.memberExists[other];
    }

    function length(uintSet storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct uint8Set {
        uint8[] members;
        mapping (uint8 => bool) memberExists;
        mapping (uint8 => uint) memberIndex;
    }

    function insert(uint8Set storage self, uint8 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(uint8Set storage self, uint8 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(uint8Set storage self, uint8 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(uint8Set storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct intSet {
        int[] members;
        mapping (int => bool) memberExists;
        mapping (int => uint) memberIndex;
    }

    function insert(intSet storage self, int other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(intSet storage self, int other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(intSet storage self, int other) returns (bool) {
        return self.memberExists[other];
    }

    function length(intSet storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct int8Set {
        int8[] members;
        mapping (int8 => bool) memberExists;
        mapping (int8 => uint) memberIndex;
    }

    function insert(int8Set storage self, int8 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(int8Set storage self, int8 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(int8Set storage self, int8 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(int8Set storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct byteSet {
        byte[] members;
        mapping (byte => bool) memberExists;
        mapping (byte => uint) memberIndex;
    }

    function insert(byteSet storage self, byte other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(byteSet storage self, byte other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(byteSet storage self, byte other) returns (bool) {
        return self.memberExists[other];
    }

    function length(byteSet storage self) returns (uint256) {
        return self.members.length;
    }


     
    struct bytes32Set {
        bytes32[] members;
        mapping (bytes32 => bool) memberExists;
        mapping (bytes32 => uint) memberIndex;
    }

    function insert(bytes32Set storage self, bytes32 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(bytes32Set storage self, bytes32 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
             
            self.memberIndex[self.members[self.members.length - 1]] = index;
             
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(bytes32Set storage self, bytes32 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(bytes32Set storage self) returns (uint256) {
        return self.members.length;
    }
}

contract Prover {
     
    using Sets for *;


     
    address owner;
    Sets.addressSet internal users;
    mapping (address => UserAccount) internal ledger;
    
    
     
    struct UserAccount {
        Sets.bytes32Set hashes;
        mapping (bytes32 => Entry) entries;
    }

    struct Entry {
        uint256 time;
        uint256 value;
    }


     
    function Prover() {
        owner = msg.sender;
    }
    
    
     
    function () {
        revert();
    }


     
    modifier hasAccount() {
        assert(ledger[msg.sender].hashes.length() >= 1);
        _;
    }


     
     
    function proveIt(address target, bytes32 dataHash) external constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return status(target, dataHash);
    }

    function proveIt(address target, string dataString) external constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return status(target, sha3(dataString));
    }
    
     
    function usersGetter() public constant
        returns (uint256 number_unique_addresses, address[] unique_addresses)
    {
        return (users.length(), users.members);
    }

    function userEntries(address target) external constant returns (bytes32[]) {
        return ledger[target].hashes.members;
    }
    
    
     
     
    function addEntry(bytes32 dataHash) payable {
        _addEntry(dataHash);
    }

    function addEntry(string dataString) payable {
        _addEntry(sha3(dataString));
    }

     
    function deleteEntry(bytes32 dataHash) hasAccount {
        _deleteEntry(dataHash);
    }

    function deleteEntry(string dataString) hasAccount {
        _deleteEntry(sha3(dataString));
    }
    
     
    function selfDestruct() {
        if ((msg.sender == owner) && (users.length() == 0)) {
            selfdestruct(owner);
        }
    }


     
    function _addEntry(bytes32 dataHash) internal {
         
        assert(!ledger[msg.sender].hashes.contains(dataHash));
         
        ledger[msg.sender].hashes.insert(dataHash);
        ledger[msg.sender].entries[dataHash] = Entry(now, msg.value);
         
        users.insert(msg.sender);
    }

    function _deleteEntry(bytes32 dataHash) internal {
         
        assert(ledger[msg.sender].hashes.contains(dataHash));
        uint256 rebate = ledger[msg.sender].entries[dataHash].value;
         
        ledger[msg.sender].hashes.remove(dataHash);
        delete ledger[msg.sender].entries[dataHash];
         
        if (rebate > 0) {
            msg.sender.transfer(rebate);
        }
         
        if (ledger[msg.sender].hashes.length() == 0) {
            users.remove(msg.sender);
        }
    }

     
    function status(address target, bytes32 dataHash) internal constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return (ledger[msg.sender].hashes.contains(dataHash),
                ledger[target].entries[dataHash].time,
                ledger[target].entries[dataHash].value);
    }
}