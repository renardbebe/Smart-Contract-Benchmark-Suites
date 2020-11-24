 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
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

 
contract ERC20 {
    function allowance(address owner, address spender) public constant returns (uint256);
    function balanceOf(address who) public constant returns  (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract FutureGame {

    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    using SafeMath for uint8;
    
     
    address public owner;
    address private nextOwner;

     
    address ERC20ContractAddres;
    address ERC20WalletAddress;

    bool IsEther = false;
    bool IsInitialized = false;
    uint256 BaseTimestamp = 1534377600;  
    uint StartBetTime = 0;
    uint LastBetTime = 0;
    uint SettleBetTime = 0;
    uint FinalAnswer;
    uint LoseTokenRate; 
    
     
    uint256 optionOneAmount = 0;
    uint256 optionTwoAmount = 0;
    uint256 optionThreeAmount = 0;
    uint256 optionFourAmount = 0;
    uint256 optionFiveAmount = 0;
    uint256 optionSixAmount = 0;
    
     
    uint256 optionOneLimit = 0;
    uint256 optionTwoLimit = 0;
    uint256 optionThreeLimit = 0;
    uint256 optionFourLimit = 0;
    uint256 optionFiveLimit = 0;
    uint256 optionSixLimit = 0;

     
    mapping(address => uint256) optionOneBet;
    mapping(address => uint256) optionTwoBet;
    mapping(address => uint256) optionThreeBet;
    mapping(address => uint256) optionFourBet;
    mapping(address => uint256) optionFiveBet;
    mapping(address => uint256) optionSixBet;

    uint256 feePool = 0;
    
     
    event BetLog(address playerAddress, uint256 amount, uint256 Option);
    event OpenBet(uint AnswerOption);

     
    mapping(address => uint256) EtherBalances;
    mapping(address => uint256) TokenBalances;

    constructor () public{
        owner = msg.sender;
        IsInitialized = true;
    }
    
     
    function initialize(uint256 _StartBetTime, uint256 _LastBetTime, uint256 _SettleBetTime,
                        uint256 _optionOneLimit, uint256 _optionTwoLimit, uint256 _optionThreeLimit,
                        uint256 _optionFourLimit, uint256 _optionFiveLimit, uint256 _optionSixLimit,
                        uint256 _LoseTokenRate, address _ERC20Contract, address _ERC20Wallet,
                        bool _IsEther) public {
        require( _LastBetTime > _StartBetTime);
        require(_SettleBetTime > _LastBetTime);
         
        StartBetTime = _StartBetTime;
        LastBetTime = _LastBetTime;
        SettleBetTime = _SettleBetTime;
        LoseTokenRate = _LoseTokenRate;
        
         
        optionOneLimit = _optionOneLimit;
        optionTwoLimit = _optionTwoLimit;
        optionThreeLimit = _optionThreeLimit;
        optionFourLimit = _optionFourLimit;
        optionFiveLimit = _optionFiveLimit;
        optionSixLimit = _optionSixLimit;
        
        ERC20ContractAddres = _ERC20Contract;
        ERC20WalletAddress = _ERC20Wallet;
        IsEther = _IsEther;
    
        IsInitialized = true;
    }
    
     
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

     
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

     
    function () public payable
    {
        revert();
    }

     
    function PlaceBet(uint optionNumber) public payable 
    {
        require(LastBetTime > now);
         
        require(IsInitialized == true,'This is not opened yet.');
        require(IsEther == true, 'This is a Token Game');
        require(msg.value >= 0.01 ether);

        uint256 _amount = msg.value;
        if(optionNumber == 1){
            require( optionOneAmount.add(_amount) <= optionOneLimit );
            optionOneBet[msg.sender] = optionOneBet[msg.sender].add(_amount);
            optionOneAmount = optionOneAmount.add(_amount);
        }else if(optionNumber == 2){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionTwoBet[msg.sender] = optionTwoBet[msg.sender].add(_amount);
            optionTwoAmount = optionTwoAmount.add(_amount);
        }else if(optionNumber == 3){
            require( optionThreeAmount.add(_amount) <= optionThreeLimit );
            optionThreeBet[msg.sender] = optionThreeBet[msg.sender].add(_amount);
            optionThreeAmount = optionThreeAmount.add(_amount);
        }else if(optionNumber == 4){
            require( optionFourAmount.add(_amount) <= optionFourLimit );
            optionFourBet[msg.sender] = optionFourBet[msg.sender].add(_amount);
            optionFourAmount = optionFourAmount.add(_amount);
        }else if(optionNumber == 5){
            require( optionFiveAmount.add(_amount) <= optionFiveLimit );
            optionFiveBet[msg.sender] = optionFiveBet[msg.sender].add(_amount);
            optionFiveAmount = optionFiveAmount.add(_amount);
        }else if(optionNumber == 6){
            require( optionSixAmount.add(_amount) <= optionSixLimit );
            optionSixBet[msg.sender] = optionSixBet[msg.sender].add(_amount);
            optionSixAmount = optionSixAmount.add(_amount);
        }
        
        feePool = feePool .add( _amount.mul(20).div(1000));
        
        emit BetLog(msg.sender, _amount, optionNumber);
    }

     
    function PlaceTokenBet(address player, uint optionNumber, uint _amount) public onlyOwner
    {
        require(LastBetTime > now);
        require(IsInitialized == true,'This is not opened yet.');
        require(IsEther == false, 'This is not an Ether Game');
        
        if(optionNumber == 1){
            require( optionOneAmount.add(_amount) <= optionOneLimit );
            optionOneBet[player] = optionOneBet[player].add(_amount);
            optionOneAmount = optionOneAmount.add(_amount);
        }else if(optionNumber == 2){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionTwoBet[player] = optionTwoBet[player].add(_amount);
            optionTwoAmount = optionTwoAmount.add(_amount);
        }else if(optionNumber == 3){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionThreeBet[player] = optionThreeBet[player].add(_amount);
            optionThreeAmount = optionThreeAmount.add(_amount);
        }else if(optionNumber == 4){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionFourBet[player] = optionFourBet[player].add(_amount);
            optionFourAmount = optionFourAmount.add(_amount);
        }else if(optionNumber == 5){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionFiveBet[player] = optionFiveBet[player].add(_amount);
            optionFiveAmount = optionFiveAmount.add(_amount);
        }else if(optionNumber == 6){
            require( optionTwoAmount.add(_amount) <= optionTwoLimit );
            optionSixBet[player] = optionSixBet[player].add(_amount);
            optionSixAmount = optionSixAmount.add(_amount);
        }
        emit BetLog(msg.sender, _amount, optionNumber);
    }
    
     
    function FinishGame(uint256 _finalOption) public onlyOwner
    {
        require(now > SettleBetTime);
        FinalAnswer = _finalOption;
    }

     
    function getGameInfo() public view returns(bool _IsInitialized, bool _IsEther, 
        uint256 _optionOneAmount, uint256 _optionTwoAmount,
        uint256 _optionThreeAmount, uint256 _optionFourAmount, uint256 _optionFiveAmount,
        uint256 _optionSixAmount,
        uint256 _StartBetTime, uint256 _LastBetTime, 
        uint256 _SettleBetTime, uint256 _FinalAnswer, uint256 _LoseTokenRate )
    {
        return(IsInitialized, IsEther, optionOneAmount, optionTwoAmount, optionThreeAmount, optionFourAmount,
        optionFiveAmount, optionSixAmount,  StartBetTime, LastBetTime, SettleBetTime, FinalAnswer, LoseTokenRate );
    }
    
    function getOptionLimit() public view returns(
        uint256 _optionOneLimit, uint256 _optionTwoLimit, uint256 _optionThreeLimit,
        uint256 _optionFourLimit, uint256 _optionFiveLimit, uint256 _optionSixLimit)
    {
        return( optionOneLimit, optionTwoLimit, optionThreeLimit, optionFourLimit,optionFiveLimit, optionSixLimit);
    }
    
     
    function DateConverter(uint256 ts) public view returns(uint256 currentDayWithoutTime){
        uint256 dayInterval = ts.sub(BaseTimestamp);
        uint256 dayCount = dayInterval.div(86400);
        return BaseTimestamp.add(dayCount.mul(86400));
    }
    
     
    function getDateInterval() public view returns(uint256 intervalDays){
        uint256 intervalTs = DateConverter(now).sub(BaseTimestamp);
        intervalDays = intervalTs.div(86400).sub(1);
    }
    
    function checkVault() public view returns(uint myReward)
    {
        uint256 myAward = 0;
        
        uint256 realReward = 
            optionOneAmount.add(optionTwoAmount).add(optionThreeAmount)
            .add(optionFourAmount).add(optionFiveAmount).add(optionSixAmount);
        
        uint256 myshare = 0;
        
        realReward = realReward.mul(980).div(1000);
        if(FinalAnswer == 1){
            myshare = optionOneBet[msg.sender].mul(100).div(optionOneAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 2){
            myshare = optionTwoBet[msg.sender].mul(100).div(optionTwoAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 3){
            myshare = optionThreeBet[msg.sender].mul(100).div(optionThreeAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 4){
            myshare = optionFourBet[msg.sender].mul(100).div(optionFourAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 5){
            myshare = optionFiveBet[msg.sender].mul(100).div(optionFiveAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 6){
            myshare = optionSixBet[msg.sender].mul(100).div(optionSixAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }
        
        return myAward;
    }
    
    function getVaultInfo() public view returns(uint256 _myReward, uint256 _totalBets, uint256 _realReward, uint256 _myShare)
    {
        uint256 myAward = 0;
        
        uint256 totalBets = 
             optionOneAmount.add(optionTwoAmount).add(optionThreeAmount)
            .add(optionFourAmount).add(optionFiveAmount).add(optionSixAmount);
        
        uint256 myshare = 0;
        
        uint256 realReward = totalBets.mul(980).div(1000);
        if(FinalAnswer == 1){
            myshare = optionOneBet[msg.sender].mul(100).div(optionOneAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 2){
            myshare = optionTwoBet[msg.sender].mul(100).div(optionTwoAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 3){
            myshare = optionThreeBet[msg.sender].mul(100).div(optionThreeAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 4){
            myshare = optionFourBet[msg.sender].mul(100).div(optionFourAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 5){
            myshare = optionFiveBet[msg.sender].mul(100).div(optionFiveAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }else if(FinalAnswer == 6){
            myshare = optionSixBet[msg.sender].mul(100).div(optionSixAmount) ;
            myAward = myshare.mul(realReward).div(100);
        }
        
        return (myAward, totalBets, realReward, myshare);
    }

    function getBet(uint number) public view returns(uint result)
    {
        if(number == 1){
            result = optionOneBet[msg.sender];
        }else if(number == 2){
            result = optionTwoBet[msg.sender];
        }else if(number == 3){
            result = optionThreeBet[msg.sender];
        }else if(number == 4){
            result = optionFourBet[msg.sender];
        }else if(number == 5){
            result = optionFiveBet[msg.sender];
        }else if(number == 6){
            result = optionSixBet[msg.sender];
        }
    }

     
    function withdraw() public
    {
        require(FinalAnswer != 0);

        uint256 myReward = checkVault();

        if(myReward ==0 && IsEther == true)
        {
            uint256 totalBet = optionOneBet[msg.sender] 
            .add(optionTwoBet[msg.sender]).add(optionThreeBet[msg.sender])
            .add(optionFourBet[msg.sender]).add(optionFiveBet[msg.sender])
            .add(optionSixBet[msg.sender]);
            
            uint256 TokenEarned = totalBet.mul(LoseTokenRate);

            ERC20(ERC20ContractAddres).transferFrom(ERC20WalletAddress, msg.sender, TokenEarned);
        }
        optionOneBet[msg.sender] = 0;
        optionTwoBet[msg.sender] = 0;
        optionThreeBet[msg.sender] = 0;
        optionFourBet[msg.sender] = 0;
        optionFiveBet[msg.sender] = 0;
        optionSixBet[msg.sender] = 0;
        
        if(IsEther)
        {
            msg.sender.transfer(myReward);
        }
        else
        {
            ERC20(ERC20ContractAddres).transferFrom(ERC20WalletAddress, msg.sender, myReward);
        }
    }
    
     
    function getServiceFeeBack() public onlyOwner
    {
        uint amount = feePool;
        feePool = 0;
        msg.sender.transfer(amount);
    }
}