 

pragma solidity ^0.4.15;

 
contract IOwnership {

     
    function isOwner(address _account) constant returns (bool);


     
    function getOwner() constant returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    function Ownership() {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function isOwner(address _account) public constant returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public constant returns (address) {
        return owner;
    }
}


 
contract ITransferableOwnership {
    

     
    function transferOwnership(address _newOwner);
}


 
contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
contract IAuthenticator {
    

     
    function authenticate(address _account) constant returns (bool);
}


 
contract IWhitelist is IAuthenticator {
    

     
    function hasEntry(address _account) constant returns (bool);


     
    function add(address _account);


     
    function remove(address _account);
}


 
contract Whitelist is IWhitelist, TransferableOwnership {

    struct Entry {
        uint datetime;
        bool accepted;
        uint index;
    }

    mapping (address => Entry) internal list;
    address[] internal listIndex;


     
    function hasEntry(address _account) public constant returns (bool) {
        return listIndex.length > 0 && _account == listIndex[list[_account].index];
    }


     
    function add(address _account) public only_owner {
        if (!hasEntry(_account)) {
            list[_account] = Entry(
                now, true, listIndex.push(_account) - 1);
        } else {
            Entry storage entry = list[_account];
            if (!entry.accepted) {
                entry.accepted = true;
                entry.datetime = now;
            }
        }
    }


     
    function remove(address _account) public only_owner {
        if (hasEntry(_account)) {
            Entry storage entry = list[_account];
            entry.accepted = false;
            entry.datetime = now;
        }
    }


     
    function authenticate(address _account) public constant returns (bool) {
        return list[_account].accepted;
    }
}