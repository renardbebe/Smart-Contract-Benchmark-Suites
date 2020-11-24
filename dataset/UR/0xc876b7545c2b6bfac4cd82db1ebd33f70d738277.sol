 

pragma solidity ^0.4.15;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

interface OraclizeI {
     
    function cbAddress() constant returns (address);  
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasoaurce) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}

interface OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}

 
contract myUsingOraclize is Ownable {
    OraclizeAddrResolverI OAR;
    OraclizeI public oraclize;
    uint public oraclize_gaslimit = 120000;

    function myUsingOraclize() {
        oraclize_setNetwork();
        update_oraclize();
    }

    function update_oraclize() onlyOwner public {
        oraclize = OraclizeI(OAR.getAddress());
    }

    function oraclize_query(string datasource, string arg1, string arg2) internal returns (bytes32 id) {
        uint price = oraclize.getPrice(datasource, oraclize_gaslimit);
        if (price > 1 ether + tx.gasprice*oraclize_gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, oraclize_gaslimit);
    }

    function oraclize_getPrice(string datasource) internal returns (uint) {
        return oraclize.getPrice(datasource, oraclize_gaslimit);
    }


    function setGasLimit(uint _newLimit) onlyOwner public {
        oraclize_gaslimit = _newLimit;
    }

    function oraclize_setNetwork() internal {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
        }
        else if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
        }
        else if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
        }
        else if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
        }
        else if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        else if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
        }
        else if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
        }
        else {
            revert();
        }
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
        return _size;
    }

     
     
    function parseAddr(string _a) internal returns (address){
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
}

 
contract InterCrypto is Ownable, myUsingOraclize {
     
    struct Conversion {
        address returnAddress;
        uint amount;
    }

    mapping (uint => Conversion) public conversions;
    uint conversionCount = 0;
    mapping (bytes32 => uint) oraclizeMyId2conversionID;
    mapping (address => uint) public recoverable;

     
    event ConversionStarted(uint indexed conversionID);
    event ConversionSentToShapeShift(uint indexed conversionID, address indexed returnAddress, address indexed depositAddress, uint amount);
    event ConversionAborted(uint indexed conversionID, string reason);
    event Recovered(address indexed recoveredTo, uint amount);

     
     
    function InterCrypto() {}

     
    function kill() onlyOwner external {
        selfdestruct(owner);
    }

     
    function () payable {}

     
    function convert1(string _coinSymbol, string _toAddress) external payable returns(uint) {
        return engine(_coinSymbol, _toAddress, msg.sender);
    }

     
    function convert2(string _coinSymbol, string _toAddress, address _returnAddress) external payable returns(uint) {
        return engine(_coinSymbol, _toAddress, _returnAddress);
    }

     
    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize.cbAddress()) revert();

        uint conversionID = oraclizeMyId2conversionID[myid];

        if( bytes(result).length == 0 ) {
            ConversionAborted(conversionID, "Oraclize return value was invalid, this is probably due to incorrect convert() argments");
            recoverable[conversions[conversionID].returnAddress] += conversions[conversionID].amount;
            conversions[conversionID].amount = 0;
        }
        else {
            address depositAddress = parseAddr(result);
            require(depositAddress != msg.sender);  
            uint sendAmount = conversions[conversionID].amount;
            conversions[conversionID].amount = 0;
            if (depositAddress.send(sendAmount)) {
                ConversionSentToShapeShift(conversionID, conversions[conversionID].returnAddress, depositAddress, sendAmount);
            }
            else {
                ConversionAborted(conversionID, "deposit to address returned by Oraclize failed");
                recoverable[conversions[conversionID].returnAddress] += sendAmount;
            }
        }
    }

     
     function cancelConversion(uint conversionID) external {
        Conversion memory conversion = conversions[conversionID];

        if (conversion.amount > 0) {
            require(msg.sender == conversion.returnAddress);
            recoverable[msg.sender] += conversion.amount;
            conversions[conversionID].amount = 0;
            ConversionAborted(conversionID, "conversion cancelled by creator");
        }
    }

     
     function recover() external {
        uint amount = recoverable[msg.sender];
        recoverable[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            Recovered(msg.sender, amount);
        }
        else {
            recoverable[msg.sender] = amount;
        }
    }
     
     
    function getInterCryptoPrice() constant public returns (uint) {
        return oraclize_getPrice('URL');
    }

     
     
    function engine(string _coinSymbol, string _toAddress, address _returnAddress) internal returns(uint conversionID) {
        conversionID = conversionCount++;

        if (
            !isValidString(_coinSymbol, 6) ||  
            !isValidString(_toAddress, 120)    
            ) {
            ConversionAborted(conversionID, "input parameters are too long or contain invalid symbols");
            recoverable[msg.sender] += msg.value;
            return;
        }

        uint oraclizePrice = getInterCryptoPrice();

        if (msg.value > oraclizePrice) {
            Conversion memory conversion = Conversion(_returnAddress, msg.value-oraclizePrice);
            conversions[conversionID] = Conversion(_returnAddress, msg.value-oraclizePrice);

            string memory postData = createShapeShiftConversionPost(_coinSymbol, _toAddress);
            bytes32 myQueryId = oraclize_query("URL", "json(https://shapeshift.io/shift).deposit", postData);

            if (myQueryId == 0) {
                ConversionAborted(conversionID, "unexpectedly high Oraclize price when calling oraclize_query");
                recoverable[msg.sender] += msg.value-oraclizePrice;
                conversions[conversionID].amount = 0;
                return;
            }
            oraclizeMyId2conversionID[myQueryId] = conversionID;
            ConversionStarted(conversionID);
        }
        else {
            ConversionAborted(conversionID, "Not enough Ether sent to cover Oraclize fee");
            conversions[conversionID].amount = 0;
            recoverable[msg.sender] += msg.value;
        }
    }

     
    function isValidString(string _string, uint maxSize) constant internal returns (bool allowed) {
        bytes memory stringBytes = bytes(_string);
        uint lengthBytes = stringBytes.length;
        if (lengthBytes < 1 ||
            lengthBytes > maxSize) {
            return false;
        }

        for (uint i = 0; i < lengthBytes; i++) {
            byte b = stringBytes[i];
            if ( !(
                (b >= 48 && b <= 57) ||  
                (b >= 65 && b <= 90) ||  
                (b >= 97 && b <= 122)    
            )) {
                return false;
            }
        }
        return true;
    }

     
    function concatBytes(bytes b1, bytes b2, bytes b3, bytes b4, bytes b5, bytes b6, bytes b7) internal returns (bytes bFinal) {
        bFinal = new bytes(b1.length + b2.length + b3.length + b4.length + b5.length + b6.length + b7.length);

        uint i = 0;
        uint j;
        for (j = 0; j < b1.length; j++) bFinal[i++] = b1[j];
        for (j = 0; j < b2.length; j++) bFinal[i++] = b2[j];
        for (j = 0; j < b3.length; j++) bFinal[i++] = b3[j];
        for (j = 0; j < b4.length; j++) bFinal[i++] = b4[j];
        for (j = 0; j < b5.length; j++) bFinal[i++] = b5[j];
        for (j = 0; j < b6.length; j++) bFinal[i++] = b6[j];
        for (j = 0; j < b7.length; j++) bFinal[i++] = b7[j];
    }

     
    function createShapeShiftConversionPost(string _coinSymbol, string _toAddress) internal returns (string sFinal) {
        string memory s1 = ' {"withdrawal":"';
        string memory s3 = '","pair":"eth_';
        string memory s5 = '","returnAddress":"';
        string memory s7 = '"}';

        bytes memory bFinal = concatBytes(bytes(s1), bytes(_toAddress), bytes(s3), bytes(_coinSymbol), bytes(s5), bytes(addressToBytes(msg.sender)), bytes(s7));

        sFinal = string(bFinal);
    }

     
    function nibbleToChar(uint nibble) internal returns (uint ret) {
        if (nibble > 9)
        return nibble + 87;  
        else
        return nibble + 48;  
    }

     
    function addressToBytes(address _address) internal returns (bytes) {
        uint160 tmp = uint160(_address);

         
        string memory holder = "                                        ";
        bytes memory ret = bytes(holder);

         
         
         
        uint j = 0;
        for (uint i = 0; i < 20; i++) {
            uint _tmp = tmp / (2 ** (8*(19-i)));  
            uint nb1 = (_tmp / 0x10) & 0x0f;      
            uint nb2 = _tmp & 0x0f;
            ret[j++] = byte(nibbleToChar(nb1));
            ret[j++] = byte(nibbleToChar(nb2));
        }

        return ret;
    }

     

}