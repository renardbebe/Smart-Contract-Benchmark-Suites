 

pragma solidity ^0.4.23;

 

library BytesUtils {
     
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := sha3(add(add(self, 32), offset), len)
        }
    }


     
    function compare(bytes memory self, bytes memory other) internal pure returns (int) {
        return compare(self, 0, self.length, other, 0, other.length);
    }

     
    function compare(bytes memory self, uint offset, uint len, bytes memory other, uint otheroffset, uint otherlen) internal pure returns (int) {
        uint shortest = len;
        if (otherlen < len)
        shortest = otherlen;

        uint selfptr;
        uint otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint mask;
                if (shortest > 32) {
                    mask = uint256(- 1);  
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint diff = (a & mask) - (b & mask);
                if (diff != 0)
                return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int(len) - int(otherlen);
    }

     
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset, uint len) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

     
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset) internal pure returns (bool) {
        return keccak(self, offset, self.length - offset) == keccak(other, otherOffset, other.length - otherOffset);
    }

     
    function equals(bytes memory self, uint offset, bytes memory other) internal pure returns (bool) {
        return self.length >= offset + other.length && equals(self, offset, other, 0, other.length);
    }

     
    function equals(bytes memory self, bytes memory other) internal pure returns(bool) {
        return self.length == other.length && equals(self, 0, other, 0, self.length);
    }

     
    function readUint8(bytes memory self, uint idx) internal pure returns (uint8 ret) {
        require(idx + 1 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 1), idx)), 0xFF)
        }
    }

     
    function readUint16(bytes memory self, uint idx) internal pure returns (uint16 ret) {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

     
    function readUint32(bytes memory self, uint idx) internal pure returns (uint32 ret) {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

     
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

     
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

     
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes20 ret) {
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

     
     
    bytes constant base32HexTable = hex'00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';

     
    function base32HexDecodeWord(bytes memory self, uint off, uint len) internal pure returns(bytes32) {
        require(len <= 52);

        uint ret = 0;
        for(uint i = 0; i < len; i++) {
            byte char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            uint8 decoded = uint8(base32HexTable[uint(char) - 0x30]);
            require(decoded <= 0x20);
            if(i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint bitlen = len * 5;
        if(len % 8 == 0) {
             
            ret = (ret << 5) | decoded;
        } else if(len % 8 == 2) {
             
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if(len % 8 == 4) {
             
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if(len % 8 == 5) {
             
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if(len % 8 == 7) {
             
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }
}

 

interface DNSSEC {

    event AlgorithmUpdated(uint8 id, address addr);
    event DigestUpdated(uint8 id, address addr);
    event NSEC3DigestUpdated(uint8 id, address addr);
    event RRSetUpdated(bytes name, bytes rrset);

    function submitRRSets(bytes memory data, bytes memory proof) public returns (bytes);
    function submitRRSet(bytes memory input, bytes memory sig, bytes memory proof) public returns(bytes memory rrs);
    function deleteRRSet(uint16 deleteType, bytes deleteName, bytes memory nsec, bytes memory sig, bytes memory proof) public;
    function rrdata(uint16 dnstype, bytes memory name) public view returns (uint32, uint64, bytes20);

}

 

 
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier owner_only() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) public owner_only {
        owner = newOwner;
    }
}

 

 
library Buffer {
     
    struct buffer {
        bytes buf;
        uint capacity;
    }

     
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
         
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
        return buf;
    }

     
    function fromBytes(bytes b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

     
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

     
    function write(buffer memory buf, uint off, bytes data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
             
            let bufptr := mload(buf)
             
            let buflen := mload(bufptr)
             
            dest := add(add(bufptr, 32), off)
             
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

         
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

     
    function append(buffer memory buf, bytes data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

     
    function append(buffer memory buf, bytes data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

     
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
             
            let bufptr := mload(buf)
             
            let buflen := mload(bufptr)
             
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
             
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

     
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

     
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
         
        data = data >> (8 * (32 - len));
        assembly {
             
            let bufptr := mload(buf)
             
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
             
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

     
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

     
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

     
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

     
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
             
            let bufptr := mload(buf)
             
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
             
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }
}

 

 
library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

     
    function nameLength(bytes memory self, uint offset) internal pure returns(uint) {
        uint idx = offset;
        while (true) {
            assert(idx < self.length);
            uint labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
        }
        return idx - offset;
    }

     
    function readName(bytes memory self, uint offset) internal pure returns(bytes memory ret) {
        uint len = nameLength(self, offset);
        return self.substring(offset, len);
    }

     
    function labelCount(bytes memory self, uint offset) internal pure returns(uint) {
        uint count = 0;
        while (true) {
            assert(offset < self.length);
            uint labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
            count += 1;
        }
        return count;
    }

     
    struct RRIterator {
        bytes data;
        uint offset;
        uint16 dnstype;
        uint16 class;
        uint32 ttl;
        uint rdataOffset;
        uint nextOffset;
    }

     
    function iterateRRs(bytes memory self, uint offset) internal pure returns (RRIterator memory ret) {
        ret.data = self;
        ret.nextOffset = offset;
        next(ret);
    }

     
    function done(RRIterator memory iter) internal pure returns(bool) {
        return iter.offset >= iter.data.length;
    }

     
    function next(RRIterator memory iter) internal pure {
        iter.offset = iter.nextOffset;
        if (iter.offset >= iter.data.length) {
            return;
        }

         
        uint off = iter.offset + nameLength(iter.data, iter.offset);

         
        iter.dnstype = iter.data.readUint16(off);
        off += 2;
        iter.class = iter.data.readUint16(off);
        off += 2;
        iter.ttl = iter.data.readUint32(off);
        off += 4;

         
        uint rdataLength = iter.data.readUint16(off);
        off += 2;
        iter.rdataOffset = off;
        iter.nextOffset = off + rdataLength;
    }

     
    function name(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.offset, nameLength(iter.data, iter.offset));
    }

     
    function rdata(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

     
    function checkTypeBitmap(bytes memory self, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(uint8(1) << (uint8(7) - uint8(rrtype & 0x7)));
        for (uint off = offset; off < self.length;) {
            uint8 window = self.readUint8(off);
            uint8 len = self.readUint8(off + 1);
            if (typeWindow < window) {
                 
                return false;
            } else if (typeWindow == window) {
                 
                if (len * 8 <= windowByte) {
                     
                    return false;
                }
                return (self.readUint8(off + windowByte + 2) & windowBitmask) != 0;
            } else {
                 
                off += len + 2;
            }
        }

        return false;
    }

    function compareNames(bytes memory self, bytes memory other) internal pure returns (int) {
        if (self.equals(other)) {
            return 0;
        }

        uint off;
        uint otheroff;
        uint prevoff;
        uint otherprevoff;
        uint counts = labelCount(self, 0);
        uint othercounts = labelCount(other, 0);

         
        while (counts > othercounts) {
            prevoff = off;
            off = progress(self, off);
            counts--;
        }

        while (othercounts > counts) {
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            othercounts--;
        }

         
        while (counts > 0 && !self.equals(off, other, otheroff)) {
            prevoff = off;
            off = progress(self, off);
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            counts -= 1;
        }

        if (off == 0) {
            return -1;
        }
        if(otheroff == 0) {
            return 1;
        }

        return self.compare(prevoff + 1, self.readUint8(prevoff), other, otherprevoff + 1, other.readUint8(otherprevoff));
    }

    function progress(bytes memory body, uint off) internal pure returns(uint) {
        return off + 1 + body.readUint8(off);
    }
}

 

 
interface Algorithm {
     
    function verify(bytes key, bytes data, bytes signature) external view returns (bool);
}

 

 
interface Digest {
     
    function verify(bytes data, bytes hash) external pure returns (bool);
}

 

 
interface NSEC3Digest {
     
     function hash(bytes salt, bytes data, uint iterations) external pure returns (bytes32);
}

 

 
contract DNSSECImpl is DNSSEC, Owned {
    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using RRUtils for *;

    uint16 constant DNSCLASS_IN = 1;

    uint16 constant DNSTYPE_DS = 43;
    uint16 constant DNSTYPE_RRSIG = 46;
    uint16 constant DNSTYPE_NSEC = 47;
    uint16 constant DNSTYPE_DNSKEY = 48;
    uint16 constant DNSTYPE_NSEC3 = 50;

    uint constant DS_KEY_TAG = 0;
    uint constant DS_ALGORITHM = 2;
    uint constant DS_DIGEST_TYPE = 3;
    uint constant DS_DIGEST = 4;

    uint constant RRSIG_TYPE = 0;
    uint constant RRSIG_ALGORITHM = 2;
    uint constant RRSIG_LABELS = 3;
    uint constant RRSIG_TTL = 4;
    uint constant RRSIG_EXPIRATION = 8;
    uint constant RRSIG_INCEPTION = 12;
    uint constant RRSIG_KEY_TAG = 16;
    uint constant RRSIG_SIGNER_NAME = 18;

    uint constant DNSKEY_FLAGS = 0;
    uint constant DNSKEY_PROTOCOL = 2;
    uint constant DNSKEY_ALGORITHM = 3;
    uint constant DNSKEY_PUBKEY = 4;

    uint constant DNSKEY_FLAG_ZONEKEY = 0x100;

    uint constant NSEC3_HASH_ALGORITHM = 0;
    uint constant NSEC3_FLAGS = 1;
    uint constant NSEC3_ITERATIONS = 2;
    uint constant NSEC3_SALT_LENGTH = 4;
    uint constant NSEC3_SALT = 5;

    uint8 constant ALGORITHM_RSASHA256 = 8;

    uint8 constant DIGEST_ALGORITHM_SHA256 = 2;

    struct RRSet {
        uint32 inception;
        uint64 inserted;
        bytes20 hash;
    }

     
    mapping (bytes32 => mapping(uint16 => RRSet)) rrsets;

    bytes public anchors;

    mapping (uint8 => Algorithm) public algorithms;
    mapping (uint8 => Digest) public digests;
    mapping (uint8 => NSEC3Digest) public nsec3Digests;

     
    constructor(bytes _anchors) public {
         
         
        anchors = _anchors;
        rrsets[keccak256(hex"00")][DNSTYPE_DS] = RRSet({
            inception: uint32(0),
            inserted: uint64(now),
            hash: bytes20(keccak256(anchors))
        });
        emit RRSetUpdated(hex"00", anchors);
    }

     
    function setAlgorithm(uint8 id, Algorithm algo) public owner_only {
        algorithms[id] = algo;
        emit AlgorithmUpdated(id, algo);
    }

     
    function setDigest(uint8 id, Digest digest) public owner_only {
        digests[id] = digest;
        emit DigestUpdated(id, digest);
    }

     
    function setNSEC3Digest(uint8 id, NSEC3Digest digest) public owner_only {
        nsec3Digests[id] = digest;
        emit NSEC3DigestUpdated(id, digest);
    }

     
    function submitRRSets(bytes memory data, bytes memory proof) public returns (bytes) {
        uint offset = 0;
        while(offset < data.length) {
            bytes memory input = data.substring(offset + 2, data.readUint16(offset));
            offset += input.length + 2;
            bytes memory sig = data.substring(offset + 2, data.readUint16(offset));
            offset += sig.length + 2;
            proof = submitRRSet(input, sig, proof);
        }
        return proof;
    }

     
    function submitRRSet(bytes memory input, bytes memory sig, bytes memory proof)
        public returns(bytes memory rrs)
    {
        bytes memory name;
        (name, rrs) = validateSignedSet(input, sig, proof);

        uint32 inception = input.readUint32(RRSIG_INCEPTION);
        uint16 typecovered = input.readUint16(RRSIG_TYPE);

        RRSet storage set = rrsets[keccak256(name)][typecovered];
        if (set.inserted > 0) {
             
            require(inception >= set.inception);
        }
        if (set.hash == keccak256(rrs)) {
             
            return;
        }

        rrsets[keccak256(name)][typecovered] = RRSet({
            inception: inception,
            inserted: uint64(now),
            hash: bytes20(keccak256(rrs))
        });
        emit RRSetUpdated(name, rrs);
    }

     
    function deleteRRSet(uint16 deleteType, bytes deleteName, bytes memory nsec, bytes memory sig, bytes memory proof) public {
        bytes memory nsecName;
        bytes memory rrs;
        (nsecName, rrs) = validateSignedSet(nsec, sig, proof);

         
        require(rrsets[keccak256(deleteName)][deleteType].inception <= nsec.readUint32(RRSIG_INCEPTION));

        for (RRUtils.RRIterator memory iter = rrs.iterateRRs(0); !iter.done(); iter.next()) {
             
             
             
             
             
             
             
             
             
             
             
             

            if(iter.dnstype == DNSTYPE_NSEC) {
                checkNsecName(iter, nsecName, deleteName, deleteType);
            } else if(iter.dnstype == DNSTYPE_NSEC3) {
                checkNsec3Name(iter, nsecName, deleteName, deleteType);
            } else {
                revert("Unrecognised record type");
            }

            delete rrsets[keccak256(deleteName)][deleteType];
            return;
        }
         
        revert();
    }

    function checkNsecName(RRUtils.RRIterator memory iter, bytes memory nsecName, bytes memory deleteName, uint16 deleteType) private pure {
        uint rdataOffset = iter.rdataOffset;
        uint nextNameLength = iter.data.nameLength(rdataOffset);
        uint rDataLength = iter.nextOffset - iter.rdataOffset;

         
        require(rDataLength > nextNameLength);

        int compareResult = deleteName.compareNames(nsecName);
        if(compareResult == 0) {
             
            require(!iter.data.checkTypeBitmap(rdataOffset + nextNameLength, deleteType));
        } else {
             
            bytes memory nextName = iter.data.substring(rdataOffset,nextNameLength);
             
            require(compareResult > 0);
            if(nsecName.compareNames(nextName) < 0) {
                 
                require(deleteName.compareNames(nextName) < 0);
            }
        }
    }

    function checkNsec3Name(RRUtils.RRIterator memory iter, bytes memory nsecName, bytes memory deleteName, uint16 deleteType) private view {
        uint16 iterations = iter.data.readUint16(iter.rdataOffset + NSEC3_ITERATIONS);
        uint8 saltLength = iter.data.readUint8(iter.rdataOffset + NSEC3_SALT_LENGTH);
        bytes memory salt = iter.data.substring(iter.rdataOffset + NSEC3_SALT, saltLength);
        bytes32 deleteNameHash = nsec3Digests[iter.data.readUint8(iter.rdataOffset)].hash(salt, deleteName, iterations);

        uint8 nextLength = iter.data.readUint8(iter.rdataOffset + NSEC3_SALT + saltLength);
        require(nextLength <= 32);
        bytes32 nextNameHash = iter.data.readBytesN(iter.rdataOffset + NSEC3_SALT + saltLength + 1, nextLength);

        bytes32 nsecNameHash = nsecName.base32HexDecodeWord(1, uint(nsecName.readUint8(0)));

        if(deleteNameHash == nsecNameHash) {
             
            require(!iter.data.checkTypeBitmap(iter.rdataOffset + NSEC3_SALT + saltLength + 1 + nextLength, deleteType));
        } else {
             
            require(deleteNameHash > nsecNameHash);
             
            if(nextNameHash > nsecNameHash) {
                 
                require(deleteNameHash < nextNameHash);
            }
        }
    }

     
    function rrdata(uint16 dnstype, bytes memory name) public view returns (uint32, uint64, bytes20) {
        RRSet storage result = rrsets[keccak256(name)][dnstype];
        return (result.inception, result.inserted, result.hash);
    }

     
    function validateSignedSet(bytes memory input, bytes memory sig, bytes memory proof) internal view returns(bytes memory name, bytes memory rrs) {
        require(validProof(input.readName(RRSIG_SIGNER_NAME), proof));

        uint32 inception = input.readUint32(RRSIG_INCEPTION);
        uint32 expiration = input.readUint32(RRSIG_EXPIRATION);
        uint16 typecovered = input.readUint16(RRSIG_TYPE);
        uint8 labels = input.readUint8(RRSIG_LABELS);

         
        uint rrdataOffset = input.nameLength(RRSIG_SIGNER_NAME) + 18;
        rrs = input.substring(rrdataOffset, input.length - rrdataOffset);

         
        name = validateRRs(rrs, typecovered);
        require(name.labelCount(0) == labels);

         

         
         
        require(expiration > now);

         
         
        require(inception < now);

         
        verifySignature(name, input, sig, proof);

        return (name, rrs);
    }

    function validProof(bytes name, bytes memory proof) internal view returns(bool) {
        uint16 dnstype = proof.readUint16(proof.nameLength(0));
        return rrsets[keccak256(name)][dnstype].hash == bytes20(keccak256(proof));
    }

     
    function validateRRs(bytes memory data, uint16 typecovered) internal pure returns (bytes memory name) {
         
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
             
            require(iter.class == DNSCLASS_IN);

            if(name.length == 0) {
                name = iter.name();
            } else {
                 
                require(name.length == data.nameLength(iter.offset));
                require(name.equals(0, data, iter.offset, name.length));
            }

             
            require(iter.dnstype == typecovered);
        }
    }

     
    function verifySignature(bytes name, bytes memory data, bytes memory sig, bytes memory proof) internal view {
        uint signerNameLength = data.nameLength(RRSIG_SIGNER_NAME);

         
         
        require(signerNameLength <= name.length);
        require(data.equals(RRSIG_SIGNER_NAME, name, name.length - signerNameLength, signerNameLength));

         
        uint offset = 18 + signerNameLength;

         
        uint16 dnstype = proof.readUint16(proof.nameLength(0));
        if (dnstype == DNSTYPE_DS) {
            require(verifyWithDS(data, sig, offset, proof));
        } else if (dnstype == DNSTYPE_DNSKEY) {
            require(verifyWithKnownKey(data, sig, proof));
        } else {
            revert("Unsupported proof record type");
        }
    }

     
    function verifyWithKnownKey(bytes memory data, bytes memory sig, bytes memory proof) internal view returns(bool) {
        uint signerNameLength = data.nameLength(RRSIG_SIGNER_NAME);

         
        uint8 algorithm = data.readUint8(RRSIG_ALGORITHM);
        uint16 keytag = data.readUint16(RRSIG_KEY_TAG);

        for (RRUtils.RRIterator memory iter = proof.iterateRRs(0); !iter.done(); iter.next()) {
             
            require(proof.nameLength(0) == signerNameLength);
            require(proof.equals(0, data, RRSIG_SIGNER_NAME, signerNameLength));
            if (verifySignatureWithKey(iter.rdata(), algorithm, keytag, data, sig)) {
                return true;
            }
        }

        return false;
    }

     
    function verifyWithDS(bytes memory data, bytes memory sig, uint offset, bytes memory proof) internal view returns(bool) {
         
        uint8 algorithm = data.readUint8(RRSIG_ALGORITHM);
        uint16 keytag = data.readUint16(RRSIG_KEY_TAG);

         
        for (RRUtils.RRIterator memory iter = data.iterateRRs(offset); !iter.done(); iter.next()) {
            if (iter.dnstype != DNSTYPE_DNSKEY) {
                return false;
            }

            bytes memory keyrdata = iter.rdata();
            if (verifySignatureWithKey(keyrdata, algorithm, keytag, data, sig)) {
                 
                return verifyKeyWithDS(iter.name(), keyrdata, keytag, algorithm, proof);
            }
        }

        return false;
    }

     
    function verifySignatureWithKey(bytes memory keyrdata, uint8 algorithm, uint16 keytag, bytes data, bytes sig) internal view returns (bool) {
        if (algorithms[algorithm] == address(0)) {
            return false;
        }
         

         
         
         
        if (keyrdata.readUint8(DNSKEY_PROTOCOL) != 3) {
            return false;
        }
        if (keyrdata.readUint8(DNSKEY_ALGORITHM) != algorithm) {
            return false;
        }
        uint16 computedkeytag = computeKeytag(keyrdata);
        if (computedkeytag != keytag) {
            return false;
        }

         
         
         
        if (keyrdata.readUint16(DNSKEY_FLAGS) & DNSKEY_FLAG_ZONEKEY == 0) {
            return false;
        }

        return algorithms[algorithm].verify(keyrdata, data, sig);
    }

     
    function verifyKeyWithDS(bytes memory keyname, bytes memory keyrdata, uint16 keytag, uint8 algorithm, bytes memory data)
        internal view returns (bool)
    {
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            if (data.readUint16(iter.rdataOffset + DS_KEY_TAG) != keytag) {
                continue;
            }
            if (data.readUint8(iter.rdataOffset + DS_ALGORITHM) != algorithm) {
                continue;
            }

            uint8 digesttype = data.readUint8(iter.rdataOffset + DS_DIGEST_TYPE);
            Buffer.buffer memory buf;
            buf.init(keyname.length + keyrdata.length);
            buf.append(keyname);
            buf.append(keyrdata);
            if (verifyDSHash(digesttype, buf.buf, data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset))) {
                return true;
            }
        }
        return false;
    }

     
    function verifyDSHash(uint8 digesttype, bytes data, bytes digest) internal view returns (bool) {
        if (digests[digesttype] == address(0)) {
            return false;
        }
        return digests[digesttype].verify(data, digest.substring(4, digest.length - 4));
    }

     
    function computeKeytag(bytes memory data) internal pure returns (uint16) {
        uint ac;
        for (uint i = 0; i < data.length; i += 2) {
            ac += data.readUint16(i);
        }
        ac += (ac >> 16) & 0xFFFF;
        return uint16(ac & 0xFFFF);
    }
}