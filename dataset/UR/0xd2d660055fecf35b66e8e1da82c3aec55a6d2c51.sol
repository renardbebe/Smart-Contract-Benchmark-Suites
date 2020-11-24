 

pragma solidity ^0.4.24;

 

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 

contract XTransferRerouter is Owned {
    bool public reroutingEnabled;

     
    event TxReroute(
        uint256 indexed _txId,
        bytes32 _toBlockchain,
        bytes32 _to
    );

     
    constructor(bool _reroutingEnabled) public {
        reroutingEnabled = _reroutingEnabled;
    }
     
    function enableRerouting(bool _enable) public ownerOnly {
        reroutingEnabled = _enable;
    }

     
    modifier whenReroutingEnabled {
        require(reroutingEnabled);
        _;
    }

     
    function rerouteTx(
        uint256 _txId,
        bytes32 _blockchain,
        bytes32 _to
    )
        public
        whenReroutingEnabled 
    {
        emit TxReroute(_txId, _blockchain, _to);
    }

}