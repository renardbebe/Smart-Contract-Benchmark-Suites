 

pragma solidity ^0.5.2;




 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EtherStake is Ownable {
  
    
  using SafeMath for uint;
   
  address payable public  leadAddress;
     
  address public reinvestmentContractAddress;
  address public withdrawalContractAddress;
   
  uint public stakeMultiplier;
  uint public totalStake;
  uint public day;
  uint public roundId;
  uint public roundEndTime;
  uint public startOfNewDay;
  uint public timeInADay;
  uint public timeInAWeek;
   
  mapping(address => string) public playerMessage;
  mapping(address => string) public playerName;
   
  uint8 constant playerMessageMinLength = 1;
  uint8 constant playerMessageMaxLength = 64;
  mapping (uint => uint) internal seed;  
  mapping (uint => uint) internal roundIdToDays;
  mapping (address => uint) public spentDivs;
   
  mapping(uint => mapping(uint => divKeeper)) public playerDivsInADay;
   
  event CashedOut(address _player, uint _amount);
  event InvestReceipt(
    address _player,
    uint _stakeBought);
    
    struct divKeeper {
      mapping(address => uint) playerStakeAtDay;
      uint totalStakeAtDay;
      uint revenueAtDay;
  } 

    constructor() public {
        roundId = 1;
        timeInADay = 86400;  
        timeInAWeek = 604800;  
        roundEndTime = now + timeInAWeek;  
        startOfNewDay = now + timeInADay;
        stakeMultiplier = 1100;
        totalStake = 1000000000; 
    }



    function() external payable {
        require(msg.value >= 10000000000000000 && msg.value < 1000000000000000000000, "0.01 ETH minimum.");  

        if(now > roundEndTime){  
            startNewRound();
        }

        uint stakeBought = msg.value.mul(stakeMultiplier);
        stakeBought = stakeBought.div(1000);
        playerDivsInADay[roundId][day].playerStakeAtDay[msg.sender] += stakeBought;
        leadAddress = msg.sender;
        totalStake += stakeBought;
        addTime(stakeBought);  
        emit InvestReceipt(msg.sender, stakeBought);
    }

     
    function buyStakeWithEth(address _referrer) public payable {
        require(msg.value >= 10000000000000000, "0.01 ETH minimum.");
        if(_referrer != address(0)){
                uint _referralBonus = msg.value.div(50);  
                if(_referrer == msg.sender) {
                    _referrer = 0x93D43eeFcFbE8F9e479E172ee5d92DdDd2600E3b;  
                }
                playerDivsInADay[roundId][day].playerStakeAtDay[_referrer] += _referralBonus;
        }
        if(now > roundEndTime){
            startNewRound();
        }

        uint stakeBought = msg.value.mul(stakeMultiplier);
        stakeBought = stakeBought.div(1000);
        playerDivsInADay[roundId][day].playerStakeAtDay[msg.sender] += stakeBought;
        leadAddress = msg.sender;
        totalStake += stakeBought;
        addTime(stakeBought);
        emit InvestReceipt(msg.sender, stakeBought);
    }
    

     
    function addMessage(string memory _message) public {
        bytes memory _messageBytes = bytes(_message);
        require(_messageBytes.length >= playerMessageMinLength, "Too short");
        require(_messageBytes.length <= playerMessageMaxLength, "Too long");
        playerMessage[msg.sender] = _message;
    }
    function getMessage(address _playerAddress)
    external
    view
    returns (
      string memory playerMessage_
  ) {
      playerMessage_ = playerMessage[_playerAddress];
  }
       
    function addName(string memory _name) public {
        bytes memory _messageBytes = bytes(_name);
        require(_messageBytes.length >= playerMessageMinLength, "Too short");
        require(_messageBytes.length <= playerMessageMaxLength, "Too long");
        playerName[msg.sender] = _name;
    }
  
    function getName(address _playerAddress)
    external
    view
    returns (
      string memory playerName_
  ) {
      playerName_ = playerName[_playerAddress];
  }
   
    
    function getPlayerCurrentRoundDivs(address _playerAddress) public view returns(uint playerTotalDivs) {
        uint _playerTotalDivs;
        uint _playerRollingStake;
        for(uint c = 0 ; c < day; c++) {  
            uint _playerStakeAtDay = playerDivsInADay[roundId][c].playerStakeAtDay[_playerAddress];
            if(_playerStakeAtDay == 0 && _playerRollingStake == 0){
                    continue;  
                }
            _playerRollingStake += _playerStakeAtDay;
            uint _revenueAtDay = playerDivsInADay[roundId][c].revenueAtDay;
            uint _totalStakeAtDay = playerDivsInADay[roundId][c].totalStakeAtDay;
            uint _playerShareAtDay = _playerRollingStake.mul(_revenueAtDay)/_totalStakeAtDay;
            _playerTotalDivs += _playerShareAtDay;
        }
        return _playerTotalDivs.div(2);  
    }
    
    function getPlayerPreviousRoundDivs(address _playerAddress) public view returns(uint playerPreviousRoundDivs) {
        uint _playerPreviousRoundDivs;
        for(uint r = 1 ; r < roundId; r++) {  
            uint _playerRollingStake;
            uint _lastDay = roundIdToDays[r];
            for(uint p = 0 ; p < _lastDay; p++) {  
                uint _playerStakeAtDay = playerDivsInADay[r][p].playerStakeAtDay[_playerAddress];
                if(_playerStakeAtDay == 0 && _playerRollingStake == 0){
                        continue;  
                    }
                _playerRollingStake += _playerStakeAtDay;
                uint _revenueAtDay = playerDivsInADay[r][p].revenueAtDay;
                uint _totalStakeAtDay = playerDivsInADay[r][p].totalStakeAtDay;
                uint _playerShareAtDay = _playerRollingStake.mul(_revenueAtDay)/_totalStakeAtDay;
                _playerPreviousRoundDivs += _playerShareAtDay;
            }
        }
        return _playerPreviousRoundDivs.div(2);  
    }
    
    function getPlayerTotalDivs(address _playerAddress) public view returns(uint PlayerTotalDivs) {
        uint _playerTotalDivs;
        _playerTotalDivs += getPlayerPreviousRoundDivs(_playerAddress);
        _playerTotalDivs += getPlayerCurrentRoundDivs(_playerAddress);
        
        return _playerTotalDivs;
    }
    
    function getPlayerCurrentStake(address _playerAddress) public view returns(uint playerCurrentStake) {
        uint _playerRollingStake;
        for(uint c = 0 ; c <= day; c++) {  
            uint _playerStakeAtDay = playerDivsInADay[roundId][c].playerStakeAtDay[_playerAddress];
            if(_playerStakeAtDay == 0 && _playerRollingStake == 0){
                    continue;  
                }
            _playerRollingStake += _playerStakeAtDay;
        }
        return _playerRollingStake;
    }
    

     
    function reinvestDivs(uint _divs) external{
        require(_divs >= 10000000000000000, "You need at least 0.01 ETH in dividends.");
        uint _senderDivs = getPlayerTotalDivs(msg.sender);
        spentDivs[msg.sender] += _divs;
        uint _spentDivs = spentDivs[msg.sender];
        uint _availableDivs = _senderDivs.sub(_spentDivs);
        require(_availableDivs >= 0);
        if(now > roundEndTime){
            startNewRound();
        }
        playerDivsInADay[roundId][day].playerStakeAtDay[msg.sender] += _divs;
        leadAddress = msg.sender;
        totalStake += _divs;
        addTime(_divs);
        emit InvestReceipt(msg.sender, _divs);
    }
     
    function withdrawDivs(uint _divs) external{
        require(_divs >= 10000000000000000, "You need at least 0.01 ETH in dividends.");
        uint _senderDivs = getPlayerTotalDivs(msg.sender);
        spentDivs[msg.sender] += _divs;
        uint _spentDivs = spentDivs[msg.sender];
        uint _availableDivs = _senderDivs.sub(_spentDivs);
        require(_availableDivs >= 0);
        msg.sender.transfer(_divs);
        emit CashedOut(msg.sender, _divs);
    }
     
    function reinvestDivsWithContract(address payable _reinvestor) external{ 
        require(msg.sender == reinvestmentContractAddress);
        uint _senderDivs = getPlayerTotalDivs(_reinvestor);
        uint _spentDivs = spentDivs[_reinvestor];
        uint _availableDivs = _senderDivs.sub(_spentDivs);
        spentDivs[_reinvestor] += _senderDivs;
        require(_availableDivs >= 10000000000000000, "You need at least 0.01 ETH in dividends.");
        if(now > roundEndTime){
            startNewRound();
        }
        playerDivsInADay[roundId][day].playerStakeAtDay[_reinvestor] += _availableDivs;
        leadAddress = _reinvestor;
        totalStake += _availableDivs;
        addTime(_availableDivs);
        emit InvestReceipt(msg.sender, _availableDivs);
    }
     
    function withdrawDivsWithContract(address payable _withdrawer) external{ 
        require(msg.sender == withdrawalContractAddress);
        uint _senderDivs = getPlayerTotalDivs(_withdrawer);
        uint _spentDivs = spentDivs[_withdrawer];
        uint _availableDivs = _senderDivs.sub(_spentDivs);
        spentDivs[_withdrawer] += _availableDivs;
        require(_availableDivs >= 0);
        _withdrawer.transfer(_availableDivs);
        emit CashedOut(_withdrawer, _availableDivs);
    }
    
     
    function addTime(uint _stakeBought) private {
        uint _timeAdd = _stakeBought/1000000000000;  
        if(_timeAdd < timeInADay){
            roundEndTime += _timeAdd;
        }else{
        roundEndTime += timeInADay;  
        }
            
        if(now > startOfNewDay) {  
            startNewDay();
        }
    }
    
    function startNewDay() private {
        playerDivsInADay[roundId][day].totalStakeAtDay = totalStake;
        playerDivsInADay[roundId][day].revenueAtDay = totalStake - playerDivsInADay[roundId][day-1].totalStakeAtDay;  
        if(stakeMultiplier > 1000) {
            stakeMultiplier -= 1;
        }
        startOfNewDay = now + timeInADay;
        ++day;
    }

    function startNewRound() private { 
        playerDivsInADay[roundId][day].totalStakeAtDay = totalStake;  
        playerDivsInADay[roundId][day].revenueAtDay = totalStake - playerDivsInADay[roundId][day-1].totalStakeAtDay;  
        roundIdToDays[roundId] = day;  
        jackpot();
        resetRound();
    }
    function jackpot() private {
        uint winnerShare = playerDivsInADay[roundId][day].totalStakeAtDay.div(2) + seed[roundId];  
        seed[roundId+1] = totalStake.div(10);  
        winnerShare -= seed[roundId+1];
        leadAddress.transfer(winnerShare);
        emit CashedOut(leadAddress, winnerShare);
    }
    function resetRound() private {
        roundId += 1;
        roundEndTime = now + timeInAWeek;   
        startOfNewDay = now;  
        day = 0;
        stakeMultiplier = 1100;
        totalStake = 10000000;
    }

    function returnTimeLeft()
     public view
     returns(uint256) {
     return(roundEndTime.sub(now));
     }
     
    function returnDayTimeLeft()
     public view
     returns(uint256) {
     return(startOfNewDay.sub(now));
     }
     
    function returnSeedAtRound(uint _roundId)
     public view
     returns(uint256) {
     return(seed[_roundId]);
     }
    function returnjackpot()
     public view 
     returns(uint256){
        uint winnerShare = totalStake/2 + seed[roundId];  
        uint nextseed = totalStake/10;  
        winnerShare -= nextseed;
        return winnerShare;
    }
    function returnEarningsAtDay(uint256 _roundId, uint256 _day, address _playerAddress)
     public view 
     returns(uint256){
        uint earnings = playerDivsInADay[_roundId][_day].playerStakeAtDay[_playerAddress];
        return earnings;
    }
      function setWithdrawalAndReinvestmentContracts(address _withdrawalContractAddress, address _reinvestmentContractAddress) external onlyOwner {
    withdrawalContractAddress = _withdrawalContractAddress;
    reinvestmentContractAddress = _reinvestmentContractAddress;
  }
}

contract WithdrawalContract {
    
    address payable public etherStakeAddress;
    address payable public owner;
    
    
    constructor(address payable _etherStakeAddress) public {
        etherStakeAddress = _etherStakeAddress;
        owner = msg.sender;
    }
    
    function() external payable{
        require(msg.value >= 10000000000000000, "0.01 ETH Fee");
        EtherStake instanceEtherStake = EtherStake(etherStakeAddress);
        instanceEtherStake.withdrawDivsWithContract(msg.sender);
    }
    
    function collectFees() external {
        owner.transfer(address(this).balance);
    }
}