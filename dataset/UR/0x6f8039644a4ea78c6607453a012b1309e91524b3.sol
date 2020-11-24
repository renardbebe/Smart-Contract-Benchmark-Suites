 

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
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);
    function balanceOf(address who) public constant returns  (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address _to, uint256 _value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Play0x_LottoBall {

    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint40;
    using SafeMath for uint8;

    uint public jackpotSize;
    uint public tokenJackpotSize;

    uint public MIN_BET;
    uint public MAX_BET;
    uint public MAX_AMOUNT;

     
    uint public maxProfit;
    uint public maxTokenProfit;

     
    uint8 public platformFeePercentage = 15;
    uint8 public jackpotFeePercentage = 5;
    uint8 public ERC20rewardMultiple = 5;

     
    uint constant BetExpirationBlocks = 250;



     
    uint public lockedInBets;
    uint public lockedTokenInBets;

    bytes32 bitComparisonMask = 0xF;

     
    address public owner;
    address private nextOwner;
    address public manager;
    address private nextManager;

     
    address public secretSigner;
    address public ERC20ContractAddres;
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    struct Bet {
         
        uint amount;
         
        uint40 placeBlockNumber;
         
        address gambler;
    }

     
    mapping (uint => Bet) public bets;

     
    uint32[] public withdrawalMode;

     
    event PlaceBetLog(address indexed player, uint amount,uint8 rotateTime);

     
    event ToManagerPayment(address indexed beneficiary, uint amount);
    event ToManagerFailedPayment(address indexed beneficiary, uint amount);
    event ToOwnerPayment(address indexed beneficiary, uint amount);
    event ToOwnerFailedPayment(address indexed beneficiary, uint amount);

     
    event Payment(address indexed beneficiary, uint amount);
    event FailedPayment(address indexed beneficiary, uint amount);
    event TokenPayment(address indexed beneficiary, uint amount);

     
    event JackpotBouns(address indexed beneficiary, uint amount);
    event TokenJackpotBouns(address indexed beneficiary, uint amount);

     
    event BetRelatedData(
        address indexed player,
        uint playerBetAmount,
        uint playerGetAmount,
        bytes32 entropy,
        bytes32 entropy2,
        uint8 Uplimit,
        uint8 rotateTime
    );

     
    constructor () public {
        owner = msg.sender;
        manager = DUMMY_ADDRESS;
        secretSigner = DUMMY_ADDRESS;
        ERC20ContractAddres = DUMMY_ADDRESS;
    }

     
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require (msg.sender == manager);
        _;
    }

    modifier onlyOwnerManager {
        require (msg.sender == owner || msg.sender == manager);
        _;
    }

    modifier onlySigner {
        require (msg.sender == secretSigner);
        _;
    }

     
    function initialParameter(address _manager,address _secretSigner,address _erc20tokenAddress ,uint _MIN_BET,uint _MAX_BET,uint _maxProfit,uint _maxTokenProfit, uint _MAX_AMOUNT, uint8 _platformFeePercentage,uint8 _jackpotFeePercentage,uint8 _ERC20rewardMultiple,uint32[] _withdrawalMode)external onlyOwner{
        manager = _manager;
        secretSigner = _secretSigner;
        ERC20ContractAddres = _erc20tokenAddress;

        MIN_BET = _MIN_BET;
        MAX_BET = _MAX_BET;
        maxProfit = _maxProfit;
        maxTokenProfit = _maxTokenProfit;
        MAX_AMOUNT = _MAX_AMOUNT;
        platformFeePercentage = _platformFeePercentage;
        jackpotFeePercentage = _jackpotFeePercentage;
        ERC20rewardMultiple = _ERC20rewardMultiple;
        withdrawalMode = _withdrawalMode;
    }

     
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner);
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner);
        owner = nextOwner;
    }

     
    function approveNextManager(address _nextManager) external onlyManager {
        require (_nextManager != manager);
        nextManager = _nextManager;
    }

    function acceptNextManager() external {
        require (msg.sender == nextManager);
        manager = nextManager;
    }

     
    function () public payable {
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

     
    function setTokenAddress(address _tokenAddress) external onlyManager {
        ERC20ContractAddres = _tokenAddress;
    }


     
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT);
        maxProfit = _maxProfit;
    }

     
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance);

        uint safetyAmount = jackpotSize.add(lockedInBets).add(withdrawAmount);
        safetyAmount = safetyAmount.add(withdrawAmount);

        require (safetyAmount <= address(this).balance);
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

     
    function withdrawToken(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= ERC20(ERC20ContractAddres).balanceOf(address(this)));

        uint safetyAmount = tokenJackpotSize.add(lockedTokenInBets);
        safetyAmount = safetyAmount.add(withdrawAmount);
        require (safetyAmount <= ERC20(ERC20ContractAddres).balanceOf(address(this)));

         ERC20(ERC20ContractAddres).transfer(beneficiary, withdrawAmount);
         emit TokenPayment(beneficiary, withdrawAmount);
    }

     
    function withdrawAllFunds(address beneficiary) external onlyOwner {
        if (beneficiary.send(address(this).balance)) {
            lockedInBets = 0;
            emit Payment(beneficiary, address(this).balance);
        } else {
            emit FailedPayment(beneficiary, address(this).balance);
        }
    }

     
    function withdrawAlltokenFunds(address beneficiary) external onlyOwner {
        ERC20(ERC20ContractAddres).transfer(beneficiary, ERC20(ERC20ContractAddres).balanceOf(address(this)));
        lockedTokenInBets = 0;
        emit TokenPayment(beneficiary, ERC20(ERC20ContractAddres).balanceOf(address(this)));
    }

     
     
    function kill() external onlyOwner {
        require (lockedInBets == 0);
        require (lockedTokenInBets == 0);
        selfdestruct(owner);
    }

    function getContractInformation()public view returns(
        uint _jackpotSize,
        uint _tokenJackpotSize,
        uint _MIN_BET,
        uint _MAX_BET,
        uint _MAX_AMOUNT,
        uint8 _platformFeePercentage,
        uint8 _jackpotFeePercentage,
        uint _maxProfit,
        uint _maxTokenProfit,
        uint _lockedInBets,
        uint _lockedTokenInBets,
        uint32[] _withdrawalMode){

        _jackpotSize = jackpotSize;
        _tokenJackpotSize = tokenJackpotSize;
        _MIN_BET = MIN_BET;
        _MAX_BET = MAX_BET;
        _MAX_AMOUNT = MAX_AMOUNT;
        _platformFeePercentage = platformFeePercentage;
        _jackpotFeePercentage = jackpotFeePercentage;
        _maxProfit = maxProfit;
        _maxTokenProfit = maxTokenProfit;
        _lockedInBets = lockedInBets;
        _lockedTokenInBets = lockedTokenInBets;
        _withdrawalMode = withdrawalMode;
    }

    function getContractAddress()public view returns(
        address _owner,
        address _manager,
        address _secretSigner,
        address _ERC20ContractAddres ){

        _owner = owner;
        _manager= manager;
        _secretSigner = secretSigner;
        _ERC20ContractAddres = ERC20ContractAddres;
    }

     
    enum PlaceParam {
        RotateTime,
        possibleWinAmount
    }

     
    function placeBet(uint[] placParameter, bytes32 _signatureHash , uint _commitLastBlock, uint _commit, bytes32 r, bytes32 s, uint8 v) external payable {
        require (uint8(placParameter[uint8(PlaceParam.RotateTime)]) != 0);
        require (block.number <= _commitLastBlock );
        require (secretSigner == ecrecover(_signatureHash, v, r, s));

         
        Bet storage bet = bets[_commit];
        require (bet.gambler == address(0));

         
        lockedInBets = lockedInBets.add(uint(placParameter[uint8(PlaceParam.possibleWinAmount)]));
        require (uint(placParameter[uint8(PlaceParam.possibleWinAmount)]) <= msg.value.add(maxProfit));
        require (lockedInBets <= address(this).balance);

         
        bet.amount = msg.value;
        bet.placeBlockNumber = uint40(block.number);
        bet.gambler = msg.sender;

        emit PlaceBetLog(msg.sender, msg.value, uint8(placParameter[uint8(PlaceParam.RotateTime)]));
    }

    function placeTokenBet(uint[] placParameter,bytes32 _signatureHash , uint _commitLastBlock, uint _commit, bytes32 r, bytes32 s, uint8 v,uint _amount,address _playerAddress) external {
        require (placParameter[uint8(PlaceParam.RotateTime)] != 0);
        require (block.number <= _commitLastBlock );
        require (secretSigner == ecrecover(_signatureHash, v, r, s));

         
        Bet storage bet = bets[_commit];
        require (bet.gambler == address(0));

         
        lockedTokenInBets = lockedTokenInBets.add(uint(placParameter[uint8(PlaceParam.possibleWinAmount)]));
        require (uint(placParameter[uint8(PlaceParam.possibleWinAmount)]) <= _amount.add(maxTokenProfit));
        require (lockedTokenInBets <= ERC20(ERC20ContractAddres).balanceOf(address(this)));

         
        bet.amount = _amount;
        bet.placeBlockNumber = uint40(block.number);
        bet.gambler = _playerAddress;

        emit PlaceBetLog(_playerAddress, _amount, uint8(placParameter[uint8(PlaceParam.RotateTime)]));
    }


     
     function getBonusPercentageByMachineMode(uint8 machineMode)public view returns( uint upperLimit,uint maxWithdrawalPercentage ){
         uint limitIndex = machineMode.mul(2);
         upperLimit = withdrawalMode[limitIndex];
         maxWithdrawalPercentage = withdrawalMode[(limitIndex.add(1))];
    }

     
     enum SettleParam {
        Uplimit,
        BonusPercentage,
        RotateTime,
        CurrencyType,
        MachineMode,
        PerWinAmount,
        PerBetAmount,
        PossibleWinAmount,
        LuckySeed,
        jackpotFee
     }

    function settleBet(uint[] combinationParameter, uint reveal) external {

         
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

         
        Bet storage bet = bets[commit];

         
        require (bet.amount != 0);
        require (block.number <= bet.placeBlockNumber.add(BetExpirationBlocks));

         
        bytes32 _entropy = keccak256(
            abi.encodePacked(
                uint(
                    keccak256(
                        abi.encodePacked(
                            uint(
                                keccak256(
                                    abi.encodePacked(
                                        reveal,
                                        blockhash(combinationParameter[uint8(SettleParam.LuckySeed)])
                                    )
                                )
                            ),
                            blockhash(block.number)
                        )
                    )
                ),
                blockhash(block.timestamp)
            )
        );

         uint totalAmount = 0;
         uint totalTokenAmount = 0;
         uint totalJackpotWin = 0;
         (totalAmount,totalTokenAmount,totalJackpotWin) = runRotateTime(combinationParameter,_entropy,keccak256(abi.encodePacked(uint(_entropy), blockhash(combinationParameter[uint8(SettleParam.LuckySeed)]))));

         
        if (totalJackpotWin > 0 && combinationParameter[uint8(SettleParam.CurrencyType)] == 0) {

            emit JackpotBouns(bet.gambler,totalJackpotWin);
            totalAmount = totalAmount.add(totalJackpotWin);
            jackpotSize = uint128(jackpotSize.sub(totalJackpotWin));

        }else if (totalJackpotWin > 0 && combinationParameter[uint8(SettleParam.CurrencyType)] == 1) {

             
            emit TokenJackpotBouns(bet.gambler,totalJackpotWin);
            totalAmount = totalAmount.add(totalJackpotWin);
            tokenJackpotSize = uint128(tokenJackpotSize.sub(totalJackpotWin));
        }

        emit BetRelatedData(bet.gambler,bet.amount,totalAmount,_entropy,keccak256(abi.encodePacked(uint(_entropy), blockhash(combinationParameter[uint8(SettleParam.LuckySeed)]))),uint8(combinationParameter[uint8(SettleParam.Uplimit)]),uint8(combinationParameter[uint8(SettleParam.RotateTime)]));

        if (combinationParameter[uint8(SettleParam.CurrencyType)] == 0) {
              
            if (totalAmount != 0){
                sendFunds(bet.gambler, totalAmount , totalAmount);
            }

             
            if (totalTokenAmount != 0){

                if(ERC20(ERC20ContractAddres).balanceOf(address(this)) > 0){
                    ERC20(ERC20ContractAddres).transfer(bet.gambler, totalTokenAmount);
                    emit TokenPayment(bet.gambler, totalTokenAmount);
                }
            }
        }else if(combinationParameter[uint8(SettleParam.CurrencyType)] == 1){
               

             
            if (totalAmount != 0){
                if(ERC20(ERC20ContractAddres).balanceOf(address(this)) > 0){
                    ERC20(ERC20ContractAddres).transfer(bet.gambler, totalAmount);
                    emit TokenPayment(bet.gambler, totalAmount);
                }
            }
        }

                 
        if (combinationParameter[uint8(SettleParam.CurrencyType)] == 0) {
                lockedInBets = lockedInBets.sub(combinationParameter[uint8(SettleParam.PossibleWinAmount)]);
        } else if (combinationParameter[uint8(SettleParam.CurrencyType)] == 1){
                lockedTokenInBets = lockedTokenInBets.sub(combinationParameter[uint8(SettleParam.PossibleWinAmount)]);
        }

         
        bet.amount = 0;

         
        if (uint16(combinationParameter[uint8(SettleParam.CurrencyType)]) == 0) {
            jackpotSize = jackpotSize.add(uint(combinationParameter[uint8(SettleParam.jackpotFee)]));
        }else if (uint16(combinationParameter[uint8(SettleParam.CurrencyType)]) == 1) {
            tokenJackpotSize = tokenJackpotSize.add(uint(combinationParameter[uint8(SettleParam.jackpotFee)]));
        }
    }


    function runRotateTime ( uint[] combinationParameter, bytes32 _entropy ,bytes32 _entropy2)private view  returns(uint totalAmount,uint totalTokenAmount,uint totalJackpotWin) {

        bytes32 resultMask = 0xF000000000000000000000000000000000000000000000000000000000000000;
        bytes32 tmp_entropy;
        bytes32 tmp_Mask = resultMask;

        bool isGetJackpot = false;

        for (uint8 i = 0; i < combinationParameter[uint8(SettleParam.RotateTime)]; i++) {
            if (i < 64){
                tmp_entropy = _entropy & tmp_Mask;
                tmp_entropy = tmp_entropy >> (4*(64 - (i.add(1))));
                tmp_Mask =  tmp_Mask >> 4;
            }else{
                if ( i == 64){
                    tmp_Mask = resultMask;
                }
                tmp_entropy = _entropy2 & tmp_Mask;
                tmp_entropy = tmp_entropy >> (4*( 64 - (i%63)));
                tmp_Mask =  tmp_Mask >> 4;
            }

            if ( uint(tmp_entropy) < uint(combinationParameter[uint8(SettleParam.Uplimit)]) ){
                 
                totalAmount = totalAmount.add(combinationParameter[uint8(SettleParam.PerWinAmount)]);

                 
                uint platformFees = combinationParameter[uint8(SettleParam.PerBetAmount)].mul(platformFeePercentage);
                platformFees = platformFees.div(1000);
                totalAmount = totalAmount.sub(platformFees);
            }else{
                 
                if (uint(combinationParameter[uint8(SettleParam.CurrencyType)]) == 0){

                    if(ERC20(ERC20ContractAddres).balanceOf(address(this)) > 0){
                         
                        uint rewardAmount = uint(combinationParameter[uint8(SettleParam.PerBetAmount)]).mul(ERC20rewardMultiple);
                        totalTokenAmount = totalTokenAmount.add(rewardAmount);
                    }
                }
            }

             
            if (isGetJackpot == false){
                isGetJackpot = getJackpotWinBonus(i,_entropy,_entropy2);
            }
        }

        if (isGetJackpot == true && combinationParameter[uint8(SettleParam.CurrencyType)] == 0) {
             
            totalJackpotWin = jackpotSize;
        }else if (isGetJackpot == true && combinationParameter[uint8(SettleParam.CurrencyType)] == 1) {
             
            totalJackpotWin = tokenJackpotSize;
        }
    }

    function getJackpotWinBonus (uint8 i,bytes32 entropy,bytes32 entropy2) private pure returns (bool isGetJackpot) {
        bytes32 one;
        bytes32 two;
        bytes32 three;
        bytes32 four;

        bytes32 resultMask = 0xF000000000000000000000000000000000000000000000000000000000000000;
        bytes32 jackpo_Mask = resultMask;

        if (i < 61){
            one = (entropy & jackpo_Mask) >> 4*(64 - (i + 1));
                jackpo_Mask =  jackpo_Mask >> 4;
            two = (entropy & jackpo_Mask)  >> (4*(64 - (i + 2)));
                jackpo_Mask =  jackpo_Mask >> 4;
            three = (entropy & jackpo_Mask) >> (4*(64 - (i + 3)));
                jackpo_Mask =  jackpo_Mask >> 4;
            four = (entropy & jackpo_Mask) >> (4*(64 - (i + 4)));
                jackpo_Mask =  jackpo_Mask << 8;
        }
        else if(i >= 61){
            if(i == 61){
                one = (entropy & jackpo_Mask) >> 4*(64 - (i + 1));
                    jackpo_Mask =  jackpo_Mask >> 4;
                two = (entropy & jackpo_Mask)  >> (4*(64 - (i + 2)));
                    jackpo_Mask =  jackpo_Mask >> 4;
                three = (entropy & jackpo_Mask) >> (4*(64 - (i + 3)));
                    jackpo_Mask =  jackpo_Mask << 4;
                four = (entropy2 & 0xF000000000000000000000000000000000000000000000000000000000000000) >> 4*63;
            }
            else if(i == 62){
                one = (entropy & jackpo_Mask) >> 4*(64 - (i + 1));
                    jackpo_Mask =  jackpo_Mask >> 4;
                two = (entropy & jackpo_Mask)  >> (4*(64 - (i + 2)));
                three = (entropy2 & 0xF000000000000000000000000000000000000000000000000000000000000000) >> 4*63;
                four =  (entropy2 & 0x0F00000000000000000000000000000000000000000000000000000000000000) >> 4*62;
            }
            else if(i == 63){
                one = (entropy & jackpo_Mask) >> 4*(64 - (i + 1));
                two = (entropy2 & 0xF000000000000000000000000000000000000000000000000000000000000000)  >> 4*63;
                    jackpo_Mask =  jackpo_Mask >> 4;
                three = (entropy2 & 0x0F00000000000000000000000000000000000000000000000000000000000000) >> 4*62;
                    jackpo_Mask =  jackpo_Mask << 4;
                four = (entropy2 & 0x00F0000000000000000000000000000000000000000000000000000000000000) >> 4*61;

                    jackpo_Mask = 0xF000000000000000000000000000000000000000000000000000000000000000;
            }
            else {
                one = (entropy2 & jackpo_Mask) >>  (4*( 64 - (i%64 + 1)));
                    jackpo_Mask =  jackpo_Mask >> 4;
                two = (entropy2 & jackpo_Mask)  >> (4*( 64 - (i%64 + 2)))   ;
                    jackpo_Mask =  jackpo_Mask >> 4;
                three = (entropy2 & jackpo_Mask) >> (4*( 64 - (i%64 + 3))) ;
                    jackpo_Mask =  jackpo_Mask >> 4;
                four = (entropy2 & jackpo_Mask) >>(4*( 64 - (i%64 + 4)));
                    jackpo_Mask =  jackpo_Mask << 8;
            }
        }

        if ((one ^ 0xF) == 0 && (two ^ 0xF) == 0 && (three ^ 0xF) == 0 && (four ^ 0xF) == 0){
            isGetJackpot = true;
       }
    }

     
    function getPossibleWinAmount(uint bonusPercentage,uint senderValue)public view returns (uint platformFee,uint jackpotFee,uint possibleWinAmount) {

         
        uint prePlatformFee = (senderValue).mul(platformFeePercentage);
        platformFee = (prePlatformFee).div(1000);

         
        uint preJackpotFee = (senderValue).mul(jackpotFeePercentage);
        jackpotFee = (preJackpotFee).div(1000);

         
        uint preUserGetAmount = senderValue.mul(bonusPercentage);
        possibleWinAmount = preUserGetAmount.div(10000);
    }

     
    function refundBet(uint commit,uint8 machineMode) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber.add(BetExpirationBlocks));

         
        bet.amount = 0;

         
        uint platformFee;
        uint jackpotFee;
        uint possibleWinAmount;
        uint upperLimit;
        uint maxWithdrawalPercentage;
        (upperLimit,maxWithdrawalPercentage) = getBonusPercentageByMachineMode(machineMode);
        (platformFee, jackpotFee, possibleWinAmount) = getPossibleWinAmount(maxWithdrawalPercentage,amount);

         
        lockedInBets = lockedInBets.sub(possibleWinAmount);

         
        sendFunds(bet.gambler, amount, amount);
    }

    function refundTokenBet(uint commit,uint8 machineMode) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber.add(BetExpirationBlocks));

         
        bet.amount = 0;

         
        uint platformFee;
        uint jackpotFee;
        uint possibleWinAmount;
        uint upperLimit;
        uint maxWithdrawalPercentage;
        (upperLimit,maxWithdrawalPercentage) = getBonusPercentageByMachineMode(machineMode);
        (platformFee, jackpotFee, possibleWinAmount) = getPossibleWinAmount(maxWithdrawalPercentage,amount);

         
        lockedTokenInBets = uint128(lockedTokenInBets.sub(possibleWinAmount));

         
        ERC20(ERC20ContractAddres).transfer(bet.gambler, amount);
        emit TokenPayment(bet.gambler, amount);
    }

     
    function clearStorage(uint[] cleanCommits) external {
        uint length = cleanCommits.length;

        for (uint i = 0; i < length; i++) {
            clearProcessedBet(cleanCommits[i]);
        }
    }

     
    function clearProcessedBet(uint commit) private {
        Bet storage bet = bets[commit];

         
        if (bet.amount != 0 || block.number <= bet.placeBlockNumber + BetExpirationBlocks) {
            return;
        }

         
        bet.placeBlockNumber = 0;
        bet.gambler = address(0);
    }

     
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

     function sendFundsToManager(uint amount) external onlyOwner {
        if (manager.send(amount)) {
            emit ToManagerPayment(manager, amount);
        } else {
            emit ToManagerFailedPayment(manager, amount);
        }
    }

    function sendTokenFundsToManager( uint amount) external onlyOwner {
        ERC20(ERC20ContractAddres).transfer(manager, amount);
        emit TokenPayment(manager, amount);
    }

    function sendFundsToOwner(address beneficiary, uint amount) external onlyOwner {
        if (beneficiary.send(amount)) {
            emit ToOwnerPayment(beneficiary, amount);
        } else {
            emit ToOwnerFailedPayment(beneficiary, amount);
        }
    }

     
    function updateMIN_BET(uint _uintNumber)public onlyManager {
         MIN_BET = _uintNumber;
    }

    function updateMAX_BET(uint _uintNumber)public onlyManager {
         MAX_BET = _uintNumber;
    }

    function updateMAX_AMOUNT(uint _uintNumber)public onlyManager {
         MAX_AMOUNT = _uintNumber;
    }

    function updateWithdrawalModeByIndex(uint8 _index, uint32 _value) public onlyManager{
       withdrawalMode[_index]  = _value;
    }

    function updateWithdrawalMode( uint32[] _withdrawalMode) public onlyManager{
       withdrawalMode  = _withdrawalMode;
    }

    function updateBitComparisonMask(bytes32 _newBitComparisonMask ) public onlyOwner{
       bitComparisonMask = _newBitComparisonMask;
    }

    function updatePlatformFeePercentage(uint8 _platformFeePercentage ) public onlyOwner{
       platformFeePercentage = _platformFeePercentage;
    }

    function updateJackpotFeePercentage(uint8 _jackpotFeePercentage ) public onlyOwner{
       jackpotFeePercentage = _jackpotFeePercentage;
    }

    function updateERC20rewardMultiple(uint8 _ERC20rewardMultiple ) public onlyManager{
       ERC20rewardMultiple = _ERC20rewardMultiple;
    }
}