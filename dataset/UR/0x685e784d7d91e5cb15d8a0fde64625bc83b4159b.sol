 

pragma solidity ^0.5.10;

 

pragma solidity ^0.5.9;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract EraswapERC20 is DetailedERC20, BurnableToken, CappedToken {
  string private name = "Eraswap";
  string private symbol = "EST";
  uint8 private decimals = 18;
  uint256 private cap = 9100000000000000000000000000;

   

  constructor() internal DetailedERC20("Eraswap", "EST", 18) CappedToken(cap){
    mint(msg.sender, 910000000000000000000000000);
  }

}

contract NRTManager is Ownable, EraswapERC20{

  using SafeMath for uint256;

  uint256 public LastNRTRelease;               
  uint256 public MonthlyNRTAmount;             
  uint256 public AnnualNRTAmount;              
  uint256 public MonthCount;                   
  uint256 public luckPoolBal;                  
  uint256 public burnTokenBal;                 

   
  address public newTalentsAndPartnerships;
  address public platformMaintenance;
  address public marketingAndRNR;
  address public kmPards;
  address public contingencyFunds;
  address public researchAndDevelopment;
  address public buzzCafe;
  address public timeSwappers;                  
  address public TimeAlly;                      

  uint256 public newTalentsAndPartnershipsBal;  
  uint256 public platformMaintenanceBal;        
  uint256 public marketingAndRNRBal;            
  uint256 public kmPardsBal;                    
  uint256 public contingencyFundsBal;           
  uint256 public researchAndDevelopmentBal;     
  uint256 public buzzCafeNRT;                   
  uint256 public TimeAllyNRT;                    
  uint256 public timeSwappersNRT;               


     
     
    event NRTDistributed(uint256 NRTReleased);

     
    event NRTTransfer(string pool, address sendAddress, uint256 value);


     
     
    event TokensBurned(uint256 amount);



     

    function burnTokens() internal returns (bool){
      if(burnTokenBal == 0){
        return true;
      }
      else{
        uint MaxAmount = ((totalSupply()).mul(2)).div(100);    
        if(MaxAmount >= burnTokenBal ){
          burn(burnTokenBal);
          burnTokenBal = 0;
        }
        else{
          burnTokenBal = burnTokenBal.sub(MaxAmount);
          burn(MaxAmount);
        }
        return true;
      }
    }

     

    function MonthlyNRTRelease() external returns (bool) {
      require(now.sub(LastNRTRelease)> 2592000);
      uint256 NRTBal = MonthlyNRTAmount.add(luckPoolBal);         

       
      newTalentsAndPartnershipsBal = (NRTBal.mul(5)).div(100);
      platformMaintenanceBal = (NRTBal.mul(10)).div(100);
      marketingAndRNRBal = (NRTBal.mul(10)).div(100);
      kmPardsBal = (NRTBal.mul(10)).div(100);
      contingencyFundsBal = (NRTBal.mul(10)).div(100);
      researchAndDevelopmentBal = (NRTBal.mul(5)).div(100);
      buzzCafeNRT = (NRTBal.mul(25)).div(1000);
      TimeAllyNRT = (NRTBal.mul(15)).div(100);
      timeSwappersNRT = (NRTBal.mul(325)).div(1000);

       
      mint(newTalentsAndPartnerships,newTalentsAndPartnershipsBal);
      emit NRTTransfer("newTalentsAndPartnerships", newTalentsAndPartnerships, newTalentsAndPartnershipsBal);
      mint(platformMaintenance,platformMaintenanceBal);
      emit NRTTransfer("platformMaintenance", platformMaintenance, platformMaintenanceBal);
      mint(marketingAndRNR,marketingAndRNRBal);
      emit NRTTransfer("marketingAndRNR", marketingAndRNR, marketingAndRNRBal);
      mint(kmPards,kmPardsBal);
      emit NRTTransfer("kmPards", kmPards, kmPardsBal);
      mint(contingencyFunds,contingencyFundsBal);
      emit NRTTransfer("contingencyFunds", contingencyFunds, contingencyFundsBal);
      mint(researchAndDevelopment,researchAndDevelopmentBal);
      emit NRTTransfer("researchAndDevelopment", researchAndDevelopment, researchAndDevelopmentBal);
      mint(buzzCafe,buzzCafeNRT);
      emit NRTTransfer("buzzCafe", buzzCafe, buzzCafeNRT);
      mint(TimeAlly,TimeAllyNRT);
      emit NRTTransfer("stakingContract", TimeAlly, TimeAllyNRT);
      mint(timeSwappers,timeSwappersNRT);
      emit NRTTransfer("timeSwappers", timeSwappers, timeSwappersNRT);

       
      emit NRTDistributed(NRTBal);
      luckPoolBal = 0;
      LastNRTRelease = LastNRTRelease.add(30 days);  
      burnTokens();                                  
      emit TokensBurned(burnTokenBal);


      if(MonthCount == 11){
        MonthCount = 0;
        AnnualNRTAmount = (AnnualNRTAmount.mul(9)).div(10);
        MonthlyNRTAmount = MonthlyNRTAmount.div(12);
      }
      else{
        MonthCount = MonthCount.add(1);
      }
      return true;
    }


   

  constructor() public{
    LastNRTRelease = now;
    AnnualNRTAmount = 819000000000000000000000000;
    MonthlyNRTAmount = AnnualNRTAmount.div(uint256(12));
    MonthCount = 0;
  }

}

contract PausableEraswap is NRTManager {

   
  modifier whenNotPaused() {
    require((now.sub(LastNRTRelease))< 2592000);
    _;
  }


  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract EraswapToken is PausableEraswap {


     
    event PoolAddressAdded(string pool, address sendAddress);

     
     
    event LuckPoolUpdated(uint256 luckPoolBal);

     
     
    event BurnTokenBalUpdated(uint256 burnTokenBal);

     
    modifier OnlyTimeAlly() {
      require(msg.sender == TimeAlly);
      _;
    }


     

    function UpdateAddresses (address[] memory pool) onlyOwner public returns(bool){

      if((pool[0] != address(0)) && (newTalentsAndPartnerships == address(0))){
        newTalentsAndPartnerships = pool[0];
        emit PoolAddressAdded( "NewTalentsAndPartnerships", newTalentsAndPartnerships);
      }
      if((pool[1] != address(0)) && (platformMaintenance == address(0))){
        platformMaintenance = pool[1];
        emit PoolAddressAdded( "PlatformMaintenance", platformMaintenance);
      }
      if((pool[2] != address(0)) && (marketingAndRNR == address(0))){
        marketingAndRNR = pool[2];
        emit PoolAddressAdded( "MarketingAndRNR", marketingAndRNR);
      }
      if((pool[3] != address(0)) && (kmPards == address(0))){
        kmPards = pool[3];
        emit PoolAddressAdded( "KmPards", kmPards);
      }
      if((pool[4] != address(0)) && (contingencyFunds == address(0))){
        contingencyFunds = pool[4];
        emit PoolAddressAdded( "ContingencyFunds", contingencyFunds);
      }
      if((pool[5] != address(0)) && (researchAndDevelopment == address(0))){
        researchAndDevelopment = pool[5];
        emit PoolAddressAdded( "ResearchAndDevelopment", researchAndDevelopment);
      }
      if((pool[6] != address(0)) && (buzzCafe == address(0))){
        buzzCafe = pool[6];
        emit PoolAddressAdded( "BuzzCafe", buzzCafe);
      }
      if((pool[7] != address(0)) && (timeSwappers == address(0))){
        timeSwappers = pool[7];
        emit PoolAddressAdded( "TimeSwapper", timeSwappers);
      }
      if((pool[8] != address(0)) && (TimeAlly == address(0))){
        TimeAlly = pool[8];
        emit PoolAddressAdded( "TimeAlly", TimeAlly);
      }

      return true;
    }


     
    function UpdateLuckpool(uint256 amount) OnlyTimeAlly external returns(bool){
      require(allowance(msg.sender, address(this)) >= amount);
      require(transferFrom(msg.sender,address(this), amount));
      luckPoolBal = luckPoolBal.add(amount);
      emit LuckPoolUpdated(luckPoolBal);
      return true;
    }

     
    function UpdateBurnBal(uint256 amount) OnlyTimeAlly external returns(bool){
      require(allowance(msg.sender, address(this)) >= amount);
      require(transferFrom(msg.sender,address(this), amount));
      burnTokenBal = burnTokenBal.add(amount);
      emit BurnTokenBalUpdated(burnTokenBal);
      return true;
    }

     
    function UpdateBalance(address[100] calldata TokenTransferList, uint256[100] calldata TokenTransferBalance) OnlyTimeAlly external returns(bool){
        for (uint256 i = 0; i < TokenTransferList.length; i++) {
      require(allowance(msg.sender, address(this)) >= TokenTransferBalance[i]);
      require(transferFrom(msg.sender, TokenTransferList[i], TokenTransferBalance[i]));
      }
      return true;
    }




}

 
 
 
 
contract BetDeEx {
    using SafeMath for uint256;

    address[] public bets;  
    address public superManager;  

    EraswapToken esTokenContract;

    mapping(address => uint256) public betBalanceInExaEs;  
    mapping(address => bool) public isBetValid;  
    mapping(address => bool) public isManager;  

    event NewBetContract (
        address indexed _deployer,
        address _contractAddress,
        uint8 indexed _category,
        uint8 indexed _subCategory,
        string _description
    );

    event NewBetting (
        address indexed _betAddress,
        address indexed _bettorAddress,
        uint8 indexed _choice,
        uint256 _betTokensInExaEs
    );

    event EndBetContract (
        address indexed _ender,
        address indexed _contractAddress,
        uint8 _result,
        uint256 _prizePool,
        uint256 _platformFee
    );

     
    event TransferES (
        address indexed _betContract,
        address indexed _to,
        uint256 _tokensInExaEs
    );

    modifier onlySuperManager() {
        require(msg.sender == superManager, "only superManager can call");
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "only manager can call");
        _;
    }

    modifier onlyBetContract() {
        require(isBetValid[msg.sender], "only bet contract can call");
        _;
    }

     
     
    constructor(address _esTokenContractAddress) public {
        superManager = msg.sender;
        isManager[msg.sender] = true;
        esTokenContract = EraswapToken(_esTokenContractAddress);
    }

     
     
     
     
     
     
     
     
     
    function createBet(
        string memory _description,
        uint8 _category,
        uint8 _subCategory,
        uint256 _minimumBetInExaEs,
        uint256 _prizePercentPerThousand,
        bool _isDrawPossible,
        uint256 _pauseTimestamp
    ) public onlyManager returns (address) {
        Bet _newBet = new Bet(
          _description,
          _category,
          _subCategory,
          _minimumBetInExaEs,
          _prizePercentPerThousand,
          _isDrawPossible,
          _pauseTimestamp
        );
        bets.push(address(_newBet));
        isBetValid[address(_newBet)] = true;

        emit NewBetContract(
          msg.sender,
          address(_newBet),
          _category,
          _subCategory,
          _description
        );

        return address(_newBet);
    }

     
     
    function getNumberOfBets() public view returns (uint256) {
        return bets.length;
    }







     
     
    function addManager(address _manager) public onlySuperManager {
        isManager[_manager] = true;
    }

     
     
    function removeManager(address _manager) public onlySuperManager {
        isManager[_manager] = false;
    }

     
    function emitNewBettingEvent(address _bettorAddress, uint8 _choice, uint256 _betTokensInExaEs) public onlyBetContract {
        emit NewBetting(msg.sender, _bettorAddress, _choice, _betTokensInExaEs);
    }

     
    function emitEndEvent(address _ender, uint8 _result, uint256 _gasFee) public onlyBetContract {
        emit EndBetContract(_ender, msg.sender, _result, betBalanceInExaEs[msg.sender], _gasFee);
    }

     
    function collectBettorTokens(address _from, uint256 _betTokensInExaEs) public onlyBetContract returns (bool) {
        require(esTokenContract.transferFrom(_from, address(this), _betTokensInExaEs), "tokens should be collected from user");
        betBalanceInExaEs[msg.sender] = betBalanceInExaEs[msg.sender].add(_betTokensInExaEs);
        return true;
    }

     
    function sendTokensToAddress(address _to, uint256 _tokensInExaEs) public onlyBetContract returns (bool) {
        betBalanceInExaEs[msg.sender] = betBalanceInExaEs[msg.sender].sub(_tokensInExaEs);
        require(esTokenContract.transfer(_to, _tokensInExaEs), "tokens should be sent");

        emit TransferES(msg.sender, _to, _tokensInExaEs);
        return true;
    }

     
    function collectPlatformFee(uint256 _platformFee) public onlyBetContract returns (bool) {
        require(esTokenContract.transfer(superManager, _platformFee), "platform fee should be collected");
        return true;
    }

}

 
 
 
contract Bet {
    using SafeMath for uint256;

    BetDeEx betDeEx;

    string public description;  
    bool public isDrawPossible;  
    uint8 public category;  
    uint8 public subCategory;  

    uint8 public finalResult;  
    address public endedBy;  

    uint256 public creationTimestamp;  
    uint256 public pauseTimestamp;  
    uint256 public endTimestamp;  

    uint256 public minimumBetInExaEs;  
    uint256 public prizePercentPerThousand;  
    uint256[3] public totalBetTokensInExaEsByChoice = [0, 0, 0];  
    uint256[3] public getNumberOfChoiceBettors = [0, 0, 0];  

    uint256 public totalPrize;  

    mapping(address => uint256[3]) public bettorBetAmountInExaEsByChoice;  
    mapping(address => bool) public bettorHasClaimed;  

    modifier onlyManager() {
        require(betDeEx.isManager(msg.sender), "only manager can call");
        _;
    }

     
     
     
     
     
     
     
     
    constructor(string memory _description, uint8 _category, uint8 _subCategory, uint256 _minimumBetInExaEs, uint256 _prizePercentPerThousand, bool _isDrawPossible, uint256 _pauseTimestamp) public {
        description = _description;
        isDrawPossible = _isDrawPossible;
        category = _category;
        subCategory = _subCategory;
        minimumBetInExaEs = _minimumBetInExaEs;
        prizePercentPerThousand = _prizePercentPerThousand;
        betDeEx = BetDeEx(msg.sender);
        creationTimestamp = now;
        pauseTimestamp = _pauseTimestamp;
    }

     
    function betBalanceInExaEs() public view returns (uint256) {
        return betDeEx.betBalanceInExaEs(address(this));
    }

     
     
     
    function enterBet(uint8 _choice, uint256 _betTokensInExaEs) public {
        require(now < pauseTimestamp, "cannot enter after pause time");
        require(_betTokensInExaEs >= minimumBetInExaEs, "betting tokens should be more than minimum");

         
        require(betDeEx.collectBettorTokens(msg.sender, _betTokensInExaEs), "betting tokens should be collected");

         
        if (_choice > 2 || (_choice == 2 && !isDrawPossible) ) {
            require(false, "this choice is not available");
        }

        getNumberOfChoiceBettors[_choice] = getNumberOfChoiceBettors[_choice].add(1);
        totalBetTokensInExaEsByChoice[_choice] = totalBetTokensInExaEsByChoice[_choice].add(_betTokensInExaEs);

        bettorBetAmountInExaEsByChoice[msg.sender][_choice] = bettorBetAmountInExaEsByChoice[msg.sender][_choice].add(_betTokensInExaEs);

        betDeEx.emitNewBettingEvent(msg.sender, _choice, _betTokensInExaEs);
    }

     
     
    function endBet(uint8 _choice) public onlyManager {
        require(now >= pauseTimestamp, "cannot end bet before pause time");
        require(endedBy == address(0), "Bet Already Ended");

         
        if(_choice < 2  || (_choice == 2 && isDrawPossible)) {
            finalResult = _choice;
        } else {
            require(false, "this choice is not available");
        }

        endedBy = msg.sender;
        endTimestamp = now;

         
        totalPrize = betBalanceInExaEs().mul(prizePercentPerThousand).div(1000);

         
        uint256 _platformFee = betBalanceInExaEs().sub(totalPrize);

         
        require(betDeEx.collectPlatformFee(_platformFee), "platform fee should be collected");

        betDeEx.emitEndEvent(endedBy, _choice, _platformFee);
    }

     
     
     
    function seeWinnerPrize(address _bettorAddress) public view returns (uint256) {
        require(endTimestamp > 0, "cannot see prize before bet ends");

        return bettorBetAmountInExaEsByChoice[_bettorAddress][finalResult].mul(totalPrize).div(totalBetTokensInExaEsByChoice[finalResult]);
    }

     
    function withdrawPrize() public {
        require(endTimestamp > 0, "cannot withdraw before end time");
        require(!bettorHasClaimed[msg.sender], "cannot claim again");
        require(bettorBetAmountInExaEsByChoice[msg.sender][finalResult] > minimumBetInExaEs, "caller should have a betting");  
        uint256 _winningAmount = bettorBetAmountInExaEsByChoice[msg.sender][finalResult].mul(totalPrize).div(totalBetTokensInExaEsByChoice[finalResult]);
        bettorHasClaimed[msg.sender] = true;
        betDeEx.sendTokensToAddress(
            msg.sender,
            _winningAmount
        );
    }
}