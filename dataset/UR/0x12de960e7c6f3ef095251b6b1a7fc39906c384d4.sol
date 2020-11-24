 

 

pragma solidity ^0.4.21;

 

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner)
        public
    {
        owner = _owner;
    }

    function nominateOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

 

contract Proxy is Owned {
    Proxyable public target;

    function Proxy(Proxyable _target, address _owner)
        Owned(_owner)
        public
    {
        target = _target;
        emit TargetChanged(_target);
    }

    function _setTarget(address _target) 
        external
        onlyOwner
    {
        require(_target != address(0));
        target = Proxyable(_target);
        emit TargetChanged(_target);
    }

    function () 
        public
        payable
    {
        target.setMessageSender(msg.sender);
        assembly {
             
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

             
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

             
            if iszero(result) { revert(free_ptr, calldatasize) }
            return(free_ptr, returndatasize)
        } 
    }

    event TargetChanged(address targetAddress);
}

 

contract Proxyable is Owned {
     
    Proxy public proxy;

     
     
     
    address messageSender;

    function Proxyable(address _owner)
        Owned(_owner)
        public { }

    function setProxy(Proxy _proxy)
        external
        onlyOwner
    {
        proxy = _proxy;
        emit ProxyChanged(_proxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy
    {
        require(Proxy(msg.sender) == proxy);
        _;
    }

    modifier onlyOwner_Proxy
    {
        require(messageSender == owner);
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

     
     
    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner);
        _;
    }

    event ProxyChanged(address proxyAddress);

}

 