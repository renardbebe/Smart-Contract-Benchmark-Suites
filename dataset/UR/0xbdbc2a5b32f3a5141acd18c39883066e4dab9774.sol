 

 

pragma solidity ^0.5.0;

 
contract OwnableProxy {
    address private _proxyOwner;
    address private _pendingProxyOwner;

    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(address indexed currentOwner, address indexed pendingOwner);

     
    constructor () internal {
        _proxyOwner = msg.sender;
        emit ProxyOwnershipTransferred(address(0), _proxyOwner);
    }

     
    function proxyOwner() public view returns (address) {
        return _proxyOwner;
    }

     
    function pendingProxyOwner() public view returns (address) {
        return _pendingProxyOwner;
    }

     
    modifier onlyProxyOwner() {
        require(isProxyOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isProxyOwner() public view returns (bool) {
        return msg.sender == _proxyOwner;
    }

     
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        _transferProxyOwnership(newOwner);
        emit NewPendingOwner(_proxyOwner, newOwner);
    }

    function claimProxyOwnership() public {
        _claimProxyOwnership(msg.sender);
    }

    function initProxyOwnership(address newOwner) public {
        require(_proxyOwner == address(0), "Ownable: already owned");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferProxyOwnership(newOwner);
    }


     
    function _transferProxyOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pendingProxyOwner = newOwner;
    }

    function _claimProxyOwnership(address newOwner) internal {
        require(newOwner == _pendingProxyOwner, "Claimed by wrong address");
        emit ProxyOwnershipTransferred(_proxyOwner, newOwner);
        _proxyOwner = newOwner;
        _pendingProxyOwner = address(0);
    }

}

 

pragma solidity ^0.5.0;



 
contract TokenProxy is OwnableProxy {
    event Upgraded(address indexed implementation);
    address public implementation;

    function upgradeTo(address _address) public onlyProxyOwner{
        require(_address != implementation, "New implementation cannot be the same as old");
        implementation = _address;
        emit Upgraded(_address);
    }

     
    
    function () external payable {
        address _impl = implementation;
        require(_impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, returndatasize, returndatasize)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
     

}