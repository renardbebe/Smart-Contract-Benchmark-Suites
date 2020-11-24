 

pragma solidity ^0.4.18;

 
interface IOwnership {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwner() public view returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function Ownership() public {
        owner = msg.sender;
    }


     
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public view returns (address) {
        return owner;
    }
}


 
interface ITransferableOwnership {
    

     
    function transferOwnership(address _newOwner) public;
}



 
contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
interface IAuthenticator {
    

     
    function authenticate(address _account) public view returns (bool);
}


 
interface IWhitelist {
    

     
    function hasEntry(address _account) public view returns (bool);


     
    function add(address _account) public;


     
    function remove(address _account) public;
}


 
contract Whitelist is IWhitelist, IAuthenticator, TransferableOwnership {

    struct Entry {
        uint datetime;
        bool accepted;
        uint index;
    }

    mapping(address => Entry) internal list;
    address[] internal listIndex;


     
    function hasEntry(address _account) public view returns (bool) {
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


     
    function authenticate(address _account) public view returns (bool) {
        return list[_account].accepted;
    }
}