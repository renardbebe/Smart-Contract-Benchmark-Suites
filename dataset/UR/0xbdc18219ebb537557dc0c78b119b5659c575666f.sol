 
contract AuctionityProxy_V1 is AuctionityLibrary_V1 {
     
     
     
     
     
    constructor(address _auctionityProxyUpdate, address _ownable) public {
         
        bytes memory _calldata = abi.encodeWithSelector(
            bytes4(keccak256("initProxyContract_V1(address,address)")),
            _auctionityProxyUpdate,
            _ownable
        );

         
         
        assembly {
            let result := delegatecall(
                gas,
                _auctionityProxyUpdate,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize
            returndatacopy(_calldata, 0, size)
            if eq(result, 0) {
                revert(_calldata, size)
            }
        }
    }

     
     
    function() external payable {
        uint returnPtr;
        uint returnSize;

        (returnPtr, returnSize) = _callDelegated_V1(
            msg.data,
            proxyFallbackContract
        );

        assembly {
            return(returnPtr, returnSize)
        }

    }
}
