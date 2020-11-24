 

pragma solidity ^0.4.20;

contract ReceiverPays {
    address owner = msg.sender;

    mapping(uint256 => bool) usedNonces;

     
    function ReceiverPays() public payable { }


    function claimPayment(uint256 amount, uint256 nonce, bytes sig) public {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

         
        bytes32 message = prefixed(keccak256(msg.sender, amount, nonce, this));

        require(recoverSigner(message, sig) == owner);

        msg.sender.transfer(amount);
    }

     
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }


     

    function splitSignature(bytes sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
             
            r := mload(add(sig, 32))
             
            s := mload(add(sig, 64))
             
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

     
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }
}