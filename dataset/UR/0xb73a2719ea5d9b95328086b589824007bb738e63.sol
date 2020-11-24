 

pragma solidity ^0.5.0;

 
  

 
contract solcChecker {
  function f(bytes calldata x) external;
}

contract OraclizeI {

    address public cbAddress;

    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string memory _datasource) public view returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string memory _datasource, uint _gasLimit) public view returns (uint _dsprice);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _address);
}
 
library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity;  
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
     
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf)  
            let buflen := mload(bufptr)  
            dest := add(add(bufptr, buflen), 32)  
            mstore(bufptr, add(buflen, mload(_data)))  
            src := add(_data, 32)
        }
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
        return _buf;
    }
     
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf)  
            let buflen := mload(bufptr)  
            let dest := add(add(bufptr, buflen), 32)  
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1))  
        }
    }
     
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf)  
            let buflen := mload(bufptr)  
            let dest := add(add(bufptr, buflen), _len)  
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len))  
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}
 
contract usingOraclize {

    using CBOR for Buffer.buffer;

    OraclizeI oraclize;
    OraclizeAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string oraclize_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) oraclize_randomDS_args;
    mapping(bytes32 => bool) oraclize_randomDS_sessionKeysHashVerified;

    modifier oraclizeAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            oraclize_setNetwork(networkID_auto);
        }
        if (address(oraclize) != OAR.getAddress()) {
            oraclize = OraclizeI(OAR.getAddress());
        }
        _;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
         
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);
        _;
    }

    function oraclize_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      return oraclize_setNetwork();
      _networkID;  
    }

    function oraclize_setNetworkName(string memory _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string memory _networkName) {
        return oraclize_network_name;
    }

    function oraclize_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) {  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) {  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        return false;
    }

    function __callback(bytes32 _myid, string memory _result) public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) public {
      return;
      _myid; _result; _proof;  
    }

    function oraclize_getPrice(string memory _datasource, uint _gasLimit) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource, _gasLimit);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;  
        }
        return oraclize.query_withGasLimit.value(price)(_timestamp, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;  
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }


    function oraclize_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address _callbackAddress) {
        return oraclize.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function oraclize_setCustomGasPrice(uint _gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(_gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32 _sessionKeyHash) {
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10;  
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
             
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        oraclize_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        oraclize_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
         
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1));  
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
         
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
         
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
         
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
         
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
         
         
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) {  
            delete oraclize_randomDS_args[_queryId];
        } else return false;
         
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
         
        if (!oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
     
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength);  
        uint i = 32 + _fromOffset;  
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
     
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
         
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32)  
            addr := mload(size)
        }
        return (ret, addr);
    }
     
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
         
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
             
            v := byte(0, mload(add(_sig, 96)))
             
        }
         
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
}
 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract GameInterface {

    uint public commissionEarned;
    uint public totalFundsLostByPlayers;

    function finalizeBet(address _user, uint _betId) public returns(uint profit, uint totalWon);
    function canFinalizeBet(address _user, uint _betId) public view returns (bool success);
    function getUserProfitForFinishedBet(address _user, uint _betId) public view returns(uint);
    function getTotalBets(address _user) public view returns(uint);
    function getPossibleWinnings(uint _chance, uint _amount) public view returns(uint);
    function getBetInfo(address _user, uint _betId) public view returns(uint amount, bool finalized, bool won, bool bonus);
    function getParamsForTokenCaluclation(uint _chance) public view returns(uint minB, uint maxB, uint gbs, uint gwp);
    function emergencyWithdraw(address payable _sender) public;
}

contract BadBitSettings {

    uint public constant GWEI_TO_WEI = 1000000000;
    uint public constant ETH_TO_WEI = 1000000000000000000;
    uint public ORACLIZE_GAS_LIMIT = 220000;
    uint public MAX_GAS_PRICE = 30000000000;  
    uint public MIN_GAS_PRICE = 1000000000;  
    uint public BIG_WIN_THRESHOLD = 3 ether;
    uint public MAX_CHANCE_FOR_BONUS_BETTING = 25;
    uint public MAX_DON_IN_ROW = 3;
    uint public HOUSE_EDGE = 2000;
    uint public MAX_WP = 9500;
    uint public MIN_WP = 476;
    uint public REVENUE_TO_INITIAL_DEPOSIT_RATIO = 2;
    bool public BETS_ALLOWED = true;
    bool public USE_BLOCKHASH_RANDOM_SEED = false;

     
    mapping(address => bool) public isGameAddress;
     
    mapping(address => bool) public isOperatorAddress;
     
    address[] public gameContractAddresses;
     
    address[] public operators;
     
    uint[] public tokenWinChanceRewardForLevel;
     
    uint[] public bonusBalanceRewardForLevel;

    event GamePaused(bool indexed yes);
    event MaxGasPriceSet(uint amount);
    event MinGasPriceSet(uint amount);
    event BigWinThresholdSet(uint amount);
    event MaxChanceForBonusBetSet(uint amount);
    event MaxDonInRowSet(uint count);
    event HouseEdgeSet(uint houseEdge);
    event MaxWPSet(uint maxWp);
    event MinWPSet(uint minWp);

    modifier onlyOperators() {
        require (isOperatorAddress[msg.sender]);
        _;
    }

    constructor() public {
        operators.push(msg.sender);
        isOperatorAddress[msg.sender] = true;

        bonusBalanceRewardForLevel = [0, 0, 0.01 ether, 0.02 ether, 0,
            0.03 ether, 0.04 ether, 0.05 ether, 0, 0.06 ether, 0.07 ether,
            0.08 ether, 0, 0.09 ether, 0.10 ether, 0.11 ether, 0, 0.12 ether,
            0.13 ether, 0.14 ether, 0, 0.15 ether, 0.16 ether, 0.17 ether, 0,
            0.18 ether, 0.19 ether, 0.20 ether, 0, 0.21 ether, 0.22 ether,
            0.23 ether, 0, 0.24 ether, 0.25 ether, 0.26 ether, 0, 0.27 ether,
            0.28 ether, 0.29 ether, 0, 0.30 ether, 0.31 ether, 0.32 ether, 0,
            0.33 ether, 0.34 ether, 0.35 ether, 0, 0.36 ether, 0.37 ether,
            0.38 ether, 0, 0.39 ether, 0.40 ether, 0.41 ether, 0, 0.42 ether,
            0.43 ether, 0.44 ether, 0, 0.45 ether, 0.46 ether, 0.47 ether, 0,
            0.48 ether, 0.49 ether, 0.50 ether, 0, 0.51 ether, 0.52 ether,
            0.53 ether, 0, 0.54 ether, 0.55 ether, 0.56 ether, 0, 0.57 ether,
            0.58 ether, 0.59 ether, 0, 0.60 ether, 0.61 ether, 0.62 ether, 0,
            0.63 ether, 0.64 ether, 0.65 ether, 0, 0.66 ether, 0.67 ether,
            0.68 ether, 0, 0.69 ether, 0.70 ether, 0.71 ether, 0, 0.72 ether,
            0.73 ether, 0.74 ether, 0];


        tokenWinChanceRewardForLevel = [0, 0, 0, 0, 40, 40, 40, 40, 80, 80, 80, 80,
            120, 120, 120, 120, 160, 160, 160, 160, 200, 200, 200, 200, 250, 250, 250, 250, 300, 300, 300, 300,
            350, 350, 350, 350, 400, 400, 400, 400, 450, 450, 450, 450, 510, 510, 510, 510, 570, 570, 570, 570,
            630, 630, 630, 630, 690, 690, 690, 690, 750, 750, 750, 750, 820, 820, 820, 820, 890, 890, 890, 890,
            960, 960, 960, 960, 1030, 1030, 1030, 1030, 1100, 1100, 1100, 1100, 1180, 1180, 1180, 1180, 1260, 1260, 1260, 1260,
            1340, 1340, 1340, 1340, 1420, 1420, 1420, 1420, 1500];
    }

     
    function addGame(address _address) public onlyOperators {
        require(!isGameAddress[_address]);

        gameContractAddresses.push(_address);
        isGameAddress[_address] = true;
    }

     
    function removeGame(address _address) public onlyOperators {
        require(isGameAddress[_address]);

        uint len = gameContractAddresses.length;

        for (uint i=0; i<len; i++) {
            if (gameContractAddresses[i] == _address) {
                 
                gameContractAddresses[i] = gameContractAddresses[len-1];
                 
                delete gameContractAddresses[len-1];
                 
                gameContractAddresses.length--;
                 
                isGameAddress[_address] = false;
                break;
            }
        }

    }

     
    function addOperator(address _address) public onlyOperators {
        require(!isOperatorAddress[_address]);

        operators.push(_address);
        isOperatorAddress[_address] = true;
    }

     
    function removeOperator(address _address) public onlyOperators {
        require(isOperatorAddress[_address]);

        uint len = operators.length;

        for (uint i=0; i<len; i++) {
            if (operators[i] == _address) {
                 
                operators[i] = operators[len-1];
                 
                delete operators[len-1];
                 
                operators.length--;
                 
                isOperatorAddress[_address] = false;
                break;
            }
        }

    }

    function setMaxGasPriceInGwei(uint _maxGasPrice) public onlyOperators {
        MAX_GAS_PRICE = _maxGasPrice * GWEI_TO_WEI;

        emit MaxGasPriceSet(MAX_GAS_PRICE);
    }

    function setMinGasPriceInGwei(uint _minGasPrice) public onlyOperators {
        MIN_GAS_PRICE = _minGasPrice * GWEI_TO_WEI;

        emit MinGasPriceSet(MIN_GAS_PRICE);
    }

    function setBetsAllowed(bool _betsAllowed) public onlyOperators {
        BETS_ALLOWED = _betsAllowed;

        emit GamePaused(!_betsAllowed);
    }

    function setBigWin(uint _bigWin) public onlyOperators {
        BIG_WIN_THRESHOLD = _bigWin;

        emit BigWinThresholdSet(BIG_WIN_THRESHOLD);
    }

    function setMaxChanceForBonus(uint _chance) public onlyOperators {
        MAX_CHANCE_FOR_BONUS_BETTING = _chance;

        emit MaxChanceForBonusBetSet(MAX_CHANCE_FOR_BONUS_BETTING);
    }

    function setMaxDonInRow(uint _count) public onlyOperators {
        MAX_DON_IN_ROW = _count;

        emit MaxDonInRowSet(MAX_DON_IN_ROW);
    }

    function setHouseEdge(uint _edge) public onlyOperators {
         
        require(_edge < 100000);

        HOUSE_EDGE = _edge;

        emit HouseEdgeSet(HOUSE_EDGE);
    }

    function setOraclizeGasLimit(uint _gas) public onlyOperators {
        ORACLIZE_GAS_LIMIT = _gas;
    }

    function setMaxWp(uint _wp) public onlyOperators {
        MAX_WP = _wp;

        emit MaxWPSet(_wp);
    }

    function setMinWp(uint _wp) public onlyOperators {
        MIN_WP = _wp;

        emit MinWPSet(_wp);
    }

    function setUseBlockhashRandomSeed(bool _use) public onlyOperators {
        USE_BLOCKHASH_RANDOM_SEED = _use;
    }

    function setRevenueToInitialDepositRatio(uint _ratio) public onlyOperators {
        require(_ratio >= 2);

        REVENUE_TO_INITIAL_DEPOSIT_RATIO = _ratio;
    }

    function getOperators() public view returns(address[] memory) {
        return operators;
    }

    function getGames() public view returns(address[] memory) {
        return gameContractAddresses;
    }

    function getNumberOfGames() public view returns(uint) {
        return gameContractAddresses.length;
    }
}

contract IBadBitDistributor{
	function sendTokens(address _user, uint _amount) public;
	function getStandardLot() public view returns(uint);
	function shouldWinTokens(address _contract, bytes32 _hash, address _user, uint[] memory _betSizes, uint[] memory _chances, uint _maxNumOfBets) public view returns (bool);
	function winTokens(address _user) public;

}

contract BadBitWallet {

    using SafeMath for uint256;

    struct Withdrawal {
        uint withdrawalTimestamp;
        uint amount;
    }

     
    address[] public users;
     
    mapping(address => uint) public userBalances;
     
    mapping(address => uint) public userBonusBalances;
     
    mapping(address => Withdrawal[]) public userWithdrawals;
     
    uint public totalPlayerBalances;
     
    uint public totalFundsSentByOwner;

    BadBitSettings public settings;
    address public distributorAddress;
    IBadBitDistributor public distributor;

    event UserWithdrawal(address indexed user, uint indexed timestamp);

    modifier onlyGames() {
        require (settings.isGameAddress(msg.sender));
        _;
    }

    modifier onlyOperators() {
        require (settings.isOperatorAddress(msg.sender));
        _;
    }

    constructor(address _settings) public {
        settings = BadBitSettings(_settings);
    }

    function setDistributor(address _distributorAddress) public onlyOperators {
        distributorAddress = _distributorAddress;
        distributor = IBadBitDistributor(_distributorAddress);
    }

     
    function topUp() public payable {
        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        totalPlayerBalances = totalPlayerBalances.add(msg.value);
    }

     
    function _subtract(address _user, uint _amount) internal returns(bool) {
        require(tx.origin == _user);

        if (userBalances[_user] < _amount) return false;

        userBalances[_user] = userBalances[_user].sub(_amount);
        totalPlayerBalances = totalPlayerBalances.sub(_amount);

        return true;
    }

     
    function add(address _user, uint _amount) public payable onlyGames returns(bool) {
        return _add(_user, _amount);
    }

     
    function _add(address _user, uint _amount) internal returns(bool) {
        if (_amount == 0) return false;

        userBalances[_user] = userBalances[_user].add(_amount);
        totalPlayerBalances = totalPlayerBalances.add(_amount);

        require(totalPlayerBalances <= address(this).balance);

        return true;
    }

     
    function addBonus(address _user, uint _amount) public onlyOperators payable returns(bool) {
        return _addBonus(_user, _amount);
    }

     
    function _addBonus(address _user, uint _amount) internal returns(bool) {
        if (_amount == 0) return false;

        userBonusBalances[_user] = userBonusBalances[_user].add(_amount);

        return true;
    }

     
    function subtractBonus(address _user, uint _amount) public onlyGames returns(bool) {
        return _subtractBonus(_user, _amount);
    }

     
    function _subtractBonus(address _user, uint _amount) internal returns(bool) {
        require(tx.origin == _user);

        if (userBonusBalances[_user] < _amount) return false;

        userBonusBalances[_user] = userBonusBalances[_user].sub(_amount);

        return true;
    }

     
    function withdraw(address payable _user, uint _amount) public {
         
        require(_user == msg.sender);

        BadBitCasino(address(this))._finalizeLastBets(_user);

         
        userBalances[_user] = userBalances[_user].sub(_amount);
        totalPlayerBalances = totalPlayerBalances.sub(_amount);

        uint _timestamp = now;
        userWithdrawals[_user].push(Withdrawal({
            withdrawalTimestamp: _timestamp,
            amount: _amount
        }));

        _user.transfer(_amount);

        emit UserWithdrawal(_user, _timestamp);
    }

    function getNumberOfUserWithdrawals(address _user) public view returns(uint) {
        return userWithdrawals[_user].length;
    }

    function addAmountByDistributor(address _user, uint _amount) public {
        require(msg.sender == distributorAddress);

        _add(_user, _amount);
    }

     
    function() external payable {
        totalFundsSentByOwner += msg.value;
    }
}

contract BadBitCasino is usingOraclize, BadBitWallet {

    using SafeMath for uint256;

    struct Bet {
        address game;
        uint betId;
    }

    struct DonBet {
        address game;
        address sender;
        uint amount;
        bool won;
        bool finalized;
    }

     
    uint public totalFundsSpentOnOraclize;
     
    uint public commissionEarned;

     
    uint public totalPlayerProfits;

     
    uint public totalFundsLostByPlayers;
     
    uint public totalFundsSentByOwner;

     
    uint public totalFundsTransferredToDepositPool;

     
    mapping(address => uint) public totalWinningsForPlayer;
     
    mapping(address => uint) public playerLevel;
     
    uint[] public amountRequiredForLevel;
     
    mapping(address => Bet[]) public bets;
     
    mapping(bytes32 => DonBet) public donBets;
     
    address[] public users;
     
    mapping(address => uint) public firstUnfinalizedBet;
     
    mapping(address => mapping(address => uint)) public lastWonAmountPerGame;

    event BigWin(address indexed user, address indexed game, uint amount);
    event DoubleOrNothingPlayed(bytes32 queryId, address indexed user, uint indexed betId, address indexed game);
    event DoubleOrNothingFinished(bytes32 indexed queryId, address indexed user, bool won, uint tokensWon);

    modifier onlyGames() {
        require (settings.isGameAddress(msg.sender));
        _;
    }

    modifier onlyOperators() {
        require (settings.isOperatorAddress(msg.sender));
        _;
    }

    constructor(address _settings) BadBitWallet(_settings) public {

        oraclize_setNetwork();
         
        oraclize_setCustomGasPrice(10000000000);
    }

    function fillAmountRequiredForLevel() public {
        amountRequiredForLevel = [0, 3 ether, 9 ether, 18 ether, 30 ether,
            45 ether, 63 ether, 84 ether, 108 ether, 135 ether, 165 ether,
            198 ether, 234 ether, 273 ether, 315 ether, 360 ether, 408 ether,
            459 ether, 513 ether, 570 ether, 630 ether, 693 ether, 759 ether,
            828 ether, 900 ether, 975 ether, 1053 ether, 1134 ether, 1218 ether,
            1305 ether, 1395 ether, 1488 ether, 1584 ether, 1683 ether, 1785 ether,
            1890 ether, 1998 ether, 2109 ether, 2223 ether, 2340 ether, 2460 ether,
            2583 ether, 2709 ether, 2838 ether, 2970 ether, 3105 ether, 3243 ether,
            3384 ether, 3528 ether, 3675 ether, 3825 ether, 3978 ether, 4134 ether,
            4293 ether, 4455 ether, 4620 ether, 4788 ether, 4959 ether, 5133 ether,
            5310 ether, 5490 ether, 5673 ether, 5859 ether, 6048 ether, 6240 ether,
            6435 ether, 6633 ether, 6834 ether, 7038 ether, 7245 ether, 7455 ether,
            7668 ether, 7884 ether, 8103 ether, 8325 ether, 8550 ether, 8778 ether,
            9009 ether, 9243 ether, 9480 ether, 9720 ether, 9963 ether, 10209 ether,
            10458 ether, 10710 ether, 10965 ether, 11223 ether, 11484 ether,
            11748 ether, 12015 ether, 12285 ether, 12558 ether, 12834 ether,
            13113 ether, 13395 ether, 13680 ether, 13968 ether, 14259 ether,
            14553 ether, 14850 ether, 15150 ether];
    }

    function placeBet(address _user, uint _betId, uint _amount, bool bonus) public onlyGames {
        require(settings.BETS_ALLOWED());

        if (bets[_user].length == 0) {
            users.push(_user);
        }

        _finalizeLastBets(_user);

        if (bonus) {
            require(_subtractBonus(_user, _amount));
        } else {
            require(_subtract(_user, _amount));
        }

        bets[_user].push(Bet({
                game: msg.sender,
                betId: _betId
            }));

         
         
         
        if (firstUnfinalizedBet[_user] != bets[_user].length - 1 && !needToUpdateBetsForUser(_user)) {
            firstUnfinalizedBet[_user] = bets[_user].length - 1;
        }
    }

    function _finalizeLastBets(address _user) public {
        uint count = bets[_user].length;

        if (count > 0 && needToUpdateBetsForUser(_user)) {
            uint starting = firstUnfinalizedBet[_user];

            for (uint i=starting; i<count; i++) {

                Bet memory betObject = bets[_user][i];
                bool finalized;
                bool isBonus;
                (, finalized, , isBonus) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

                if (!finalized) {
                    if (GameInterface(betObject.game).canFinalizeBet(_user, betObject.betId)) {
                        (uint profit, uint totalWon) = GameInterface(betObject.game).finalizeBet(_user, betObject.betId);

                        if (totalWon > 0) {
                            require(_add(_user, totalWon));
                            totalPlayerProfits += isBonus ? totalWon : profit;
                            totalWinningsForPlayer[_user] += totalWon;
                            updatePlayerLevelIfNeeded(_user);
                            lastWonAmountPerGame[betObject.game][_user] = totalWon;

                            if (totalWon > settings.BIG_WIN_THRESHOLD()) {
                                emit BigWin(_user, betObject.game, totalWon);
                            }
                        }
                    } else {
                        if (starting == firstUnfinalizedBet[_user]) {
                            bool isFirstFinalized;
                             
                            (, isFirstFinalized, ,) = GameInterface(bets[_user][starting].game).getBetInfo(_user, bets[_user][starting].betId);

                            if (isFirstFinalized) {
                                firstUnfinalizedBet[_user] = i;
                            }
                        }
                    }
                }
            }
        }
    }

     
    function finalizeLastBetsForAddresses(address[] memory _addresses) public onlyOperators {
        for (uint i=0; i<_addresses.length; i++) {
            _finalizeLastBets(_addresses[i]);
        }
    }

    function placeBetForDoubleOrNothing(address _game, uint _amount) public {
        require(settings.BETS_ALLOWED());

        _finalizeLastBets(msg.sender);

         
        require(lastWonAmountPerGame[_game][msg.sender] >= _amount);

        uint _gasPrice = tx.gasprice;
         
        if (_gasPrice < settings.MIN_GAS_PRICE()) {
            _gasPrice = settings.MIN_GAS_PRICE();
        } else if (_gasPrice > settings.MAX_GAS_PRICE()) {
            _gasPrice = settings.MAX_GAS_PRICE();
        }

        oraclize_setCustomGasPrice(_gasPrice);
        uint gasLimit = settings.ORACLIZE_GAS_LIMIT();

        bytes32 queryId = settings.USE_BLOCKHASH_RANDOM_SEED() ? oraclize_query(0, "URL", "", gasLimit) : oraclize_newRandomDSQuery(0, 8, gasLimit);

        totalFundsSpentOnOraclize += settings.USE_BLOCKHASH_RANDOM_SEED() ? oraclize_getPrice("url", gasLimit) : oraclize_getPrice("random", gasLimit);

        donBets[queryId] = DonBet({
            game: _game,
            sender: msg.sender,
            amount: _amount,
            won: false,
            finalized: false
        });

        require(_subtract(msg.sender, _amount));

        emit DoubleOrNothingPlayed(queryId, msg.sender, GameInterface(_game).getTotalBets(msg.sender) - 1, _game);
    }

    function __callback(bytes32 myid, string memory result) public {
        if (msg.sender != oraclize_cbAddress() && !settings.isOperatorAddress(msg.sender)) revert();

         
        require(!donBets[myid].finalized);
        require(settings.USE_BLOCKHASH_RANDOM_SEED() || bytes(result)[0] != 0);

        uint randomNumber;

        if(settings.isOperatorAddress(msg.sender) || settings.USE_BLOCKHASH_RANDOM_SEED()) {
            randomNumber = uint224(uint(blockhash(block.number - 1)).mod(100));
        } else {
            randomNumber = uint224(uint(keccak256(abi.encodePacked(result))).mod(100));
        }

         
        if (randomNumber < 50) {
            commissionEarned += getCommission(donBets[myid].amount);
            uint winnings = getPossibleWinnings(donBets[myid].amount);
            uint wonAmount = donBets[myid].amount + winnings;

            totalWinningsForPlayer[donBets[myid].sender] += winnings;
            updatePlayerLevelIfNeeded(donBets[myid].sender);

            require(_add(donBets[myid].sender, wonAmount));
            lastWonAmountPerGame[donBets[myid].game][donBets[myid].sender] = wonAmount;
            donBets[myid].won = true;
        } else {
            totalFundsLostByPlayers += donBets[myid].amount;
        }

        uint tokensWon = 0;

        uint[] memory betSizes = new uint[](1);
        betSizes[0] = donBets[myid].amount;
        uint[] memory chances = new uint[](1);
        chances[0] = 50;

        if (distributor.shouldWinTokens(donBets[myid].game, keccak256(abi.encodePacked(result)), donBets[myid].sender, betSizes, chances, 1)) {
            distributor.winTokens(donBets[myid].sender);
            tokensWon = distributor.getStandardLot();
        }

        emit DoubleOrNothingFinished(myid, donBets[myid].sender, randomNumber < 50, tokensWon);

        donBets[myid].finalized = true;
    }

     
    function getCurrentBalance(address _user) public view returns(uint) {
        uint balance = userBalances[_user];
        uint count = bets[_user].length;

        if (count == 0) {
            return balance;
        }

        if (needToUpdateBetsForUser(_user)) {
            uint starting = firstUnfinalizedBet[_user];

            for (uint i=starting; i<count; i++) {
                Bet memory betObject = bets[_user][i];
                (uint amount, bool finalized, ,) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

                if (!finalized) {
                    uint winnings = GameInterface(betObject.game).getUserProfitForFinishedBet(_user, betObject.betId);

                    if(winnings > 0) {
                        balance = balance + amount + winnings;
                    }
                }
            }
        }

        return balance;
    }

     
    function getCommission(uint _amount) public view returns(uint) {
        uint commission = settings.HOUSE_EDGE().mul(2);

        
        return commission < 100000 ? (_amount).mul(commission).div(100000) : _amount;
    }

     
    function getPossibleWinnings(uint _amount) public view returns(uint) {
        uint commission = settings.HOUSE_EDGE().mul(2);
         
        return commission < 100000 ? _amount.mul(100000-commission).div(100000) : 0;
    }

    function getExtraTokenWinChanceForPlayer(address _user) public view returns (uint){
        return settings.tokenWinChanceRewardForLevel(playerLevel[_user]);
    }

    function needToUpdateBetsForUser(address _user) public view returns(bool) {
        Bet memory betObject = bets[_user][firstUnfinalizedBet[_user]];
        (, bool finalized, ,) = GameInterface(betObject.game).getBetInfo(_user, betObject.betId);

        return (!finalized);
    }

    function updatePlayerLevelIfNeeded(address _user) public {
        uint currentPlayerLevel = playerLevel[_user];

        while(currentPlayerLevel < amountRequiredForLevel.length - 1 && totalWinningsForPlayer[_user] >= amountRequiredForLevel[currentPlayerLevel+1]) {
            currentPlayerLevel++;

             
            _addBonus(_user, settings.bonusBalanceRewardForLevel(currentPlayerLevel));
        }

        playerLevel[_user] = currentPlayerLevel;
    }

    function sendEthToGame(uint _amount) public onlyGames {
        totalFundsSpentOnOraclize += _amount;
        msg.sender.transfer(_amount);
    }


    function emergencyShutdown(address payable[] memory _addresses, bool transferToOperator) public onlyOperators {
        for (uint i=0; i<_addresses.length; i++) {
            _finalizeLastBets(_addresses[i]);
            _addresses[i].transfer(userBalances[_addresses[i]]);
        }

        if(transferToOperator) {
            msg.sender.transfer(address(this).balance);

            address[] memory games = settings.getGames();

            for(uint i = 0; i < games.length; i++) {
                if(games[i] != address(this)) {
                    GameInterface(games[i]).emergencyWithdraw(msg.sender);
                }
            }
        }
    }

    function setTotalFundsTransferredToDepositPool(uint _value) public {
        require(msg.sender == distributorAddress);

        totalFundsTransferredToDepositPool = _value;
    }

     
    function getTotalBets(address _user) public view returns(uint) {
        return bets[_user].length;
    }

    function getUsers() public view returns(address[] memory) {
        return users;
    }

     
    function() external payable {
        require(totalFundsTransferredToDepositPool == 0);

        totalFundsSentByOwner += msg.value;
    }
}