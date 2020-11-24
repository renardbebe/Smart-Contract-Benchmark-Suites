 

pragma solidity ^0.4.21;
 

 
 

 

pragma solidity >=0.4.18; 

contract OraclizeI {
    address public cbAddress;

    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);

    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);

    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);

    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);

    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);

    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);

    function getPrice(string _datasource) public returns (uint _dsprice);

    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);

    function setProofType(byte _proofType) external;

    function setCustomGasPrice(uint _gasPrice) external;

    function randomDS_getSessionPubKeyHash() external constant returns (bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}

 

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) capacity += 32 - (capacity % 32);
         
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns (uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

     
    function append(buffer memory buf, bytes data) internal pure returns (buffer memory) {
        if (data.length + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, data.length) * 2);
        }

        uint dest;
        uint src;
        uint len = data.length;
        assembly {
         
            let bufptr := mload(buf)
         
            let buflen := mload(bufptr)
         
            dest := add(add(bufptr, buflen), 32)
         
            mstore(bufptr, add(buflen, mload(data)))
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

     
    function append(buffer memory buf, uint8 data) internal pure {
        if (buf.buf.length + 1 > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
         
            let bufptr := mload(buf)
         
            let buflen := mload(bufptr)
         
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, data)
         
            mstore(bufptr, add(buflen, 1))
        }
    }

     
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns (buffer memory) {
        if (len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
         
            let bufptr := mload(buf)
         
            let buflen := mload(bufptr)
         
            let dest := add(add(bufptr, buflen), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
         
            mstore(bufptr, add(buflen, len))
        }
        return buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if (value <= 23) {
            buf.append(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.append(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.append(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.append(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if (value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.append(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if (value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(- 1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

 

contract usingOraclize {
    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Android = 0x40;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if ((address(OAR) == 0) || (getCodeSize(address(OAR)) == 0))
            oraclize_setNetwork(networkID_auto);

        if (address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns (bool){
        return oraclize_setNetwork();
        networkID;
         
    }

    function oraclize_setNetwork() internal returns (bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { 
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { 
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { 
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { 
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { 
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { 
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { 
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }

    function __callback(bytes32 myid, string result, bytes proof) public {
        return;
        myid;
        result;
        proof;
         
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        return oraclize.query.value(price)(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }

    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }

    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }

    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }

    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice * 200000) return 0;
         
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0;
         
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }

    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }

    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }

    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i + 1]);
            if ((b1 >= 97) && (b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65) && (b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48) && (b1 <= 57)) b1 -= 48;
            if ((b2 >= 97) && (b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65) && (b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48) && (b2 <= 57)) b2 -= 48;
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return - 1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return - 1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length))
            return - 1;
        else if (h.length > (2 ** 128 - 1))
            return - 1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while (subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if (subindex == n.length)
                        return int(i);
                }
            }
            return - 1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10 ** _b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    using CBOR for Buffer.buffer;
    function stra2cbor(string[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeString(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeBytes(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    string oraclize_network_name;

    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
         
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
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

        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32 => bytes32) oraclize_randomDS_args;
    mapping(bytes32 => bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset + (uint(dersig[offset - 1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

         
        bytes memory sig2 = new bytes(uint(proof[sig2offset + 1]) + 2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3 + 1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(1);
         
        copyBytes(proof, sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


         
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3 + 65 + 1]) + 2);
        copyBytes(proof, 3 + 65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
         
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
         
        if ((_proof[0] != "L") || (_proof[1] != "P") || (_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;

        require(prefix.length == n_random_bytes);

        for (uint256 i = 0; i < n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

         
        uint ledgerProofLength = 3 + 65 + (uint(proof[3 + 65 + 1]) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1]) + 2);
        copyBytes(proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);

         
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength + 32 + 8]))) return false;

         
         
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(proof, sig2offset - 64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)) { 
            delete oraclize_randomDS_args[queryId];
        } else return false;


         
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

         
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false) {
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

     
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

         
        require(to.length >= minLength);
         

         
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

     
     
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
         
         
         
         
         

         
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

         
         
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

     
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
            return (false, 0);

         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

         
         
         
            v := byte(0, mload(add(sig, 96)))

         
         
         
         
        }

         
         
         
         
         
        if (v < 27)
            v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }

}
 


 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

library SafeMath16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
         
        uint16 c = a / b;
         
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     

    function _transfer(address _to, uint _value) internal {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

     

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(_to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}

contract MintableToken is BasicToken, StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;


    function mint(address _to, uint256 _amount) internal returns (bool) {
        require(!mintingFinished);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

     
    function finishMinting() internal returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}

 
contract BurnableToken is MintableToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract HeliumToken is BurnableToken {

    string public constant name = "HeliumToken";
    string public constant symbol = "HLT";
    uint8 public constant decimals = 18;

    uint256 public INITIAL_SUPPLY = 0;

}

contract Balloons3D is HeliumToken, usingOraclize {

    using SafeMath for uint256;
    using SafeMath16 for uint16;

    address[] public users;
    address[] public winners;
    uint16[] public balloons;

    uint16 public step;
    uint16 public initialNumberOfBalloons;
    uint16 public totalBalloons;
    uint16 public sold;
    uint16 public min;
    uint16 public max;
    uint16 public winnerDetectionTime;

    uint public feeForTeam;
    uint public feeForReferral;
    uint public refCount;
    uint public withdrawnFromReferrals;
    uint public price;
    uint public nextPrice;
    uint public pot;
    uint public attempts;
    uint public safeGasLimit;
    uint public safeGasPrice;
    uint public gasOraclize;
    uint public gasPriceOraclize;
    uint N;
    uint delay;

    address public beneficiary;

    bool public gameIsOver;
    bool public canPlay;
    bool public canRevealWinner;
    bool public oracleFailed;

    struct UserStruct {
        uint16 numberOfExploded;
        uint balance;
        uint index;
    }

    mapping(uint16 => address) private ownerOfBalloon;
    mapping(address => uint16) private numberOfBalloons;
    mapping(address => UserStruct) userStructs;
    mapping(address => uint) private totalWinnings;
    mapping(address => uint) private ethReferrals;
    mapping(uint => mapping(uint => bool)) private participatedIDs;
    mapping(uint => mapping(uint => mapping(uint => bool))) private returnedBalloons;
    mapping(uint => mapping(uint => bool)) expiredIds;
    mapping(uint => uint) private idTrack;

    event OnNewUser(address indexed _address, uint _index);
    event OnPurchaseBalloon(address indexed _buyer, address _referredBy, uint16 _id);
    event OnWithdrawRefEth(address _to, uint _value);
    event OnRevealWinner(address _winner, uint _amount, uint16 _min, uint16 _max, uint16 _data, uint16 _id);
    event OnGeneratingRandomNum(string _text);
    event OnRandomNumberGenerated(uint _data, uint _randomNumber);
    event OnReturned(address indexed _address, uint16 _id);
    event OnReturnFailed(address indexed _address, uint16 _id);
    event OnPriceChanged(uint _oldPrice, uint _newPrice);
    event OnGasLimitChanged(uint _oldGasLimit, uint _newGasLimit);
    event OnGasPriceChanged(uint _oldGasPrice, uint _newGasPrice);

    modifier onlyOraclize() {
        require(msg.sender == oraclize_cbAddress());
        _;
    }

    constructor() public {
        totalBalloons = 10000;
        price = 30000000000000000;
        nextPrice = price;
        beneficiary = 0xbDcBD634DA96782a1566061f5ceaE5c436681A07;
        initialNumberOfBalloons = totalBalloons;
        feeForReferral = price.mul(45).div(100);
        refCount = 0;
        step = 20;
        winnerDetectionTime = step;
        attempts = 0;
        canPlay = true;
        gameIsOver = false;
        canRevealWinner = false;
        oracleFailed = false;
        N = 4;
        delay = 0;
        safeGasLimit = 200000;
        safeGasPrice = 20000000000 wei;
        gasOraclize = safeGasLimit.add(100000);
        gasPriceOraclize = safeGasPrice;
        oraclize_setCustomGasPrice(gasPriceOraclize);
    }

    function() public payable {
        _buyBalloon(msg.sender, msg.value, msg.sender);
    }

    function buyBalloon(address _referredBy) public payable {
        _buyBalloon(msg.sender, msg.value, _referredBy);
    }

    function _buyBalloon(address _sender, uint _value, address _referredBy) internal {
        require(!gameIsOver);
        require(canPlay);
        require(_value == price);
        require(totalBalloons > 0);
        numberOfBalloons[_sender] = numberOfBalloons[_sender].add(1);
        userStructs[_sender].balance = userStructs[_sender].balance.add(_value);
        uint16 balloonId = sold;
        balloons.push(balloonId);
        ownerOfBalloon[balloonId] = _sender;
        sold = sold.add(1);
        totalBalloons = totalBalloons .sub(1);
        idTrack[balloonId] = price;
        if (!existUser(_sender)) {
            userStructs[_sender].index = users.push(_sender).sub(1);
            emit OnNewUser(_sender, userStructs[_sender].index);
        }

        if (_referredBy != address(0) && _referredBy != msg.sender) {
            if (feeForReferral != price.mul(45).div(100)) {
                feeForReferral = price.mul(45).div(100);
            }
            mint(_referredBy, feeForReferral);
            refCount = refCount.add(1);
        }

        if (sold == winnerDetectionTime) {
            min = uint16(balloons.length.sub(step));
            max = uint16(balloons.length);
            canRevealWinner = true;
            winnerDetectionTime = winnerDetectionTime.add(step);
            attempts = attempts.add(1);
            pot = price.mul(step);
            feeForTeam = pot.mul(5).div(100);
            if (price != nextPrice) {
                canPlay = false;
                price = nextPrice;
                emit OnPriceChanged(price, nextPrice);
            }
            pingOracle();
        }

        if (totalBalloons == 0) {
            finishMinting();
            gameIsOver = true;
        }
        emit OnPurchaseBalloon(_sender, _referredBy, balloonId);
    }

    function withdraw() public {
        require(balanceOf(msg.sender) > 0, "Sorry, you don't have enough HeliumToken");
        uint award = balanceOf(msg.sender);
        withdrawnFromReferrals = withdrawnFromReferrals.add(award);
        ethReferrals[msg.sender] = ethReferrals[msg.sender].add(award);
        msg.sender.transfer(award);
        burn(balanceOf(msg.sender));
        emit OnWithdrawRefEth(msg.sender, award);
    }

    function revealWinner(uint16 _balloonIndex, uint _attempts, uint16 _data, uint16 _min, uint16 _max) internal {
        require(_balloonIndex < max && _balloonIndex >= min);
        uint feeForRefs = feeForReferral.mul(refCount);
        uint amountForTeam = feeForTeam.sub(_attempts.mul(gasOraclize.mul(gasPriceOraclize)));
        uint amount = pot.sub(feeForRefs).sub(amountForTeam).sub(_attempts.mul(gasOraclize.mul(gasPriceOraclize)));
        uint index = winners.push(ownerOfBalloon[_balloonIndex]).sub(1);

        ownerOfBalloon[_balloonIndex].transfer(amount);
        beneficiary.transfer(amountForTeam);
        totalWinnings[winners[index]] = totalWinnings[winners[index]].add(amount);
        participatedIDs[_min][_max] = true;
        expiredIds[_min][_max] = true;
        refCount = 0;
        if (!canPlay) {
            canPlay = true;
        }

        emit OnRevealWinner(ownerOfBalloon[_balloonIndex], amount, _min, _max, _data, _balloonIndex);
    }

    function __callback(bytes32 _queryId, string _result, bytes _proof) public onlyOraclize {
        require(canRevealWinner);
        require(!expiredIds[min][max]);
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            oracleFailed = true;
        } else {
            uint16 data = uint16(keccak256(abi.encodePacked(_result)));
            uint16 randomNumber = (data % (max.sub(min))).add(min);
            revealWinner(randomNumber, attempts, data, min, max);
            oracleFailed = false;
            canRevealWinner = false;
            attempts = 0;

            emit OnRandomNumberGenerated(data, randomNumber);
        }

        if (oracleFailed && canRevealWinner) {
            attempts = attempts.add(1);
            pingOracle();
        }
    }

    function pingOracle() private {
        oraclize_setProof(proofType_Ledger);
         
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, gasOraclize);
         
        emit OnGeneratingRandomNum("Oraclize was sent for generate random number");
    }

    function setPrice(uint _newPrice) public onlyOwner {
        require(price != _newPrice);
        nextPrice = _newPrice;
    }

    function setOraclizeGasLimit(uint _newGasLimit) public onlyOwner {
        require(gasOraclize >= safeGasLimit);
        uint oldGasLimit = gasOraclize;
        gasOraclize = _newGasLimit;
        emit OnGasLimitChanged(oldGasLimit, _newGasLimit);
    }

    function setOraclizeGasPrice(uint _newGasPrice) public onlyOwner {
        require(_newGasPrice >= safeGasPrice);
        uint oldGasPrice = gasPriceOraclize;
        gasPriceOraclize = _newGasPrice;
        oraclize_setCustomGasPrice(_newGasPrice);
        emit OnGasPriceChanged(oldGasPrice, _newGasPrice);
    }

    function changeStatusGame() public onlyOwner {
        require(!canPlay);
        canPlay = true;
    }

    function refundPendingId(uint16 _id) public {
        require(!participatedID(_id));
        require(_id < getMaxOfId(_id));
        require(getMaxOfId(_id).add(step) < sold);
        require(_id <= sold);
        require(ownerOfBalloon[_id] == msg.sender);
        require(!returnedBalloons[getMinOfId(_id)][getMaxOfId(_id)][_id]);
        if (ownerOfBalloon[_id].send(idTrack[_id])) {
            returnedBalloons[getMinOfId(_id)][getMaxOfId(_id)][_id] = true;
            if (!expiredIds[getMinOfId(_id)][getMaxOfId(_id)]) {
                expiredIds[getMinOfId(_id)][getMaxOfId(_id)] = true;
            }
            emit OnReturned(ownerOfBalloon[_id], _id);
        } else {
            emit OnReturnFailed(ownerOfBalloon[_id], _id);
        }
    }

    function canRefund(uint16 _id) public view returns (bool) {
        return (!participatedID(_id) && getMaxOfId(_id).add(step) < sold && !returnedBalloons[getMinOfId(_id)][getMaxOfId(_id)][_id]);
    }

    function participatedID(uint16 _id) public view returns (bool) {
        uint _min;
        uint _max;
        if (_id < step) {
            _min = 0;
            _max = step;
        }
        else {
            uint16 lastDigit = _id % 10;
            _min = differenceOfId(_id.sub(lastDigit));
            _max = _min + step;
        }

        return participatedIDs[_min][_max];
    }

    function getMinOfId(uint16 _id) public view returns (uint16) {
        uint16 _min;
        if (_id < step) {
            _min = 0;
        } else {
            uint16 lastDigit = _id % 10;
            _min = differenceOfId(_id.sub(lastDigit));
        }
        return _min;
    }

    function getMaxOfId(uint16 _id) public view returns (uint16) {
        uint16 _max;
        if (_id < step) {
            _max = 20;
        } else {
            _max = getMinOfId(_id).add(step);
        }
        return _max;
    }

    function differenceOfId(uint16 _id) internal view returns (uint16) {
        uint16 minNumber;
        if (_id % step == 0) {
            minNumber = _id;
        } else {
            minNumber = _id.sub(10);
        }
        return minNumber;
    }

    function balloonOwner(uint16 _index) public view returns (address) {
        return ownerOfBalloon[_index];
    }

    function existUser(address _address) public view returns (bool) {
        if (users.length == 0) return false;
        return (users[userStructs[_address].index] == _address);
    }

    function countOfBalloons(address _address) public view returns (uint16) {
        return numberOfBalloons[_address];
    }

    function currentFund() public view returns (uint) {
        return address(this).balance;
    }

    function winnersFund() public view returns (uint) {
        return currentFund().sub(totalSupply_);
    }

    function refPayment() public view returns (uint) {
        return balanceOf(msg.sender).mul(feeForReferral);
    }

    function usersList() public view returns (address[]) {
        return users;
    }

    function balloonsList() public view returns (uint16[]) {
        return balloons;
    }

    function winnersList() public view returns (address[]) {
        return winners;
    }

    function ethRefs(address _address) public view returns (uint) {
        return ethReferrals[_address];
    }

    function getTotalWinnings(address _address) public view returns (uint) {
        return totalWinnings[_address];
    }

}