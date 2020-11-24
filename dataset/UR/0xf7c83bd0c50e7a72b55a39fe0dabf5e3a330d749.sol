 

 

pragma solidity >=0.4.24;

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

 

pragma solidity >=0.4.24;

interface Deed {

    function setOwner(address payable newOwner) external;
    function setRegistrar(address newRegistrar) external;
    function setBalance(uint newValue, bool throwOnFailure) external;
    function closeDeed(uint refundRatio) external;
    function destroyDeed() external;

    function owner() external view returns (address);
    function previousOwner() external view returns (address);
    function value() external view returns (uint);
    function creationDate() external view returns (uint);

}

 

pragma solidity >=0.4.24;


interface Registrar {

    enum Mode { Open, Auction, Owned, Forbidden, Reveal, NotYetAvailable }

    event AuctionStarted(bytes32 indexed hash, uint registrationDate);
    event NewBid(bytes32 indexed hash, address indexed bidder, uint deposit);
    event BidRevealed(bytes32 indexed hash, address indexed owner, uint value, uint8 status);
    event HashRegistered(bytes32 indexed hash, address indexed owner, uint value, uint registrationDate);
    event HashReleased(bytes32 indexed hash, uint value);
    event HashInvalidated(bytes32 indexed hash, string indexed name, uint value, uint registrationDate);

    function state(bytes32 _hash) external view returns (Mode);
    function startAuction(bytes32 _hash) external;
    function startAuctions(bytes32[] calldata _hashes) external;
    function newBid(bytes32 sealedBid) external payable;
    function startAuctionsAndBid(bytes32[] calldata hashes, bytes32 sealedBid) external payable;
    function unsealBid(bytes32 _hash, uint _value, bytes32 _salt) external;
    function cancelBid(address bidder, bytes32 seal) external;
    function finalizeAuction(bytes32 _hash) external;
    function transfer(bytes32 _hash, address payable newOwner) external;
    function releaseDeed(bytes32 _hash) external;
    function invalidateName(string calldata unhashedName) external;
    function eraseNode(bytes32[] calldata labels) external;
    function transferRegistrars(bytes32 _hash) external;
    function acceptRegistrarTransfer(bytes32 hash, Deed deed, uint registrationDate) external;
    function entries(bytes32 _hash) external view returns (Mode, address, uint, uint, uint);
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity >=0.4.24;





contract BaseRegistrar is IERC721, Ownable {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

     
    uint public transferPeriodEnds;

     
    ENS public ens;

     
    bytes32 public baseNode;

     
    Registrar public previousRegistrar;

     
    mapping(address=>bool) public controllers;

     
    function addController(address controller) external;

     
    function removeController(address controller) external;

     
    function setResolver(address resolver) external;

     
    function nameExpires(uint256 id) external view returns(uint);

     
    function available(uint256 id) public view returns(bool);

     
    function register(uint256 id, address owner, uint duration) external returns(uint);

    function renew(uint256 id, uint duration) external returns(uint);

     
    function reclaim(uint256 id, address owner) external;

     
    function acceptRegistrarTransfer(bytes32 label, Deed deed, uint) external;
}

 

pragma solidity >=0.4.24;

library StringUtils {
     
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            byte b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

 

pragma solidity >=0.4.24;

interface PriceOracle {
     
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}

 

pragma solidity >0.4.18;

 
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
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

     
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
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

     
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
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

     
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

     
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

     
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off >= buf.capacity) {
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
            resize(buf, (len + off) * 2);
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
            resize(buf, (len + off) * 2);
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

     
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

 

pragma solidity >0.4.23;

library BytesUtils {
     
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
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
        return uint8(self[idx]);
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

     
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
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

     
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
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
        uint8 decoded;
        for(uint i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint(uint8(char)) - 0x30]);
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

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;







 
contract ShortNameClaims {
    using Roles for Roles.Role;

    uint constant public REGISTRATION_PERIOD = 31536000;

    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using StringUtils for string;

    enum Phase {
        OPEN,
        REVIEW,
        FINAL
    }

    enum Status {
        PENDING,
        APPROVED,
        DECLINED,
        WITHDRAWN
    }

    struct Claim {
        bytes32 labelHash;
        address claimant;
        uint paid;
        Status status;
    }

    Roles.Role owners;
    Roles.Role ratifiers;

    PriceOracle public priceOracle;
    BaseRegistrar public registrar;
    mapping(bytes32=>Claim) public claims;
    mapping(bytes32=>bool) approvedNames;
    uint public pendingClaims;
    uint public unresolvedClaims;
    Phase public phase;

    event ClaimSubmitted(string claimed, bytes dnsname, uint paid, address claimant, string email);
    event ClaimStatusChanged(bytes32 indexed claimId, Status status);

    constructor(PriceOracle _priceOracle, BaseRegistrar _registrar, address _ratifier) public {
        priceOracle = _priceOracle;
        registrar = _registrar;
        phase = Phase.OPEN;

        owners.add(msg.sender);
        ratifiers.add(_ratifier);
    }

    modifier onlyOwner() {
        require(owners.has(msg.sender), "Caller must be an owner");
        _;
    }

    modifier onlyRatifier() {
        require(ratifiers.has(msg.sender), "Caller must be a ratifier");
        _;
    }

    modifier inPhase(Phase p) {
        require(phase == p, "Not in required phase");
        _;
    }

    function addOwner(address owner) external onlyOwner {
        owners.add(owner);
    }

    function removeOwner(address owner) external onlyOwner {
        owners.remove(owner);
    }

    function addRatifier(address ratifier) external onlyRatifier {
        ratifiers.add(ratifier);
    }

    function removeRatifier(address ratifier) external onlyRatifier {
        ratifiers.remove(ratifier);
    }

     
    function computeClaimId(string memory claimed, bytes memory dnsname, address claimant, string memory email) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(claimed)), keccak256(dnsname), claimant, keccak256(bytes(email))));
    }

     
    function getClaimCost(string memory claimed) public view returns(uint) {
        return priceOracle.price(claimed, 0, REGISTRATION_PERIOD);
    }

     
    function submitExactClaim(bytes memory name, address claimant, string memory email) public payable {
        string memory claimed = getLabel(name, 0);
        handleClaim(claimed, name, claimant, email);
    }

     
    function submitCombinedClaim(bytes memory name, address claimant, string memory email) public payable {
        bytes memory firstLabel = bytes(getLabel(name, 0));
        bytes memory secondLabel = bytes(getLabel(name, 1));
        Buffer.buffer memory buf;
        buf.init(firstLabel.length + secondLabel.length);
        buf.append(firstLabel);
        buf.append(secondLabel);

        handleClaim(string(buf.buf), name, claimant, email);
    }

     
    function submitPrefixClaim(bytes memory name, address claimant, string memory email) public payable {
        bytes memory firstLabel = bytes(getLabel(name, 0));
        require(firstLabel.equals(firstLabel.length - 3, bytes("eth")));
        handleClaim(string(firstLabel.substring(0, firstLabel.length - 3)), name, claimant, email);
    }

     
    function closeClaims() external onlyOwner inPhase(Phase.OPEN) {
        phase = Phase.REVIEW;
    }

     
    function ratifyClaims() external onlyRatifier inPhase(Phase.REVIEW) {
         
        require(pendingClaims == 0);
        phase = Phase.FINAL;
    }

     
    function destroy() external onlyOwner inPhase(Phase.FINAL) {
        require(unresolvedClaims == 0);
        selfdestruct(toPayable(msg.sender));
    }

     
    function setClaimStatus(bytes32 claimId, bool approved) public inPhase(Phase.REVIEW) {
         
        require(owners.has(msg.sender) || ratifiers.has(msg.sender));

        Claim memory claim = claims[claimId];
        require(claim.paid > 0, "Claim not found");

        if(claim.status == Status.PENDING) {
           
          pendingClaims--;
          unresolvedClaims++;
        } else if(claim.status == Status.APPROVED) {
           
          approvedNames[claim.labelHash] = false;
        }

         
         
        if(approved) {
          require(!approvedNames[claim.labelHash]);
          approvedNames[claim.labelHash] = true;
        }

        Status status = approved?Status.APPROVED:Status.DECLINED;
        claims[claimId].status = status;
        emit ClaimStatusChanged(claimId, status);
    }

     
    function setClaimStatuses(bytes32[] calldata approved, bytes32[] calldata declined) external {
        for(uint i = 0; i < approved.length; i++) {
            setClaimStatus(approved[i], true);
        }
        for(uint i = 0; i < declined.length; i++) {
            setClaimStatus(declined[i], false);
        }
    }

     
    function resolveClaim(bytes32 claimId) public inPhase(Phase.FINAL) {
        Claim memory claim = claims[claimId];
        require(claim.paid > 0, "Claim not found");

        if(claim.status == Status.APPROVED) {
            registrar.register(uint256(claim.labelHash), claim.claimant, REGISTRATION_PERIOD);
            toPayable(registrar.owner()).transfer(claim.paid);
        } else if(claim.status == Status.DECLINED) {
            toPayable(claim.claimant).transfer(claim.paid);
        } else {
             
             
            assert(false);
        }

        unresolvedClaims--;
        delete claims[claimId];
    }

     
    function resolveClaims(bytes32[] calldata claimIds) external {
        for(uint i = 0; i < claimIds.length; i++) {
            resolveClaim(claimIds[i]);
        }
    }

     
    function withdrawClaim(bytes32 claimId) external {
        Claim memory claim = claims[claimId];

         
        require(msg.sender == claim.claimant);

        if(claim.status == Status.PENDING) {
            pendingClaims--;
        } else {
            unresolvedClaims--;
        }

        toPayable(claim.claimant).transfer(claim.paid);
        emit ClaimStatusChanged(claimId, Status.WITHDRAWN);
        delete claims[claimId];
    }

    function handleClaim(string memory claimed, bytes memory name, address claimant, string memory email) internal inPhase(Phase.OPEN) {
        uint len = claimed.strlen();
        require(len >= 3 && len <= 6);

        bytes32 claimId = computeClaimId(claimed, name, claimant, email);
        require(claims[claimId].paid == 0, "Claim already submitted");

         
        require(bytes(getLabel(name, 2)).length == 0, "Name must be a 2LD");

        uint price = getClaimCost(claimed);
        require(msg.value >= price, "Insufficient funds for reservation");
        if(msg.value > price) {
            msg.sender.transfer(msg.value - price);
        }

        claims[claimId] = Claim(keccak256(bytes(claimed)), claimant, price, Status.PENDING);
        pendingClaims++;
        emit ClaimSubmitted(claimed, name, price, claimant, email);
    }

    function getLabel(bytes memory name, uint idx) internal pure returns(string memory) {
         
        uint offset = 0;
        for(uint i = 0; i < idx; i++) {
            if(offset >= name.length) return "";
            offset += name.readUint8(offset) + 1;
        }

         
        if(offset >= name.length) return '';
        uint len = name.readUint8(offset);
        return string(name.substring(offset + 1, len));
    }

    function toPayable(address addr) internal pure returns(address payable) {
        return address(uint160(addr));
    }
}