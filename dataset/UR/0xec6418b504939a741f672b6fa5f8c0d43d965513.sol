 

pragma solidity ^0.4.18;

 
pragma solidity ^0.4.0;

contract OraclizeI {
    address public cbAddress;
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable public returns (bytes32 _id);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) public;
    function setCustomGasPrice(uint _gasPrice) public;
}

contract OraclizeAddrResolverI {
    function getAddress() view public returns (address _addr);
}

contract usingOraclize {
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;

    OraclizeAddrResolverI OAR;
    OraclizeI oraclize;

    modifier oraclizeAPI {
        if ((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetworkAuto();

        if (address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }

    function oraclize_setNetworkAuto() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
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

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg, uint gaslimit, uint priceLimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > priceLimit + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
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

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
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

library Helpers {
	using SafeMath for uint256;
	function parseIntRound(string _a, uint256 _b) internal pure returns (uint256) {
		bytes memory bresult = bytes(_a);
		uint256 mint = 0;
		_b++;
		bool decimals = false;
		for (uint i = 0; i < bresult.length; i++) {
			if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
				if (decimals) {
					if (_b == 0) {
						break;
					}
					else
						_b--;
				}
				if (_b == 0) {
					if (uint(bresult[i]) - 48 >= 5)
						mint += 1;
				} else {
					mint *= 10;
					mint += uint(bresult[i]) - 48;
				}
			} else if (bresult[i] == 46)
				decimals = true;
		}
		if (_b > 0)
			mint *= 10**(_b - 1);
		return mint;
	}
}

contract OracleI {
    bytes32 public oracleName;
    bytes16 public oracleType;
    uint256 public rate;
    bool public waitQuery;
    uint256 public updateTime;
    uint256 public callbackTime;
    function getPrice() view public returns (uint);
    function setBank(address _bankAddress) public;
    function setGasPrice(uint256 _price) public;
    function setGasLimit(uint256 _limit) public;
    function updateRate() external returns (bool);
}


 
contract OracleBase is Ownable, usingOraclize, OracleI {
    event NewOraclizeQuery();
    event OraclizeError(string desciption);
    event PriceTicker(string price, bytes32 queryId, bytes proof);
    event BankSet(address bankAddress);

    struct OracleConfig {
        string datasource;
        string arguments;
    }

    bytes32 public oracleName = "Base Oracle";
    bytes16 public oracleType = "Undefined";
    uint256 public updateTime;
    uint256 public callbackTime;
    uint256 public priceLimit = 1 ether;

    mapping(bytes32=>bool) validIds;  
    address public bankAddress;
    uint256 public rate;
    bool public waitQuery = false;
    OracleConfig public oracleConfig;

    
    uint256 public gasPrice = 20 * 10**9;
    uint256 public gasLimit = 100000;

    uint256 constant MIN_GAS_PRICE = 1 * 10**9;  
    uint256 constant MAX_GAS_PRICE = 100 * 10**9;  
    uint256 constant MIN_GAS_LIMIT = 95000; 
    uint256 constant MAX_GAS_LIMIT = 1000000;
    uint256 constant MIN_REQUEST_PRICE = 0.001118 ether;

    modifier onlyBank() {
        require(msg.sender == bankAddress);
        _;
    }

     
    function OracleBase() public {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

     
    function setGasPrice(uint256 priceInWei) public onlyOwner {
        require((priceInWei >= MIN_GAS_PRICE) && (priceInWei <= MAX_GAS_PRICE));
        gasPrice = priceInWei;
        oraclize_setCustomGasPrice(gasPrice);
    }

     
    function setGasLimit(uint256 _gasLimit) public onlyOwner {
        require((_gasLimit >= MIN_GAS_LIMIT) && (_gasLimit <= MAX_GAS_LIMIT));
        gasLimit = _gasLimit;
    }

     
    function setBank(address bank) public onlyOwner {
        bankAddress = bank;
        BankSet(bankAddress);
    }

     
    function getPrice() public view returns (uint) {
        return oraclize_getPrice(oracleConfig.datasource, gasLimit);
    }

     
    function updateRate() external onlyBank returns (bool) {
        if (getPrice() > this.balance) {
            OraclizeError("Not enough ether");
            return false;
        }
        bytes32 queryId = oraclize_query(oracleConfig.datasource, oracleConfig.arguments, gasLimit, priceLimit);
        
        if (queryId == bytes32(0)) {
            OraclizeError("Unexpectedly high query price");
            return false;
        }

        NewOraclizeQuery();
        validIds[queryId] = true;
        waitQuery = true;
        updateTime = now;
        return true;
    }

     
    function __callback(bytes32 myid, string result, bytes proof) public {
        require(validIds[myid] && msg.sender == oraclize_cbAddress());

        rate = Helpers.parseIntRound(result, 3);  
        delete validIds[myid];
        callbackTime = now;
        waitQuery = false;
        PriceTicker(result, myid, proof);
    }

     
    function __callback(bytes32 myid, string result) public {
        bytes memory proof = new bytes(1);
        __callback(myid, result, proof);
    }

         
    function () public payable {}
}

 
contract OracleBitfinex is OracleBase {
    bytes32 constant ORACLE_NAME = "Bitfinex Oraclize Async";
    bytes16 constant ORACLE_TYPE = "ETHUSD";
    string constant ORACLE_DATASOURCE = "URL";
    string constant ORACLE_ARGUMENTS = "json(https://api.bitfinex.com/v1/pubticker/ethusd).last_price";
    
     
    function OracleBitfinex() public {
        oracleName = ORACLE_NAME;
        oracleType = ORACLE_TYPE;
        oracleConfig = OracleConfig({datasource: ORACLE_DATASOURCE, arguments: ORACLE_ARGUMENTS});
    }
}