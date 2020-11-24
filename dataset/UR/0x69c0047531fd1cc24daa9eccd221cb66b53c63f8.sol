 

 

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;


contract Owned {

     
    address public owner;

    event OwnerChanged(address indexed _newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
     
     
    function isOwner(address _potentialOwner) external view returns (bool) {
        return owner == _potentialOwner;
    }

     
     
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

contract AuthereumProxy {
    string constant public authereumProxyVersion = "2019102500";

     
     
     
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

     
     
    constructor(address _logic) public payable {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _logic)
        }
    }

     
     
     
     
    function () external payable {
        if (msg.data.length == 0) return;
        address _implementation = implementation();

        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)

             
             
            let result := delegatecall(gas, _implementation, 0, calldatasize, 0, 0)

             
            returndatacopy(0, 0, returndatasize)

            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

     
     
    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

contract AuthereumEnsManager {
    function register(string calldata _label, address _owner) external {}
}

contract AuthereumProxyFactory is Owned {
    string constant public authereumProxyFactoryVersion = "2019111500";
    bytes private initCode;
    address private authereumEnsManagerAddress;
    
    AuthereumEnsManager authereumEnsManager;

    event initCodeChanged(bytes initCode);
    event authereumEnsManagerChanged(address indexed authereumEnsManager);

     
     
     
    constructor(address _implementation, address _authereumEnsManagerAddress) public {
        initCode = abi.encodePacked(type(AuthereumProxy).creationCode, uint256(_implementation));
        authereumEnsManagerAddress =  _authereumEnsManagerAddress;
        authereumEnsManager = AuthereumEnsManager(authereumEnsManagerAddress);
        emit initCodeChanged(initCode);
        emit authereumEnsManagerChanged(authereumEnsManagerAddress);
    }

     

     
     
    function setInitCode(bytes memory _initCode) public onlyOwner {
        initCode = _initCode;
        emit initCodeChanged(initCode);
    }

     
     
    function setAuthereumEnsManager(address _authereumEnsManagerAddress) public onlyOwner {
        authereumEnsManagerAddress = _authereumEnsManagerAddress;
        authereumEnsManager = AuthereumEnsManager(authereumEnsManagerAddress);
        emit authereumEnsManagerChanged(authereumEnsManagerAddress);
    }

     

     
     
    function getInitCode() public view returns (bytes memory) {
        return initCode;
    }

     
     
    function getAuthereumEnsManager() public view returns (address) {
        return authereumEnsManagerAddress;
    }

     
     
     
     
     
     
     
    function createProxy(
        uint256 _salt, 
        string memory _label,
        bytes[] memory _initData
    ) 
        public 
        onlyOwner
        returns (AuthereumProxy)
    {
        address payable addr;
        bytes memory _initCode = initCode;
        bytes32 salt = _getSalt(_salt, msg.sender);

         
        assembly {
            addr := create2(0, add(_initCode, 0x20), mload(_initCode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

         
        bool success;
        for (uint256 i = 0; i < _initData.length; i++) {
            if(_initData.length > 0) {
                (success,) = addr.call(_initData[i]);
                require(success);
            }
        }

         
        authereumEnsManager.register(_label, addr);

        return AuthereumProxy(addr);
    }

     
     
     
    function _getSalt(uint256 _salt, address _sender) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_salt, _sender)); 
    }
}