 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 



 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    bool private initialised;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised);
        owner = _owner;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


 
 
 
 
contract Operated is Owned {
    mapping(address => bool) public operators;

    event OperatorAdded(address _operator);
    event OperatorRemoved(address _operator);

    modifier onlyOperator() {
        require(operators[msg.sender] || owner == msg.sender);
        _;
    }

    function initOperated(address _owner) internal {
        initOwned(_owner);
    }
    function addOperator(address _operator) public onlyOwner {
        require(!operators[_operator]);
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }
    function removeOperator(address _operator) public onlyOwner {
        require(operators[_operator]);
        delete operators[_operator];
        emit OperatorRemoved(_operator);
    }
}

 
 
 
contract BonusListInterface {
    function isInBonusList(address account) public view returns (bool);
}


 
 
 
contract BonusList is BonusListInterface, Operated {
    mapping(address => bool) public bonusList;

    event AccountListed(address indexed account, bool status);

    constructor() public {
        initOperated(msg.sender);
    }

    function isInBonusList(address account) public view returns (bool) {
        return bonusList[account];
    }

    function add(address[] accounts) public onlyOperator {
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (!bonusList[accounts[i]]) {
                bonusList[accounts[i]] = true;
                emit AccountListed(accounts[i], true);
            }
        }
    }
    function remove(address[] accounts) public onlyOperator {
        require(accounts.length != 0);
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (bonusList[accounts[i]]) {
                delete bonusList[accounts[i]];
                emit AccountListed(accounts[i], false);
            }
        }
    }
}