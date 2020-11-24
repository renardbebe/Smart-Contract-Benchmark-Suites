 

contract Delegatable {
    address public empty1;  
    address public empty2;  
    address public empty3;   
    address public owner;   
    address public delegation;  

    event DelegationTransferred(address indexed previousDelegate, address indexed newDelegation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    constructor() public {}

     
    function transferDelegation(address _newDelegation) public onlyOwner {
        require(_newDelegation != address(0), "Trying to transfer to address 0");
        emit DelegationTransferred(delegation, _newDelegation);
        delegation = _newDelegation;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Trying to transfer to address 0");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract DelegateProxy {

    constructor() public {}

     
    function delegatedFwd(address _dst, bytes _calldata) internal {
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

             
             
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract Proxy is Delegatable, DelegateProxy {

    constructor() public {}

     
    function () public {
        require(delegation != address(0), "Delegation is address 0, not initialized");
        delegatedFwd(delegation, msg.data);
    }

     
    function initialize(address _controller, uint256) public {
        require(owner == 0, "Already initialized");
        owner = msg.sender;
        delegation = _controller;
        delegatedFwd(_controller, msg.data);
    }
}