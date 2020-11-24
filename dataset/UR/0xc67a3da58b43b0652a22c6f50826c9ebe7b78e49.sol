 

 
 

pragma solidity 0.4.19;


 
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


 
contract Pausable is Ownable {
    event OnPause();
    event OnUnpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        OnPause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        OnUnpause();
    }
}


 
contract ReentrancyGuard {
    bool private reentrancyLock = false;

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}


 
contract DateTime {
    function getMonth(uint timestamp) public pure returns (uint8);
    function getDay(uint timestamp) public pure returns (uint8);
}


 
contract OwnTheDayContract {
    function ownerOf(uint256 _tokenId) public view returns (address);
}


 
contract CryptoTorchToken {
    function contractBalance() public view returns (uint256);
    function totalSupply() public view returns(uint256);
    function balanceOf(address _playerAddress) public view returns(uint256);
    function dividendsOf(address _playerAddress) public view returns(uint256);
    function profitsOf(address _playerAddress) public view returns(uint256);
    function referralBalanceOf(address _playerAddress) public view returns(uint256);
    function sellPrice() public view returns(uint256);
    function buyPrice() public view returns(uint256);
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256);
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256);

    function sellFor(address _for, uint256 _amountOfTokens) public;
    function withdrawFor(address _for) public;
    function mint(address _to, uint256 _amountForTokens, address _referredBy) public payable returns(uint256);
}


 
contract CryptoTorch is Pausable, ReentrancyGuard {
    using SafeMath for uint256;

     
     
     
     
    event onTorchPassed(
        address indexed from,
        address indexed to,
        uint256 pricePaid
    );

     
     
     
     
    struct HighPrice {
        uint256 price;
        address owner;
    }

    struct HighMileage {
        uint256 miles;
        address owner;
    }

    struct PlayerData {
        string name;
        string note;
        string coords;
        uint256 dividends;  
        uint256 profits;    
        bool champion;      
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
    uint8 public constant maxLeaders = 3;  

    uint256 private _lowestHighPrice;
    uint256 private _lowestHighMiles;
    uint256 public whaleIncreaseLimit = 2 ether;
    uint256 public whaleMax = 20 ether;

    HighPrice[maxLeaders] private _highestPrices;
    HighMileage[maxLeaders] private _highestMiles;

    address[maxLeaders] public torchRunners;
    address internal donationsReceiver_;
    mapping (address => PlayerData) private playerData_;

    DateTime internal DateTimeLib_;
    CryptoTorchToken internal CryptoTorchToken_;
    OwnTheDayContract internal OwnTheDayContract_;
    string[3] internal holidayMap_;

     
     
     
     
     
     
    modifier antiWhalePrice(uint256 _amount) {
        require(
            whaleIncreaseLimit == 0 ||
            (
                _amount <= (whaleIncreaseLimit.add(_highestPrices[0].price)) &&
                playerData_[msg.sender].dividends.add(playerData_[msg.sender].profits).add(_amount) <= whaleMax
            )
        );
        _;
    }

     
     
     
     
     
    function CryptoTorch() public {
        torchRunners[0] = msg.sender;
    }

     
    function initialize(address _dateTimeAddress, address _tokenAddress, address _otdAddress) public onlyOwner {
        DateTimeLib_ = DateTime(_dateTimeAddress);
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
        OwnTheDayContract_ = OwnTheDayContract(_otdAddress);
        holidayMap_[0] = "10000110000001100000000000000101100000000011101000000000000011000000000000001001000010000101100010100110000100001000110000";
        holidayMap_[1] = "10111000100101000111000000100100000100010001001000100000000010010000000001000000110000000000000100000000010001100001100000";
        holidayMap_[2] = "01000000000100000101011000000110000001100000000100000000000011100001000100000000101000000000100000000000000000010011000001";
    }

     
    function setDateTimeLib(address _dateTimeAddress) public onlyOwner {
        DateTimeLib_ = DateTime(_dateTimeAddress);
    }

     
    function setTokenContract(address _tokenAddress) public onlyOwner {
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
    }

     
    function setOwnTheDayContract(address _otdAddress) public onlyOwner {
        OwnTheDayContract_ = OwnTheDayContract(_otdAddress);
    }

     
    function setDonationsReceiver(address _receiver) public onlyOwner {
        donationsReceiver_ = _receiver;
    }

     
    function setWhaleMax(uint256 _max) public onlyOwner {
        whaleMax = _max;
    }

     
    function setWhaleIncreaseLimit(uint256 _limit) public onlyOwner {
        whaleIncreaseLimit = _limit;
    }

     
    function updateHolidayState(uint8 _listIndex, string _holidayMap) public onlyOwner {
        require(_listIndex >= 0 && _listIndex < 3);
        holidayMap_[_listIndex] = _holidayMap;
    }

     
     
     
     
     
    function isHoliday(uint256 _dayIndex) public view returns (bool) {
        require(_dayIndex >= 0 && _dayIndex < 366);
        return (getHolidayByIndex_(_dayIndex) == 1);
    }

     
    function isHolidayToday() public view returns (bool) {
        uint256 _dayIndex = getDayIndex_(now);
        return (getHolidayByIndex_(_dayIndex) == 1);
    }

     
    function getTodayIndex() public view returns (uint256) {
        return getDayIndex_(now);
    }

     
    function getTodayOwnerName() public view returns (string) {
        address dayOwner = OwnTheDayContract_.ownerOf(getTodayIndex());
        return playerData_[dayOwner].name;  
    }

     
    function getTodayOwnerAddress() public view returns (address) {
        return OwnTheDayContract_.ownerOf(getTodayIndex());
    }

     
    function setAccountNickname(string _nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(_nickname).length > 0);
        playerData_[msg.sender].name = _nickname;
    }

     
    function getAccountNickname(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].name;
    }

     
    function setAccountNote(string _note) public whenNotPaused {
        require(msg.sender != address(0));
        playerData_[msg.sender].note = _note;
    }

     
    function getAccountNote(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].note;
    }

     
    function setAccountCoords(string _coords) public whenNotPaused {
        require(msg.sender != address(0));
        playerData_[msg.sender].coords = _coords;
    }

     
    function getAccountCoords(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].coords;
    }

     
    function isChampionAccount(address _playerAddress) public view returns (bool) {
        return playerData_[_playerAddress].champion;
    }

     
    function takeTheTorch(address _referredBy) public nonReentrant whenNotPaused payable {
        takeTheTorch_(msg.value, msg.sender, _referredBy);
    }

     
    function() payable public {
        if (msg.value > 0 && donationsReceiver_ != 0x0) {
            donationsReceiver_.transfer(msg.value);  
        }
    }

     
    function sell(uint256 _amountOfTokens) public {
        CryptoTorchToken_.sellFor(msg.sender, _amountOfTokens);
    }

     
    function withdrawDividends() public returns (uint256) {
        CryptoTorchToken_.withdrawFor(msg.sender);
        return withdrawFor_(msg.sender);
    }

     
     
     
     
     
    function torchContractBalance() public view returns (uint256) {
        return this.balance;
    }

     
    function tokenContractBalance() public view returns (uint256) {
        return CryptoTorchToken_.contractBalance();
    }

     
    function totalSupply() public view returns(uint256) {
        return CryptoTorchToken_.totalSupply();
    }

     
    function balanceOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.balanceOf(_playerAddress);
    }

     
    function tokenDividendsOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.dividendsOf(_playerAddress);
    }

     
    function referralDividendsOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.referralBalanceOf(_playerAddress);
    }

     
    function torchDividendsOf(address _playerAddress) public view returns(uint256) {
        return playerData_[_playerAddress].dividends;
    }

     
    function profitsOf(address _playerAddress) public view returns(uint256) {
        return playerData_[_playerAddress].profits.add(CryptoTorchToken_.profitsOf(_playerAddress));
    }

     
    function sellPrice() public view returns(uint256) {
        return CryptoTorchToken_.sellPrice();
    }

     
    function buyPrice() public view returns(uint256) {
        return CryptoTorchToken_.buyPrice();
    }

     
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256) {
        uint256 forTokens = _etherToSpend.sub(_etherToSpend.div(4));
        return CryptoTorchToken_.calculateTokensReceived(forTokens);
    }

     
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256) {
        return CryptoTorchToken_.calculateEtherReceived(_tokensToSell);
    }

     
    function getMaxPrice() public view returns (uint256) {
        if (whaleIncreaseLimit == 0) { return 0; }   
        return whaleIncreaseLimit.add(_highestPrices[0].price);
    }

     
    function getHighestPriceAt(uint _index) public view returns (uint256) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestPrices[_index].price;
    }

     
    function getHighestPriceOwnerAt(uint _index) public view returns (address) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestPrices[_index].owner;
    }

     
    function getHighestMilesAt(uint _index) public view returns (uint256) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestMiles[_index].miles;
    }

     
    function getHighestMilesOwnerAt(uint _index) public view returns (address) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestMiles[_index].owner;
    }

     
     
     
     
     
    function takeTheTorch_(uint256 _amountPaid, address _takenBy, address _referredBy) internal antiWhalePrice(_amountPaid) returns (uint256) {
        require(_takenBy != address(0));
        require(_amountPaid >= 5 finney);
        require(_takenBy != torchRunners[0]);  
        if (_referredBy == address(this)) { _referredBy = address(0); }

         
        address previousLast = torchRunners[2];
        torchRunners[2] = torchRunners[1];
        torchRunners[1] = torchRunners[0];
        torchRunners[0] = _takenBy;

         
        address dayOwner = OwnTheDayContract_.ownerOf(getDayIndex_(now));

         
        uint256 forDev = _amountPaid.mul(5).div(100);
        uint256 forTokens = _amountPaid.sub(_amountPaid.div(4));
        uint256 forPayout = _amountPaid.sub(forDev).sub(forTokens);
        uint256 forDayOwner = calculateDayOwnerCut_(forPayout);
        if (dayOwner == _takenBy) {
            forTokens = forTokens.add(forDayOwner);
            forPayout = _amountPaid.sub(forDev).sub(forTokens);
            playerData_[_takenBy].champion = true;
        } else {
            forPayout = forPayout.sub(forDayOwner);
        }

         
        onTorchPassed(torchRunners[1], _takenBy, _amountPaid);

         
        uint256 mintedTokens = CryptoTorchToken_.mint.value(forTokens)(_takenBy, forTokens, _referredBy);

         
        updateLeaders_(_takenBy, _amountPaid);

         
        handlePayouts_(forDev, forPayout, forDayOwner, _takenBy, previousLast, dayOwner);
        return mintedTokens;
    }

     
    function handlePayouts_(uint256 _forDev, uint256 _forPayout, uint256 _forDayOwner, address _takenBy, address _previousLast, address _dayOwner) internal {
        uint256[] memory runnerPortions = new uint256[](3);

         
         
         
        if (_previousLast != address(0)) {
            runnerPortions[2] = _forPayout.mul(10).div(100);
        }
        if (torchRunners[2] != address(0)) {
            runnerPortions[1] = _forPayout.mul(30).div(100);
        }
        runnerPortions[0] = _forPayout.sub(runnerPortions[1]).sub(runnerPortions[2]);

         
        playerData_[_previousLast].dividends = playerData_[_previousLast].dividends.add(runnerPortions[2]);
        playerData_[torchRunners[2]].dividends = playerData_[torchRunners[2]].dividends.add(runnerPortions[1]);
        playerData_[torchRunners[1]].dividends = playerData_[torchRunners[1]].dividends.add(runnerPortions[0]);

         
        playerData_[owner].profits = playerData_[owner].profits.add(_forDev);
        if (_dayOwner != _takenBy) {
            playerData_[_dayOwner].profits = playerData_[_dayOwner].profits.add(_forDayOwner);
        }

         
         
         
        owner.transfer(_forDev);
        if (_dayOwner != _takenBy) {
            _dayOwner.transfer(_forDayOwner);
        }
    }

     
    function withdrawFor_(address _for) internal returns (uint256) {
        uint256 torchDividends = playerData_[_for].dividends;
        if (playerData_[_for].dividends > 0) {
            playerData_[_for].dividends = 0;
            playerData_[_for].profits = playerData_[_for].profits.add(torchDividends);
            _for.transfer(torchDividends);
        }
        return torchDividends;
    }

     
    function updateLeaders_(address _takenBy, uint256 _amountPaid) internal {
         
        if (_takenBy == owner || _takenBy == donationsReceiver_) { return; }

         
        if (_amountPaid > _lowestHighPrice) {
            updateHighestPrices_(_amountPaid, _takenBy);
        }

         
        uint256 tokenBalance = CryptoTorchToken_.balanceOf(_takenBy);
        if (tokenBalance > _lowestHighMiles) {
            updateHighestMiles_(tokenBalance, _takenBy);
        }
    }

     
    function calculateDayOwnerCut_(uint256 _price) internal view returns (uint256) {
        if (getHolidayByIndex_(getDayIndex_(now)) == 1) {
            return _price.mul(25).div(100);
        }
        return _price.mul(10).div(100);
    }

     
    function getDayIndex_(uint timestamp) internal view returns (uint256) {
        uint8 day = DateTimeLib_.getDay(timestamp);
        uint8 month = DateTimeLib_.getMonth(timestamp);
         
        uint16[12] memory offset = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
        return offset[month-1] + day;
    }

     
    function getHolidayByIndex_(uint256 _dayIndex) internal view returns (uint result) {
        if (_dayIndex < 122) {
            return getFromList_(0, _dayIndex);
        }
        if (_dayIndex < 244) {
            return getFromList_(1, _dayIndex-122);
        }
        return getFromList_(2, _dayIndex-244);
    }
    function getFromList_(uint8 _idx, uint256 _dayIndex) internal view returns (uint result) {
        result = parseInt_(uint(bytes(holidayMap_[_idx])[_dayIndex]));
    }
    function parseInt_(uint c) internal pure returns (uint result) {
        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
        }
    }

     
    function updateHighestPrices_(uint256 _price, address _owner) internal {
        uint256 newPos = maxLeaders;
        uint256 oldPos = maxLeaders;
        uint256 i;
        HighPrice memory tmp;

         
        for (i = maxLeaders-1; i >= 0; i--) {
            if (_price >= _highestPrices[i].price) {
                newPos = i;
            }
            if (_owner == _highestPrices[i].owner) {
                oldPos = i;
            }
            if (i == 0) { break; }  
        }
         
        if (newPos < maxLeaders) {
            if (oldPos < maxLeaders-1) {
                 
                _highestPrices[oldPos].price = _price;
                if (newPos != oldPos) {
                     
                    tmp = _highestPrices[newPos];
                    _highestPrices[newPos] = _highestPrices[oldPos];
                    _highestPrices[oldPos] = tmp;
                }
            } else {
                 
                for (i = maxLeaders-1; i > newPos; i--) {
                    _highestPrices[i] = _highestPrices[i-1];
                }
                 
                _highestPrices[newPos].price = _price;
                _highestPrices[newPos].owner = _owner;
            }
             
            _lowestHighPrice = _highestPrices[maxLeaders-1].price;
        }
    }

     
    function updateHighestMiles_(uint256 _miles, address _owner) internal {
        uint256 newPos = maxLeaders;
        uint256 oldPos = maxLeaders;
        uint256 i;
        HighMileage memory tmp;

         
        for (i = maxLeaders-1; i >= 0; i--) {
            if (_miles >= _highestMiles[i].miles) {
                newPos = i;
            }
            if (_owner == _highestMiles[i].owner) {
                oldPos = i;
            }
            if (i == 0) { break; }  
        }
         
        if (newPos < maxLeaders) {
            if (oldPos < maxLeaders-1) {
                 
                _highestMiles[oldPos].miles = _miles;
                if (newPos != oldPos) {
                     
                    tmp = _highestMiles[newPos];
                    _highestMiles[newPos] = _highestMiles[oldPos];
                    _highestMiles[oldPos] = tmp;
                }
            } else {
                 
                for (i = maxLeaders-1; i > newPos; i--) {
                    _highestMiles[i] = _highestMiles[i-1];
                }
                 
                _highestMiles[newPos].miles = _miles;
                _highestMiles[newPos].owner = _owner;
            }
             
            _lowestHighMiles = _highestMiles[maxLeaders-1].miles;
        }
    }
}