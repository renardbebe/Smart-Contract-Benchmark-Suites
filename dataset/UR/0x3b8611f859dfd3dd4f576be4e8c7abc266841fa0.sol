 

 

pragma solidity 0.4.24;

contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}

contract Ownable is
    IOwnable
{
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "ONLY_CONTRACT_OWNER"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract IAuthorizable is
    IOwnable
{
     
     
    function addAuthorizedAddress(address target)
        external;

     
     
    function removeAuthorizedAddress(address target)
        external;

     
     
     
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;
    
     
     
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}

contract MAuthorizable is
    IAuthorizable
{
     
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

     
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

     
    modifier onlyAuthorized { revert(); _; }
}

contract MixinAuthorizable is
    Ownable,
    MAuthorizable
{
     
    modifier onlyAuthorized {
        require(
            authorized[msg.sender],
            "SENDER_NOT_AUTHORIZED"
        );
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

     
     
    function addAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            !authorized[target],
            "TARGET_ALREADY_AUTHORIZED"
        );

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

     
     
    function removeAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );

        delete authorized[target];
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

     
     
     
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );
        require(
            index < authorities.length,
            "INDEX_OUT_OF_BOUNDS"
        );
        require(
            authorities[index] == target,
            "AUTHORIZED_ADDRESS_MISMATCH"
        );

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.length -= 1;
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

     
     
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        return authorities;
    }
}

contract ERC721Proxy is
    MixinAuthorizable
{
     
    bytes4 constant internal PROXY_ID = bytes4(keccak256("ERC721Token(address,uint256)"));

     
    function () 
        external
    {
        assembly {
             
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

             
             
             
             
             
             
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                 
                 
                let start := mload(64)
                mstore(start, and(caller, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(start, 32), authorized_slot)

                 
                if iszero(sload(keccak256(start, 64))) {
                     
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 

                 
                 
                 
                 
                 
                 
                 
                 
                
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 

                 
                 
                if sub(calldataload(100), 1) {
                     
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000e494e56414c49445f414d4f554e540000000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                 
                 
                 
                 
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                
                 
                 
                 
                calldatacopy(4, 36, 64)

                 
                let assetDataOffset := calldataload(4)
                calldatacopy(68, add(assetDataOffset, 72), 32)

                 
                let token := calldataload(add(assetDataOffset, 40))
                let success := call(
                    gas,             
                    token,           
                    0,               
                    0,               
                    100,             
                    0,               
                    0                
                )
                if success {
                    return(0, 0)
                }
                
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

             
            revert(0, 0)
        }
    }

     
     
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}