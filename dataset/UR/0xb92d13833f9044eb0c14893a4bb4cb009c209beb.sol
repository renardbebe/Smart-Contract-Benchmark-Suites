 

pragma solidity ^0.4.18;

contract PixelStorageWithFee {
    event PixelUpdate(uint32 indexed index, uint8 color);
    byte[500000] public packedBytes;
    uint256 feeWei;
    address masterAddress;

    function PixelStorageWithFee(uint256 startingFeeWei) public {
        masterAddress = msg.sender;
        feeWei = startingFeeWei;
    }

     
     
     
     
     
     

    function set(uint32 index, uint8 color) public payable {
        require(index < 1000000);
        require(msg.value >= feeWei);

        uint32 packedByteIndex = index / 2;
        byte currentByte = packedBytes[packedByteIndex];
        bool left = index % 2 == 0;

        byte newByte;
        if (left) {
             
             
            newByte = (currentByte & hex'0f') | bytes1(color * 2 ** 4);
        } else {
             
             
            newByte = (currentByte & hex'f0') | (bytes1(color) & hex'0f');
        }

        packedBytes[packedByteIndex] = newByte;
        PixelUpdate(index, color);
    }

    function getAll() public constant returns (byte[500000]) {
        return packedBytes;
    }

    modifier masterOnly() {
        require(msg.sender == masterAddress);
        _;
    }

    function setFee(uint256 fee) public masterOnly {
        feeWei = fee;
    }

    function withdraw() public masterOnly {
        masterAddress.transfer(this.balance);
    }

    function() public payable { }
}