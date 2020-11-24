 

 

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

contract IAssetProxy is
    IAuthorizable
{
     
     
     
     
     
    function transferFrom(
        bytes assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
     
     
    function getProxyId()
        external
        pure
        returns (bytes4);
}


contract IAssetProxyDispatcher {

     
     
     
    function registerAssetProxy(address assetProxy)
        external;

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}


contract MAssetProxyDispatcher is
    IAssetProxyDispatcher
{
     
    event AssetProxyRegistered(
        bytes4 id,               
        address assetProxy       
    );

     
     
     
     
     
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal;
}

contract MixinAssetProxyDispatcher is
    Ownable,
    MAssetProxyDispatcher
{
     
    mapping (bytes4 => IAssetProxy) public assetProxies;

     
     
     
    function registerAssetProxy(address assetProxy)
        external
        onlyOwner
    {
        IAssetProxy assetProxyContract = IAssetProxy(assetProxy);

         
        bytes4 assetProxyId = assetProxyContract.getProxyId();
        address currentAssetProxy = assetProxies[assetProxyId];
        require(
            currentAssetProxy == address(0),
            "ASSET_PROXY_ALREADY_EXISTS"
        );

         
        assetProxies[assetProxyId] = assetProxyContract;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address)
    {
        return assetProxies[assetProxyId];
    }

     
     
     
     
     
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
         
        if (amount > 0 && from != to) {
             
            require(
                assetData.length > 3,
                "LENGTH_GREATER_THAN_3_REQUIRED"
            );
            
             
            bytes4 assetProxyId;
            assembly {
                assetProxyId := and(mload(
                    add(assetData, 32)),
                    0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
                )
            }
            address assetProxy = assetProxies[assetProxyId];

             
            require(
                assetProxy != address(0),
                "ASSET_PROXY_DOES_NOT_EXIST"
            );
            
             
             
             
             
             
             
             
             
             
             
             
             
             
             

            assembly {
                 
                 
                let cdStart := mload(64)
                 
                 
                 
                let dataAreaLength := and(add(mload(assetData), 63), 0xFFFFFFFFFFFE0)
                 
                let cdEnd := add(cdStart, add(132, dataAreaLength))

                
                 
                 
                 
                mstore(cdStart, 0xa85e59e400000000000000000000000000000000000000000000000000000000)
                
                 
                 
                 
                 
                 
                mstore(add(cdStart, 4), 128)
                mstore(add(cdStart, 36), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 68), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 100), amount)
                
                 
                 
                let dataArea := add(cdStart, 132)
                 
                for {} lt(dataArea, cdEnd) {} {
                    mstore(dataArea, mload(assetData))
                    dataArea := add(dataArea, 32)
                    assetData := add(assetData, 32)
                }

                 
                let success := call(
                    gas,                     
                    assetProxy,              
                    0,                       
                    cdStart,                 
                    sub(cdEnd, cdStart),     
                    cdStart,                 
                    512                      
                )
                if iszero(success) {
                    revert(cdStart, returndatasize())
                }
            }
        }
    }
}


contract MultiAssetProxy is
    MixinAssetProxyDispatcher,
    MixinAuthorizable
{
     
    bytes4 constant internal PROXY_ID = bytes4(keccak256("MultiAsset(uint256[],bytes[])"));

     
    function ()
        external
    {
        assembly {
             
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

             
             
             
             
             
             
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                 
                 
                mstore(0, caller)
                mstore(32, authorized_slot)

                 
                if iszero(sload(keccak256(0, 64))) {
                     
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 

                 
                let assetDataOffset := calldataload(4)

                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 
                 

                 
                 
                 
                 
                 
                let amountsOffset := calldataload(add(assetDataOffset, 40))

                 
                 
                 
                 
                 
                 
                let nestedAssetDataOffset := calldataload(add(assetDataOffset, 72))

                 
                 
                 
                 
                 
                 
                 
                let amountsContentsStart := add(assetDataOffset, add(amountsOffset, 72))

                 
                let amountsLen := calldataload(sub(amountsContentsStart, 32))

                 
                 
                 
                 
                 
                 
                 
                let nestedAssetDataContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, 72))

                 
                let nestedAssetDataLen := calldataload(sub(nestedAssetDataContentsStart, 32))

                 
                if iszero(eq(amountsLen, nestedAssetDataLen)) {
                     
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000f4c454e4754485f4d49534d4154434800000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                 
                calldatacopy(
                    0,    
                    0,    
                    100   
                )

                 
                mstore(4, 128)
                
                 
                let amount := calldataload(100)
        
                 
                let amountsByteLen := mul(amountsLen, 32)

                 
                let assetProxyId := 0
                let assetProxy := 0

                 
                for {let i := 0} lt(i, amountsByteLen) {i := add(i, 32)} {

                     
                    let amountsElement := calldataload(add(amountsContentsStart, i))
                    let totalAmount := mul(amountsElement, amount)

                     
                    if iszero(eq(div(totalAmount, amount), amountsElement)) {
                         
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001055494e543235365f4f564552464c4f57000000000000000000000000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                     
                    mstore(100, totalAmount)

                     
                    let nestedAssetDataElementOffset := calldataload(add(nestedAssetDataContentsStart, i))

                     
                     
                     
                     
                     
                     
                     
                     
                     
                    let nestedAssetDataElementContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, add(nestedAssetDataElementOffset, 104)))

                     
                    let nestedAssetDataElementLenStart := sub(nestedAssetDataElementContentsStart, 32)
                    let nestedAssetDataElementLen := calldataload(nestedAssetDataElementLenStart)

                     
                    if lt(nestedAssetDataElementLen, 4) {
                         
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001e4c454e4754485f475245415445525f5448414e5f335f524551554952)
                        mstore(96, 0x4544000000000000000000000000000000000000000000000000000000000000)
                        revert(0, 100)
                    }

                     
                    let currentAssetProxyId := and(
                        calldataload(nestedAssetDataElementContentsStart),
                        0xffffffff00000000000000000000000000000000000000000000000000000000
                    )

                     
                     
                    if iszero(eq(currentAssetProxyId, assetProxyId)) {
                         
                        assetProxyId := currentAssetProxyId
                         
                         
                        mstore(132, assetProxyId)
                        mstore(164, assetProxies_slot)
                        assetProxy := sload(keccak256(132, 64))
                    }
                    
                     
                    if iszero(assetProxy) {
                         
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001a41535345545f50524f58595f444f45535f4e4f545f45584953540000)
                        mstore(96, 0)
                        revert(0, 100)
                    }
    
                     
                    calldatacopy(
                        132,                                 
                        nestedAssetDataElementLenStart,      
                        add(nestedAssetDataElementLen, 32)   
                    )

                     
                    let success := call(
                        gas,                                     
                        assetProxy,                              
                        0,                                       
                        0,                                       
                        add(164, nestedAssetDataElementLen),     
                        0,                                       
                        0                                        
                    )

                     
                    if iszero(success) {
                        returndatacopy(
                            0,                 
                            0,                 
                            returndatasize()   
                        )
                        revert(0, returndatasize())
                    }
                }

                 
                return(0, 0)
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