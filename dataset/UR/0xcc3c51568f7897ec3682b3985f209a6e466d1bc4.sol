 

pragma solidity ^0.4.18;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) public payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) public  payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public  payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) public payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) public payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) public;
    function setConfig(bytes32 _config) public;
    function setCustomGasPrice(uint _gasPrice) public;
    function randomDS_getSessionPubKeyHash() public returns(bytes32);
}

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}

contract Priceable {
    modifier costsExactly(uint price) {
        if (msg.value == price) {
            _;
        }
    }

    modifier costs(uint price) {
        if (msg.value >= price) {
            _;
        }
    }
}

contract RewardDistributable {
    event TokensRewarded(address indexed player, address rewardToken, uint rewards, address requester, uint gameId, uint block);
    event ReferralRewarded(address indexed referrer, address indexed player, address rewardToken, uint rewards, uint gameId, uint block);
    event ReferralRegistered(address indexed player, address indexed referrer);

     
    function transferRewards(address player, uint entryAmount, uint gameId) public;

     
    function getTotalTokens(address tokenAddress) public constant returns(uint);

     
    function getRewardTokenCount() public constant returns(uint);

     
    function getTotalApprovers() public constant returns(uint);

     
    function getRewardRate(address player, address tokenAddress) public constant returns(uint);

     
     
    function addRequester(address requester) public;

     
     
    function removeRequester(address requester) public;

     
     
    function addApprover(address approver) public;

     
     
    function removeApprover(address approver) public;

     
    function updateRewardRate(address tokenAddress, uint newRewardRate) public;

     
    function addRewardToken(address tokenAddress, uint newRewardRate) public;

     
    function removeRewardToken(address tokenAddress) public;

     
    function updateReferralBonusRate(uint newReferralBonusRate) public;

     
     
     
    function registerReferral(address player, address referrer) public;

     
    function destroyRewards() public;
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library OraclizeLib {
   
    struct OraclizeData {
        OraclizeAddrResolverI oraclizeAddressResolver;
        OraclizeI oraclize;
        mapping(bytes32=>bytes32) oraclizeRandomDSArgs;
        mapping(bytes32=>bool) oraclizeRandomDsSessionKeyHashVerified;
        string oraclizeNetworkName;
    }

    function initializeOraclize(OraclizeData storage self) internal {
       self.oraclizeAddressResolver = oraclize_setNetwork(self);
       if (self.oraclizeAddressResolver != address(0)) {
           self.oraclize = OraclizeI(self.oraclizeAddressResolver.getAddress());
       }
    }

    function oraclize_setNetwork(OraclizeData storage self) public returns(OraclizeAddrResolverI) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0) {  
            oraclize_setNetworkName(self, "eth_mainnet");
            return OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0) {  
            oraclize_setNetworkName(self, "eth_ropsten3");
            return OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0) {  
            oraclize_setNetworkName(self, "eth_kovan");
            return OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0) {  
            oraclize_setNetworkName(self, "eth_rinkeby");
            return OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0) {  
            return OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0) {  
            return OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0) {  
            return OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
        }
    }

    function oraclize_setNetworkName(OraclizeData storage self, string _network_name) internal {
        self.oraclizeNetworkName = _network_name;
    }
    
    function oraclize_getNetworkName(OraclizeData storage self) internal constant returns (string) {
        return self.oraclizeNetworkName;
    }

    function oraclize_getPrice(OraclizeData storage self, string datasource) public returns (uint) {
        return self.oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(OraclizeData storage self, string datasource, uint gaslimit) public returns (uint) {
        return self.oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string arg) public returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, arg);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string arg) public returns (bytes32 id) {
        uint price = self.oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) {
            return 0;  
        }
        return self.oraclize.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string arg, uint gaslimit) public returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, arg, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string arg, uint gaslimit) public returns (bytes32 id) {
        uint price = self.oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) {
            return 0;  
        }
        return self.oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string arg1, string arg2) public returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, arg1, arg2);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string arg1, string arg2) public returns (bytes32 id) {
        uint price = self.oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) {
            return 0;  
        }
        return self.oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string arg1, string arg2, uint gaslimit) public returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) public returns (bytes32 id) {
        uint price = self.oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) {
            return 0;  
        }
        return self.oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string[] argN) internal returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, argN);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string[] argN) internal returns (bytes32 id) {
        uint price = self.oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) {
            return 0;  
        }
        bytes memory args = stra2cbor(argN);
        return self.oraclize.queryN.value(price)(timestamp, datasource, args);
    }

    function oraclize_query(OraclizeData storage self, string datasource, string[] argN, uint gaslimit) internal returns (bytes32 id) {
        return oraclize_query(self, 0, datasource, argN, gaslimit);
    }

    function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, string[] argN, uint gaslimit) internal returns (bytes32 id){
        uint price = self.oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) {
            return 0;  
        }
        bytes memory args = stra2cbor(argN);
        return self.oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

     function oraclize_query(OraclizeData storage self, uint timestamp, string datasource, bytes[] argN, uint gaslimit) internal returns (bytes32 id){
        uint price = self.oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) {
            return 0;  
        }
        bytes memory args = ba2cbor(argN);
        return self.oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_newRandomDSQuery(OraclizeData storage self, uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32) {
        assert((_nbytes > 0) && (_nbytes <= 32));
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash(self);
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes[] memory args = new bytes[](3);
        args[0] = unonce;
        args[1] = nbytes;
        args[2] = sessionKeyHash; 
        bytes32 queryId = oraclize_query(self, _delay, "random", args, _customGasLimit);
        oraclize_randomDS_setCommitment(self, queryId, keccak256(bytes8(_delay), args[1], sha256(args[0]), args[2]));
        return queryId;
    }

     function oraclize_randomDS_proofVerify__main(OraclizeData storage self, bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){
        bool checkok;
        
         
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        checkok = (keccak256(keyhash) == keccak256(sha256(context_name, queryId)));
        if (checkok == false) {
            return false;
        }
        
        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);
        
         
        checkok = matchBytes32Prefix(sha256(sig1), result);
        if (checkok == false) {
            return false;
        }
        
         
         
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);
        
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);
        
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (self.oraclizeRandomDSArgs[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)) {
            delete self.oraclizeRandomDSArgs[queryId];  
        } else {
            return false;
        }

         
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        checkok = verifySig(sha256(tosign1), sig1, sessionPubkey);
        if (checkok == false) {
            return false;
        }

         
        if (self.oraclizeRandomDsSessionKeyHashVerified[sessionPubkeyHash] == false) {
            self.oraclizeRandomDsSessionKeyHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }
        
        return self.oraclizeRandomDsSessionKeyHashVerified[sessionPubkeyHash];
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;
        
         
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);
        
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);
        
        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = 1;  
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        
        if (sigok == false) {
            return false;
        }
        
         
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        
        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);
        
        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);
        
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        
        return sigok;
    }

    function oraclize_randomDS_proofVerify__returnCode(OraclizeData storage self, bytes32 _queryId, string _result, bytes _proof) internal returns (uint8) {
         
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) {
            return 1;
        }
        bool proofVerified = oraclize_randomDS_proofVerify__main(self, _proof, _queryId, bytes(_result), oraclize_getNetworkName(self));
        if (proofVerified == false) {
            return 2;
        }
        return 0;
    }
    
    function oraclize_randomDS_setCommitment(OraclizeData storage self, bytes32 queryId, bytes32 commitment) internal {
        self.oraclizeRandomDSArgs[queryId] = commitment;
    }
    
    function matchBytes32Prefix(bytes32 content, bytes prefix) internal pure returns (bool) {
        bool match_ = true;
        
        for (uint i=0; i<prefix.length; i++) {
            if (content[i] != prefix[i]) {
                match_ = false;
            }
        }
        
        return match_;
    }

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool) {
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
        if (address(keccak256(pubkey)) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
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
    
    function oraclize_cbAddress(OraclizeData storage self) public constant returns (address) {
        return self.oraclize.cbAddress();
    }

    function oraclize_setProof(OraclizeData storage self, byte proofP) public {
        return self.oraclize.setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(OraclizeData storage self, uint gasPrice) public {
        return self.oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_setConfig(OraclizeData storage self, bytes32 config) public {
        return self.oraclize.setConfig(config);
    }

    function getCodeSize(address _addr) public constant returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }
    
    function oraclize_randomDS_getSessionPubKeyHash(OraclizeData storage self) internal returns (bytes32){
        return self.oraclize.randomDS_getSessionPubKeyHash();
    }

    function stra2cbor(string[] arr) internal pure returns (bytes) {
        uint arrlen = arr.length;

         
        uint outputlen = 0;
        bytes[] memory elemArray = new bytes[](arrlen);
        for (uint i = 0; i < arrlen; i++) {
            elemArray[i] = (bytes(arr[i]));
            outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
        }
        uint ctr = 0;
        uint cborlen = arrlen + 0x80;
        outputlen += byte(cborlen).length;
        bytes memory res = new bytes(outputlen);

        while (byte(cborlen).length > ctr) {
            res[ctr] = byte(cborlen)[ctr];
            ctr++;
        }
        for (i = 0; i < arrlen; i++) {
            res[ctr] = 0x5F;
            ctr++;
            for (uint x = 0; x < elemArray[i].length; x++) {
                 
                if (x % 23 == 0) {
                    uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                    elemcborlen += 0x40;
                    uint lctr = ctr;
                    while (byte(elemcborlen).length > ctr - lctr) {
                        res[ctr] = byte(elemcborlen)[ctr - lctr];
                        ctr++;
                    }
                }
                res[ctr] = elemArray[i][x];
                ctr++;
            }
            res[ctr] = 0xFF;
            ctr++;
        }
        return res;
    }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

             
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                     
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

        assert (to.length >= minLength);

         
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
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Cascading is Ownable {
    using SafeMath for uint256;

    struct Cascade {
        address cascade;
        uint16 percentage;
    }

    uint public totalCascadingPercentage;
    Cascade[] public cascades;    

     
     
    function addCascade(address newAddress, uint newPercentage) public onlyOwner {
        cascades.push(Cascade(newAddress, uint16(newPercentage)));
        totalCascadingPercentage += newPercentage;
    }

     
     
    function deleteCascade(uint index) public onlyOwner {
        require(index < cascades.length);
        
        totalCascadingPercentage -= cascades[index].percentage;

        cascades[index] = cascades[cascades.length - 1];
        delete cascades[cascades.length - 1];
        cascades.length--;
    }

     
     
    function transferCascades(uint totalJackpot) internal {
        for (uint i = 0; i < cascades.length; i++) {
            uint cascadeTotal = getCascadeTotal(cascades[i].percentage, totalJackpot);

             
            cascades[i].cascade.transfer(cascadeTotal);
        }
    }

     
     
     
     
    function getCascadeTotal(uint percentage, uint totalJackpot) internal pure returns(uint) {
        return totalJackpot.mul(percentage).div(100);        
    }
   
     
     
     
    function getTotalAfterCascades(uint totalJackpot) internal constant returns (uint) {
        uint cascadeTotal = getCascadeTotal(totalCascadingPercentage, totalJackpot);
        return totalJackpot.sub(cascadeTotal);
    }
}

contract SafeWinner is Ownable {
    using SafeMath for uint256;

    mapping(address => uint) public pendingPayments;
    address[] public pendingWinners;
    uint public totalPendingPayments;

    event WinnerWithdrew(address indexed winner, uint amount, uint block);

     
     
    function addPendingWinner(address winner, uint amount) internal {
        pendingPayments[winner] = pendingPayments[winner].add(amount);
        totalPendingPayments = totalPendingPayments.add(amount);
        pendingWinners.push(winner);
    }

     
    function withdrawWinnings() public {
        address winner = msg.sender;
        uint payment = pendingPayments[winner];

        require(payment > 0);
        require(this.balance >= payment);

        transferPending(winner, payment);
    }

     
    function retryWinners() public onlyOwner {
        for (uint i = 0; i < pendingWinners.length; i++) {
            retryWinner(i);
        }

        pendingWinners.length = 0;
    }

    function retryWinner(uint index) public onlyOwner {
        address winner = pendingWinners[index];
        uint payment = pendingPayments[winner];
        require(this.balance >= payment);
        if (payment != 0) {
            transferPending(winner, payment);
        }
    }

    function transferPending(address winner, uint256 payment) internal {
        totalPendingPayments = totalPendingPayments.sub(payment);
        pendingPayments[winner] = 0;
        winner.transfer(payment);        
        WinnerWithdrew(winner, payment, block.number);
    }
}

contract Raffle is Ownable, Priceable, SafeWinner, Cascading {
  using SafeMath for uint256;
  using OraclizeLib for OraclizeLib.OraclizeData;

  enum RaffleState { Active, InActive, PendingInActive }
  enum RandomSource { RandomDS, Qrng }

  struct Jackpot {
    uint absoluteTotal;
    uint feeTotal;
    uint cascadeTotal;
    uint winnerTotal;
  }

  struct TicketHolder {
    address purchaser;
    uint16 count;
    uint80 runningTotal;
  }
  
   
  RaffleState public raffleState;
  RandomSource public randomSource;
  uint public ticketPrice;
  uint public gameId;
  uint public fee;
  

   
  TicketHolder[] internal ticketHolders;
  uint internal randomBytes;
  uint internal randomQueried;
  uint internal callbackGas;
  RewardDistributable internal rewardDistributor;

   
  OraclizeLib.OraclizeData oraclizeData;

   
  event TicketPurchased(address indexed ticketPurchaser, uint indexed id, uint numTickets, uint totalCost, uint block);
  event WinnerSelected(address indexed winner, uint indexed id, uint winnings, uint block);
  event RandomProofFailed(bytes32 queryId, uint indexed id, uint block);

  function Raffle(uint _ticketPrice, address _rewardDistributor) public {
    ticketPrice = _ticketPrice;
    raffleState = RaffleState.Active;
    callbackGas = 200000;
    randomBytes = 8;
    fee = 5 finney;
    rewardDistributor = RewardDistributable(_rewardDistributor);
    oraclizeData.initializeOraclize();
    randomSource = RandomSource.Qrng;
    resetRaffle();
  }

   
  function isActive() public constant returns (bool) {
    return raffleState == RaffleState.Active || raffleState == RaffleState.PendingInActive;
  }
  
   
  function () public payable {
  }
   
   
   
  function getProjectedJackpot() public constant returns (uint) {
    uint jackpot = getAbsoluteProjectedJackpot();
    Jackpot memory totals = getJackpotTotals(jackpot);
    return totals.winnerTotal;
  }

   
   
  function getJackpot() public constant returns (uint) {
    uint jackpot = getAbsoluteJackpot();
    Jackpot memory totals = getJackpotTotals(jackpot);
    return totals.winnerTotal;
  }

   
   
  function getTicketHolderCount() public constant returns (uint) {
    return getTotalTickets();
  }

   
  function updateTicketPrice(uint updatedPrice) public onlyOwner {
    require(raffleState == RaffleState.InActive);
    require(updatedPrice > 0);
    ticketPrice = updatedPrice;
  }

   
  function updateFee(uint updatedFee) public onlyOwner {
    require(updatedFee > 0);
    fee = updatedFee;
  }

   
  function deactivate() public onlyOwner {
    require(raffleState == RaffleState.Active);
    raffleState = ticketHolders.length == 0 ? RaffleState.InActive : RaffleState.PendingInActive;
  }

   
  function activate() public onlyOwner {
    require(raffleState == RaffleState.InActive);
    raffleState = RaffleState.Active;
  }

   
  function __callback(bytes32 queryId, string result, bytes proof) public {
    require(msg.sender == oraclizeData.oraclize_cbAddress());
    
     
    if (oraclizeData.oraclize_randomDS_proofVerify__returnCode(queryId, result, proof) != 0) {
      RandomProofFailed(queryId, gameId, now);
      randomQueried = 0;
      return;
    }

    __callback(queryId, result);
  }

   
  function __callback(bytes32 queryId, string result) public {
    require(msg.sender == oraclizeData.oraclize_cbAddress());
    
     
    if (!shouldChooseWinner()) {
      return;
    }

    uint maxRange = 2**(8*randomBytes); 
    uint randomNumber = uint(keccak256(result)) % maxRange; 
    winnerSelected(randomNumber);
  }

   
   
  function forceChooseRandomWinner() public onlyOwner {
    require(raffleState != RaffleState.InActive);
    executeRandomQuery();
  }

   
   
  function forceRefund() public onlyOwner {
    raffleState = RaffleState.PendingInActive;

    uint total = getTotalTickets() * ticketPrice;
    require(this.balance > total);

    for (uint i = 0; i < ticketHolders.length; i++) {
      TicketHolder storage holder = ticketHolders[i];
      holder.purchaser.transfer(uint256(holder.count).mul(ticketPrice));
    }

    resetRaffle();
  }

   
  function updateRewardDistributor(address newRewardDistributor) public onlyOwner {
    rewardDistributor = RewardDistributable(newRewardDistributor);
  }

   
   
  function destroy() public onlyOwner {
    require(raffleState == RaffleState.InActive);
    selfdestruct(owner);
  }

   
   
  function getAbsoluteProjectedJackpot() internal constant returns (uint);

   
   
  function getAbsoluteJackpot() internal constant returns (uint);
  
   
   
  function shouldChooseWinner() internal returns (bool);

  function executeRandomQuery() internal {
    if (randomSource == RandomSource.RandomDS) {
      oraclizeData.oraclize_newRandomDSQuery(0, randomBytes, callbackGas);
    }
    else {
      oraclizeData.oraclize_query("URL","json(https://qrng.anu.edu.au/API/jsonI.php?length=1&type=hex16&size=32).data[0]", callbackGas);
    }
  }

   
  function chooseWinner() internal {
     
     
    if (randomQueried < (block.number.sub(20))) {
      executeRandomQuery();
      randomQueried = block.number;
    }
  }

   
  function winnerSelected(uint randomNumber) internal {
    TicketHolder memory winner = getWinningTicketHolder(randomNumber);
    uint jackpot = getAbsoluteJackpot();
    Jackpot memory jackpotTotals = getJackpotTotals(jackpot);

    WinnerSelected(winner.purchaser, gameId, jackpotTotals.winnerTotal, now);    
    transferJackpot(winner.purchaser, jackpotTotals.winnerTotal);
    transferCascades(jackpotTotals.absoluteTotal);
    resetRaffle();
  }

  function getWinningTicketHolder(uint randomNumber) internal view returns(TicketHolder) {
    assert(ticketHolders.length > 0);
    uint totalTickets = getTotalTickets();
    uint winner = (randomNumber % totalTickets) + 1;

    uint min = 0;
    uint max = ticketHolders.length-1;
    while (max > min) {
        uint mid = (max + min + 1) / 2;
        if (ticketHolders[mid].runningTotal >= winner &&
         (ticketHolders[mid].runningTotal-ticketHolders[mid].count) < winner) {
           return ticketHolders[mid];
        }

        if (ticketHolders[mid].runningTotal <= winner) {
            min = mid;
        } else {
            max = mid-1;
        }
    }

    return ticketHolders[min];
  }

   
  function transferJackpot(address winner, uint jackpot) internal returns(uint) {
     
     
    bool sendSuccessful = winner.send(jackpot);
    if (!sendSuccessful) {
      addPendingWinner(winner, jackpot);
    }

    return jackpot;
  }

   
  function resetRaffle() internal {
    if (raffleState == RaffleState.PendingInActive) {
      raffleState = RaffleState.InActive;
    }
    ticketHolders.length = 0;
    gameId = block.number;
    randomQueried = 0;
  }

   
  function getJackpotTotals(uint jackpot) internal constant returns(Jackpot) {
    if (jackpot < fee) {
      return Jackpot(0, 0, 0, 0);
    }

    uint cascadeTotal = getCascadeTotal(totalCascadingPercentage, jackpot);
    return Jackpot(jackpot, fee, cascadeTotal, jackpot.sub(fee).sub(cascadeTotal));
  }

  function updateRandomSource(uint newRandomSource) public onlyOwner {
    if (newRandomSource == 1) {
      randomSource = RandomSource.RandomDS;
    } else {
      randomSource = RandomSource.Qrng;
    }

    setProof();
  }


  function setProof() internal {
      if (randomSource == RandomSource.RandomDS) {
         
        oraclizeData.oraclize_setProof(0x30);
      }
      else {
        oraclizeData.oraclize_setProof(0x00);
      }
  }

  function getTotalTickets() internal view returns(uint) {
    return ticketHolders.length == 0 ? 0 : ticketHolders[ticketHolders.length-1].runningTotal;
  }

  function updateOraclizeGas(uint newCallbackGas, uint customGasPrice) public onlyOwner {
    callbackGas = newCallbackGas;
    updateCustomGasPrice(customGasPrice);
  }

  function updateCustomGasPrice(uint customGasPrice) internal {
    oraclizeData.oraclize_setCustomGasPrice(customGasPrice);
  }
}

contract CountBasedRaffle is Raffle {
  
  uint public drawTicketCount;

   
   
   
  function CountBasedRaffle(uint _ticketPrice, uint _drawTicketCount, address _rewardDistributor) Raffle(_ticketPrice, _rewardDistributor) public {
    drawTicketCount = _drawTicketCount;
  }

   
  function getAbsoluteProjectedJackpot() internal constant returns (uint) {
    uint totalTicketCount = getTotalTickets();
    uint ticketCount = drawTicketCount > totalTicketCount ? drawTicketCount : totalTicketCount;
    return ticketCount.mul(ticketPrice); 
  }

   
  function getAbsoluteJackpot() internal constant returns (uint) {
    if (ticketHolders.length == 0) {
      return 0;
    }

    return this.balance.sub(totalPendingPayments);
  }

     
  function purchaseTicket(uint numTickets, address referrer) public payable costsExactly(numTickets.mul(ticketPrice)) {
    require(raffleState != RaffleState.InActive);
    require(numTickets < drawTicketCount);

     
    uint totalTickets = getTotalTickets();
    ticketHolders.push(TicketHolder(msg.sender, uint16(numTickets), uint80(totalTickets.add(numTickets))));
    TicketPurchased(msg.sender, gameId, numTickets, ticketPrice.mul(numTickets), now);
    if (rewardDistributor != address(0)) {
      rewardDistributor.registerReferral(msg.sender, referrer);
      rewardDistributor.transferRewards(msg.sender, msg.value, gameId);
    }

    if (shouldChooseWinner()) {
      chooseWinner();
    }
  }
  
   
   
  function shouldChooseWinner() internal returns (bool) {
    return getTotalTickets() >= drawTicketCount;
  }
}

contract BronzeRaffle is CountBasedRaffle {

   
   
  function BronzeRaffle(address _rewardDistributor) CountBasedRaffle(20 finney, 15, _rewardDistributor) public {
  }
}