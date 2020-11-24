 

pragma solidity ^0.4.18;

 

 
contract Auction {
    function bid() public payable returns (bool);
    function end() public returns (bool);

    event AuctionBid(address indexed from, uint256 value);
}

 

library Base {
    struct NTVUConfig {
        uint bidStartValue;
        int bidStartTime;
        int bidEndTime;

        uint tvUseStartTime;
        uint tvUseEndTime;

        bool isPrivate;
        bool special;
    }
}

 

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 

 
library SafeMath {
   
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

library StringUtils {
    function uintToString(uint v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }

        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }

        str = string(s);
    }

    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        require(source.length <= 32);

        if (source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function toBytes96(string memory text) internal pure returns (bytes32, bytes32, bytes32, uint8) {
        bytes memory temp = bytes(text);
        len = uint8(temp.length);
        require(len <= 96);

        uint8 i=0;
        uint8 j=0;
        uint8 k=0;

        string memory _b1 = new string(32);
        bytes memory b1 = bytes(_b1);

        string memory _b2 = new string(32);
        bytes memory b2 = bytes(_b2);

        string memory _b3 = new string(32);
        bytes memory b3 = bytes(_b3);

        uint8 len;

        for(i=0; i<len; i++) {
            k = i / 32;
            j = i % 32;

            if (k == 0) {
                b1[j] = temp[i];
            } else if(k == 1) {
                b2[j] = temp[i];
            } else if(k == 2) {
                b3[j] = temp[i];
            } 
        }

        return (bytesToBytes32(b1), bytesToBytes32(b2), bytesToBytes32(b3), len);
    }

    function fromBytes96(bytes32 b1, bytes32 b2, bytes32 b3, uint8 len) internal pure returns (string) {
        require(len <= 96);
        string memory _tmpValue = new string(len);
        bytes memory temp = bytes(_tmpValue);

        uint8 i;
        uint8 j = 0;

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b1[i];
        }

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b2[i];
        }

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b3[i];
        }

        return string(temp);
    }
}

 

 
contract NTVUToken is BasicToken, Ownable, Auction {
    string public name;
    string public symbol = "FOT";

    uint8 public number = 0;
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 1;

    uint public bidStartValue;
    uint public bidStartTime;
    uint public bidEndTime;

    uint public tvUseStartTime;
    uint public tvUseEndTime;

    bool public isPrivate = false;

    uint public maxBidValue;
    address public maxBidAccount;

    bool internal auctionEnded = false;

    string public text;  
    string public auditedText;  
    string public defaultText;  
    uint8 public auditStatus = 0;  

    uint32 public bidCount;
    uint32 public auctorCount;

    mapping(address => bool) acutors;

    address public ethSaver;  

     
    function NTVUToken(uint8 _number, uint _bidStartValue, uint _bidStartTime, uint _bidEndTime, uint _tvUseStartTime, uint _tvUseEndTime, bool _isPrivate, string _defaultText, address _ethSaver) public {
        number = _number;

        if (_number + 1 < 10) {
            symbol = StringUtils.concat(symbol, StringUtils.concat("0", StringUtils.uintToString(_number + 1)));
        } else {
            symbol = StringUtils.concat(symbol, StringUtils.uintToString(_number + 1));
        }

        name = symbol;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;

        bidStartValue = _bidStartValue;
        bidStartTime = _bidStartTime;
        bidEndTime = _bidEndTime;

        tvUseStartTime = _tvUseStartTime;
        tvUseEndTime = _tvUseEndTime;

        isPrivate = _isPrivate;

        defaultText = _defaultText;

        ethSaver = _ethSaver;
    }

     
    function bid() public payable returns (bool) {
        require(now >= bidStartTime);  
        require(now < bidEndTime);  
        require(msg.value >= bidStartValue);  
        require(msg.value >= maxBidValue + 0.05 ether);  
        require(!isPrivate || (isPrivate && maxBidAccount == address(0)));  

         
        if (maxBidAccount != address(0)) {
            maxBidAccount.transfer(maxBidValue);
        } 
        
        maxBidAccount = msg.sender;
        maxBidValue = msg.value;
        AuctionBid(maxBidAccount, maxBidValue);  

         
        bidCount++;

         
        bool bided = acutors[msg.sender];
        if (!bided) {
            auctorCount++;
            acutors[msg.sender] = true;
        }
    }

     
    function end() public returns (bool) {
        require(!auctionEnded);  
        require((now >= bidEndTime) || (isPrivate && maxBidAccount != address(0)));  
   
         
        if (maxBidAccount != address(0)) {
            address _from = owner;
            address _to = maxBidAccount;
            uint _value = INITIAL_SUPPLY;

             
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);  

             
            ethSaver.transfer(this.balance);
        }

        auctionEnded = true;
    }

     
    function setText(string _text) public {
        require(INITIAL_SUPPLY == balances[msg.sender]);  
        require(bytes(_text).length > 0 && bytes(_text).length <= 90);  
        require(now < tvUseStartTime - 30 minutes);  

        text = _text;
    }

    function getTextBytes96() public view returns(bytes32, bytes32, bytes32, uint8) {
        return StringUtils.toBytes96(text);
    }

     
    function auditText(uint8 _status, string _text) external onlyOwner {
        require((now >= tvUseStartTime - 30 minutes) && (now < tvUseEndTime));  
        auditStatus = _status;

        if (_status == 2) {  
            auditedText = _text;
        } else if (_status == 1) {  
            auditedText = text; 
        }
    }

     
    function getShowText() public view returns(string) {
        if (auditStatus == 1 || auditStatus == 2) {  
            return auditedText;
        } else {  
            return defaultText;
        }
    }

    function getShowTextBytes96() public view returns(bytes32, bytes32, bytes32, uint8) {
        return StringUtils.toBytes96(getShowText());
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(now >= tvUseEndTime);  

        super.transfer(_to, _value);
    }

     
    function getInfo() public view returns(
        string _symbol,
        string _name,
        uint _bidStartValue, 
        uint _bidStartTime, 
        uint _bidEndTime, 
        uint _tvUseStartTime,
        uint _tvUseEndTime,
        bool _isPrivate
        ) {
        _symbol = symbol;
        _name = name;

        _bidStartValue = bidStartValue;
        _bidStartTime = bidStartTime;
        _bidEndTime = bidEndTime;

        _tvUseStartTime = tvUseStartTime;
        _tvUseEndTime = tvUseEndTime;

        _isPrivate = isPrivate;
    }

     
    function getMutalbeInfo() public view returns(
        uint _maxBidValue,
        address _maxBidAccount,
        bool _auctionEnded,
        string _text,
        uint8 _auditStatus,
        uint8 _number,
        string _auditedText,
        uint32 _bidCount,
        uint32 _auctorCount
        ) {
        _maxBidValue = maxBidValue;
        _maxBidAccount = maxBidAccount;

        _auctionEnded = auctionEnded;

        _text = text;
        _auditStatus = auditStatus;

        _number = number;
        _auditedText = auditedText;

        _bidCount = bidCount;
        _auctorCount = auctorCount;
    }

     
    function reclaimEther() external onlyOwner {
        require((now > bidEndTime) || (isPrivate && maxBidAccount != address(0)));  
        ethSaver.transfer(this.balance);
    }

     
    function() payable public {
        bid();  
    }
}

 

 
contract NTVToken is Ownable {
    using SafeMath for uint256;

    bool public isRunning;  

    uint public onlineTime;  
    uint8 public totalTimeRange;  
    mapping(uint => address) internal timeRanges;  

    string public defaultText = "浪花有意千里雪，桃花无言一队春。";  

    mapping(uint8 => Base.NTVUConfig) internal dayConfigs;  
    mapping(uint8 => Base.NTVUConfig) internal specialConfigs;  

    address public ethSaver;  

    event OnTV(address indexed ntvu, address indexed winer, string text);  

     
    function NTVToken() public {}

     
    function startup(uint256 _onlineTime, address _ethSaver) public onlyOwner {
        require(!isRunning);  
        require((_onlineTime - 57600) % 1 days == 0);  
        require(_onlineTime >= now);  
        require(_ethSaver != address(0));

        onlineTime = _onlineTime;
        ethSaver = _ethSaver;

        isRunning = true;

         
         
         
         
         
         
        uint8[6] memory tvUseStartTimes = [0, 10, 12, 18, 20, 22];  
        uint8[6] memory tvUseEndTimes = [2, 12, 14, 20, 22, 24];  

        for (uint8 i=0; i<6; i++) {
            dayConfigs[i].bidStartValue = 0.1 ether;  
            dayConfigs[i].bidStartTime = 18 hours + 30 minutes - 1 days;  
            dayConfigs[i].bidEndTime = 22 hours - 1 days;  

            dayConfigs[i].tvUseStartTime = uint(tvUseStartTimes[i]) * 1 hours;
            dayConfigs[i].tvUseEndTime = uint(tvUseEndTimes[i]) * 1 hours;

            dayConfigs[i].isPrivate = false;  
        }

         
         
         

         
        for(uint8 p=0; p<6; p++) {
            specialConfigs[p].special = true;
            
            specialConfigs[p].bidStartValue = 0.1 ether;  
            specialConfigs[p].bidStartTime = 18 hours + 30 minutes - 2 days;  
            specialConfigs[p].bidEndTime = 22 hours - 1 days;  
            specialConfigs[p].isPrivate = false;  
        }
    }

     
    function time() constant internal returns (uint) {
        return block.timestamp;
    }

     
    function dayFor(uint timestamp) constant public returns (uint) {
        return timestamp < onlineTime
            ? 0
            : (timestamp.sub(onlineTime) / 1 days) + 1;
    }

     
    function numberFor(uint timestamp) constant public returns (uint8) {
        if (timestamp >= onlineTime) {
            uint current = timestamp.sub(onlineTime) % 1 days;

            for(uint8 i=0; i<6; i++) {
                if (dayConfigs[i].tvUseStartTime<=current && current<dayConfigs[i].tvUseEndTime) {
                    return (i + 1);
                }
            }
        }

        return 0;
    }

     
    function createNTVU() public onlyOwner {
        require(isRunning);

        uint8 number = totalTimeRange++;
        uint8 day = number / 6;
        uint8 num = number % 6;

        Base.NTVUConfig memory cfg = dayConfigs[num];  

         
        Base.NTVUConfig memory expCfg = specialConfigs[number];
        if (expCfg.special) {
            cfg.bidStartValue = expCfg.bidStartValue;
            cfg.bidStartTime = expCfg.bidStartTime;
            cfg.bidEndTime = expCfg.bidEndTime;
            cfg.isPrivate = expCfg.isPrivate;
        }

         
        uint bidStartTime = uint(int(onlineTime) + day * 24 hours + cfg.bidStartTime);
        uint bidEndTime = uint(int(onlineTime) + day * 24 hours + cfg.bidEndTime);
        uint tvUseStartTime = onlineTime + day * 24 hours + cfg.tvUseStartTime;
        uint tvUseEndTime = onlineTime + day * 24 hours + cfg.tvUseEndTime;

        timeRanges[number] = new NTVUToken(number, cfg.bidStartValue, bidStartTime, bidEndTime, tvUseStartTime, tvUseEndTime, cfg.isPrivate, defaultText, ethSaver);
    }

     
    function queryNTVUs(uint startIndex, uint count) public view returns(address[]){
        startIndex = (startIndex < totalTimeRange)? startIndex : totalTimeRange;
        count = (startIndex + count < totalTimeRange) ? count : (totalTimeRange - startIndex);

        address[] memory result = new address[](count);
        for(uint i=0; i<count; i++) {
            result[i] = timeRanges[startIndex + i];
        }

        return result;
    }

     
    function playingNTVU() public view returns(address){
        uint day = dayFor(time());
        uint8 num = numberFor(time());

        if (day>0 && (num>0 && num<=6)) {
            day = day - 1;
            num = num - 1;

            return timeRanges[day * 6 + uint(num)];
        } else {
            return address(0);
        }
    }

     
    function auditNTVUText(uint8 index, uint8 status, string _text) public onlyOwner {
        require(isRunning);  
        require(index >= 0 && index < totalTimeRange);  
        require(status==1 || (status==2 && bytes(_text).length>0 && bytes(_text).length <= 90));  

        address ntvu = timeRanges[index];
        assert(ntvu != address(0));

        NTVUToken ntvuToken = NTVUToken(ntvu);
        ntvuToken.auditText(status, _text);

        var (b1, b2, b3, len) = ntvuToken.getShowTextBytes96();
        var auditedText = StringUtils.fromBytes96(b1, b2, b3, len);
        OnTV(ntvuToken, ntvuToken.maxBidAccount(), auditedText);  
    }

     
    function getText() public view returns(string){
        address playing = playingNTVU();

        if (playing != address(0)) {
            NTVUToken ntvuToken = NTVUToken(playing);

            var (b1, b2, b3, len) = ntvuToken.getShowTextBytes96();
            return StringUtils.fromBytes96(b1, b2, b3, len);
        } else {
            return "";  
        }
    }

     
    function status() public view returns(uint8) {
        if (!isRunning) {
            return 0;  
        } else if (time() < onlineTime) {
            return 1;  
        } else {
            if (totalTimeRange == 0) {
                return 2;  
            } else {
                if (time() < NTVUToken(timeRanges[totalTimeRange - 1]).tvUseEndTime()) {
                    return 3;  
                } else {
                    return 4;  
                }
            }
        }
    }
    
     
    function totalAuctorCount() public view returns(uint32) {
        uint32 total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).auctorCount();
        }

        return total;
    }

     
    function totalBidCount() public view returns(uint32) {
        uint32 total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).bidCount();
        }

        return total;
    }

     
    function totalBidEth() public view returns(uint) {
        uint total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).balance;
        }

        total += this.balance;
        total += ethSaver.balance;

        return total;
    }

     
    function maxBidEth() public view returns(uint) {
        uint maxETH = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            uint val = NTVUToken(timeRanges[i]).maxBidValue();
            maxETH =  (val > maxETH) ? val : maxETH;
        }

        return maxETH;
    }

     
    function reclaimEther() public onlyOwner {
        require(isRunning);

        ethSaver.transfer(this.balance);
    }

     
    function reclaimNtvuEther(uint8 index) public onlyOwner {
        require(isRunning);
        require(index >= 0 && index < totalTimeRange);  

        NTVUToken(timeRanges[index]).reclaimEther();
    }

     
    function() payable external {}
}