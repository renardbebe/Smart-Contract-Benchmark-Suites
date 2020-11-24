 

 
 
 
 

pragma solidity ^0.4.21;

 
 
 
contract Crowdsale{

    uint256 constant USER_UNPAUSE_TOKEN_TIMEOUT =  60 days;
    uint256 constant FORCED_REFUND_TIMEOUT1     = 400 days;
    uint256 constant FORCED_REFUND_TIMEOUT2     = 600 days;
    uint256 constant ROUND_PROLONGATE           =   0 days;
    uint256 constant BURN_TOKENS_TIME           =  90 days;

    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}
    TokenSaleType public TokenSale = TokenSaleType.round2;

     
    enum Roles {beneficiary, accountant, manager, observer, bounty, company, team, founders, fund, fees}

    Creator public creator;
    bool creator2;
    bool isBegin=false;
    Token public token;
    RefundVault public vault;
    AllocationTOSS public allocation;

    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;
    bool public chargeBonuses;
    bool public canFirstMint=true;

     
     
     
     
     
     
    address[10] public wallets = [

         
         
        0xAa951F7c52055B89d3F281c73d557275070cBBfb,

         
         
        0xD29f0aE1621F4Be48C4DF438038E38af546DA498,

         
         
         
         
         
         
        msg.sender,

         
         
        0x8a91aC199440Da0B45B2E278f3fE616b1bCcC494,

         
        0xd7AC0393e2B29D8aC6221CF69c27171aba6278c4,

         
        0x765f60E314766Bc25eb2a9F66991Fe867D42A449,

         
        0xF9f0c53c07803a2670a354F3de88482393ABdBac,

         
        0x61628D884b5F137c3D3e0b04b90DaE4402f32510,

         
        0xd833899Ea1b84E980daA13553CE13D1512bF0774,

         
        0xEB29e654AFF7658394C9d413dDC66711ADD44F59

    ];



    struct Bonus {
        uint256 value;
        uint256 procent;
        uint256 freezeTime;
    }

    struct Profit {
        uint256 percent;
        uint256 duration;
    }

    struct Freezed {
        uint256 value;
        uint256 dateTo;
    }

    Bonus[] public bonuses;
    Profit[] public profits;


    uint256 public startTime= 1524560400;
    uint256 public endTime  = 1529830799;
    uint256 public renewal;

     
     
     
    uint256 public rate = 10000 ether;

     
     
    uint256 public exchange  = 700 ether;  

     
     
     
    uint256 public softCap = 8500 ether;

     
     
    uint256 public hardCap = 71500 ether;

     
     
     
     
     
     
     
    uint256 public overLimit = 20 ether;

     
     
    uint256 public minPay = 71 finney;

    uint256 public maxAllProfit = 30;

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    uint256 public totalSaledToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function Crowdsale(Creator _creator) public
    {
        creator2=true;
        creator=_creator;
    }

    function onlyAdmin(bool forObserver) internal view {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender ||
            forObserver==true && wallets[uint8(Roles.observer)] == msg.sender);
    }

     
     
     
     
     
    function begin() internal
    {
        if (isBegin) return;
        isBegin=true;

        token = creator.createToken();
        if (creator2) {
            vault = creator.createRefund();
        }

        token.setUnpausedWallet(wallets[uint8(Roles.accountant)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.manager)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.bounty)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.company)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.observer)], true);

        bonuses.push(Bonus(71 ether, 30, 30*5 days));

        profits.push(Profit(15,1 days));
        profits.push(Profit(10,2 days));
        profits.push(Profit(5, 4 days));

    }



     
     
     
     
     
    function firstMintRound0(uint256 _amount) public {
        onlyAdmin(false);
        require(canFirstMint);
        begin();
        token.mint(wallets[uint8(Roles.accountant)],_amount);
    }

     
    function totalSupply() external view returns (uint256){
        return token.totalSupply();
    }

     
    function getTokenSaleType() external view returns(string){
        return (TokenSale == TokenSaleType.round1)?'round1':'round2';
    }

     
    function forwardFunds() internal {
        if(address(vault) != 0x0){
            vault.deposit.value(msg.value)(msg.sender);
        }else {
            if(address(this).balance > 0){
                wallets[uint8(Roles.beneficiary)].transfer(address(this).balance);
            }
        }

    }

     
    function validPurchase() internal view returns (bool) {

         
        bool withinPeriod = (now > startTime && now < endTime.add(renewal));

         
        bool nonZeroPurchase = msg.value >= minPay;

         
        bool withinCap = msg.value <= hardCap.sub(weiRaised()).add(overLimit);

         
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isPausedCrowdsale;
    }

     
    function hasEnded() public view returns (bool) {

        bool timeReached = now > endTime.add(renewal);

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }

     
     
     
     
     
     
     
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender || !goalReached());
        require(!isFinalized);
        require(hasEnded() || ((wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender) && goalReached()));

        isFinalized = true;
        finalization();
        emit Finalized();
    }

     
     
     
     
     
    function finalization() internal {

         
         
        if (goalReached()) {

            if(address(vault) != 0x0){
                 
                vault.close(wallets[uint8(Roles.beneficiary)], wallets[uint8(Roles.fees)], ethWeiRaised.mul(7).div(100));  
            }

             
            if (tokenReserved > 0) {

                token.mint(wallets[uint8(Roles.accountant)],tokenReserved);

                 
                tokenReserved = 0;
            }

             
            if (TokenSale == TokenSaleType.round1) {

                 
                isInitialized = false;
                isFinalized = false;

                 
                TokenSale = TokenSaleType.round2;

                 
                weiRound1 = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;



            }
            else  
            {

                 
                chargeBonuses = true;

                totalSaledToken = token.totalSupply();

            }

        }
        else if (address(vault) != 0x0)  
        {
             

            vault.enableRefunds();
        }
    }

     
     
     
     
     
     
    function finalize2() public {

        onlyAdmin(false);
        require(chargeBonuses);
        chargeBonuses = false;

        allocation = creator.createAllocation(token, now + 1 years  , now + 2 years  );
        token.setUnpausedWallet(allocation, true);

         
        allocation.addShare(wallets[uint8(Roles.team)],       6,  50);  
        allocation.addShare(wallets[uint8(Roles.founders)],  10,  50);  
        allocation.addShare(wallets[uint8(Roles.fund)],       6, 100);  

         
        token.mint(allocation, totalSaledToken.mul(22).div(70));

         
        token.mint(wallets[uint8(Roles.bounty)], totalSaledToken.mul(7).div(70));

         
        token.mint(wallets[uint8(Roles.company)], totalSaledToken.mul(1).div(70));

    }



     
     
     
     
     
     
     
     
    function initialize() public {

        onlyAdmin(false);
         
        require(!isInitialized);
        begin();


         
         
        require(now <= startTime);

        initialization();

        emit Initialized();

        isInitialized = true;
        renewal = 0;
        canFirstMint = false;
    }

    function initialization() internal {
        if (address(vault) != 0x0 && vault.state() != RefundVault.State.Active){
            vault.restart();
        }
    }

     
     
     
     
     
    function claimRefund() external {
        require(address(vault) != 0x0);
        vault.refund(msg.sender);
    }

     
    function goalReached() public view returns (bool) {
        return weiRaised() >= softCap;
    }


     
     
     
     
     
    function setup(uint256 _startTime, uint256 _endTime, uint256 _softCap, uint256 _hardCap,
        uint256 _rate, uint256 _exchange,
        uint256 _maxAllProfit, uint256 _overLimit, uint256 _minPay,
        uint256[] _durationTB , uint256[] _percentTB, uint256[] _valueVB, uint256[] _percentVB, uint256[] _freezeTimeVB) public
    {

        onlyAdmin(false);
        require(!isInitialized);

        begin();

         
        require(now <= _startTime);
        require(_startTime < _endTime);
        startTime = _startTime;
        endTime = _endTime;

         
        require(_softCap <= _hardCap);
        softCap = _softCap;
        hardCap = _hardCap;

        require(_rate > 0);
        rate = _rate;

        overLimit = _overLimit;
        minPay = _minPay;
        exchange = _exchange;
        maxAllProfit = _maxAllProfit;

        require(_valueVB.length == _percentVB.length && _valueVB.length == _freezeTimeVB.length);
        bonuses.length = _valueVB.length;
        for(uint256 i = 0; i < _valueVB.length; i++){
            bonuses[i] = Bonus(_valueVB[i],_percentVB[i],_freezeTimeVB[i]);
        }

        require(_percentTB.length == _durationTB.length);
        profits.length = _percentTB.length;
        for( i = 0; i < _percentTB.length; i++){
            profits[i] = Profit(_percentTB[i],_durationTB[i]);
        }

    }

     
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

     
    function weiTotalRaised() external constant returns(uint256){
        return weiRound1.add(weiRaised());
    }

     
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }

     
    function getProfitPercentForData(uint256 _timeNow) public constant returns (uint256){
        uint256 allDuration;
        for(uint8 i = 0; i < profits.length; i++){
            allDuration = allDuration.add(profits[i].duration);
            if(_timeNow < startTime.add(allDuration)){
                return profits[i].percent;
            }
        }
        return 0;
    }

    function getBonuses(uint256 _value) public constant returns (uint256,uint256,uint256){
        if(bonuses.length == 0 || bonuses[0].value > _value){
            return (0,0,0);
        }
        uint16 i = 1;
        for(i; i < bonuses.length; i++){
            if(bonuses[i].value > _value){
                break;
            }
        }
        return (bonuses[i-1].value,bonuses[i-1].procent,bonuses[i-1].freezeTime);
    }

     
     
     
     
     
     
     
     
     
     
    function tokenUnpause() external {
        require(wallets[uint8(Roles.manager)] == msg.sender
            || (now > endTime.add(renewal).add(USER_UNPAUSE_TOKEN_TIMEOUT) && TokenSale == TokenSaleType.round2 && isFinalized && goalReached()));
        token.setPause(false);
    }

     
     
     
     
     
     
    function tokenPause() public {
        onlyAdmin(false);
        require(!isFinalized);
        token.setPause(true);
    }

     
     
     
     
     
    function setCrowdsalePause(bool mode) public {
        onlyAdmin(false);
        isPausedCrowdsale = mode;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function moveTokens(address _migrationAgent) public {
        onlyAdmin(false);
        token.setMigrationAgent(_migrationAgent);
    }

     
     
     
     
    function migrateAll(address[] _holders) public {
        onlyAdmin(false);
        token.migrateAll(_holders);
    }

     
     
     
     
     
     
     
     
    function changeWallet(Roles _role, address _wallet) external
    {
        require(
            (msg.sender == wallets[uint8(_role)] && _role != Roles.observer)
            ||
            (msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer) && _role != Roles.fees )
        );

        wallets[uint8(_role)] = _wallet;
    }


     
     
     
     
     
     
     
    function resetAllWallets() external{
        address _beneficiary = wallets[uint8(Roles.beneficiary)];
        require(msg.sender == _beneficiary);
        for(uint8 i = 0; i < wallets.length; i++){
            if(uint8(Roles.fees) == i || uint8(Roles.team) == i)
                continue;

            wallets[i] = _beneficiary;
        }
        token.setUnpausedWallet(_beneficiary, true);
    }


     
     
     
     
     
     
    function massBurnTokens(address[] _beneficiary, uint256[] _value) external {
        onlyAdmin(false);
        require(endTime.add(renewal).add(BURN_TOKENS_TIME) > now);
        require(_beneficiary.length == _value.length);
        for(uint16 i; i<_beneficiary.length; i++) {
            token.burn(_beneficiary[i],_value[i]);
        }
    }

     
     
     
     
     
     
     
    function prolong(uint256 _duration) external {
        onlyAdmin(false);
        require(now > startTime && now < endTime.add(renewal) && isInitialized);
        renewal = renewal.add(_duration);
        require(renewal <= ROUND_PROLONGATE);

    }
     
     
     
     
     
     
     

     
     

     
     

     

     
     
     
     
     
     
    function distructVault() public {
        require(address(vault) != 0x0);
        if (wallets[uint8(Roles.beneficiary)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT1))) {
            vault.del(wallets[uint8(Roles.beneficiary)]);
        }
        if (wallets[uint8(Roles.manager)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT2))) {
            vault.del(wallets[uint8(Roles.manager)]);
        }
    }


     
     

     
     

     
     
     
     
     

     
     
     

     
     
     
     
     
     

     
     
     
     
     

     
     
     
     
     

     

     
     

     

     
     
     
     
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {
         
        onlyAdmin(true);
        bool withinPeriod = (now >= startTime && now <= endTime.add(renewal));

        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }

    function lokedMint(address _beneficiary, uint256 _value, uint256 _freezeTime) internal {
        if(_freezeTime > 0){

            uint256 totalBloked = token.freezedTokenOf(_beneficiary).add(_value);
            uint256 pastDateUnfreeze = token.defrostDate(_beneficiary);
            uint256 newDateUnfreeze = _freezeTime.add(now);
            newDateUnfreeze = (pastDateUnfreeze > newDateUnfreeze ) ? pastDateUnfreeze : newDateUnfreeze;

            token.freezeTokens(_beneficiary,totalBloked,newDateUnfreeze);
        }
        token.mint(_beneficiary,_value);
    }


     
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 ProfitProcent = getProfitPercent();

        uint256 value;
        uint256 percent;
        uint256 freezeTime;

        (value,
        percent,
        freezeTime) = getBonuses(weiAmount);

        Bonus memory curBonus = Bonus(value,percent,freezeTime);

        uint256 bonus = curBonus.procent;

         
         
        uint256 totalProfit = (ProfitProcent < bonus) ? bonus : ProfitProcent;

         
        totalProfit = (totalProfit > maxAllProfit) ? maxAllProfit : totalProfit;

         
        uint256 tokens = weiAmount.mul(rate).mul(totalProfit.add(100)).div(100 ether);

         
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        lokedMint(beneficiary, tokens, curBonus.freezeTime);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }



}

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
 
 
 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    uint8 round;

    mapping (uint8 => mapping (address => uint256)) public deposited;

    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Deposited(address indexed beneficiary, uint256 weiAmount);

    function RefundVault() public {
        state = State.Active;
    }

     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[round][investor] = deposited[round][investor].add(msg.value);
        emit Deposited(investor,msg.value);
    }

     
    function close(address _wallet1, address _wallet2, uint256 _feesValue) onlyOwner public {
        require(state == State.Active);
        require(_wallet1 != 0x0);
        state = State.Closed;
        emit Closed();
        if(_wallet2 != 0x0)
            _wallet2.transfer(_feesValue);
        _wallet1.transfer(address(this).balance);
    }

     
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

     
     
     
     
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[round][investor];
        require(depositedValue > 0);
        deposited[round][investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function restart() external onlyOwner {
        require(state == State.Closed);
        round++;
        state = State.Active;

    }

     
     
    function del(address _wallet) external onlyOwner {
        selfdestruct(_wallet);
    }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



   
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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

   
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
}



 
contract Pausable is Ownable {

  mapping (address => bool) public unpausedWallet;

  event Pause();
  event Unpause();

  bool public paused = true;


   
  modifier whenNotPaused(address _to) {
    require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
    _;
  }

    
  function setUnpausedWallet(address _wallet, bool mode) public {
       require(owner == msg.sender || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
       unpausedWallet[_wallet] = mode;
  }

   
  function setPause(bool mode) public onlyOwner {
    if (!paused && mode) {
        paused = true;
        emit Pause();
    }
    if (paused && !mode) {
        paused = false;
        emit Unpause();
    }
  }

}



 
contract PausableToken is StandardToken, Pausable {

    mapping (address => bool) public grantedToSetUnpausedWallet;

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
      return super.transferFrom(_from, _to, _value);
    }

    function grantToSetUnpausedWallet(address _to, bool permission) public {
        require(owner == msg.sender || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        grantedToSetUnpausedWallet[_to] = permission;
    }

     
    function setUnpausedWallet(address _wallet, bool mode) public {
        require(owner == msg.sender || grantedToSetUnpausedWallet[msg.sender] || msg.sender == Crowdsale(owner).wallets(uint8(Crowdsale.Roles.manager)));
        unpausedWallet[_wallet] = mode;
    }
}


contract MigratableToken is BasicToken,Ownable {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }

    function migrateInternal(address _holder) internal {
        require(migrationAgent != 0x0);

        uint256 value = balances[_holder];
        balances[_holder] = 0;

        totalSupply_ = totalSupply_.sub(value);
        totalMigrated = totalMigrated.add(value);

        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        emit Migrate(_holder,migrationAgent,value);
    }

    function migrateAll(address[] _holders) public onlyOwner {
        for(uint i = 0; i < _holders.length; i++){
            migrateInternal(_holders[i]);
        }
    }

     
    function migrate() public
    {
        require(balances[msg.sender] > 0);
        migrateInternal(msg.sender);
    }

}

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract FreezingToken is PausableToken {
    struct freeze {
        uint256 amount;
        uint256 when;
    }


    mapping (address => freeze) freezedTokens;


     
     
     
     
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

     
     
     
     
    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }


     
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public onlyOwner {
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(unpausedWallet[msg.sender]);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_to];
            _freeze.amount = _freeze.amount.add(_value);
            _freeze.when = (_freeze.when > _when)? _freeze.when: _when;
        }
        transfer(_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        return super.transferFrom( _from,_to,_value);
    }



}

contract BurnableToken is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);

   
  function burn(address _beneficiary, uint256 _value) public onlyOwner {
    require(_value <= balances[_beneficiary]);
     
     

    balances[_beneficiary] = balances[_beneficiary].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_beneficiary, _value);
    emit Transfer(_beneficiary, address(0), _value);
  }
}

 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
 
contract Token is FreezingToken, MintableToken, MigratableToken, BurnableToken {
    string public constant name = "TOSS";

    string public constant symbol = "PROOF OF TOSS";

    uint8 public constant decimals = 18;

    mapping (address => mapping (address => bool)) public grantedToAllowBlocking;  
    mapping (address => mapping (address => bool)) public allowedToBlocking;  
    mapping (address => mapping (address => uint256)) public blocked;  

    event TokenOperationEvent(string operation, address indexed from, address indexed to, uint256 value, address indexed _contract);


    modifier contractOnly(address _to) {
        uint256 codeLength;

        assembly {
         
        codeLength := extcodesize(_to)
        }

        require(codeLength > 0);

        _;
    }

     

    function transferToContract(address _to, uint256 _value, bytes _data) public contractOnly(_to) returns (bool) {
         
         


        super.transfer(_to, _value);

        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);

        return true;
    }

     
     
     
    function grantToAllowBlocking(address _contract, bool permission) contractOnly(_contract) public {


        grantedToAllowBlocking[msg.sender][_contract] = permission;

        emit TokenOperationEvent('grant_allow_blocking', msg.sender, _contract, 0, 0);
    }

     
     
     
    function allowBlocking(address _owner, address _contract) contractOnly(_contract) public {


        require(_contract != msg.sender && _contract != owner);

        require(grantedToAllowBlocking[_owner][msg.sender]);

        allowedToBlocking[_owner][_contract] = true;

        emit TokenOperationEvent('allow_blocking', _owner, _contract, 0, msg.sender);
    }

     
     
     
    function blockTokens(address _blocking, uint256 _value) whenNotPaused(_blocking) public {
        require(allowedToBlocking[_blocking][msg.sender]);

        require(balanceOf(_blocking) >= freezedTokenOf(_blocking).add(_value) && _value > 0);

        balances[_blocking] = balances[_blocking].sub(_value);
        blocked[_blocking][msg.sender] = blocked[_blocking][msg.sender].add(_value);

        emit Transfer(_blocking, address(0), _value);
        emit TokenOperationEvent('block', _blocking, 0, _value, msg.sender);
    }

     
     
     
     
    function unblockTokens(address _blocking, address _unblockTo, uint256 _value) whenNotPaused(_unblockTo) public {
        require(allowedToBlocking[_blocking][msg.sender]);
        require(blocked[_blocking][msg.sender] >= _value && _value > 0);

        blocked[_blocking][msg.sender] = blocked[_blocking][msg.sender].sub(_value);
        balances[_unblockTo] = balances[_unblockTo].add(_value);

        emit Transfer(address(0), _blocking, _value);

        if (_blocking != _unblockTo) {
            emit Transfer(_blocking, _unblockTo, _value);
        }

        emit TokenOperationEvent('unblock', _blocking, _unblockTo, _value, msg.sender);
    }
}

 
 
contract AllocationTOSS is Ownable {
    using SafeMath for uint256;

    struct Share {
        uint256 proportion;
        uint256 forPart;
    }

     
    uint256 public unlockPart1;
    uint256 public unlockPart2;
    uint256 public totalShare;

    mapping(address => Share) public shares;

    ERC20Basic public token;

    address public owner;

     
     
    function AllocationTOSS(ERC20Basic _token, uint256 _unlockPart1, uint256 _unlockPart2) public{
        unlockPart1 = _unlockPart1;
        unlockPart2 = _unlockPart2;
        token = _token;
    }

    function addShare(address _beneficiary, uint256 _proportion, uint256 _percenForFirstPart) onlyOwner external {
        shares[_beneficiary] = Share(shares[_beneficiary].proportion.add(_proportion),_percenForFirstPart);
        totalShare = totalShare.add(_proportion);
    }

     
    function unlockFor(address _owner) public {
        require(now >= unlockPart1);
        uint256 share = shares[_owner].proportion;
        if (now < unlockPart2) {
            share = share.mul(shares[_owner].forPart)/100;
            shares[_owner].forPart = 0;
        }
        if (share > 0) {
            uint256 unlockedToken = token.balanceOf(this).mul(share).div(totalShare);
            shares[_owner].proportion = shares[_owner].proportion.sub(share);
            totalShare = totalShare.sub(share);
            token.transfer(_owner,unlockedToken);
        }
    }
}

contract Creator{
    Token public token = new Token();
    RefundVault public refund = new RefundVault();

    function createToken() external returns (Token) {
        token.transferOwnership(msg.sender);
        return token;
    }

    function createAllocation(Token _token, uint256 _unlockPart1, uint256 _unlockPart2) external returns (AllocationTOSS) {
        AllocationTOSS allocation = new AllocationTOSS(_token,_unlockPart1,_unlockPart2);
        allocation.transferOwnership(msg.sender);
        return allocation;
    }

    function createRefund() external returns (RefundVault) {
        refund.transferOwnership(msg.sender);
        return refund;
    }

}