 

 

pragma solidity 0.5.0;

 
contract Ownable {

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
    constructor() public {
        setOwner(msg.sender);
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "msg.sender should be onlyPendingOwner");
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner, "msg.sender should be owner");
        _;
    }

     
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }
    
     
    function owner() public view returns (address ) {
        return _owner;
    }
    
     
    function setOwner(address _newOwner) internal {
        _owner = _newOwner;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0); 
    }
    
}

 

pragma solidity 0.5.0;


contract Operable is Ownable {

    address private _operator; 

    event OperatorChanged(address indexed previousOperator, address indexed newOperator);

     
    function operator() external view returns (address) {
        return _operator;
    }
    
     
    modifier onlyOperator() {
        require(msg.sender == _operator, "msg.sender should be operator");
        _;
    }

     
    function updateOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Cannot change the newOperator to the zero address");
        emit OperatorChanged(_operator, _newOperator);
        _operator = _newOperator;
    }

}

 

pragma solidity 0.5.0;


contract BlacklistStore is Operable {

    mapping (address => uint256) public blacklisted;

     
    function setBlacklist(address _account, uint256 _status) public onlyOperator {
        blacklisted[_account] = _status;
    }

}