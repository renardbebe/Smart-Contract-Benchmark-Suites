 
    function circulatingSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(owner()));
    }

     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner(), tokens);
    }

    mapping(bytes32 => bool) invalidHashes;

     
    function transferPreSigned(
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce,
        bytes memory signature
    )
        public
        whenNotPaused
        returns (bool)
    {
        uint256 gas = gasleft();

        require(to != address(0));

        bytes32 payloadHash = transferPreSignedPayloadHash(address(this), to, value, gasPrice, nonce);

         
        address from = payloadHash.toEthSignedMessageHash().recover(signature);
        require(from != address(0), "Invalid signature provided.");

         
        bytes32 txHash = keccak256(abi.encodePacked(from, payloadHash));

         
        require(!invalidHashes[txHash], "Transaction has already been executed.");

         
        invalidHashes[txHash] = true;

         
        _transfer(from, to, value);

         
        uint256 fee = 0;
        if (gasPrice > 0) {
             
            gas = 21000 + 14000 + 10000 + gas.sub(gasleft());
            fee = gasPrice.mul(gas);
            _transfer(from, tx.origin, fee);
        }

        emit HashRedeemed(txHash, from);

        return true;
    }

     
    function transferPreSignedPayloadHash(
        address token,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce
    )
        public
        pure
        returns (bytes32)
    {
         
        return keccak256(abi.encodePacked(bytes4(0x452d3c59), token, to, value, gasPrice, nonce));
    }
}
