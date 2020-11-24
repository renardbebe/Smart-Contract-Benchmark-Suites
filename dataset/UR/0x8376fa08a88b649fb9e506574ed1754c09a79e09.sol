 

pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    
     
     

     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
         
        totalSupply = initialSupply;
         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) internal
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        internal
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

}

 
 
 

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) internal  {
         
         
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
         
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     

     
     
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        if (sellPrice>0) {
            msg.sender.transfer(amount * sellPrice);           
        }
        totalSupply -= amount;
    }
    
    function getBalance(address target)  view public returns (uint256){
        return balanceOf[target];
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
    
    
}


interface token {
    function transfer(address receiver, uint amount) public;
}


contract ScavengerHuntTokenWatch is MyAdvancedToken {
    uint public crowdsaleDeadline;
    uint public tokensDistributed;
    uint public totalHunters;
    uint public maxDailyRewards;
    string public scavengerHuntTokenName;
    string public scavengerHuntTokenSymbol;

     
    mapping (address => bytes32) public registeredNames;

     
     
    mapping (bytes32 => mapping (bytes32 => uint)) public GPSDigs;

     
    mapping (bytes32 => mapping (bytes32 => address)) public GPSActivityAddress;

     
    mapping (address => mapping(uint => uint256) ) public dailyRewardCount;
    
    
    
     
    uint256 digHashBase;
    bool crowdsaleClosed = false;

    event FundTransfer(address backer, uint amountEhter, uint amountScavengerHuntTokens, bool isContribution);
    event ShareLocation(address owner, uint ScavengerHuntTokenAmount, uint PercentageOfTotal, bytes32 GPSLatitude, bytes32 GPSLongitude);
    event ShareMessage(address recipient, string Message, string TokenName);
    event SaleEnded(address owner, uint totalTokensDistributed,uint totalHunters);
    event SharePersonalMessage(address Sender, string MyPersonalMessage, bytes32 GPSLatitude, bytes32 GPSLongitude);
    event NameClaimed(address owner, string Name, bytes32 GPSLatitude, bytes32 GPSLongitude);
    event HunterRewarded(address owner, uint ScavengerHuntTokenAmount, uint PercentageOfTotal, bytes32 GPSLatitude, bytes32 GPSLongitude);
    
    modifier afterDeadline() { if (now >= crowdsaleDeadline) _; }
    

     
    function checkDeadlinePassed() afterDeadline public {
        SaleEnded(owner, tokensDistributed,totalHunters);
        crowdsaleClosed = true;
    }

    
     
     function ScavengerHuntTokenWatch (
        address ifSuccessfulSendTo,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        uint initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 adigHashBase,
        uint aMaxDailyRewards
        ) MyAdvancedToken(initialSupply, tokenName, tokenSymbol) public {
        owner=msg.sender;
        
        scavengerHuntTokenName = tokenName;
        scavengerHuntTokenSymbol = tokenSymbol;

         
        setPrices(0,weiCostOfEachToken * 1 wei);
       
        digHashBase = adigHashBase;
        maxDailyRewards = aMaxDailyRewards;

        crowdsaleDeadline = now + durationInMinutes * 1 minutes;
        tokensDistributed = initialSupply;
        FundTransfer(ifSuccessfulSendTo, 0, tokensDistributed, true);

         
        owner = ifSuccessfulSendTo;
        totalHunters=1;
        balanceOf[owner] = initialSupply;
        

    }


    function destroySHT(address _from, uint256 _value) internal {
        require(balanceOf[_from] >= _value);                 
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
        if(balanceOf[_from]==0) {
            totalHunters--;
        }
    }

    

    function extendCrowdsalePeriod (uint durationInMinutes) onlyOwner public {
        crowdsaleDeadline = now + durationInMinutes * 1 minutes;
        crowdsaleClosed = false;
        ShareMessage(msg.sender,"The crowdsale is extended for token ->",scavengerHuntTokenName );
    }

    function setMaxDailyRewards(uint aMaxDailyRewards) onlyOwner public {
        maxDailyRewards = aMaxDailyRewards;
        ShareMessage(msg.sender,"The maximum of daily reward is now updated for token ->",scavengerHuntTokenName );
    }

    

     
    function buyScavengerHuntToken() payable public {
         
        if (crowdsaleClosed) {
            ShareMessage(msg.sender,"Sorry: The crowdsale has ended. You cannot buy anymore ->",scavengerHuntTokenName );
        }
        require(!crowdsaleClosed);
        uint amountEth = msg.value;
        uint amountSht = amountEth / buyPrice;

         
        mintScavengerToken(msg.sender, amountSht);

        FundTransfer(msg.sender, amountEth, amountSht, true);
        
        
         
        checkDeadlinePassed();
    }

    
    function buyScavengerHuntTokenWithLocationSharing(bytes32 GPSLatitude, bytes32 GPSLongitude) payable public {
        buyScavengerHuntToken();
        ShareLocation(msg.sender, balanceOf[msg.sender],getPercentageComplete(msg.sender), GPSLatitude, GPSLongitude);
    }

    
     
    function () payable public {
        buyScavengerHuntToken();
    }

    
     
     
     
    function mintScavengerToken(address target, uint256 mintedAmount) private {
        if(balanceOf[target]==0) {
             
            totalHunters++;
        }else {}
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(this, target, mintedAmount);
        tokensDistributed += mintedAmount;
    }


     
     
     
    function mintExtraScavengerHuntTokens(address target, uint256 mintedAmount) onlyOwner public {
        mintScavengerToken(target, mintedAmount);
    }



    function shareScavengerHuntTokenLocation(bytes32 GPSLatitude, bytes32 GPSLongitude) public {
         
        require(balanceOf[msg.sender] > 0); 
        ShareLocation(msg.sender, balanceOf[msg.sender],getPercentageComplete(msg.sender), GPSLatitude, GPSLongitude);
    }

    function sharePersonalScavengerHuntTokenMessage(string MyPersonalMessage, bytes32 GPSLatitude, bytes32 GPSLongitude) public {
         
        require(balanceOf[msg.sender] >=1); 
        SharePersonalMessage(msg.sender, MyPersonalMessage, GPSLatitude, GPSLongitude);
         
        destroySHT(msg.sender, 1);
    }

    function claimName(string MyName, bytes32 GPSLatitude, bytes32 GPSLongitude) public {
         
        require(bytes(MyName).length < 32);
        require(balanceOf[msg.sender] >= 10); 
        registeredNames[msg.sender]=getStringAsKey(MyName);
        NameClaimed(msg.sender, MyName, GPSLatitude, GPSLongitude);
         
        destroySHT(msg.sender, 10);
    }

    
    function transferScavengerHuntToken(address to, uint SHTokenAmount,bytes32 GPSLatitude, bytes32 GPSLongitude) public {
         
        if(balanceOf[to]==0) {
            totalHunters++;
        }

         
        _transfer(msg.sender, to, SHTokenAmount);

        ShareLocation(to, balanceOf[to], getPercentageComplete(to), "unknown", "unknown");
        ShareLocation(msg.sender, balanceOf[msg.sender], getPercentageComplete(msg.sender), GPSLatitude, GPSLongitude);
        if(balanceOf[msg.sender]==0) {
            totalHunters--;
        }

    }

    function returnEtherumToOwner(uint amount) onlyOwner public {
        if (owner.send(amount)) {
            FundTransfer(owner, amount,0, false);
        } 
    }

     

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;
    
    function leapYearsBefore(uint year) internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }    
    
    function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
    }
    
    function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
    }

    
    function getToday() public view returns (uint) {
        uint16 year;
        uint8 month;
        uint8 day;

        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        
        uint timestamp=now;
        
         
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);

         
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                    month = i;
                    break;
            }
            secondsAccountedFor += secondsInMonth;
        }

         
        for (i = 1; i <= getDaysInMonth(month, year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        day = i;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }
        
         
        uint endDate = uint(year) * 10000;
        if (month<10) {
            endDate += uint(month)*100;
        } else {
            endDate += uint(month)*10;
        }
        endDate += uint(day);
        return endDate;
        
    }

    function getYear(uint timestamp) internal pure returns (uint16) {
            uint secondsAccountedFor = 0;
            uint16 year;
            uint numLeapYears;

             
            year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
            numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
            secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

            while (secondsAccountedFor > timestamp) {
                    if (isLeapYear(uint16(year - 1))) {
                            secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            secondsAccountedFor -= YEAR_IN_SECONDS;
                    }
                    year -= 1;
            }
            return year;
    }

    
    function hashSeriesNumber(bytes32 series, uint256 number) internal pure returns (bytes32){
        return keccak256(number, series);
    }
    
    function digRewardCheck(uint hash, uint modulo,uint reward,bytes32 GPSLatitude, bytes32 GPSLongitude) internal returns (uint256) {
        if (hash % modulo == 0) {
             
            mintScavengerToken(msg.sender, reward);
            dailyRewardCount[msg.sender][getToday()]++;
            GPSDigs[GPSLatitude][GPSLongitude]=reward;
            GPSActivityAddress[GPSLatitude][GPSLongitude]=msg.sender;
            HunterRewarded(msg.sender, reward,getPercentageComplete(msg.sender), GPSLatitude, GPSLongitude);
            return reward;
        }
        else {
            return 0;
        }
    }

    function digForTokens(bytes32 GPSLatitude, bytes32 GPSLongitude) payable public returns(uint256) {
         
        require(balanceOf[msg.sender] > 1); 
         
        require(GPSDigs[GPSLatitude][GPSLongitude] == 0); 

         
        require( dailyRewardCount[msg.sender][getToday()] <= maxDailyRewards);
        
         
        destroySHT(msg.sender, 1);

        uint hash = uint(hashSeriesNumber(GPSLatitude,digHashBase));
        hash += uint(hashSeriesNumber(GPSLongitude,digHashBase));

        uint awarded = digRewardCheck(hash, 100000000,100000,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }

        awarded = digRewardCheck(hash, 100000,1000,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }
        
        awarded = digRewardCheck(hash, 10000,500,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }

        awarded = digRewardCheck(hash, 1000,200,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }

        awarded = digRewardCheck(hash, 100,50,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }

        awarded = digRewardCheck(hash, 10,3,GPSLatitude,GPSLongitude);
        if (awarded>0) {
            return awarded;
        }
        
         
        GPSDigs[GPSLatitude][GPSLongitude]=1;
        GPSActivityAddress[GPSLatitude][GPSLongitude]=msg.sender;
        HunterRewarded(msg.sender, 0,getPercentageComplete(msg.sender), GPSLatitude, GPSLongitude);
        return 0;
    }
    
    
    function getPercentageComplete(address ScavengerHuntTokenOwner)  view public returns (uint256){
         
        uint256 myBalance = balanceOf[ScavengerHuntTokenOwner]*100000.0;
        uint256 myTotalSupply = totalSupply;
        uint256 myResult = myBalance / myTotalSupply;
        return  myResult;
    }

    function getStringAsKey(string key) pure public returns (bytes32 ret) {
        require(bytes(key).length < 32);
        assembly {
          ret := mload(add(key, 32))
        }
    }
    
    function getKeyAsString(bytes32 x) pure public returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    modifier aftercrowdsaleDeadline()  { if (now >= crowdsaleDeadline) _; }
    
}