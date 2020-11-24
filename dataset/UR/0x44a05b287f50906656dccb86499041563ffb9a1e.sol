 

pragma solidity 0.5.0;

 

 

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
        for(; len >= 32; len -= 32) {
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

     
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

 

 
contract Themis {

    struct Stamp {
        string hash;
        string data;
        bool exists;
    }

    struct AuthorityStamps {
        bool enabled;
        Stamp[] stamps;
        mapping(string => Stamp) hashToStamp;
    }

    event TransferChairEvent (
        address indexed newChair
    );

    event StampEvent (
        address indexed authority,
        string indexed hash,
        string data
    );

    event AuthorityAbilitation (
        address indexed authority,
        bool enabled
    );

    address public chairAuthority;
    mapping(address => AuthorityStamps) private authorities;
    address[] private authorityAddresses;

    constructor() public {
        chairAuthority = msg.sender;
        authorities[msg.sender].enabled = true;
        authorityAddresses.push(msg.sender);
    }

    function transferChair(address authority) public {
        require(msg.sender == chairAuthority, 'unauthorised');
        chairAuthority = authority;
        emit TransferChairEvent(authority);
    }

    function enableAuthority(address authority) public {
        require(msg.sender == chairAuthority);
        authorities[authority].enabled = true;
        bool found = false;
        for(uint256 i = 0; i < authorityAddresses.length; i++) {
            if(authorityAddresses[i] == authority) {
                found = true;
                break;
            }
        }
        if(!found) {
            authorityAddresses.push(authority);
        }
        emit AuthorityAbilitation(authority, true);
    }

    function disableAuthority(address authority) public {
        require(msg.sender == chairAuthority);
        authorities[authority].enabled = false;
        emit AuthorityAbilitation(authority, false);
    }

    function stamp(string memory hash, string memory data) public {
        require(bytes(hash).length > 0, 'hash cannot be empty');
        AuthorityStamps storage authority = authorities[msg.sender];
        require (authority.enabled, 'authority is not enabled');
        require(authority.hashToStamp[hash].exists == false, 'Hash has been already stamped');
        Stamp memory _stamp = Stamp(hash, data, true);
        authority.stamps.push(_stamp);
        authority.hashToStamp[hash] = _stamp;
        emit StampEvent(msg.sender, hash, data);
    }

    function getAuthoritiesCount() public view returns(uint256 chain) {
        return authorityAddresses.length;
    }

    function getAuthorityAddress(uint i) public view returns(address authority) {
        return authorityAddresses[i];
    }

    function isAuthorityEnabled(address authority) public view returns(bool enabled) {
        return authorities[authority].enabled;
    }

    function getStampsCount(address authority) public view returns(uint256 count) {
        return authorities[authority].stamps.length;
    }

    function getStampHash(address authority, uint256 i) public view returns(string memory hash) {
        Stamp memory _stamp = authorities[authority].stamps[i];
        require(_stamp.exists);
        return _stamp.hash;
    }

    function getStampData(address authority, uint256 i) public view returns(string memory data) {
        Stamp memory _stamp = authorities[authority].stamps[i];
        require(_stamp.exists);
        return _stamp.data;
    }

    function getStampsRange(address authority, uint256 frm, uint256 to, string memory separator) public view returns(string memory hashstr, string memory datastr) {
        Stamp[] memory stamps = authorities[authority].stamps;
        strings.slice memory hashBuf = strings.toSlice("");
        strings.slice memory dataBuf = strings.toSlice("");
        strings.slice memory sep = strings.toSlice(separator);
        for(uint256 c = frm; c < to; c++) {
            hashBuf = strings.toSlice(strings.concat(hashBuf, strings.toSlice(strings.concat(strings.toSlice(stamps[c].hash), sep))));
            dataBuf = strings.toSlice(strings.concat(dataBuf, strings.toSlice(strings.concat(strings.toSlice(stamps[c].data), sep))));
        }
        return (strings.toString(hashBuf), strings.toString(dataBuf));
    }

    function getStampByHash(address authority, string memory hash) public view returns (string memory data, bool exists) {
        Stamp memory _stamp = authorities[authority].hashToStamp[hash];
        return (_stamp.data, _stamp.exists);
    }

}