 

pragma solidity^0.4.24;

 

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DSA {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetOrcl (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSA  public  a;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setOrcl(DSA a_)
        public
        auth
    {
        a = a_;
        emit LogSetOrcl(a);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (a == DSA(0)) {
            return false;
        } else {
            return a.canCall(src, this, sig);
        }
    }
}

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

 

contract usingOraclize is DSAuth {
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
        
        return false;
    }

    function oraclize_cbAddress() internal oraclizeAPI returns (address){
        return oraclize.cbAddress();
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    
    function __callback(bytes32 myid, string result, bytes proof) public;

    function oraclize_getPrice(string datasource) internal oraclizeAPI returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) internal oraclizeAPI returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) internal oraclizeAPI returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) internal oraclizeAPI returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_setProof(byte proofP) internal oraclizeAPI {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) internal oraclizeAPI {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() internal oraclizeAPI returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    using CBOR for Buffer.buffer;

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

     
    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32) {
        require((_nbytes > 0) && (_nbytes <= 32), "Requested bytes out of range!");
         
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(caller, callvalue)))
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

     
    function oraclize_newRandomDSQuery(uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32), "Requested bytes out of range!");
         
        
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
             
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(caller, callvalue)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);

        bytes memory delay_bytes8_left = new bytes(8);

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
 

contract UsingOraclizeRandom is usingOraclize {
    uint public oraclizeCallbackGas = 200000;
    uint public oraclizeGasPrice = 20000000000;  

    constructor() public {
        a = DSA(0xdbf98a75f521Cb1BD421c03F2b6A6a617f4240F1);
    }

     

     

     

    function setOraclizeGasLimit(uint _newLimit) public auth {
        oraclizeCallbackGas = _newLimit;
    }

    function setOraclizeGasPrice(uint _newGasPrice) public auth {
        oraclizeGasPrice = _newGasPrice;
        oraclize_setCustomGasPrice(_newGasPrice);
    }

}

interface MobiusToken {
    function disburseDividends() external payable;
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

contract MobiusRandom is UsingOraclizeRandom, DSMath {
    
     
    uint24 constant public SECONDAY_MODULO = 1000000; 
    uint16 constant public MAX_UNDER2 = 150;
    uint constant public BET_EXPIRY = 6 hours;
    uint constant public HOUSE_EDGE_DIVISOR = 70;  
    uint constant public HOUSE_EDGE_DIVISOR_CLASSIC = 125; 
    uint constant public SECONDARY_JACKPOT_DIVISOR = 400; 
    uint constant public UNLUCK_RATE = 1 * WAD / 6 hours;    
    MobiusToken constant public TOKEN = MobiusToken(0x54cdC9D889c28f55F59f6b136822868c7d4726fC);
    
     
    uint public pendingBets;
    uint public secondaryPot;

     
    uint public minHouse = 0.4 finney;
    uint public minHouseClassic = 1.5 finney;
    uint public minSecondaryAmount = 100 finney;
    uint public maxProfit = 2 ether;
    uint public luckPrice = 10 * WAD;    

     
    uint public dividendsPaid;

    struct Bet {
        uint props;
        address player;
    }

    mapping(bytes32 => Bet) public bets;
    mapping(address => uint) public luck;

    event BetPlaced(bytes32 queryId, address indexed player, uint props);
    event BetFinalized(bytes32 queryId, address indexed player, uint props, uint amountToSend);
    event SecondaryJackpotWon(bytes32 queryId, address indexed player, uint amount);
    event FailedPayment(bytes32 queryId, uint amount);
    event RefundAttempt(bytes32 queryId);
    event RandomFailed(bytes32 queryId);

    constructor() public {
        
    }

    function () public payable {
         
    }

    function placeBet(uint16 modulo, uint16 rollUnder, bool classic) external payable {
        bytes32 queryId = oraclize_newRandomDSQuery(32, oraclizeCallbackGas);
        address player = msg.sender;
        uint128 amount = uint128(msg.value);
        uint props;
         
         
        require(_getBetAmount(queryId) == 0, "Invalid query ID!");
        
         
        Bet storage newBet = bets[queryId];
        newBet.player = player;
        props = amount;
        props = props << 64;
         
        props |= uint64(now);        
        props = props << 16;
        props |= modulo;
        props = props << 16;
        props |= rollUnder;
        props = props << 16; 

        uint win;
        uint jackpotFee;
        (win,jackpotFee) = _winAmount(amount, modulo, rollUnder, classic);
        require(win <= amount + maxProfit, "Potential profit exceeds maximum!");

        if(!classic) {
            if(amount >= minSecondaryAmount) {
                uint lucky = getLuck(player);
                props |= uint16(min(MAX_UNDER2, 1 + (lucky * 25) / WAD));
                secondaryPot += jackpotFee;
            }
             
             
            _addLuck(player, amount);
        }
        props = props << 16;
        props |= uint16(classic ? 1 : 0);
        newBet.props = props;

        pendingBets += win;

        require(secondaryPot + pendingBets <= address(this).balance, "Can't cover bet!");
        emit BetPlaced(queryId, player, props);
    }

    function topUpLuck(uint level) external {
        address player = msg.sender;
        require(level <= 4 * WAD, "Can't top up more than 4 levels!");
        require(TOKEN.transferFrom(player, address(this), wmul(level, luckPrice)), "Token transfer failed!");
        _addLuck(player, level);
    }

    function refundExpiredBet(bytes32 queryId) external {

        require(_getBetTimestamp(queryId) + BET_EXPIRY < now, "Bet not expired!");
        require(_getBetAmount(queryId) > 0, "Bet invalid!");

        _processRefund(queryId);
    }

     

    function initOraclize() external auth {
        oraclizeCallbackGas = 200000;
        if(oraclize_setNetwork()){
            oraclize_setProof(proofType_Ledger);
        }
    }

    function setMinHouse(uint newValue) external auth {
        minHouse = newValue;
    }
    
    function setMinHouseClassic(uint newValue) external auth {
        minHouseClassic = newValue;
    }

    function setMinSecondaryAmount(uint newValue) external auth {
        minSecondaryAmount = newValue;
    }

    function setLuckPrice(uint newValue) external auth {
        luckPrice = newValue;
    }

    function setMaxProfit(uint newValue) external auth {
        maxProfit = newValue;
    }

    function destroy() external auth {
         
         
        require (pendingBets < 100 finney, "There are pending bets!");
        selfdestruct(msg.sender);
    }

    function feedSecondaryPot(uint amount) external auth {
        require (amount <= address(this).balance, "Nonsense amount!");
        require (secondaryPot + pendingBets + amount <= address(this).balance, "Can't use what you don't own!");
        secondaryPot += amount;
    }

    function withdraw(uint amount) external auth {
        require (amount <= address(this).balance, "Nonsense amount!");  
        require (secondaryPot + pendingBets + amount <= address(this).balance, "Can't withdraw what you don't own!");
        msg.sender.transfer(amount);
    }

    function withdrawTokens(address to, uint amount) external auth {
        require(TOKEN.transfer(to, amount), "Token transfer failed!");
    }

    function disburseDividends(uint amount) external auth {
        require (amount <= address(this).balance, "Nonsense amount!");  
        require (secondaryPot + pendingBets + amount <= address(this).balance, "Can't send what you don't own!");
        TOKEN.disburseDividends.value(amount)();
        dividendsPaid += amount;
    }

     
    function __callback(bytes32 _queryId, string _result, bytes _proof) public {
        
        require(msg.sender == oraclize_cbAddress(), "You can't do that!");
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            _onRandomFailed(_queryId);
        } else {
            uint randomNumber = uint(keccak256(abi.encode(_result)));
            _onRandom(randomNumber, _queryId);
        }
    }

    function getLuck(address player) public view returns(uint) {
        uint lastTime;
        uint lastLvl;
        (lastLvl, lastTime) = getLuckProps(player);
        uint elapsed = (now - lastTime) * UNLUCK_RATE;
        if(lastLvl > elapsed) {
            return lastLvl - elapsed;
        } else {
            return 0;
        }
    }

    function getContractProps() public view 
    returns(
        uint secondaryPot_,
        uint minHouseEdge,
        uint minHouseEdgeClassic,
        uint maxProfit_,
        uint luckPrice_
    ) {
        secondaryPot_ = secondaryPot;
        minHouseEdge = _minHouseEdge();
        minHouseEdgeClassic = _minHouseEdgeClassic();
        maxProfit_ = maxProfit;
        luckPrice_ = luckPrice;
    }

    function getBetProps(bytes32 queryId) public view 
    returns(
        uint128 amount,
        uint64 time,
        uint16 modulo,
        uint16 rollUnder,
        uint16 rollUnder2,
        bool classicMode
    ) {
        uint props = bets[queryId].props;
        return decodeProps(props);
    }

    function decodeProps(uint props) public pure 
    returns(
        uint128 amount,
        uint64 time,
        uint16 modulo,
        uint16 rollUnder,
        uint16 rollUnder2,
        bool classicMode
    ) {
        classicMode = uint16(props) == 1 ? true : false;
        rollUnder2 = uint16(props >> 16);
        rollUnder = uint16(props >> 32);
        modulo = uint16(props >> 48);
        time = uint64(props >> 64);
        amount = uint128(props >> 128);
    }

    function getLuckProps(address player) public view returns(uint128 lastLevel, uint64 lastToppedUp) {
        uint props = luck[player];
         
         
        lastToppedUp = uint64(props);
        lastLevel = uint128(props >> 64);
    }

     

    function _addLuck(address player, uint amount) internal {
         
        uint props = min(getLuck(player) + amount, 5 * WAD);
        props = props << 64;
        props |= uint64(now);
        luck[player] = props;
    }

    function _onRandom(uint _rand, bytes32 queryId) internal {
        Bet storage bet = bets[queryId];
        address player = bet.player;
        uint props = bet.props;
        uint128 amount;
        uint64 time;
        uint16 modulo;
        uint16 rollUnder;
        uint16 rollUnder2;
        bool classicMode;

        (amount, time, modulo, rollUnder, rollUnder2, classicMode) = decodeProps(props);

        require(time + BET_EXPIRY >= now, "Bet already expired");
        require(amount > 0, "Invalid query ID!");
        
        uint win;  
        uint won;  
        (win,) = _winAmount(amount, modulo, rollUnder, classicMode);

        if(uint16(_rand) % modulo < rollUnder) {
            won += win;
        }

        if(!classicMode) {
            if(amount >= minSecondaryAmount) {           
                if(uint16(_rand >> 16) % SECONDAY_MODULO < rollUnder2) {
                    won += secondaryPot / 2;
                    secondaryPot /= 2;
                    emit SecondaryJackpotWon(queryId, player, secondaryPot);
                }
            }
        }

        _finalizeBet(queryId, player, props, won);

         
         
        if(pendingBets >= win) {
            pendingBets -= win;
        } else {
            pendingBets = 0;
        }
    }

    function _finalizeBet(bytes32 queryId, address player, uint props, uint amountToSend) internal {
        uint _props = props << 128;
        bets[queryId].props = _props >> 128;
        if(amountToSend > 0) {
             
            if(!player.send(amountToSend)) {
                emit FailedPayment(queryId, amountToSend);
            }            
        }
        emit BetFinalized(queryId, player, props, amountToSend);
    }

    function _processRefund(bytes32 queryId) internal {    
        emit RefundAttempt(queryId); 
        uint props = bets[queryId].props;
        uint128 amount;
        uint16 modulo;
        uint16 rollUnder;
        bool classicMode;

        (amount, , modulo, rollUnder, , classicMode) = decodeProps(props);

        uint win;
        (win,) = _winAmount(amount, modulo, rollUnder, classicMode);

        _finalizeBet(queryId, bets[queryId].player, props, amount); 
        
         
        if(pendingBets >= win) {
            pendingBets -= win;
        } else {
            pendingBets = 0;
        }
    }

    function _onRandomFailed(bytes32 queryId) internal {
        emit RandomFailed(queryId);
        _processRefund(queryId);
    }

    function _winAmount(uint128 betSize, uint16 modulo, uint16 rollUnder, bool classic) 
    internal 
    view 
    returns(uint reward, uint secondaryJackpotFee){
        require(rollUnder > 0 && rollUnder <= modulo, "Nonsense bet!");
       
        uint houseEdge;
        if(!classic) {
            houseEdge = max(betSize / HOUSE_EDGE_DIVISOR, _minHouseEdge());
            if(betSize >= minSecondaryAmount){
                secondaryJackpotFee = betSize / SECONDARY_JACKPOT_DIVISOR;
            }            
        } else {
            houseEdge = max(betSize / HOUSE_EDGE_DIVISOR_CLASSIC, _minHouseEdgeClassic());
        }

        reward = (betSize - houseEdge - secondaryJackpotFee) * modulo / rollUnder;
        require(betSize >= houseEdge + secondaryJackpotFee, "Bet doesn't cover minimum fee!");
    }

    function _minHouseEdge() internal view returns(uint) {
        return oraclizeGasPrice * oraclizeCallbackGas + minHouse;
    }

    function _minHouseEdgeClassic() internal view returns(uint) {
        return oraclizeGasPrice * oraclizeCallbackGas + minHouseClassic;
    }

    function _getBetAmount(bytes32 queryId) internal view returns(uint128 amount) {
        uint props = bets[queryId].props;
        amount = uint128(props >> 128);
    }

    function _getBetTimestamp(bytes32 queryId) internal view returns(uint64 timestamp) {
        uint props = bets[queryId].props;
        timestamp = uint64(props >> 64);
    }
}