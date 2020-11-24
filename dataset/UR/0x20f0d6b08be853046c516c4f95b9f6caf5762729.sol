 

pragma solidity ^0.4.16;

 
contract owned  {
  address owner;
  function owned() {
    owner = msg.sender;
  }
  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
  modifier onlyOwner() {
    if (msg.sender==owner) 
    _;
  }
}

 
contract mortal is owned() {
  function kill() onlyOwner {
    if (msg.sender == owner) selfdestruct(owner);
  }
}
 

 
 

 
contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}
 
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
 
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
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
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0)) oraclize_setNetwork();
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
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

   function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
       return oraclize.getPrice(datasource);
   }

   function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
       return oraclize.getPrice(datasource, gaslimit);
   }
   
	function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal { 
        return oraclize.setCustomGasPrice(gasPrice); 
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


    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }
        
    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }
    
    function oraclize_getNetworkName() internal returns (string) {
        return oraclize_network_name;
    }
        
}
 

 
contract DSParser{
    uint8 constant WAD_Dec=18;
    uint128 constant WAD = 10 ** 18;
    function parseInt128(string _a)  constant  returns (uint128) { 
		return cast(parseInt( _a, WAD_Dec));
    }
    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }
    function parseInt(string _a, uint _b)  
			constant 
			returns (uint) { 
		 
			bytes memory bresult = bytes(_a);
            uint mint = 0;
            bool decimals = false;
            for (uint i=0; i<bresult.length; i++){
                if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                    if (decimals){
                       if (_b == 0){
                         
                        if(uint(bresult[i])- 48>4){
                            mint = mint+1;
                        }    
                        break;
                       }
                       else _b--;
                    }
                    mint *= 10;
                    mint += uint(bresult[i]) - 48;
                } else if (bresult[i] == 46||bresult[i] == 44) {  
                    decimals = true;
                }
            }
            if (_b > 0) mint *= 10**_b;
           return mint;
    }
	
}

 
contract I_minter { 
    event EventCreateStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventCreateRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventBankrupt();
	
    function Leverage() constant returns (uint128)  {}
    function RiskPrice(uint128 _currentPrice,uint128 _StaticTotal,uint128 _RiskTotal, uint128 _ETHTotal) constant returns (uint128 price)  {}
    function RiskPrice(uint128 _currentPrice) constant returns (uint128 price)  {}     
    function PriceReturn(uint _TransID,uint128 _Price) {}
    function NewStatic() external payable returns (uint _TransID)  {}
    function NewStaticAdr(address _Risk) external payable returns (uint _TransID)  {}
    function NewRisk() external payable returns (uint _TransID)  {}
    function NewRiskAdr(address _Risk) external payable returns (uint _TransID)  {}
    function RetRisk(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function RetStatic(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function Strike() constant returns (uint128)  {}
}

 
contract I_Pricer {
    uint128 public lastPrice;
    uint public constant DELAY = 1 days; 
    I_minter public mint;
    string public sURL; 
    mapping (bytes32 => uint) RevTransaction;
    function setMinter(address _newAddress) {}
    function __callback(bytes32 myid, string result) {}
    function queryCost() constant returns (uint128 _value) {}
    function QuickPrice() payable {}
    function requestPrice(uint _actionID) payable returns (uint _TrasID){}
    function collectFee() returns(bool) {}
    function () {
         
        revert();
    }
}

 
contract Pricer is I_Pricer, 
	mortal, 
	usingOraclize, 
	DSParser {
	 
     
     
     
     
     
     
     
     
     
	
    function Pricer(string _URL) {
		 
		oraclize_setNetwork();
		sURL=_URL;
    }

	function () {
         
        revert();
    }

    function setMinter(address _newAddress) 
		onlyOwner {
		 
        mint=I_minter(_newAddress);
    }

    function queryCost() 
		constant 
		returns (uint128 _value) {
		 
		return cast(oraclize_getPrice("URL")); 
    }

    function QuickPrice() 
		payable {
		 
        bytes32 TrasID =oraclize_query(1, "URL", sURL);
        RevTransaction[TrasID]=0;
    }
	
    function __callback(bytes32 myid, string result) {
		 
        if (msg.sender != oraclize_cbAddress()) revert();  
        bytes memory tempEmptyStringTest = bytes(result);  
        if (tempEmptyStringTest.length == 0) {
             lastPrice =  0;   
        } else {
            lastPrice =  parseInt128(result);   
        }
        if(RevTransaction[myid]>0){   
            mint.PriceReturn(RevTransaction[myid],lastPrice);   
        }
        delete RevTransaction[myid];  
    }

	function setGas(uint gasPrice) 
		onlyOwner 
		returns(bool) {
		 
		oraclize_setCustomGasPrice(gasPrice);
		return true;
    }
	
	function collectFee() 
		onlyOwner 
		returns(bool) {
		 
        return owner.send(this.balance);
		return true;
    }
	
	modifier onlyminter() {
      if (msg.sender==address(mint)) 
      _;
    }

    function requestPrice(uint _actionID) 
		payable 
		onlyminter 
		returns (uint _TrasID){
		 
         
        bytes32 TrasID;
        TrasID=oraclize_query(DELAY, "URL", sURL);
        RevTransaction[TrasID]=_actionID;
		return _TrasID;
    }
}