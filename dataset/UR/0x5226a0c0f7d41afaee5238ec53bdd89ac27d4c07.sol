 

 

pragma solidity 0.4.25;

 
     
     

     

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
        function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
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
            if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
             
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

        function max(uint a, uint b) private pure returns(uint) {
            if(a > b) {
                return a;
            }
            return b;
        }

         
        function append(buffer memory buf, bytes data) internal pure returns(buffer memory) {
            if(data.length + buf.buf.length > buf.capacity) {
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

            return buf;
        }

         
        function append(buffer memory buf, uint8 data) internal pure {
            if(buf.buf.length + 1 > buf.capacity) {
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

         
        function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
            if(len + buf.buf.length > buf.capacity) {
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
            if(value <= 23) {
                buf.append(uint8((major << 5) | value));
            } else if(value <= 0xFF) {
                buf.append(uint8((major << 5) | 24));
                buf.appendInt(value, 1);
            } else if(value <= 0xFFFF) {
                buf.append(uint8((major << 5) | 25));
                buf.appendInt(value, 2);
            } else if(value <= 0xFFFFFFFF) {
                buf.append(uint8((major << 5) | 26));
                buf.appendInt(value, 4);
            } else if(value <= 0xFFFFFFFFFFFFFFFF) {
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
            if(value >= 0) {
                encodeType(buf, MAJOR_TYPE_INT, uint(value));
            } else {
                encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
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
        uint constant day = 60*60*24;
        uint constant week = 60*60*24*7;
        uint constant month = 60*60*24*30;
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
            if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
                oraclize_setNetwork(networkID_auto);

            if(address(oraclize) != OAR.getAddress())
                oraclize = OraclizeI(OAR.getAddress());

            _;
        }
        modifier coupon(string code){
            oraclize = OraclizeI(OAR.getAddress());
            _;
        }

        function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        return oraclize_setNetwork();
        networkID;  
        }
        function oraclize_setNetwork() internal returns(bool){
            if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
                OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
                oraclize_setNetworkName("eth_mainnet");
                return true;
            }
            if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
                OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
                oraclize_setNetworkName("eth_ropsten3");
                return true;
            }
            if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
                OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
                oraclize_setNetworkName("eth_kovan");
                return true;
            }
            if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
                OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
                oraclize_setNetworkName("eth_rinkeby");
                return true;
            }
            if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
                OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
                return true;
            }
            if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
                OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
                return true;
            }
            if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
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
         
         
         
        myid; result; proof;  
        oraclize = OraclizeI(0);  
        }

        function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
            return oraclize.getPrice(datasource);
        }

        function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
            return oraclize.getPrice(datasource, gaslimit);
        }

        function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            return oraclize.query.value(price)(0, datasource, arg);
        }
        function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            return oraclize.query.value(price)(timestamp, datasource, arg);
        }
        function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
        }
        function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
        }
        function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            return oraclize.query2.value(price)(0, datasource, arg1, arg2);
        }
        function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
        }
        function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
        }
        function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
        }
        function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            bytes memory args = stra2cbor(argN);
            return oraclize.queryN.value(price)(0, datasource, args);
        }
        function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            bytes memory args = stra2cbor(argN);
            return oraclize.queryN.value(price)(timestamp, datasource, args);
        }
        function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            bytes memory args = stra2cbor(argN);
            return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
        }
        function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
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
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            bytes memory args = ba2cbor(argN);
            return oraclize.queryN.value(price)(0, datasource, args);
        }
        function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource);
            if (price > 1 ether + tx.gasprice*200000) return 0;  
            bytes memory args = ba2cbor(argN);
            return oraclize.queryN.value(price)(timestamp, datasource, args);
        }
        function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
            bytes memory args = ba2cbor(argN);
            return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
        }
        function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
            uint price = oraclize.getPrice(datasource, gaslimit);
            if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
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

        function getCodeSize(address _addr) view internal returns(uint _size) {
            assembly {
                _size := extcodesize(_addr)
            }
        }

        function parseAddr(string _a) internal pure returns (address){
            bytes memory tmp = bytes(_a);
            uint160 iaddr = 0;
            uint160 b1;
            uint160 b2;
            for (uint i=2; i<2+2*20; i+=2){
                iaddr *= 256;
                b1 = uint160(tmp[i]);
                b2 = uint160(tmp[i+1]);
                if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
                else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
                else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
                if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
                else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
                else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
                iaddr += (b1*16+b2);
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
                    return -1;
                else if (a[i] > b[i])
                    return 1;
            if (a.length < b.length)
                return -1;
            else if (a.length > b.length)
                return 1;
            else
                return 0;
        }

        function indexOf(string _haystack, string _needle) internal pure returns (int) {
            bytes memory h = bytes(_haystack);
            bytes memory n = bytes(_needle);
            if(h.length < 1 || n.length < 1 || (n.length > h.length))
                return -1;
            else if(h.length > (2**128 -1))
                return -1;
            else
            {
                uint subindex = 0;
                for (uint i = 0; i < h.length; i ++)
                {
                    if (h[i] == n[0])
                    {
                        subindex = 1;
                        while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                        {
                            subindex++;
                        }
                        if(subindex == n.length)
                            return int(i);
                    }
                }
                return -1;
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
            for (uint i=0; i<bresult.length; i++){
                if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                    if (decimals){
                    if (_b == 0) break;
                        else _b--;
                    }
                    mint *= 10;
                    mint += uint(bresult[i]) - 48;
                } else if (bresult[i] == 46) decimals = true;
            }
            if (_b > 0) mint *= 10**_b;
            return mint;
        }

        function uint2str(uint i) internal pure returns (string){
            if (i == 0) return "0";
            uint j = i;
            uint len;
            while (j != 0){
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (i != 0){
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

            oraclize_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
            return queryId;
        }

        function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
            oraclize_randomDS_args[queryId] = commitment;
        }

        mapping(bytes32=>bytes32) oraclize_randomDS_args;
        mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

        function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
            bool sigok;
            address signer;

            bytes32 sigr;
            bytes32 sigs;

            bytes memory sigr_ = new bytes(32);
            uint offset = 4+(uint(dersig[3]) - 0x20);
            sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
            bytes memory sigs_ = new bytes(32);
            offset += 32 + 2;
            sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

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

             
            bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
            copyBytes(proof, sig2offset, sig2.length, sig2, 0);

            bytes memory appkey1_pubkey = new bytes(64);
            copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

            bytes memory tosign2 = new bytes(1+65+32);
            tosign2[0] = byte(1);  
            copyBytes(proof, sig2offset-65, 65, tosign2, 1);
            bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
            copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
            sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

            if (sigok == false) return false;


             
            bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

            bytes memory tosign3 = new bytes(1+65);
            tosign3[0] = 0xFE;
            copyBytes(proof, 3, 65, tosign3, 1);

            bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
            copyBytes(proof, 3+65, sig3.length, sig3, 0);

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
             
            if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

            bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
            if (proofVerified == false) return 2;

            return 0;
        }

        function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
            bool match_ = true;

            require(prefix.length == n_random_bytes);

            for (uint256 i=0; i< n_random_bytes; i++) {
                if (content[i] != prefix[i]) match_ = false;
            }

            return match_;
        }

        function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

             
            uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
            bytes memory keyhash = new bytes(32);
            copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
            if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(context_name, queryId)))))) return false;

            bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
            copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

             
            if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

             
             
            bytes memory commitmentSlice1 = new bytes(8+1+32);
            copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

            bytes memory sessionPubkey = new bytes(64);
            uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
            copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

            bytes32 sessionPubkeyHash = sha256(sessionPubkey);
            if (oraclize_randomDS_args[queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))){  
                delete oraclize_randomDS_args[queryId];
            } else return false;


             
            bytes memory tosign1 = new bytes(32+8+1+32);
            copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
            if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

             
            if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Access denied");
        _;
    }

    function isOwner() public view returns(bool) {
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
        require(newOwner != address(0), "Zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract CryptoBets is Ownable, usingOraclize {
    struct Room {
        address author;
        uint bet;
        uint max_players;
        string pass;
        bool run;
        bool closed;
        address[] players;
    }

    uint public min_bet = 0.1 ether;
    uint public max_bet = 3 ether;
    uint public min_players = 2;
    uint public max_players = 10;
    uint[] public ref_payouts = [3, 2, 1];
    uint public jackpot_max_players = 100;
    uint public jackpot_bank = 0;
    uint public commision = 0;
    uint public oraclize_gas_limit = 250000;

    Room[] public rooms;
    mapping(bytes32 => uint) public games;
    mapping(address => address) public refferals;
    address[] public jackpot_players;

    mapping(address => bool) public managers;
    mapping(address => uint) public withdraws;

    event NewRoom(uint indexed room_id, address indexed author, uint bet, uint max_players, string pass);
    event NewBet(uint indexed room_id, address indexed addr);
    event Run(uint indexed room_id, bytes32 indexed id);
    event FinishRoom(uint indexed room_id, address indexed winner);
    event Withdraw(address indexed to, uint value);
    
    modifier onlyManager() {
        require(managers[msg.sender], "Access denied");
        _;
    }

    constructor() payable public {
         
        managers[0x909bf2E71fe8f8cEDb8D55E1818E152b003c5612] = true;
        managers[0xB224A65FA9a76d6cc0f3c96A181894Be342fcB63] = true;
        managers[0x5BC1987a3f4E43650b2E3FbE7C404c4C5ffF1531] = true;
        managers[0xF20175D17Be5d6b215b6063EAaAc158969064ee8] = true;
        managers[0xA745ac0BB1F88EeCF9EC0Db369Ed29F07CD42966] = true;
        managers[0xdc0B815316383BA4d087a2dBB9268CB5346b88aa] = true;
        managers[0x2431CfCDEa6abc4112EA67a41910D986D7475ac5] = true;
        managers[0x756F9B5DAd8d119fA7442FB636Db7f3bDF5435eF] = true;
        managers[0xecC78D8DA24F9625F615374279F0627c97da9379] = true;
        managers[0xcBE575FFa93d7D9eE1CC7aACC72a5C93FD1e08c3] = true;
    }
    
    function() payable external {}

    function __callback(bytes32 id, string res) public {
        require(msg.sender == oraclize_cbAddress(), "Permission denied");

        Room storage room = rooms[games[id]];
        
        require(room.author != address(0), "Room not found");
        require(!room.closed, "Room already closed");

        uint result = parseInt(res);
        uint win = room.bet * room.players.length;
        uint comm = 14;
        uint oc = oraclize_getPrice("URL");

        jackpot_bank += win / 100;

        address ref = refferals[room.players[result]];
        if(ref != room.players[result]) {
            for(uint i = 0; i < ref_payouts.length; i++) {
                if(ref != address(0)) {
                    uint p = win * ref_payouts[i] / 100;

                    comm -= ref_payouts[i];

                    ref.transfer(p);
                    ref = refferals[ref];
                }
                else break;
            }
        }

        room.players[result].transfer(win - (win * 15 / 100));

        if(win * comm / 100 > oc) {
            commision += (win * comm / 100) - oc;
        }

        emit FinishRoom(games[id], room.players[result]);

        room.closed = true;

        delete games[id];

        if(jackpot_players.length >= jackpot_max_players) {
            uint jp_winner = (uint(blockhash(block.number - 1)) + result) % jackpot_players.length;

            if(jackpot_players[jp_winner] != address(0)) {
                jackpot_players[jp_winner].transfer(jackpot_bank);

                jackpot_bank = 0;
                jackpot_players.length = 0;
            }
        }
    }

    function createRoom(uint players, string pass, address refferal) payable external {
        require(msg.value >= min_bet && msg.value <= max_bet, "Bet does not match the interval");
        require(players >= min_players && players <= max_players, "Players does not match the interval");

        address[] memory pls;

        rooms.push(Room({
            author: msg.sender,
            bet: msg.value,
            max_players: players,
            pass: pass,
            run: false,
            closed: false,
            players: pls
        }));

        emit NewRoom(rooms.length - 1, msg.sender, msg.value, players, pass);

        _joinRoom(msg.value, msg.sender, rooms.length - 1, pass, refferal);
    }

    function _joinRoom(uint value, address to, uint room_id, string pass, address refferal) private {
        require(rooms[room_id].author != address(0), "Room not found");
        require(!rooms[room_id].closed, "Room already closed");
        require(value == rooms[room_id].bet, "Insufficient funds");
        require(strCompare(pass, rooms[room_id].pass) == 0, "Invalid password");
        require(rooms[room_id].max_players > rooms[room_id].players.length, "Room is full");

        rooms[room_id].players.push(msg.sender);
        jackpot_players.push(msg.sender);

        if(refferals[msg.sender] == address(0)) {
            refferals[msg.sender] = refferal != address(0) ? refferal : msg.sender;
        }

        emit NewBet(room_id, to);

        if(rooms[room_id].max_players == rooms[room_id].players.length) {
            _play(room_id);
        }
    }

    function joinRoom(uint room_id, string pass, address refferal) payable external {
        _joinRoom(msg.value, msg.sender, room_id, pass, refferal);
    }

    function _play(uint room_id) private {
        require(rooms[room_id].author != address(0), "Room not found");
        require(!rooms[room_id].closed, "Room already closed");
        require(rooms[room_id].max_players == rooms[room_id].players.length, "Room is empty");
        require(oraclize_getPrice("URL") <= address(this).balance, "Insufficient funds");
        
        bytes32 id = oraclize_query("WolframAlpha", strConcat("RandomInteger[{0, ", uint2str(rooms[room_id].players.length - 1), "}]"), oraclize_gas_limit);
        
        rooms[room_id].run = true;
        games[id] = room_id;

        emit Run(room_id, id);
    }

    function play(uint room_id) onlyManager external {
        _play(room_id);
    }
    
    function withdraw() onlyManager external {
        uint s = commision / 10;
        uint b = withdraws[msg.sender] < s ? s - withdraws[msg.sender] : 0;

        require(b > 0 && address(this).balance >= b, "Insufficient funds");

        withdraws[msg.sender] += b;

        msg.sender.transfer(b);

        emit Withdraw(msg.sender, b);
    }

    function setJackpotMaxPlayers(uint value) onlyOwner external {
        jackpot_max_players = value;
    }

    function setOraclizeGasLimit(uint value) onlyOwner external {
        oraclize_gas_limit = value;
    }

    function setOraclizeGasPrice(uint value) onlyOwner external {
        oraclize_setCustomGasPrice(value);
    }
}