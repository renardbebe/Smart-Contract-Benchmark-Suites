 

pragma solidity ^0.5.2;

 
interface RegistryInterface {
    function logic(address logicAddr) external view returns (bool);
    function record(address currentOwner, address nextOwner) external;
}


 
contract AddressRecord {

     
    address public registry;

     
    modifier logicAuth(address logicAddr) {
        require(logicAddr != address(0), "logic-proxy-address-required");
        require(RegistryInterface(registry).logic(logicAddr), "logic-not-authorised");
        _;
    }

}


 
contract UserAuth is AddressRecord {

    event LogSetOwner(address indexed owner);
    address public owner;

     
    modifier auth {
        require(isAuth(msg.sender), "permission-denied");
        _;
    }

     
    function setOwner(address nextOwner) public auth {
        RegistryInterface(registry).record(owner, nextOwner);
        owner = nextOwner;
        emit LogSetOwner(nextOwner);
    }

     
    function isAuth(address src) public view returns (bool) {
        if (src == owner) {
            return true;
        } else if (src == address(this)) {
            return true;
        }
        return false;
    }
}


 
contract UserNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }
        emit LogNote(
            msg.sig, 
            msg.sender, 
            foo, 
            bar, 
            msg.value,
            msg.data
        );
        _;
    }
}


 
contract UserWallet is UserAuth, UserNote {

    event LogExecute(address target, uint srcNum, uint sessionNum);

     
    constructor() public {
        registry = msg.sender;
        owner = msg.sender;
    }

    function() external payable {}

     
    function execute(
        address _target,
        bytes memory _data,
        uint _src,
        uint _session
    ) 
        public
        payable
        note
        auth
        logicAuth(_target)
        returns (bytes memory response)
    {
        emit LogExecute(
            _target,
            _src,
            _session
        );
        
         
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                     
                    revert(add(response, 0x20), size)
                }
        }
    }

}