 

pragma solidity > 0.5.2 < 0.6.0;

contract MultiSig {
     
    address private addr1;
    address private addr2;
    address private addr3;

     
    address private tokenContract;
    
     
    uint256 constant HALF_CURVE_ORDER = uint256(0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0);
    
     
    mapping (bytes32 => bool) public nonces;
    
     
    constructor(address _addr1, address _addr2, address _addr3, address _tokenContract) public {
        require(_addr1 != _addr2 && _addr2 != _addr3 && _addr1 != _addr3, 'MultiSig representatives must not be the same.');

        addr1 = _addr1;
        addr2 = _addr2;
        addr3 = _addr3;

        tokenContract = _tokenContract;
    }

     
    function claim(uint256 amount, address sender, address to, bytes32 r, bytes32 s, uint8 v, bytes32 salt) public {
        checkSignature(amount, sender, to, r, s, v);
        
        deploy(salt, sender, to, amount);
    }
    
     
    function checkSignature(uint256 amount, address sender, address to, bytes32 r, bytes32 s, uint8 v) internal {
        require(msg.sender == addr1 || msg.sender == addr2 || msg.sender == addr3, "Invalid signer.");

        require(uint256(s) <= HALF_CURVE_ORDER, "Found malleable signature. Please insert a low-s signature.");
        
        bytes32 msgString = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n96",
            tokenContract,
            bytes4(keccak256("transfer(address,uint256)")),
            sender,
            to,
            amount
        ));
        
        address signer = ecrecover(msgString, v, r, s);

        require(signer != msg.sender, "Cosigner and signer must not be the same.");

        require(signer == addr1 || signer == addr2 || signer == addr3, "Invalid co-signer.");

        require(!nonces[msgString], "Nonce was already used.");
        nonces[msgString] = true;
    }
    
     
    function deploy(bytes32 salt, address sender, address to, uint256 amount) internal {
        bytes memory result = new bytes(273);
        address addr;

        assembly {
            let bytecode := add(result, 0x20)
            
            mstore(add(bytecode, 0),  0x608060405234801561001057600080fd5b5060f28061001f6000396000f3fe60)  
            mstore(add(bytecode, 32),  0x80604052348015600f57600080fd5b506004361060285760003560e01c8063a9)  
            mstore(add(bytecode, 64),  0x059cbb14602d575b600080fd5b605660048036036040811015604157600080fd)  
            mstore(add(bytecode, 96),  0x5b506001600160a01b0381351690602001356058565b005b7300000000000000)  

            mstore(add(bytecode, 121), shl(96, address()))  

            mstore(add(bytecode, 141), 0x803314607857600080fd5b730000000000000000000000000000000000000000)  

            mstore(add(bytecode, 153), shl(96, sload(tokenContract_slot)))  

            mstore(add(bytecode, 173), 0x60405163a9059cbb60e01b815284600482015283602482015260008060448360)  
            mstore(add(bytecode, 205), 0x00865af18060ba57600080fd5b83fffea265627a7a72305820a57bc3e7ae7d2e)  
            mstore(add(bytecode, 237), 0xb2dbb60e9abedab864f8ff1848db33ef2cec7a159a1793027864736f6c634300)  
            mstore(add(bytecode, 269), 0x0509003200000000000000000000000000000000000000000000000000000000)  
            
             
             
             
            addr := create2(0, bytecode, 273, salt)
            
            if iszero(eq(addr, sender)) {
                revert(0,0)
            }

            mstore(bytecode, shl(224, 0xa9059cbb))
            mstore(add(bytecode, 4), to)
            mstore(add(bytecode, 36), amount)
            
             
            if iszero(call(gas(), addr, 0, bytecode, 68, 0, 0)) {
                revert(0,0)
            }
        }
    }
}