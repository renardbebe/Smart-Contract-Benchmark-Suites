 

pragma solidity ^0.4.19;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract SyscoinDepositsManager {

    using SafeMath for uint;

    mapping(address => uint) public deposits;

    event DepositMade(address who, uint amount);
    event DepositWithdrawn(address who, uint amount);

     
    function() public payable {
        makeDeposit();
    }

     
     
     
    function getDeposit(address who) constant public returns (uint) {
        return deposits[who];
    }

     
     
    function makeDeposit() public payable returns (uint) {
        increaseDeposit(msg.sender, msg.value);
        return deposits[msg.sender];
    }

     
     
    function increaseDeposit(address who, uint amount) internal {
        deposits[who] = deposits[who].add(amount);
        require(deposits[who] <= address(this).balance);

        emit DepositMade(who, amount);
    }

     
     
     
    function withdrawDeposit(uint amount) public returns (uint) {
        require(deposits[msg.sender] >= amount);

        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        msg.sender.transfer(amount);

        emit DepositWithdrawn(msg.sender, amount);
        return deposits[msg.sender];
    }
}

 
contract SyscoinTransactionProcessor {
    function processTransaction(uint txHash, uint value, address destinationAddress, uint32 _assetGUID, address superblockSubmitterAddress) public returns (uint);
    function burn(uint _value, uint32 _assetGUID, bytes syscoinWitnessProgram) payable public returns (bool success);
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



 
library SyscoinMessageLibrary {

    uint constant p = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;   
    uint constant q = (p + 1) / 4;

     
    uint constant ERR_INVALID_HEADER = 10050;
    uint constant ERR_COINBASE_INDEX = 10060;  
    uint constant ERR_NOT_MERGE_MINED = 10070;  
    uint constant ERR_FOUND_TWICE = 10080;  
    uint constant ERR_NO_MERGE_HEADER = 10090;  
    uint constant ERR_NOT_IN_FIRST_20 = 10100;  
    uint constant ERR_CHAIN_MERKLE = 10110;
    uint constant ERR_PARENT_MERKLE = 10120;
    uint constant ERR_PROOF_OF_WORK = 10130;
    uint constant ERR_INVALID_HEADER_HASH = 10140;
    uint constant ERR_PROOF_OF_WORK_AUXPOW = 10150;
    uint constant ERR_PARSE_TX_OUTPUT_LENGTH = 10160;
    uint constant ERR_PARSE_TX_SYS = 10170;
    enum Network { MAINNET, TESTNET, REGTEST }
    uint32 constant SYSCOIN_TX_VERSION_ASSET_ALLOCATION_BURN = 0x7407;
    uint32 constant SYSCOIN_TX_VERSION_BURN = 0x7401;
     
    struct AuxPoW {
        uint blockHash;

        uint txHash;

        uint coinbaseMerkleRoot;  
        uint[] chainMerkleProof;  
        uint syscoinHashIndex;  
        uint coinbaseMerkleRootCode;  

        uint parentMerkleRoot;  
        uint[] parentMerkleProof;  
        uint coinbaseTxIndex;  

        uint parentNonce;
    }

     
     
     
    struct BlockHeader {
        uint32 bits;
        uint blockHash;
    }
     
     
    function parseVarInt(bytes memory txBytes, uint pos) private pure returns (uint, uint) {
         
        uint8 ibit = uint8(txBytes[pos]);
        pos += 1;   

        if (ibit < 0xfd) {
            return (ibit, pos);
        } else if (ibit == 0xfd) {
            return (getBytesLE(txBytes, pos, 16), pos + 2);
        } else if (ibit == 0xfe) {
            return (getBytesLE(txBytes, pos, 32), pos + 4);
        } else if (ibit == 0xff) {
            return (getBytesLE(txBytes, pos, 64), pos + 8);
        }
    }
     
    function getBytesLE(bytes memory data, uint pos, uint bits) internal pure returns (uint) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return uint16(data[pos])
                 + uint16(data[pos + 1]) * 2 ** 8;
        } else if (bits == 32) {
            return uint32(data[pos])
                 + uint32(data[pos + 1]) * 2 ** 8
                 + uint32(data[pos + 2]) * 2 ** 16
                 + uint32(data[pos + 3]) * 2 ** 24;
        } else if (bits == 64) {
            return uint64(data[pos])
                 + uint64(data[pos + 1]) * 2 ** 8
                 + uint64(data[pos + 2]) * 2 ** 16
                 + uint64(data[pos + 3]) * 2 ** 24
                 + uint64(data[pos + 4]) * 2 ** 32
                 + uint64(data[pos + 5]) * 2 ** 40
                 + uint64(data[pos + 6]) * 2 ** 48
                 + uint64(data[pos + 7]) * 2 ** 56;
        }
    }
    

     
     
     
     
     
     


    function parseTransaction(bytes memory txBytes) internal pure
             returns (uint, uint, address, uint32)
    {
        
        uint output_value;
        uint32 assetGUID;
        address destinationAddress;
        uint32 version;
        uint pos = 0;
        version = bytesToUint32Flipped(txBytes, pos);
        if(version != SYSCOIN_TX_VERSION_ASSET_ALLOCATION_BURN && version != SYSCOIN_TX_VERSION_BURN){
            return (ERR_PARSE_TX_SYS, output_value, destinationAddress, assetGUID);
        }
        pos = skipInputs(txBytes, 4);
            
        (output_value, destinationAddress, assetGUID) = scanBurns(txBytes, version, pos);
        return (0, output_value, destinationAddress, assetGUID);
    }


  
     
    function skipWitnesses(bytes memory txBytes, uint pos, uint n_inputs) private pure
             returns (uint)
    {
        uint n_stack;
        (n_stack, pos) = parseVarInt(txBytes, pos);
        
        uint script_len;
        for (uint i = 0; i < n_inputs; i++) {
            for (uint j = 0; j < n_stack; j++) {
                (script_len, pos) = parseVarInt(txBytes, pos);
                pos += script_len;
            }
        }

        return n_stack;
    }    

    function skipInputs(bytes memory txBytes, uint pos) private pure
             returns (uint)
    {
        uint n_inputs;
        uint script_len;
        (n_inputs, pos) = parseVarInt(txBytes, pos);
         
        if(n_inputs == 0x00){
            (n_inputs, pos) = parseVarInt(txBytes, pos);  
            assert(n_inputs != 0x00);
             
            (n_inputs, pos) = parseVarInt(txBytes, pos);
        }
        require(n_inputs < 100);

        for (uint i = 0; i < n_inputs; i++) {
            pos += 36;   
            (script_len, pos) = parseVarInt(txBytes, pos);
            pos += script_len + 4;   
        }

        return pos;
    }
             
     
    function scanBurns(bytes memory txBytes, uint32 version, uint pos) private pure
             returns (uint, address, uint32)
    {
        uint script_len;
        uint output_value;
        uint32 assetGUID = 0;
        address destinationAddress;
        uint n_outputs;
        (n_outputs, pos) = parseVarInt(txBytes, pos);
        require(n_outputs < 10);
        for (uint i = 0; i < n_outputs; i++) {
             
            if(version == SYSCOIN_TX_VERSION_BURN){
                output_value = getBytesLE(txBytes, pos, 64);
            }
            pos += 8;
             
            (script_len, pos) = parseVarInt(txBytes, pos);
            if(!isOpReturn(txBytes, pos)){
                 
                pos += script_len;
                output_value = 0;
                continue;
            }
             
            pos += 1;
            if(version == SYSCOIN_TX_VERSION_ASSET_ALLOCATION_BURN){
                (output_value, destinationAddress, assetGUID) = scanAssetDetails(txBytes, pos);
            }
            else if(version == SYSCOIN_TX_VERSION_BURN){                
                destinationAddress = scanSyscoinDetails(txBytes, pos);   
            }
             
            break;
        }

        return (output_value, destinationAddress, assetGUID);
    }

    function skipOutputs(bytes memory txBytes, uint pos) private pure
             returns (uint)
    {
        uint n_outputs;
        uint script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        require(n_outputs < 10);

        for (uint i = 0; i < n_outputs; i++) {
            pos += 8;
            (script_len, pos) = parseVarInt(txBytes, pos);
            pos += script_len;
        }

        return pos;
    }
     
     
    function getSlicePos(bytes memory txBytes, uint pos) private pure
             returns (uint slicePos)
    {
        slicePos = skipInputs(txBytes, pos + 4);
        slicePos = skipOutputs(txBytes, slicePos);
        slicePos += 4;  
    }
     
     
     
     
    function scanMerkleBranch(bytes memory txBytes, uint pos, uint stop) private pure
             returns (uint[], uint)
    {
        uint n_siblings;
        uint halt;

        (n_siblings, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_siblings) {
            halt = n_siblings;
        } else {
            halt = stop;
        }

        uint[] memory sibling_values = new uint[](halt);

        for (uint i = 0; i < halt; i++) {
            sibling_values[i] = flip32Bytes(sliceBytes32Int(txBytes, pos));
            pos += 32;
        }

        return (sibling_values, pos);
    }   
     
    function sliceBytes20(bytes memory data, uint start) private pure returns (bytes20) {
        uint160 slice = 0;
         
         
         
        for (uint i = 0; i < 20; i++) {
            slice += uint160(data[i + start]) << (8 * (19 - i));
        }
        return bytes20(slice);
    }
     
    function sliceBytes32Int(bytes memory data, uint start) private pure returns (uint slice) {
        for (uint i = 0; i < 32; i++) {
            if (i + start < data.length) {
                slice += uint(data[i + start]) << (8 * (31 - i));
            }
        }
    }

     
     
     
     
     
     
     
     
    function sliceArray(bytes memory _rawBytes, uint offset, uint _endIndex) internal view returns (bytes) {
        uint len = _endIndex - offset;
        bytes memory result = new bytes(len);
        assembly {
             
            if iszero(staticcall(gas, 0x04, add(add(_rawBytes, 0x20), offset), len, add(result, 0x20), len)) {
                revert(0, 0)
            }
        }
        return result;
    }
    
    
     
    function isOpReturn(bytes memory txBytes, uint pos) private pure
             returns (bool) {
         
         
        return 
            txBytes[pos] == byte(0x6a);
    }
     
    function scanSyscoinDetails(bytes memory txBytes, uint pos) private pure
             returns (address) {      
        uint8 op;
        (op, pos) = getOpcode(txBytes, pos);
         
        require(op == 0x14);
        return readEthereumAddress(txBytes, pos);
    }    
     
    function scanAssetDetails(bytes memory txBytes, uint pos) private pure
             returns (uint, address, uint32) {
                 
        uint32 assetGUID;
        address destinationAddress;
        uint output_value;
        uint8 op;
         
        (op, pos) = getOpcode(txBytes, pos);
         
        require(op == 0x04);
        assetGUID = bytesToUint32(txBytes, pos);
        pos += op;
         
        (op, pos) = getOpcode(txBytes, pos);
        require(op == 0x08);
        output_value = bytesToUint64(txBytes, pos);
        pos += op;
          
        (op, pos) = getOpcode(txBytes, pos);
         
        require(op == 0x14);
        destinationAddress = readEthereumAddress(txBytes, pos);       
        return (output_value, destinationAddress, assetGUID);
    }         
     
    function readEthereumAddress(bytes memory txBytes, uint pos) private pure
             returns (address) {
        uint256 data;
        assembly {
            data := mload(add(add(txBytes, 20), pos))
        }
        return address(uint160(data));
    }

     
    function getOpcode(bytes memory txBytes, uint pos) private pure
             returns (uint8, uint)
    {
        require(pos < txBytes.length);
        return (uint8(txBytes[pos]), pos + 1);
    }

     
     
     
     
    function flip32Bytes(uint _input) internal pure returns (uint result) {
        assembly {
            let pos := mload(0x40)
            for { let i := 0 } lt(i, 32) { i := add(i, 1) } {
                mstore8(add(pos, i), byte(sub(31, i), _input))
            }
            result := mload(pos)
        }
    }
     
    struct UintWrapper {
        uint value;
    }

    function ptr(UintWrapper memory uw) private pure returns (uint addr) {
        assembly {
            addr := uw
        }
    }

    function parseAuxPoW(bytes memory rawBytes, uint pos) internal view
             returns (AuxPoW memory auxpow)
    {
         
        pos += 80;  
        uint slicePos;
        (slicePos) = getSlicePos(rawBytes, pos);
        auxpow.txHash = dblShaFlipMem(rawBytes, pos, slicePos - pos);
        pos = slicePos;
         
        pos += 32;
        (auxpow.parentMerkleProof, pos) = scanMerkleBranch(rawBytes, pos, 0);
        auxpow.coinbaseTxIndex = getBytesLE(rawBytes, pos, 32);
        pos += 4;
        (auxpow.chainMerkleProof, pos) = scanMerkleBranch(rawBytes, pos, 0);
        auxpow.syscoinHashIndex = getBytesLE(rawBytes, pos, 32);
        pos += 4;
         
        auxpow.blockHash = dblShaFlipMem(rawBytes, pos, 80);
        pos += 36;  
        auxpow.parentMerkleRoot = sliceBytes32Int(rawBytes, pos);
        pos += 40;  
        auxpow.parentNonce = getBytesLE(rawBytes, pos, 32);
        uint coinbaseMerkleRootPosition;
        (auxpow.coinbaseMerkleRoot, coinbaseMerkleRootPosition, auxpow.coinbaseMerkleRootCode) = findCoinbaseMerkleRoot(rawBytes);
    }

     
     
     
     
    function findCoinbaseMerkleRoot(bytes memory rawBytes) private pure
             returns (uint, uint, uint)
    {
        uint position;
        bool found = false;

        for (uint i = 0; i < rawBytes.length; ++i) {
            if (rawBytes[i] == 0xfa && rawBytes[i+1] == 0xbe && rawBytes[i+2] == 0x6d && rawBytes[i+3] == 0x6d) {
                if (found) {  
                    return (0, position - 4, ERR_FOUND_TWICE);
                } else {
                    found = true;
                    position = i + 4;
                }
            }
        }

        if (!found) {  
            return (0, position - 4, ERR_NO_MERGE_HEADER);
        } else {
            return (sliceBytes32Int(rawBytes, position), position - 4, 1);
        }
    }

     
     
     
     
     
     
    function makeMerkle(bytes32[] hashes2) external pure returns (bytes32) {
        bytes32[] memory hashes = hashes2;
        uint length = hashes.length;
        if (length == 1) return hashes[0];
        require(length > 0);
        uint i;
        uint j;
        uint k;
        k = 0;
        while (length > 1) {
            k = 0;
            for (i = 0; i < length; i += 2) {
                j = i+1<length ? i+1 : length-1;
                hashes[k] = bytes32(concatHash(uint(hashes[i]), uint(hashes[j])));
                k += 1;
            }
            length = k;
        }
        return hashes[0];
    }

     
     
     
     
     
     
     
    function computeMerkle(uint _txHash, uint _txIndex, uint[] memory _siblings) internal pure returns (uint) {
        uint resultHash = _txHash;
        uint i = 0;
        while (i < _siblings.length) {
            uint proofHex = _siblings[i];

            uint sideOfSiblings = _txIndex % 2;   

            uint left;
            uint right;
            if (sideOfSiblings == 1) {
                left = proofHex;
                right = resultHash;
            } else if (sideOfSiblings == 0) {
                left = resultHash;
                right = proofHex;
            }

            resultHash = concatHash(left, right);

            _txIndex /= 2;
            i += 1;
        }

        return resultHash;
    }

     
     
     
     
     
     
     
    function computeParentMerkle(AuxPoW memory _ap) internal pure returns (uint) {
        return flip32Bytes(computeMerkle(_ap.txHash,
                                         _ap.coinbaseTxIndex,
                                         _ap.parentMerkleProof));
    }

     
     
     
     
     
     
     
     
    function computeChainMerkle(uint _blockHash, AuxPoW memory _ap) internal pure returns (uint) {
        return computeMerkle(_blockHash,
                             _ap.syscoinHashIndex,
                             _ap.chainMerkleProof);
    }

     
     
     
     
     
     
     
     
    function concatHash(uint _tx1, uint _tx2) internal pure returns (uint) {
        return flip32Bytes(uint(sha256(abi.encodePacked(sha256(abi.encodePacked(flip32Bytes(_tx1), flip32Bytes(_tx2)))))));
    }

     
     
     
     
     
     
     
     
    function checkAuxPoW(uint _blockHash, AuxPoW memory _ap) internal pure returns (uint) {
        if (_ap.coinbaseTxIndex != 0) {
            return ERR_COINBASE_INDEX;
        }

        if (_ap.coinbaseMerkleRootCode != 1) {
            return _ap.coinbaseMerkleRootCode;
        }

        if (computeChainMerkle(_blockHash, _ap) != _ap.coinbaseMerkleRoot) {
            return ERR_CHAIN_MERKLE;
        }

        if (computeParentMerkle(_ap) != _ap.parentMerkleRoot) {
            return ERR_PARENT_MERKLE;
        }

        return 1;
    }

    function sha256mem(bytes memory _rawBytes, uint offset, uint len) internal view returns (bytes32 result) {
        assembly {
             
             
            let ptr := mload(0x40)
            if iszero(staticcall(gas, 0x02, add(add(_rawBytes, 0x20), offset), len, ptr, 0x20)) {
                revert(0, 0)
            }
            result := mload(ptr)
        }
    }

     
     
     
    function dblShaFlip(bytes _dataBytes) internal pure returns (uint) {
        return flip32Bytes(uint(sha256(abi.encodePacked(sha256(abi.encodePacked(_dataBytes))))));
    }

     
     
     
    function dblShaFlipMem(bytes memory _rawBytes, uint offset, uint len) internal view returns (uint) {
        return flip32Bytes(uint(sha256(abi.encodePacked(sha256mem(_rawBytes, offset, len)))));
    }

     
    function readBytes32(bytes memory data, uint offset) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(add(data, 0x20), offset))
        }
        return result;
    }

     
    function readUint32(bytes memory data, uint offset) internal pure returns (uint32) {
        uint32 result;
        assembly {
            result := mload(add(add(data, 0x20), offset))
            
        }
        return result;
    }

     
     
     
     
     
    function targetFromBits(uint32 _bits) internal pure returns (uint) {
        uint exp = _bits / 0x1000000;   
        uint mant = _bits & 0xffffff;
        return mant * 256**(exp - 3);
    }

    uint constant SYSCOIN_DIFFICULTY_ONE = 0xFFFFF * 256**(0x1e - 3);

     
     
     
     
    function targetToDiff(uint target) internal pure returns (uint) {
        return SYSCOIN_DIFFICULTY_ONE / target;
    }
    

     
     
     
     
     
     

     
     
     
     
     
    function getHashPrevBlock(bytes memory _blockHeader) internal pure returns (uint) {
        uint hashPrevBlock;
        assembly {
            hashPrevBlock := mload(add(add(_blockHeader, 32), 0x04))
        }
        return flip32Bytes(hashPrevBlock);
    }

     
     
     
     
     
    function getHeaderMerkleRoot(bytes memory _blockHeader) public pure returns (uint) {
        uint merkle;
        assembly {
            merkle := mload(add(add(_blockHeader, 32), 0x24))
        }
        return flip32Bytes(merkle);
    }

     
     
     
     
     
    function getTimestamp(bytes memory _blockHeader) internal pure returns (uint32 time) {
        return bytesToUint32Flipped(_blockHeader, 0x44);
    }

     
     
     
     
     
    function getBits(bytes memory _blockHeader) internal pure returns (uint32 bits) {
        return bytesToUint32Flipped(_blockHeader, 0x48);
    }


     
     
     
     
    function parseHeaderBytes(bytes memory _rawBytes, uint pos) internal view returns (BlockHeader bh) {
        bh.bits = getBits(_rawBytes);
        bh.blockHash = dblShaFlipMem(_rawBytes, pos, 80);
    }

    uint32 constant VERSION_AUXPOW = (1 << 8);

     
     
    function bytesToUint32Flipped(bytes memory input, uint pos) internal pure returns (uint32 result) {
        result = uint32(input[pos]) + uint32(input[pos + 1])*(2**8) + uint32(input[pos + 2])*(2**16) + uint32(input[pos + 3])*(2**24);
    }
    function bytesToUint64(bytes memory input, uint pos) internal pure returns (uint64 result) {
        result = uint64(input[pos+7]) + uint64(input[pos + 6])*(2**8) + uint64(input[pos + 5])*(2**16) + uint64(input[pos + 4])*(2**24) + uint64(input[pos + 3])*(2**32) + uint64(input[pos + 2])*(2**40) + uint64(input[pos + 1])*(2**48) + uint64(input[pos])*(2**56);
    }
     function bytesToUint32(bytes memory input, uint pos) internal pure returns (uint32 result) {
        result = uint32(input[pos+3]) + uint32(input[pos + 2])*(2**8) + uint32(input[pos + 1])*(2**16) + uint32(input[pos])*(2**24);
    }  
     
    function isMergeMined(bytes memory _rawBytes, uint pos) internal pure returns (bool) {
        return bytesToUint32Flipped(_rawBytes, pos) & VERSION_AUXPOW != 0;
    }

     
     
     
	 
     
    function verifyBlockHeader(bytes _blockHeaderBytes, uint _pos, uint _proposedBlockHash) external view returns (uint, bool) {
        BlockHeader memory blockHeader = parseHeaderBytes(_blockHeaderBytes, _pos);
        uint blockSha256Hash = blockHeader.blockHash;
		 
		if(blockSha256Hash != _proposedBlockHash){
			return (ERR_INVALID_HEADER_HASH, true);
		}
        uint target = targetFromBits(blockHeader.bits);
        if (_blockHeaderBytes.length > 80 && isMergeMined(_blockHeaderBytes, 0)) {
            AuxPoW memory ap = parseAuxPoW(_blockHeaderBytes, _pos);
            if (ap.blockHash > target) {

                return (ERR_PROOF_OF_WORK_AUXPOW, true);
            }
            uint auxPoWCode = checkAuxPoW(blockSha256Hash, ap);
            if (auxPoWCode != 1) {
                return (auxPoWCode, true);
            }
            return (0, true);
        } else {
            if (_proposedBlockHash > target) {
                return (ERR_PROOF_OF_WORK, false);
            }
            return (0, false);
        }
    }

     
    int64 constant TARGET_TIMESPAN =  int64(21600); 
    int64 constant TARGET_TIMESPAN_DIV_4 = TARGET_TIMESPAN / int64(4);
    int64 constant TARGET_TIMESPAN_MUL_4 = TARGET_TIMESPAN * int64(4);
    int64 constant TARGET_TIMESPAN_ADJUSTMENT =  int64(360);   
    uint constant INITIAL_CHAIN_WORK =  0x100001; 
    uint constant POW_LIMIT = 0x00000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

     
    function diffFromBits(uint32 bits) external pure returns (uint) {
        return targetToDiff(targetFromBits(bits))*INITIAL_CHAIN_WORK;
    }
    
    function difficultyAdjustmentInterval() external pure returns (int64) {
        return TARGET_TIMESPAN_ADJUSTMENT;
    }
     
     
     
     
    function calculateDifficulty(int64 _actualTimespan, uint32 _bits) external pure returns (uint32 result) {
       int64 actualTimespan = _actualTimespan;
         
        if (_actualTimespan < TARGET_TIMESPAN_DIV_4) {
            actualTimespan = TARGET_TIMESPAN_DIV_4;
        } else if (_actualTimespan > TARGET_TIMESPAN_MUL_4) {
            actualTimespan = TARGET_TIMESPAN_MUL_4;
        }

         
        uint bnNew = targetFromBits(_bits);
        bnNew = bnNew * uint(actualTimespan);
        bnNew = uint(bnNew) / uint(TARGET_TIMESPAN);

        if (bnNew > POW_LIMIT) {
            bnNew = POW_LIMIT;
        }

        return toCompactBits(bnNew);
    }

     
     
     
     
     
    function shiftRight(uint _val, uint _shift) private pure returns (uint) {
        return _val / uint(2)**_shift;
    }

     
     
     
     
     
    function shiftLeft(uint _val, uint _shift) private pure returns (uint) {
        return _val * uint(2)**_shift;
    }

     
     
     
     
    function bitLen(uint _val) private pure returns (uint length) {
        uint int_type = _val;
        while (int_type > 0) {
            int_type = shiftRight(int_type, 1);
            length += 1;
        }
    }

     
     
     
     
     
     
    function toCompactBits(uint _val) private pure returns (uint32) {
        uint nbytes = uint (shiftRight((bitLen(_val) + 7), 3));
        uint32 compact = 0;
        if (nbytes <= 3) {
            compact = uint32 (shiftLeft((_val & 0xFFFFFF), 8 * (3 - nbytes)));
        } else {
            compact = uint32 (shiftRight(_val, 8 * (nbytes - 3)));
            compact = uint32 (compact & 0xFFFFFF);
        }

         
         
        if ((compact & 0x00800000) > 0) {
            compact = uint32(shiftRight(compact, 8));
            nbytes += 1;
        }

        return compact | uint32(shiftLeft(nbytes, 24));
    }
}

 
contract SyscoinErrorCodes {
     
    uint constant ERR_SUPERBLOCK_OK = 0;
    uint constant ERR_SUPERBLOCK_BAD_STATUS = 50020;
    uint constant ERR_SUPERBLOCK_BAD_SYSCOIN_STATUS = 50025;
    uint constant ERR_SUPERBLOCK_NO_TIMEOUT = 50030;
    uint constant ERR_SUPERBLOCK_BAD_TIMESTAMP = 50035;
    uint constant ERR_SUPERBLOCK_INVALID_MERKLE = 50040;
    uint constant ERR_SUPERBLOCK_BAD_PARENT = 50050;
    uint constant ERR_SUPERBLOCK_OWN_CHALLENGE = 50055;

    uint constant ERR_SUPERBLOCK_MIN_DEPOSIT = 50060;

    uint constant ERR_SUPERBLOCK_NOT_CLAIMMANAGER = 50070;

    uint constant ERR_SUPERBLOCK_BAD_CLAIM = 50080;
    uint constant ERR_SUPERBLOCK_VERIFICATION_PENDING = 50090;
    uint constant ERR_SUPERBLOCK_CLAIM_DECIDED = 50100;
    uint constant ERR_SUPERBLOCK_BAD_CHALLENGER = 50110;

    uint constant ERR_SUPERBLOCK_BAD_ACCUMULATED_WORK = 50120;
    uint constant ERR_SUPERBLOCK_BAD_BITS = 50130;
    uint constant ERR_SUPERBLOCK_MISSING_CONFIRMATIONS = 50140;
    uint constant ERR_SUPERBLOCK_BAD_LASTBLOCK = 50150;
    uint constant ERR_SUPERBLOCK_BAD_BLOCKHEIGHT = 50160;

     
    uint constant ERR_BAD_FEE = 20010;
    uint constant ERR_CONFIRMATIONS = 20020;
    uint constant ERR_CHAIN = 20030;
    uint constant ERR_SUPERBLOCK = 20040;
    uint constant ERR_MERKLE_ROOT = 20050;
    uint constant ERR_TX_64BYTE = 20060;
     
    uint constant ERR_RELAY_VERIFY = 30010;

     
    uint constant public minReward = 1000000000000000000;
    uint constant public superblockCost = 440000;
    uint constant public challengeCost = 34000;
    uint constant public minProposalDeposit = challengeCost + minReward;
    uint constant public minChallengeDeposit = superblockCost + minReward;
    uint constant public respondMerkleRootHashesCost = 378000;  
    uint constant public respondBlockHeaderCost = 40000;
    uint constant public verifySuperblockCost = 220000;
}

 
 
 
contract SyscoinSuperblocks is SyscoinErrorCodes {

     
    enum Status { Unitialized, New, InBattle, SemiApproved, Approved, Invalid }

    struct SuperblockInfo {
        bytes32 blocksMerkleRoot;
        uint accumulatedWork;
        uint timestamp;
        uint prevTimestamp;
        bytes32 lastHash;
        bytes32 parentId;
        address submitter;
        bytes32 ancestors;
        uint32 lastBits;
        uint32 index;
        uint32 height;
        uint32 blockHeight;
        Status status;
    }

     
    mapping (bytes32 => SuperblockInfo) superblocks;

     
    mapping (uint32 => bytes32) private indexSuperblock;

    struct ProcessTransactionParams {
        uint value;
        address destinationAddress;
        uint32 assetGUID;
        address superblockSubmitterAddress;
        SyscoinTransactionProcessor untrustedTargetContract;
    }

    mapping (uint => ProcessTransactionParams) private txParams;

    uint32 indexNextSuperblock;

    bytes32 public bestSuperblock;
    uint public bestSuperblockAccumulatedWork;

    event NewSuperblock(bytes32 superblockHash, address who);
    event ApprovedSuperblock(bytes32 superblockHash, address who);
    event ChallengeSuperblock(bytes32 superblockHash, address who);
    event SemiApprovedSuperblock(bytes32 superblockHash, address who);
    event InvalidSuperblock(bytes32 superblockHash, address who);

    event ErrorSuperblock(bytes32 superblockHash, uint err);

    event VerifyTransaction(bytes32 txHash, uint returnCode);
    event RelayTransaction(bytes32 txHash, uint returnCode);

     
    address public trustedClaimManager;

    modifier onlyClaimManager() {
        require(msg.sender == trustedClaimManager);
        _;
    }

     
    constructor() public {}

     
     
     
    function setClaimManager(address _claimManager) public {
        require(address(trustedClaimManager) == 0x0 && _claimManager != 0x0);
        trustedClaimManager = _claimManager;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function initialize(
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        uint32 _blockHeight
    ) public returns (uint, bytes32) {
        require(bestSuperblock == 0);
        require(_parentId == 0);

        bytes32 superblockHash = calcSuperblockHash(_blocksMerkleRoot, _accumulatedWork, _timestamp, _prevTimestamp, _lastHash, _lastBits, _parentId, _blockHeight);
        SuperblockInfo storage superblock = superblocks[superblockHash];

        require(superblock.status == Status.Unitialized);

        indexSuperblock[indexNextSuperblock] = superblockHash;

        superblock.blocksMerkleRoot = _blocksMerkleRoot;
        superblock.accumulatedWork = _accumulatedWork;
        superblock.timestamp = _timestamp;
        superblock.prevTimestamp = _prevTimestamp;
        superblock.lastHash = _lastHash;
        superblock.parentId = _parentId;
        superblock.submitter = msg.sender;
        superblock.index = indexNextSuperblock;
        superblock.height = 1;
        superblock.lastBits = _lastBits;
        superblock.status = Status.Approved;
        superblock.ancestors = 0x0;
        superblock.blockHeight = _blockHeight;
        indexNextSuperblock++;

        emit NewSuperblock(superblockHash, msg.sender);

        bestSuperblock = superblockHash;
        bestSuperblockAccumulatedWork = _accumulatedWork;

        emit ApprovedSuperblock(superblockHash, msg.sender);

        return (ERR_SUPERBLOCK_OK, superblockHash);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function propose(
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        uint32 _blockHeight,
        address submitter
    ) public returns (uint, bytes32) {
        if (msg.sender != trustedClaimManager) {
            emit ErrorSuperblock(0, ERR_SUPERBLOCK_NOT_CLAIMMANAGER);
            return (ERR_SUPERBLOCK_NOT_CLAIMMANAGER, 0);
        }

        SuperblockInfo storage parent = superblocks[_parentId];
        if (parent.status != Status.SemiApproved && parent.status != Status.Approved) {
            emit ErrorSuperblock(superblockHash, ERR_SUPERBLOCK_BAD_PARENT);
            return (ERR_SUPERBLOCK_BAD_PARENT, 0);
        }

        bytes32 superblockHash = calcSuperblockHash(_blocksMerkleRoot, _accumulatedWork, _timestamp, _prevTimestamp, _lastHash, _lastBits, _parentId, _blockHeight);
        SuperblockInfo storage superblock = superblocks[superblockHash];
        if (superblock.status == Status.Unitialized) {
            indexSuperblock[indexNextSuperblock] = superblockHash;
            superblock.blocksMerkleRoot = _blocksMerkleRoot;
            superblock.accumulatedWork = _accumulatedWork;
            superblock.timestamp = _timestamp;
            superblock.prevTimestamp = _prevTimestamp;
            superblock.lastHash = _lastHash;
            superblock.parentId = _parentId;
            superblock.submitter = submitter;
            superblock.index = indexNextSuperblock;
            superblock.height = parent.height + 1;
            superblock.lastBits = _lastBits;
            superblock.status = Status.New;
            superblock.blockHeight = _blockHeight;
            superblock.ancestors = updateAncestors(parent.ancestors, parent.index, parent.height);
            indexNextSuperblock++;
            emit NewSuperblock(superblockHash, submitter);
        }
        

        return (ERR_SUPERBLOCK_OK, superblockHash);
    }

     
     
     
     
     
     
     
     
     
    function confirm(bytes32 _superblockHash, address _validator) public returns (uint, bytes32) {
        if (msg.sender != trustedClaimManager) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_NOT_CLAIMMANAGER);
            return (ERR_SUPERBLOCK_NOT_CLAIMMANAGER, 0);
        }
        SuperblockInfo storage superblock = superblocks[_superblockHash];
        if (superblock.status != Status.New && superblock.status != Status.SemiApproved) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return (ERR_SUPERBLOCK_BAD_STATUS, 0);
        }
        SuperblockInfo storage parent = superblocks[superblock.parentId];
        if (parent.status != Status.Approved) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_BAD_PARENT);
            return (ERR_SUPERBLOCK_BAD_PARENT, 0);
        }
        superblock.status = Status.Approved;
        if (superblock.accumulatedWork > bestSuperblockAccumulatedWork) {
            bestSuperblock = _superblockHash;
            bestSuperblockAccumulatedWork = superblock.accumulatedWork;
        }
        emit ApprovedSuperblock(_superblockHash, _validator);
        return (ERR_SUPERBLOCK_OK, _superblockHash);
    }

     
     
     
     
     
     
     
     
    function challenge(bytes32 _superblockHash, address _challenger) public returns (uint, bytes32) {
        if (msg.sender != trustedClaimManager) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_NOT_CLAIMMANAGER);
            return (ERR_SUPERBLOCK_NOT_CLAIMMANAGER, 0);
        }
        SuperblockInfo storage superblock = superblocks[_superblockHash];
        if (superblock.status != Status.New && superblock.status != Status.InBattle) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return (ERR_SUPERBLOCK_BAD_STATUS, 0);
        }
        if(superblock.submitter == _challenger){
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_OWN_CHALLENGE);
            return (ERR_SUPERBLOCK_OWN_CHALLENGE, 0);        
        }
        superblock.status = Status.InBattle;
        emit ChallengeSuperblock(_superblockHash, _challenger);
        return (ERR_SUPERBLOCK_OK, _superblockHash);
    }

     
     
     
     
     
     
     
     
     
    function semiApprove(bytes32 _superblockHash, address _validator) public returns (uint, bytes32) {
        if (msg.sender != trustedClaimManager) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_NOT_CLAIMMANAGER);
            return (ERR_SUPERBLOCK_NOT_CLAIMMANAGER, 0);
        }
        SuperblockInfo storage superblock = superblocks[_superblockHash];

        if (superblock.status != Status.InBattle && superblock.status != Status.New) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return (ERR_SUPERBLOCK_BAD_STATUS, 0);
        }
        superblock.status = Status.SemiApproved;
        emit SemiApprovedSuperblock(_superblockHash, _validator);
        return (ERR_SUPERBLOCK_OK, _superblockHash);
    }

     
     
     
     
     
     
     
     
     
     
    function invalidate(bytes32 _superblockHash, address _validator) public returns (uint, bytes32) {
        if (msg.sender != trustedClaimManager) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_NOT_CLAIMMANAGER);
            return (ERR_SUPERBLOCK_NOT_CLAIMMANAGER, 0);
        }
        SuperblockInfo storage superblock = superblocks[_superblockHash];
        if (superblock.status != Status.InBattle && superblock.status != Status.SemiApproved) {
            emit ErrorSuperblock(_superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return (ERR_SUPERBLOCK_BAD_STATUS, 0);
        }
        superblock.status = Status.Invalid;
        emit InvalidSuperblock(_superblockHash, _validator);
        return (ERR_SUPERBLOCK_OK, _superblockHash);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function relayTx(
        bytes memory _txBytes,
        uint _txIndex,
        uint[] _txSiblings,
        bytes memory _syscoinBlockHeader,
        uint _syscoinBlockIndex,
        uint[] memory _syscoinBlockSiblings,
        bytes32 _superblockHash,
        SyscoinTransactionProcessor _untrustedTargetContract
    ) public returns (uint) {

         
        if (bytes32(SyscoinMessageLibrary.computeMerkle(SyscoinMessageLibrary.dblShaFlip(_syscoinBlockHeader), _syscoinBlockIndex, _syscoinBlockSiblings))
            != getSuperblockMerkleRoot(_superblockHash)) {
             
            emit RelayTransaction(bytes32(0), ERR_SUPERBLOCK);
            return ERR_SUPERBLOCK;
        }
        uint txHash = verifyTx(_txBytes, _txIndex, _txSiblings, _syscoinBlockHeader, _superblockHash);
        if (txHash != 0) {
            uint ret = parseTxHelper(_txBytes, txHash, _untrustedTargetContract);
            if(ret != 0){
                emit RelayTransaction(bytes32(0), ret);
                return ret;
            }
            ProcessTransactionParams memory params = txParams[txHash];
            params.superblockSubmitterAddress = superblocks[_superblockHash].submitter;
            txParams[txHash] = params;
            return verifyTxHelper(txHash);
        }
        emit RelayTransaction(bytes32(0), ERR_RELAY_VERIFY);
        return(ERR_RELAY_VERIFY);        
    }
    function parseTxHelper(bytes memory _txBytes, uint txHash, SyscoinTransactionProcessor _untrustedTargetContract) private returns (uint) {
        uint value;
        address destinationAddress;
        uint32 _assetGUID;
        uint ret;
        (ret, value, destinationAddress, _assetGUID) = SyscoinMessageLibrary.parseTransaction(_txBytes);
        if(ret != 0){
            return ret;
        }

        ProcessTransactionParams memory params;
        params.value = value;
        params.destinationAddress = destinationAddress;
        params.assetGUID = _assetGUID;
        params.untrustedTargetContract = _untrustedTargetContract;
        txParams[txHash] = params;        
        return 0;
    }
    function verifyTxHelper(uint txHash) private returns (uint) {
        ProcessTransactionParams memory params = txParams[txHash];        
        uint returnCode = params.untrustedTargetContract.processTransaction(txHash, params.value, params.destinationAddress, params.assetGUID, params.superblockSubmitterAddress);
        emit RelayTransaction(bytes32(txHash), returnCode);
        return (returnCode);
    }
     
     
     
     
     
     
     
     
     
     
     
    function verifyTx(
        bytes memory _txBytes,
        uint _txIndex,
        uint[] memory _siblings,
        bytes memory _txBlockHeaderBytes,
        bytes32 _txsuperblockHash
    ) public returns (uint) {
        uint txHash = SyscoinMessageLibrary.dblShaFlip(_txBytes);

        if (_txBytes.length == 64) {   
            emit VerifyTransaction(bytes32(txHash), ERR_TX_64BYTE);
            return 0;
        }

        if (helperVerifyHash(txHash, _txIndex, _siblings, _txBlockHeaderBytes, _txsuperblockHash) == 1) {
            return txHash;
        } else {
             
            return 0;
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function helperVerifyHash(
        uint256 _txHash,
        uint _txIndex,
        uint[] memory _siblings,
        bytes memory _blockHeaderBytes,
        bytes32 _txsuperblockHash
    ) private returns (uint) {

         
        if (!isApproved(_txsuperblockHash) || !inMainChain(_txsuperblockHash)) {
            emit VerifyTransaction(bytes32(_txHash), ERR_CHAIN);
            return (ERR_CHAIN);
        }

         
        uint merkle = SyscoinMessageLibrary.getHeaderMerkleRoot(_blockHeaderBytes);
        if (SyscoinMessageLibrary.computeMerkle(_txHash, _txIndex, _siblings) != merkle) {
            emit VerifyTransaction(bytes32(_txHash), ERR_MERKLE_ROOT);
            return (ERR_MERKLE_ROOT);
        }

        emit VerifyTransaction(bytes32(_txHash), 1);
        return (1);
    }

     
     
     
     
     
     
     
     
     
     
     
    function calcSuperblockHash(
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        uint32 _blockHeight
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _blocksMerkleRoot,
            _accumulatedWork,
            _timestamp,
            _prevTimestamp,
            _lastHash,
            _lastBits,
            _parentId,
            _blockHeight
        ));
    }

     
     
     
    function getBestSuperblock() public view returns (bytes32) {
        return bestSuperblock;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getSuperblock(bytes32 superblockHash) public view returns (
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        address _submitter,
        Status _status,
        uint32 _blockHeight
    ) {
        SuperblockInfo storage superblock = superblocks[superblockHash];
        return (
            superblock.blocksMerkleRoot,
            superblock.accumulatedWork,
            superblock.timestamp,
            superblock.prevTimestamp,
            superblock.lastHash,
            superblock.lastBits,
            superblock.parentId,
            superblock.submitter,
            superblock.status,
            superblock.blockHeight
        );
    }

     
    function getSuperblockHeight(bytes32 superblockHash) public view returns (uint32) {
        return superblocks[superblockHash].height;
    }

     
    function getSuperblockIndex(bytes32 superblockHash) public view returns (uint32) {
        return superblocks[superblockHash].index;
    }

     
    function getSuperblockAncestors(bytes32 superblockHash) public view returns (bytes32) {
        return superblocks[superblockHash].ancestors;
    }

     
    function getSuperblockMerkleRoot(bytes32 _superblockHash) public view returns (bytes32) {
        return superblocks[_superblockHash].blocksMerkleRoot;
    }

     
    function getSuperblockTimestamp(bytes32 _superblockHash) public view returns (uint) {
        return superblocks[_superblockHash].timestamp;
    }

     
    function getSuperblockPrevTimestamp(bytes32 _superblockHash) public view returns (uint) {
        return superblocks[_superblockHash].prevTimestamp;
    }

     
    function getSuperblockLastHash(bytes32 _superblockHash) public view returns (bytes32) {
        return superblocks[_superblockHash].lastHash;
    }

     
    function getSuperblockParentId(bytes32 _superblockHash) public view returns (bytes32) {
        return superblocks[_superblockHash].parentId;
    }

     
    function getSuperblockAccumulatedWork(bytes32 _superblockHash) public view returns (uint) {
        return superblocks[_superblockHash].accumulatedWork;
    }

     
    function getSuperblockStatus(bytes32 _superblockHash) public view returns (Status) {
        return superblocks[_superblockHash].status;
    }

     
    function getIndexNextSuperblock() public view returns (uint32) {
        return indexNextSuperblock;
    }

     
    function makeMerkle(bytes32[] hashes) public pure returns (bytes32) {
        return SyscoinMessageLibrary.makeMerkle(hashes);
    }

    function isApproved(bytes32 _superblockHash) public view returns (bool) {
        return (getSuperblockStatus(_superblockHash) == Status.Approved);
    }

    function getChainHeight() public view returns (uint) {
        return superblocks[bestSuperblock].height;
    }

     
     
     
     
     
     
    function writeUint32(bytes32 _word, uint _position, uint32 _fourBytes) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            let pointer := mload(0x40)
            mstore(pointer, _word)
            mstore8(add(pointer, _position), byte(28, _fourBytes))
            mstore8(add(pointer, add(_position,1)), byte(29, _fourBytes))
            mstore8(add(pointer, add(_position,2)), byte(30, _fourBytes))
            mstore8(add(pointer, add(_position,3)), byte(31, _fourBytes))
            result := mload(pointer)
        }
        return result;
    }

    uint constant ANCESTOR_STEP = 5;
    uint constant NUM_ANCESTOR_DEPTHS = 8;

     
    function updateAncestors(bytes32 ancestors, uint32 index, uint height) internal pure returns (bytes32) {
        uint step = ANCESTOR_STEP;
        ancestors = writeUint32(ancestors, 0, index);
        uint i = 1;
        while (i<NUM_ANCESTOR_DEPTHS && (height % step == 1)) {
            ancestors = writeUint32(ancestors, 4*i, index);
            step *= ANCESTOR_STEP;
            ++i;
        }
        return ancestors;
    }

     
     
     
     
     
     
     
     
     
    function getSuperblockLocator() public view returns (bytes32[9]) {
        bytes32[9] memory locator;
        locator[0] = bestSuperblock;
        bytes32 ancestors = getSuperblockAncestors(bestSuperblock);
        uint i = NUM_ANCESTOR_DEPTHS;
        while (i > 0) {
            locator[i] = indexSuperblock[uint32(ancestors & 0xFFFFFFFF)];
            ancestors >>= 32;
            --i;
        }
        return locator;
    }

     
    function getSuperblockAncestor(bytes32 superblockHash, uint index) internal view returns (bytes32) {
        bytes32 ancestors = superblocks[superblockHash].ancestors;
        uint32 ancestorsIndex =
            uint32(ancestors[4*index + 0]) * 0x1000000 +
            uint32(ancestors[4*index + 1]) * 0x10000 +
            uint32(ancestors[4*index + 2]) * 0x100 +
            uint32(ancestors[4*index + 3]) * 0x1;
        return indexSuperblock[ancestorsIndex];
    }

     
     
     
     
    function getAncDepth(uint _index) private pure returns (uint) {
        return ANCESTOR_STEP**(uint(_index));
    }

     
     
     
     
    function getSuperblockAt(uint _height) public view returns (bytes32) {
        bytes32 superblockHash = bestSuperblock;
        uint index = NUM_ANCESTOR_DEPTHS - 1;

        while (getSuperblockHeight(superblockHash) > _height) {
            while (getSuperblockHeight(superblockHash) - _height < getAncDepth(index) && index > 0) {
                index -= 1;
            }
            superblockHash = getSuperblockAncestor(superblockHash, index);
        }

        return superblockHash;
    }

     
     
     
     
     
    function inMainChain(bytes32 _superblockHash) internal view returns (bool) {
        uint height = getSuperblockHeight(_superblockHash);
        if (height == 0) return false;
        return (getSuperblockAt(height) == _superblockHash);
    }
}

 
contract SyscoinBattleManager is SyscoinErrorCodes {

    enum ChallengeState {
        Unchallenged,              
        Challenged,                
        QueryMerkleRootHashes,     
        RespondMerkleRootHashes,   
        QueryBlockHeader,          
        RespondBlockHeader,        
        PendingVerification,       
        SuperblockVerified,        
        SuperblockFailed           
    }

    enum BlockInfoStatus {
        Uninitialized,
        Requested,
		Verified
    }

    struct BlockInfo {
        bytes32 prevBlock;
        uint64 timestamp;
        uint32 bits;
        BlockInfoStatus status;
        bytes powBlockHeader;
        bytes32 blockHash;
    }

    struct BattleSession {
        bytes32 id;
        bytes32 superblockHash;
        address submitter;
        address challenger;
        uint lastActionTimestamp;          
        uint lastActionClaimant;           
        uint lastActionChallenger;         
        uint actionsCounter;               

        bytes32[] blockHashes;             
        uint countBlockHeaderQueries;      
        uint countBlockHeaderResponses;    

        mapping (bytes32 => BlockInfo) blocksInfo;

        ChallengeState challengeState;     
    }


    mapping (bytes32 => BattleSession) public sessions;

    uint public sessionsCount = 0;

    uint public superblockDuration;          
    uint public superblockTimeout;           


     
    SyscoinMessageLibrary.Network private net;


     
    SyscoinClaimManager trustedSyscoinClaimManager;

     
    SyscoinSuperblocks trustedSuperblocks;

    event NewBattle(bytes32 superblockHash, bytes32 sessionId, address submitter, address challenger);
    event ChallengerConvicted(bytes32 superblockHash, bytes32 sessionId, address challenger);
    event SubmitterConvicted(bytes32 superblockHash, bytes32 sessionId, address submitter);

    event QueryMerkleRootHashes(bytes32 superblockHash, bytes32 sessionId, address submitter);
    event RespondMerkleRootHashes(bytes32 superblockHash, bytes32 sessionId, address challenger, bytes32[] blockHashes);
    event QueryBlockHeader(bytes32 superblockHash, bytes32 sessionId, address submitter, bytes32 blockSha256Hash);
    event RespondBlockHeader(bytes32 superblockHash, bytes32 sessionId, address challenger, bytes blockHeader, bytes powBlockHeader);

    event ErrorBattle(bytes32 sessionId, uint err);
    modifier onlyFrom(address sender) {
        require(msg.sender == sender);
        _;
    }

    modifier onlyClaimant(bytes32 sessionId) {
        require(msg.sender == sessions[sessionId].submitter);
        _;
    }

    modifier onlyChallenger(bytes32 sessionId) {
        require(msg.sender == sessions[sessionId].challenger);
        _;
    }

     
     
     
     
     
    constructor(
        SyscoinMessageLibrary.Network _network,
        SyscoinSuperblocks _superblocks,
        uint _superblockDuration,
        uint _superblockTimeout
    ) public {
        net = _network;
        trustedSuperblocks = _superblocks;
        superblockDuration = _superblockDuration;
        superblockTimeout = _superblockTimeout;
    }

    function setSyscoinClaimManager(SyscoinClaimManager _syscoinClaimManager) public {
        require(address(trustedSyscoinClaimManager) == 0x0 && address(_syscoinClaimManager) != 0x0);
        trustedSyscoinClaimManager = _syscoinClaimManager;
    }

     
    function beginBattleSession(bytes32 superblockHash, address submitter, address challenger)
        onlyFrom(trustedSyscoinClaimManager) public returns (bytes32) {
        bytes32 sessionId = keccak256(abi.encode(superblockHash, msg.sender, sessionsCount));
        BattleSession storage session = sessions[sessionId];
        session.id = sessionId;
        session.superblockHash = superblockHash;
        session.submitter = submitter;
        session.challenger = challenger;
        session.lastActionTimestamp = block.timestamp;
        session.lastActionChallenger = 0;
        session.lastActionClaimant = 1;      
        session.actionsCounter = 1;
        session.challengeState = ChallengeState.Challenged;

        sessionsCount += 1;

        emit NewBattle(superblockHash, sessionId, submitter, challenger);
        return sessionId;
    }

     
    function doQueryMerkleRootHashes(BattleSession storage session) internal returns (uint) {
        if (!hasDeposit(msg.sender, respondMerkleRootHashesCost)) {
            return ERR_SUPERBLOCK_MIN_DEPOSIT;
        }
        if (session.challengeState == ChallengeState.Challenged) {
            session.challengeState = ChallengeState.QueryMerkleRootHashes;
            assert(msg.sender == session.challenger);
            (uint err, ) = bondDeposit(session.superblockHash, msg.sender, respondMerkleRootHashesCost);
            if (err != ERR_SUPERBLOCK_OK) {
                return err;
            }
            return ERR_SUPERBLOCK_OK;
        }
        return ERR_SUPERBLOCK_BAD_STATUS;
    }

     
    function queryMerkleRootHashes(bytes32 superblockHash, bytes32 sessionId) onlyChallenger(sessionId) public {
        BattleSession storage session = sessions[sessionId];
        uint err = doQueryMerkleRootHashes(session);
        if (err != ERR_SUPERBLOCK_OK) {
            emit ErrorBattle(sessionId, err);
        } else {
            session.actionsCounter += 1;
            session.lastActionTimestamp = block.timestamp;
            session.lastActionChallenger = session.actionsCounter;
            emit QueryMerkleRootHashes(superblockHash, sessionId, session.submitter);
        }
    }

     
    function doVerifyMerkleRootHashes(BattleSession storage session, bytes32[] blockHashes) internal returns (uint) {
        if (!hasDeposit(msg.sender, verifySuperblockCost)) {
            return ERR_SUPERBLOCK_MIN_DEPOSIT;
        }
        require(session.blockHashes.length == 0);
        if (session.challengeState == ChallengeState.QueryMerkleRootHashes) {
            (bytes32 merkleRoot, , , , bytes32 lastHash, , , ,,) = getSuperblockInfo(session.superblockHash);
            if (lastHash != blockHashes[blockHashes.length - 1]){
                return ERR_SUPERBLOCK_BAD_LASTBLOCK;
            }
            if (merkleRoot != SyscoinMessageLibrary.makeMerkle(blockHashes)) {
                return ERR_SUPERBLOCK_INVALID_MERKLE;
            }
            (uint err, ) = bondDeposit(session.superblockHash, msg.sender, verifySuperblockCost);
            if (err != ERR_SUPERBLOCK_OK) {
                return err;
            }
            session.blockHashes = blockHashes;
            session.challengeState = ChallengeState.RespondMerkleRootHashes;
            return ERR_SUPERBLOCK_OK;
        }
        return ERR_SUPERBLOCK_BAD_STATUS;
    }

     
    function respondMerkleRootHashes(bytes32 superblockHash, bytes32 sessionId, bytes32[] blockHashes) onlyClaimant(sessionId) public {
        BattleSession storage session = sessions[sessionId];
        uint err = doVerifyMerkleRootHashes(session, blockHashes);
        if (err != 0) {
            emit ErrorBattle(sessionId, err);
        } else {
            session.actionsCounter += 1;
            session.lastActionTimestamp = block.timestamp;
            session.lastActionClaimant = session.actionsCounter;
            emit RespondMerkleRootHashes(superblockHash, sessionId, session.challenger, blockHashes);
        }
    }

     
    function doQueryBlockHeader(BattleSession storage session, bytes32 blockHash) internal returns (uint) {
        if (!hasDeposit(msg.sender, respondBlockHeaderCost)) {
            return ERR_SUPERBLOCK_MIN_DEPOSIT;
        }
        if ((session.countBlockHeaderQueries == 0 && session.challengeState == ChallengeState.RespondMerkleRootHashes) ||
            (session.countBlockHeaderQueries > 0 && session.challengeState == ChallengeState.RespondBlockHeader)) {
            require(session.countBlockHeaderQueries < session.blockHashes.length);
            require(session.blocksInfo[blockHash].status == BlockInfoStatus.Uninitialized);
            (uint err, ) = bondDeposit(session.superblockHash, msg.sender, respondBlockHeaderCost);
            if (err != ERR_SUPERBLOCK_OK) {
                return err;
            }
            session.countBlockHeaderQueries += 1;
            session.blocksInfo[blockHash].status = BlockInfoStatus.Requested;
            session.challengeState = ChallengeState.QueryBlockHeader;
            return ERR_SUPERBLOCK_OK;
        }
        return ERR_SUPERBLOCK_BAD_STATUS;
    }

     
    function queryBlockHeader(bytes32 superblockHash, bytes32 sessionId, bytes32 blockHash) onlyChallenger(sessionId) public {
        BattleSession storage session = sessions[sessionId];
        uint err = doQueryBlockHeader(session, blockHash);
        if (err != ERR_SUPERBLOCK_OK) {
            emit ErrorBattle(sessionId, err);
        } else {
            session.actionsCounter += 1;
            session.lastActionTimestamp = block.timestamp;
            session.lastActionChallenger = session.actionsCounter;
            emit QueryBlockHeader(superblockHash, sessionId, session.submitter, blockHash);
        }
    }

     
    function verifyTimestamp(bytes32 superblockHash, bytes blockHeader) internal view returns (bool) {
        uint blockTimestamp = SyscoinMessageLibrary.getTimestamp(blockHeader);
        uint superblockTimestamp;

        (, , superblockTimestamp, , , , , ,,) = getSuperblockInfo(superblockHash);

         
        return (blockTimestamp <= superblockTimestamp)
            && (blockTimestamp / superblockDuration >= superblockTimestamp / superblockDuration - 1);
    }

     
    function verifyBlockAuxPoW(
        BlockInfo storage blockInfo,
        bytes32 blockHash,
        bytes blockHeader
    ) internal returns (uint, bytes) {
        (uint err, bool isMergeMined) =
            SyscoinMessageLibrary.verifyBlockHeader(blockHeader, 0, uint(blockHash));
        if (err != 0) {
            return (err, new bytes(0));
        }
        bytes memory powBlockHeader = (isMergeMined) ?
            SyscoinMessageLibrary.sliceArray(blockHeader, blockHeader.length - 80, blockHeader.length) :
            SyscoinMessageLibrary.sliceArray(blockHeader, 0, 80);

        blockInfo.timestamp = SyscoinMessageLibrary.getTimestamp(blockHeader);
        blockInfo.bits = SyscoinMessageLibrary.getBits(blockHeader);
        blockInfo.prevBlock = bytes32(SyscoinMessageLibrary.getHashPrevBlock(blockHeader));
        blockInfo.blockHash = blockHash;
        blockInfo.powBlockHeader = powBlockHeader;
        return (ERR_SUPERBLOCK_OK, powBlockHeader);
    }

     
    function doVerifyBlockHeader(
        BattleSession storage session,
        bytes memory blockHeader
    ) internal returns (uint, bytes) {
        if (!hasDeposit(msg.sender, respondBlockHeaderCost)) {
            return (ERR_SUPERBLOCK_MIN_DEPOSIT, new bytes(0));
        }
        if (session.challengeState == ChallengeState.QueryBlockHeader) {
            bytes32 blockSha256Hash = bytes32(SyscoinMessageLibrary.dblShaFlipMem(blockHeader, 0, 80));
            BlockInfo storage blockInfo = session.blocksInfo[blockSha256Hash];
            if (blockInfo.status != BlockInfoStatus.Requested) {
                return (ERR_SUPERBLOCK_BAD_SYSCOIN_STATUS, new bytes(0));
            }

            if (!verifyTimestamp(session.superblockHash, blockHeader)) {
                return (ERR_SUPERBLOCK_BAD_TIMESTAMP, new bytes(0));
            }
			 
             
             
            (uint err, bytes memory powBlockHeader) =
                verifyBlockAuxPoW(blockInfo, blockSha256Hash, blockHeader);
            if (err != ERR_SUPERBLOCK_OK) {
                return (err, new bytes(0));
            }
			 
            blockInfo.status = BlockInfoStatus.Verified;

            (err, ) = bondDeposit(session.superblockHash, msg.sender, respondBlockHeaderCost);
            if (err != ERR_SUPERBLOCK_OK) {
                return (err, new bytes(0));
            }

            session.countBlockHeaderResponses += 1;
			 
            if (session.countBlockHeaderResponses == session.blockHashes.length) {
                session.challengeState = ChallengeState.PendingVerification;
            } else {
                session.challengeState = ChallengeState.RespondBlockHeader;
            }

            return (ERR_SUPERBLOCK_OK, powBlockHeader);
        }
        return (ERR_SUPERBLOCK_BAD_STATUS, new bytes(0));
    }

     
    function respondBlockHeader(
        bytes32 superblockHash,
        bytes32 sessionId,
        bytes memory blockHeader
    ) onlyClaimant(sessionId) public {
        BattleSession storage session = sessions[sessionId];
        (uint err, bytes memory powBlockHeader) = doVerifyBlockHeader(session, blockHeader);
        if (err != 0) {
            emit ErrorBattle(sessionId, err);
        } else {
            session.actionsCounter += 1;
            session.lastActionTimestamp = block.timestamp;
            session.lastActionClaimant = session.actionsCounter;
            emit RespondBlockHeader(superblockHash, sessionId, session.challenger, blockHeader, powBlockHeader);
        }
    }

     
    function validateLastBlocks(BattleSession storage session) internal view returns (uint) {
        if (session.blockHashes.length <= 0) {
            return ERR_SUPERBLOCK_BAD_LASTBLOCK;
        }
        uint lastTimestamp;
        uint prevTimestamp;
        uint32 lastBits;
        bytes32 parentId;
        (, , lastTimestamp, prevTimestamp, , lastBits, parentId,,,) = getSuperblockInfo(session.superblockHash);
        bytes32 blockSha256Hash = session.blockHashes[session.blockHashes.length - 1];
        if (session.blocksInfo[blockSha256Hash].timestamp != lastTimestamp) {
            return ERR_SUPERBLOCK_BAD_TIMESTAMP;
        }
        if (session.blocksInfo[blockSha256Hash].bits != lastBits) {
            return ERR_SUPERBLOCK_BAD_BITS;
        }
        if (prevTimestamp > lastTimestamp) {
            return ERR_SUPERBLOCK_BAD_TIMESTAMP;
        }
        
        return ERR_SUPERBLOCK_OK;
    }

     
    function validateProofOfWork(BattleSession storage session) internal view returns (uint) {
        uint accWork;
        bytes32 prevBlock;
        uint32 prevHeight;  
        uint32 proposedHeight;  
        uint prevTimestamp;
        (, accWork, , prevTimestamp, , , prevBlock, ,,proposedHeight) = getSuperblockInfo(session.superblockHash);
        uint parentTimestamp;
        
        uint32 prevBits;
       
        uint work;    
        (, work, parentTimestamp, , prevBlock, prevBits, , , ,prevHeight) = getSuperblockInfo(prevBlock);
        
        if (proposedHeight != (prevHeight+uint32(session.blockHashes.length))) {
            return ERR_SUPERBLOCK_BAD_BLOCKHEIGHT;
        }      
        uint ret = validateSuperblockProofOfWork(session, parentTimestamp, prevHeight, work, accWork, prevTimestamp, prevBits, prevBlock);
        if(ret != 0){
            return ret;
        }
        return ERR_SUPERBLOCK_OK;
    }
    function validateSuperblockProofOfWork(BattleSession storage session, uint parentTimestamp, uint32 prevHeight, uint work, uint accWork, uint prevTimestamp, uint32 prevBits, bytes32 prevBlock) internal view returns (uint){
         uint32 idx = 0;
         while (idx < session.blockHashes.length) {
            bytes32 blockSha256Hash = session.blockHashes[idx];
            uint32 bits = session.blocksInfo[blockSha256Hash].bits;
            if (session.blocksInfo[blockSha256Hash].prevBlock != prevBlock) {
                return ERR_SUPERBLOCK_BAD_PARENT;
            }
            if (net != SyscoinMessageLibrary.Network.REGTEST) {
                uint32 newBits;
                if (net == SyscoinMessageLibrary.Network.TESTNET && session.blocksInfo[blockSha256Hash].timestamp - parentTimestamp > 120) {
                    newBits = 0x1e0fffff;
                }
                else if((prevHeight+idx+1) % SyscoinMessageLibrary.difficultyAdjustmentInterval() != 0){
                    newBits = prevBits;
                }
                else{
                    newBits = SyscoinMessageLibrary.calculateDifficulty(int64(parentTimestamp) - int64(prevTimestamp), prevBits);
                    prevTimestamp = parentTimestamp;
                    prevBits = bits;
                }
                if (bits != newBits) {
                   return ERR_SUPERBLOCK_BAD_BITS;
                }
            }
            work += SyscoinMessageLibrary.diffFromBits(bits);
            prevBlock = blockSha256Hash;
            parentTimestamp = session.blocksInfo[blockSha256Hash].timestamp;
            idx += 1;
        }
        if (net != SyscoinMessageLibrary.Network.REGTEST &&  work != accWork) {
            return ERR_SUPERBLOCK_BAD_ACCUMULATED_WORK;
        }       
        return 0;
    }
     
     
    function doVerifySuperblock(BattleSession storage session, bytes32 sessionId) internal returns (uint) {
        if (session.challengeState == ChallengeState.PendingVerification) {
            uint err;
            err = validateLastBlocks(session);
            if (err != 0) {
                emit ErrorBattle(sessionId, err);
                return 2;
            }
            err = validateProofOfWork(session);
            if (err != 0) {
                emit ErrorBattle(sessionId, err);
                return 2;
            }
            return 1;
        } else if (session.challengeState == ChallengeState.SuperblockFailed) {
            return 2;
        }
        return 0;
    }

     
    function verifySuperblock(bytes32 sessionId) public {
        BattleSession storage session = sessions[sessionId];
        uint status = doVerifySuperblock(session, sessionId);
        if (status == 1) {
            convictChallenger(sessionId, session.challenger, session.superblockHash);
        } else if (status == 2) {
            convictSubmitter(sessionId, session.submitter, session.superblockHash);
        }
    }

     
    function timeout(bytes32 sessionId) public returns (uint) {
        BattleSession storage session = sessions[sessionId];
        if (session.challengeState == ChallengeState.SuperblockFailed ||
            (session.lastActionChallenger > session.lastActionClaimant &&
            block.timestamp > session.lastActionTimestamp + superblockTimeout)) {
            convictSubmitter(sessionId, session.submitter, session.superblockHash);
            return ERR_SUPERBLOCK_OK;
        } else if (session.lastActionClaimant > session.lastActionChallenger &&
            block.timestamp > session.lastActionTimestamp + superblockTimeout) {
            convictChallenger(sessionId, session.challenger, session.superblockHash);
            return ERR_SUPERBLOCK_OK;
        }
        emit ErrorBattle(sessionId, ERR_SUPERBLOCK_NO_TIMEOUT);
        return ERR_SUPERBLOCK_NO_TIMEOUT;
    }

     
    function convictChallenger(bytes32 sessionId, address challenger, bytes32 superblockHash) internal {
        BattleSession storage session = sessions[sessionId];
        sessionDecided(sessionId, superblockHash, session.submitter, session.challenger);
        disable(sessionId);
        emit ChallengerConvicted(superblockHash, sessionId, challenger);
    }

     
    function convictSubmitter(bytes32 sessionId, address submitter, bytes32 superblockHash) internal {
        BattleSession storage session = sessions[sessionId];
        sessionDecided(sessionId, superblockHash, session.challenger, session.submitter);
        disable(sessionId);
        emit SubmitterConvicted(superblockHash, sessionId, submitter);
    }

     
     
    function disable(bytes32 sessionId) internal {
        delete sessions[sessionId];
    }

     
    function getChallengerHitTimeout(bytes32 sessionId) public view returns (bool) {
        BattleSession storage session = sessions[sessionId];
        return (session.lastActionClaimant > session.lastActionChallenger &&
            block.timestamp > session.lastActionTimestamp + superblockTimeout);
    }

     
    function getSubmitterHitTimeout(bytes32 sessionId) public view returns (bool) {
        BattleSession storage session = sessions[sessionId];
        return (session.lastActionChallenger > session.lastActionClaimant &&
            block.timestamp > session.lastActionTimestamp + superblockTimeout);
    }

     
    function getSyscoinBlockHashes(bytes32 sessionId) public view returns (bytes32[]) {
        return sessions[sessionId].blockHashes;
    }

     
    function sessionDecided(bytes32 sessionId, bytes32 superblockHash, address winner, address loser) internal {
        trustedSyscoinClaimManager.sessionDecided(sessionId, superblockHash, winner, loser);
    }

     
    function getSuperblockInfo(bytes32 superblockHash) internal view returns (
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        address _submitter,
        SyscoinSuperblocks.Status _status,
        uint32 _height
    ) {
        return trustedSuperblocks.getSuperblock(superblockHash);
    }

     
    function hasDeposit(address who, uint amount) internal view returns (bool) {
        return trustedSyscoinClaimManager.getDeposit(who) >= amount;
    }

     
    function bondDeposit(bytes32 superblockHash, address account, uint amount) internal returns (uint, uint) {
        return trustedSyscoinClaimManager.bondDeposit(superblockHash, account, amount);
    }
}

 
 
 
contract SyscoinClaimManager is SyscoinDepositsManager, SyscoinErrorCodes {

    using SafeMath for uint;

    struct SuperblockClaim {
        bytes32 superblockHash;                        
        address submitter;                            
        uint createdAt;                              

        address[] challengers;                       
        mapping (address => uint) bondedDeposits;    

        uint currentChallenger;                      
        mapping (address => bytes32) sessions;       

        uint challengeTimeout;                       

        bool verificationOngoing;                    

        bool decided;                                
        bool invalid;                                
    }

     
    mapping (bytes32 => SuperblockClaim) public claims;

     
    SyscoinSuperblocks public trustedSuperblocks;

     
    SyscoinBattleManager public trustedSyscoinBattleManager;

     
    uint public superblockConfirmations;

     
    uint public battleReward;

    uint public superblockDelay;     
    uint public superblockTimeout;   

    event DepositBonded(bytes32 superblockHash, address account, uint amount);
    event DepositUnbonded(bytes32 superblockHash, address account, uint amount);
    event SuperblockClaimCreated(bytes32 superblockHash, address submitter);
    event SuperblockClaimChallenged(bytes32 superblockHash, address challenger);
    event SuperblockBattleDecided(bytes32 sessionId, address winner, address loser);
    event SuperblockClaimSuccessful(bytes32 superblockHash, address submitter);
    event SuperblockClaimPending(bytes32 superblockHash, address submitter);
    event SuperblockClaimFailed(bytes32 superblockHash, address submitter);
    event VerificationGameStarted(bytes32 superblockHash, address submitter, address challenger, bytes32 sessionId);

    event ErrorClaim(bytes32 superblockHash, uint err);

    modifier onlyBattleManager() {
        require(msg.sender == address(trustedSyscoinBattleManager));
        _;
    }

    modifier onlyMeOrBattleManager() {
        require(msg.sender == address(trustedSyscoinBattleManager) || msg.sender == address(this));
        _;
    }

     
     
     
     
     
     
    constructor(
        SyscoinSuperblocks _superblocks,
        SyscoinBattleManager _syscoinBattleManager,
        uint _superblockDelay,
        uint _superblockTimeout,
        uint _superblockConfirmations,
        uint _battleReward
    ) public {
        trustedSuperblocks = _superblocks;
        trustedSyscoinBattleManager = _syscoinBattleManager;
        superblockDelay = _superblockDelay;
        superblockTimeout = _superblockTimeout;
        superblockConfirmations = _superblockConfirmations;
        battleReward = _battleReward;
    }

     
     
     
     
     
    function bondDeposit(bytes32 superblockHash, address account, uint amount) onlyMeOrBattleManager external returns (uint, uint) {
        SuperblockClaim storage claim = claims[superblockHash];

        if (!claimExists(claim)) {
            return (ERR_SUPERBLOCK_BAD_CLAIM, 0);
        }

        if (deposits[account] < amount) {
            return (ERR_SUPERBLOCK_MIN_DEPOSIT, deposits[account]);
        }

        deposits[account] = deposits[account].sub(amount);
        claim.bondedDeposits[account] = claim.bondedDeposits[account].add(amount);
        emit DepositBonded(superblockHash, account, amount);

        return (ERR_SUPERBLOCK_OK, claim.bondedDeposits[account]);
    }

     
     
     
     
    function getBondedDeposit(bytes32 superblockHash, address account) public view returns (uint) {
        SuperblockClaim storage claim = claims[superblockHash];
        require(claimExists(claim));
        return claim.bondedDeposits[account];
    }

    function getDeposit(address account) public view returns (uint) {
        return deposits[account];
    }

     
     
     
     
    function unbondDeposit(bytes32 superblockHash, address account) internal returns (uint, uint) {
        SuperblockClaim storage claim = claims[superblockHash];
        if (!claimExists(claim)) {
            return (ERR_SUPERBLOCK_BAD_CLAIM, 0);
        }
        if (!claim.decided) {
            return (ERR_SUPERBLOCK_BAD_STATUS, 0);
        }

        uint bondedDeposit = claim.bondedDeposits[account];

        delete claim.bondedDeposits[account];
        deposits[account] = deposits[account].add(bondedDeposit);

        emit DepositUnbonded(superblockHash, account, bondedDeposit);

        return (ERR_SUPERBLOCK_OK, bondedDeposit);
    }

     
     
     
     
     
     
     
     
     
     
    function proposeSuperblock(
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentHash,
        uint32 _blockHeight
    ) public returns (uint, bytes32) {
        require(address(trustedSuperblocks) != 0);

        if (deposits[msg.sender] < minProposalDeposit) {
            emit ErrorClaim(0, ERR_SUPERBLOCK_MIN_DEPOSIT);
            return (ERR_SUPERBLOCK_MIN_DEPOSIT, 0);
        }

        if (_timestamp + superblockDelay > block.timestamp) {
            emit ErrorClaim(0, ERR_SUPERBLOCK_BAD_TIMESTAMP);
            return (ERR_SUPERBLOCK_BAD_TIMESTAMP, 0);
        }

        uint err;
        bytes32 superblockHash;
        (err, superblockHash) = trustedSuperblocks.propose(_blocksMerkleRoot, _accumulatedWork,
            _timestamp, _prevTimestamp, _lastHash, _lastBits, _parentHash, _blockHeight,msg.sender);
        if (err != 0) {
            emit ErrorClaim(superblockHash, err);
            return (err, superblockHash);
        }


        SuperblockClaim storage claim = claims[superblockHash];
         
         
         
        if (claimExists(claim)) {
            bool allowed = claim.invalid == true && claim.decided == true && claim.submitter != msg.sender;
            if(allowed){
                 
                if(trustedSuperblocks.getSuperblockStatus(_parentHash) == SyscoinSuperblocks.Status.Approved){
                    allowed = trustedSuperblocks.getBestSuperblock() == _parentHash;
                }
                 
                else if(trustedSuperblocks.getSuperblockStatus(_parentHash) == SyscoinSuperblocks.Status.SemiApproved){
                    allowed = true;
                }
                else{
                    allowed = false;
                }
            }
            if(!allowed){
                emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
                return (ERR_SUPERBLOCK_BAD_CLAIM, superblockHash);  
            }
        }


        claim.superblockHash = superblockHash;
        claim.submitter = msg.sender;
        claim.currentChallenger = 0;
        claim.decided = false;
        claim.invalid = false;
        claim.verificationOngoing = false;
        claim.createdAt = block.timestamp;
        claim.challengeTimeout = block.timestamp + superblockTimeout;
        claim.challengers.length = 0;

        (err, ) = this.bondDeposit(superblockHash, msg.sender, battleReward);
        assert(err == ERR_SUPERBLOCK_OK);

        emit SuperblockClaimCreated(superblockHash, msg.sender);

        return (ERR_SUPERBLOCK_OK, superblockHash);
    }

     
     
     
    function challengeSuperblock(bytes32 superblockHash) public returns (uint, bytes32) {
        require(address(trustedSuperblocks) != 0);

        SuperblockClaim storage claim = claims[superblockHash];

        if (!claimExists(claim)) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
            return (ERR_SUPERBLOCK_BAD_CLAIM, superblockHash);
        }
        if (claim.decided) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_CLAIM_DECIDED);
            return (ERR_SUPERBLOCK_CLAIM_DECIDED, superblockHash);
        }
        if (deposits[msg.sender] < minChallengeDeposit) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_MIN_DEPOSIT);
            return (ERR_SUPERBLOCK_MIN_DEPOSIT, superblockHash);
        }

        uint err;
        (err, ) = trustedSuperblocks.challenge(superblockHash, msg.sender);
        if (err != 0) {
            emit ErrorClaim(superblockHash, err);
            return (err, 0);
        }

        (err, ) = this.bondDeposit(superblockHash, msg.sender, battleReward);
        assert(err == ERR_SUPERBLOCK_OK);

        claim.challengeTimeout = block.timestamp + superblockTimeout;
        claim.challengers.push(msg.sender);
        emit SuperblockClaimChallenged(superblockHash, msg.sender);

        if (!claim.verificationOngoing) {
            runNextBattleSession(superblockHash);
        }

        return (ERR_SUPERBLOCK_OK, superblockHash);
    }

     
     
    function runNextBattleSession(bytes32 superblockHash) internal returns (bool) {
        SuperblockClaim storage claim = claims[superblockHash];

        if (!claimExists(claim)) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
            return false;
        }

         
        if (claim.decided || claim.invalid) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_CLAIM_DECIDED);
            return false;
        }

        if (claim.verificationOngoing) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_VERIFICATION_PENDING);
            return false;
        }

        if (claim.currentChallenger < claim.challengers.length) {

            bytes32 sessionId = trustedSyscoinBattleManager.beginBattleSession(superblockHash, claim.submitter,
                claim.challengers[claim.currentChallenger]);

            claim.sessions[claim.challengers[claim.currentChallenger]] = sessionId;
            emit VerificationGameStarted(superblockHash, claim.submitter,
                claim.challengers[claim.currentChallenger], sessionId);

            claim.verificationOngoing = true;
            claim.currentChallenger += 1;
        }

        return true;
    }

     
     
     
     
     
     
    function checkClaimFinished(bytes32 superblockHash) public returns (bool) {
        SuperblockClaim storage claim = claims[superblockHash];

        if (!claimExists(claim)) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
            return false;
        }

         
        if (claim.verificationOngoing) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_VERIFICATION_PENDING);
            return false;
        }

         
        if (claim.invalid) {
             
             
            claim.decided = true;
            trustedSuperblocks.invalidate(claim.superblockHash, msg.sender);
            emit SuperblockClaimFailed(superblockHash, claim.submitter);
            doPayChallengers(superblockHash, claim);
            return false;
        }

         
        if (block.timestamp <= claim.challengeTimeout) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_NO_TIMEOUT);
            return false;
        }

         
        if (claim.currentChallenger < claim.challengers.length) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_VERIFICATION_PENDING);
            return false;
        }

        claim.decided = true;

        bool confirmImmediately = false;
         
        if (claim.challengers.length == 0) {
            bytes32 parentId = trustedSuperblocks.getSuperblockParentId(claim.superblockHash);
            SyscoinSuperblocks.Status status = trustedSuperblocks.getSuperblockStatus(parentId);
            if (status == SyscoinSuperblocks.Status.Approved) {
                confirmImmediately = true;
            }
        }

        if (confirmImmediately) {
            trustedSuperblocks.confirm(claim.superblockHash, msg.sender);
            unbondDeposit(superblockHash, claim.submitter);
            emit SuperblockClaimSuccessful(superblockHash, claim.submitter);
        } else {
            trustedSuperblocks.semiApprove(claim.superblockHash, msg.sender);
            emit SuperblockClaimPending(superblockHash, claim.submitter);
        }
        return true;
    }

     
     
     
     
     
     
     
     
    function confirmClaim(bytes32 superblockHash, bytes32 descendantId) public returns (bool) {
        uint numSuperblocks = 0;
        bool confirmDescendants = true;
        bytes32 id = descendantId;
        SuperblockClaim storage claim = claims[id];
        while (id != superblockHash) {
            if (!claimExists(claim)) {
                emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
                return false;
            }
            if (trustedSuperblocks.getSuperblockStatus(id) != SyscoinSuperblocks.Status.SemiApproved) {
                emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
                return false;
            }
            if (confirmDescendants && claim.challengers.length > 0) {
                confirmDescendants = false;
            }
            id = trustedSuperblocks.getSuperblockParentId(id);
            claim = claims[id];
            numSuperblocks += 1;
        }

        if (numSuperblocks < superblockConfirmations) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_MISSING_CONFIRMATIONS);
            return false;
        }
        if (trustedSuperblocks.getSuperblockStatus(id) != SyscoinSuperblocks.Status.SemiApproved) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return false;
        }

        bytes32 parentId = trustedSuperblocks.getSuperblockParentId(superblockHash);
        if (trustedSuperblocks.getSuperblockStatus(parentId) != SyscoinSuperblocks.Status.Approved) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
            return false;
        }

        (uint err, ) = trustedSuperblocks.confirm(superblockHash, msg.sender);
        if (err != ERR_SUPERBLOCK_OK) {
            emit ErrorClaim(superblockHash, err);
            return false;
        }
        emit SuperblockClaimSuccessful(superblockHash, claim.submitter);
        doPaySubmitter(superblockHash, claim);
        unbondDeposit(superblockHash, claim.submitter);

        if (confirmDescendants) {
            bytes32[] memory descendants = new bytes32[](numSuperblocks);
            id = descendantId;
            uint idx = 0;
            while (id != superblockHash) {
                descendants[idx] = id;
                id = trustedSuperblocks.getSuperblockParentId(id);
                idx += 1;
            }
            while (idx > 0) {
                idx -= 1;
                id = descendants[idx];
                claim = claims[id];
                (err, ) = trustedSuperblocks.confirm(id, msg.sender);
                require(err == ERR_SUPERBLOCK_OK);
                emit SuperblockClaimSuccessful(id, claim.submitter);
                doPaySubmitter(id, claim);
                unbondDeposit(id, claim.submitter);
            }
        }

        return true;
    }

     
     
     
     
     
     
    function rejectClaim(bytes32 superblockHash) public returns (bool) {
        SuperblockClaim storage claim = claims[superblockHash];
        if (!claimExists(claim)) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_CLAIM);
            return false;
        }

        uint height = trustedSuperblocks.getSuperblockHeight(superblockHash);
        bytes32 id = trustedSuperblocks.getBestSuperblock();
        if (trustedSuperblocks.getSuperblockHeight(id) < height + superblockConfirmations) {
            emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_MISSING_CONFIRMATIONS);
            return false;
        }

        id = trustedSuperblocks.getSuperblockAt(height);

        if (id != superblockHash) {
            SyscoinSuperblocks.Status status = trustedSuperblocks.getSuperblockStatus(superblockHash);

            if (status != SyscoinSuperblocks.Status.SemiApproved) {
                emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_BAD_STATUS);
                return false;
            }

            if (!claim.decided) {
                emit ErrorClaim(superblockHash, ERR_SUPERBLOCK_CLAIM_DECIDED);
                return false;
            }

            trustedSuperblocks.invalidate(superblockHash, msg.sender);
            emit SuperblockClaimFailed(superblockHash, claim.submitter);
            doPayChallengers(superblockHash, claim);
            return true;
        }

        return false;
    }

     
     
     
     
     
     
    function sessionDecided(bytes32 sessionId, bytes32 superblockHash, address winner, address loser) public onlyBattleManager {
        SuperblockClaim storage claim = claims[superblockHash];

        require(claimExists(claim));

        claim.verificationOngoing = false;

        if (claim.submitter == loser) {
             
             
            claim.invalid = true;
        } else if (claim.submitter == winner) {
             
             
            runNextBattleSession(superblockHash);
        } else {
            revert();
        }

        emit SuperblockBattleDecided(sessionId, winner, loser);
    }

     
     
    function doPayChallengers(bytes32 superblockHash, SuperblockClaim storage claim) internal {
        uint rewards = claim.bondedDeposits[claim.submitter];
        claim.bondedDeposits[claim.submitter] = 0;
        uint totalDeposits = 0;
        uint idx = 0;
        for (idx = 0; idx < claim.currentChallenger; ++idx) {
            totalDeposits = totalDeposits.add(claim.bondedDeposits[claim.challengers[idx]]);
        }
        
        address challenger;
        uint reward = 0;
        if(totalDeposits == 0 && claim.currentChallenger > 0){
            reward = rewards.div(claim.currentChallenger);
        }
        for (idx = 0; idx < claim.currentChallenger; ++idx) {
            reward = 0;
            challenger = claim.challengers[idx];
            if(totalDeposits > 0){
                reward = rewards.mul(claim.bondedDeposits[challenger]).div(totalDeposits);
            }
            claim.bondedDeposits[challenger] = claim.bondedDeposits[challenger].add(reward);
        }
        uint bondedDeposit;
        for (idx = 0; idx < claim.challengers.length; ++idx) {
            challenger = claim.challengers[idx];
            bondedDeposit = claim.bondedDeposits[challenger];
            deposits[challenger] = deposits[challenger].add(bondedDeposit);
            claim.bondedDeposits[challenger] = 0;
            emit DepositUnbonded(superblockHash, challenger, bondedDeposit);
        }
    }

     
    function doPaySubmitter(bytes32 superblockHash, SuperblockClaim storage claim) internal {
        address challenger;
        uint bondedDeposit;
        for (uint idx=0; idx < claim.challengers.length; ++idx) {
            challenger = claim.challengers[idx];
            bondedDeposit = claim.bondedDeposits[challenger];
            claim.bondedDeposits[challenger] = 0;
            claim.bondedDeposits[claim.submitter] = claim.bondedDeposits[claim.submitter].add(bondedDeposit);
        }
        unbondDeposit(superblockHash, claim.submitter);
    }

     
    function getInBattleAndSemiApprovable(bytes32 superblockHash) public view returns (bool) {
        SuperblockClaim storage claim = claims[superblockHash];
        return (trustedSuperblocks.getSuperblockStatus(superblockHash) == SyscoinSuperblocks.Status.InBattle &&
            !claim.invalid && !claim.verificationOngoing && block.timestamp > claim.challengeTimeout
            && claim.currentChallenger >= claim.challengers.length);
    }

     
    function claimExists(SuperblockClaim claim) private pure returns (bool) {
        return (claim.submitter != 0x0);
    }

     
    function getClaimSubmitter(bytes32 superblockHash) public view returns (address) {
        return claims[superblockHash].submitter;
    }

     
    function getNewSuperblockEventTimestamp(bytes32 superblockHash) public view returns (uint) {
        return claims[superblockHash].createdAt;
    }

     
    function getClaimExists(bytes32 superblockHash) public view returns (bool) {
        return claimExists(claims[superblockHash]);
    }

     
    function getClaimDecided(bytes32 superblockHash) public view returns (bool) {
        return claims[superblockHash].decided;
    }

     
    function getClaimInvalid(bytes32 superblockHash) public view returns (bool) {
         
        return claims[superblockHash].invalid;
    }

     
    function getClaimVerificationOngoing(bytes32 superblockHash) public view returns (bool) {
        return claims[superblockHash].verificationOngoing;
    }

     
    function getClaimChallengeTimeout(bytes32 superblockHash) public view returns (uint) {
        return claims[superblockHash].challengeTimeout;
    }

     
    function getClaimRemainingChallengers(bytes32 superblockHash) public view returns (uint) {
        SuperblockClaim storage claim = claims[superblockHash];
        return claim.challengers.length - (claim.currentChallenger);
    }

     
    function getSession(bytes32 superblockHash, address challenger) public view returns(bytes32) {
        return claims[superblockHash].sessions[challenger];
    }

    function getClaimChallengers(bytes32 superblockHash) public view returns (address[]) {
        SuperblockClaim storage claim = claims[superblockHash];
        return claim.challengers;
    }

    function getSuperblockInfo(bytes32 superblockHash) internal view returns (
        bytes32 _blocksMerkleRoot,
        uint _accumulatedWork,
        uint _timestamp,
        uint _prevTimestamp,
        bytes32 _lastHash,
        uint32 _lastBits,
        bytes32 _parentId,
        address _submitter,
        SyscoinSuperblocks.Status _status,
        uint32 _height
    ) {
        return trustedSuperblocks.getSuperblock(superblockHash);
    }
}