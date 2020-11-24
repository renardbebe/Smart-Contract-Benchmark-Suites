 

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

 
 
 
contract PriceFeedInterface {
    function name() public view returns (string);
    function getRate() public view returns (uint _rate, bool _live);
}


 
 
 
contract PriceFeed is PriceFeedInterface, Operated {
    string private _name;
    uint private _rate;
    bool private _live;

    event SetRate(uint oldRate, bool oldLive, uint newRate, bool newLive);

    constructor(string name, uint rate, bool live) public {
        initOperated(msg.sender);
        _name = name;
        _rate = rate;
        _live = live;
        emit SetRate(0, false, _rate, _live);
    }
    function name() public view returns (string) {
        return _name;
    }
    function setRate(uint rate, bool live) public onlyOperator {
        emit SetRate(_rate, _live, rate, live);
        _rate = rate;
        _live = live;
    }
    function getRate() public view returns (uint rate, bool live) {
        return (_rate, _live);
    }
}