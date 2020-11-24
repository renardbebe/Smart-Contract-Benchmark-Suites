 

 


 
library strUtils {
    string constant CHAINY_JSON_ID = '"id":"CHAINY"';
    uint8 constant CHAINY_JSON_MIN_LEN = 32;

     
    function toBase58(uint256 _value, uint8 _maxLength) internal returns (string) {
        string memory letters = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
        bytes memory alphabet = bytes(letters);
        uint8 base = 58;
        uint8 len = 0;
        uint256 remainder = 0;
        bool needBreak = false;
        bytes memory bytesReversed = bytes(new string(_maxLength));

        for (uint8 i = 0; i < _maxLength; i++) {
            if(_value < base){
                needBreak = true;
            }
            remainder = _value % base;
            _value = uint256(_value / base);
            bytesReversed[i] = alphabet[remainder];
            len++;
            if(needBreak){
                break;
            }
        }

         
        bytes memory result = bytes(new string(len));
        for (i = 0; i < len; i++) {
            result[i] = bytesReversed[len - i - 1];
        }
        return string(result);
    }

     
    function concat(string _s1, string _s2) internal returns (string) {
        bytes memory bs1 = bytes(_s1);
        bytes memory bs2 = bytes(_s2);
        string memory s3 = new string(bs1.length + bs2.length);
        bytes memory bs3 = bytes(s3);

        uint256 j = 0;
        for (uint256 i = 0; i < bs1.length; i++) {
            bs3[j++] = bs1[i];
        }
        for (i = 0; i < bs2.length; i++) {
            bs3[j++] = bs2[i];
        }

        return string(bs3);
    }

     
    function isValidChainyJson(string _json) internal returns (bool) {
        bytes memory json = bytes(_json);
        bytes memory id = bytes(CHAINY_JSON_ID);

        if (json.length < CHAINY_JSON_MIN_LEN) {
            return false;
        } else {
            uint len = 0;
            if (json[1] == id[0]) {
                len = 1;
                while (len < id.length && (1 + len) < json.length && json[1 + len] == id[len]) {
                    len++;
                }
                if (len == id.length) {
                    return true;
                }
            }
        }

        return false;
    }
}


 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract Chainy is owned {
     
    string CHAINY_URL;

     
    mapping(string => uint256) private chainyConfig;

     
    mapping (address => bool) private srvAccount;

     
    address private receiverAddress;

    struct data {uint256 timestamp; string json; address sender;}
    mapping (string => data) private chainy;

    event chainyShortLink(uint256 timestamp, string code);

     
    function Chainy(){
        setConfig("fee", 0);
         
        setConfig("blockoffset", 2000000);
        setChainyURL("https://txn.me/");
    }

     
    function setChainyURL(string _url) onlyOwner {
        CHAINY_URL = _url;
    }

     
    function getChainyURL() constant returns(string){
        return CHAINY_URL;
    }

     
    function setConfig(string _key, uint256 _value) onlyOwner {
        chainyConfig[_key] = _value;
    }

     
    function getConfig(string _key) constant returns (uint256 _value) {
        return chainyConfig[_key];
    }

     
    function setServiceAccount(address _address, bool _value) onlyOwner {
        srvAccount[_address] = _value;
    }

     
    function setReceiverAddress(address _address) onlyOwner {
        receiverAddress = _address;
    }

     
    function releaseFunds() onlyOwner {
        if(!owner.send(this.balance)) throw;
    }

     
    function addChainyData(string json) {
        checkFormat(json);

        var code = generateShortLink();
         
        if (getChainyTimestamp(code) > 0) throw;

        processFee();
        chainy[code] = data({
            timestamp: block.timestamp,
            json: json,
            sender: tx.origin
        });

         
        var link = strUtils.concat(CHAINY_URL, code);
        chainyShortLink(block.timestamp, link);
    }

     
    function getChainyTimestamp(string code) constant returns (uint256) {
        return chainy[code].timestamp;
    }

     
    function getChainyData(string code) constant returns (string) {
        return chainy[code].json;
    }

     
    function getChainySender(string code) constant returns (address) {
        return chainy[code].sender;
    }

     
    function processFee() internal {
        var fee = getConfig("fee");
        if (srvAccount[msg.sender] || (fee == 0)) return;

        if (msg.value < fee)
            throw;
        else
            if (!receiverAddress.send(fee)) throw;
    }

     
    function checkFormat(string json) internal {
        if (!strUtils.isValidChainyJson(json)) throw;
    }

     
    function generateShortLink() internal returns (string) {
        var s1 = strUtils.toBase58(block.number - getConfig("blockoffset"), 11);
        var s2 = strUtils.toBase58(uint256(tx.origin), 2);

        var s = strUtils.concat(s1, s2);
        return s;
    }

}