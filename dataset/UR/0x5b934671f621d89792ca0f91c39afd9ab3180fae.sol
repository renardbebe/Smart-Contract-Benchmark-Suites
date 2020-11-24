 

pragma solidity ^0.4.24;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



contract MultiSig2of3 {

     
     
     
    mapping(address => bool) private owners;

     
     
    uint256 public spendNonce = 0;

     
    uint256 public unchainedMultisigVersionMajor = 2;
    uint256 public unchainedMultisigVersionMinor = 0;

     
    event Funded(uint newBalance);

     
    event Spent(address to, uint transfer);

     
     
    constructor(address owner1, address owner2, address owner3) public {
        address zeroAddress = 0x0;

        require(owner1 != zeroAddress, "1");
        require(owner2 != zeroAddress, "1");
        require(owner3 != zeroAddress, "1");

        require(owner1 != owner2, "1");
        require(owner2 != owner3, "1");
        require(owner1 != owner3, "1");

        owners[owner1] = true;
        owners[owner2] = true;
        owners[owner3] = true;
    }

     
    function() public payable {
        emit Funded(address(this).balance);
    }

     
     
     
     
    function generateMessageToSign(
        address destination,
        uint256 value
    )
        public view returns (bytes32)
    {
        require(destination != address(this), "2");
        bytes32 message = keccak256(
            abi.encodePacked(
                spendNonce,
                this,
                value,
                destination
            )
        );
        return message;
    }

     
     
     
    function spend(
        address destination,
        uint256 value,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    )
        public
    {
         
         
        require(address(this).balance >= value, "3");
        require(
            _validSignature(
                destination,
                value,
                v1, r1, s1,
                v2, r2, s2
            ),
            "4");
        spendNonce = spendNonce + 1;
        destination.transfer(value);
        emit Spent(destination, value);
    }

     
     
     
    function _validSignature(
        address destination,
        uint256 value,
        uint8 v1, bytes32 r1, bytes32 s1,
        uint8 v2, bytes32 r2, bytes32 s2
    )
        private view returns (bool)
    {
        bytes32 message = _messageToRecover(destination, value);
        address addr1 = ecrecover(
            message,
            v1+27, r1, s1
        );
        address addr2 = ecrecover(
            message,
            v2+27, r2, s2
        );
        require(_distinctOwners(addr1, addr2), "5");

        return true;
    }

     
     
     
     
     
     
     
     
     
    function _messageToRecover(
        address destination,
        uint256 value
    )
        private view returns (bytes32)
    {
        bytes32 hashedUnsignedMessage = generateMessageToSign(
            destination,
            value
        );
        bytes memory unsignedMessageBytes = _hashToAscii(
            hashedUnsignedMessage
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";
        return keccak256(abi.encodePacked(prefix,unsignedMessageBytes));
    }

     
    function _distinctOwners(
        address addr1,
        address addr2
    )
        private view returns (bool)
    {
         
        require(addr1 != addr2, "5");
         
        require(owners[addr1], "5");
        require(owners[addr2], "5");
        return true;
    }

     
     
    function _hashToAscii(bytes32 hash) private pure returns (bytes) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte  b = hash[i];
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return s;
    }

     
     
    function _char(byte b) private pure returns (byte c) {
        if (b < 10) {
            return byte(uint8(b) + 0x30);
        } else {
            return byte(uint8(b) + 0x57);
        }
    }
}