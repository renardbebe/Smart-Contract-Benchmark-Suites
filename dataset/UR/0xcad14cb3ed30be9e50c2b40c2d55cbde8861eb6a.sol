 

pragma solidity ^0.4.24;

contract SecuredTokenTransfer {

     
     
     
     
    function transferToken (
        address token, 
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
         
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize 
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }
}

contract Proxy {

     
    address masterCopy;

     
     
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != 0, "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

     
    function ()
        external
        payable
    {
         
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }

    function implementation()
        public
        view
        returns (address)
    {
        return masterCopy;
    }

    function proxyType()
        public
        pure
        returns (uint256)
    {
        return 2;
    }
}

contract DelegateConstructorProxy is Proxy {

     
     
     
    constructor(address _masterCopy, bytes initializer) Proxy(_masterCopy)
        public
    {
        if (initializer.length > 0) {
             
            assembly {
                let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
                let success := delegatecall(sub(gas, 10000), masterCopy, add(initializer, 0x20), mload(initializer), 0, 0)
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize)
                if eq(success, 0) { revert(ptr, returndatasize) }
            }
        }
    }
}

contract PayingProxy is DelegateConstructorProxy, SecuredTokenTransfer {

     
     
     
     
     
     
    constructor(address _masterCopy, bytes initializer, address funder, address paymentToken, uint256 payment) 
        DelegateConstructorProxy(_masterCopy, initializer)
        public
    {
        if (payment > 0) {
            if (paymentToken == address(0)) {
                  
                require(funder.send(payment), "Could not pay safe creation with ether");
            } else {
                require(transferToken(paymentToken, funder, payment), "Could not pay safe creation with token");
            }
        } 
    }
}