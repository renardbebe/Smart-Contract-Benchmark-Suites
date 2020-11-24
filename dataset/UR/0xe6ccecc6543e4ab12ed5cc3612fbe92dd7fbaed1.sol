 

 
 
 
 
 
 

 

pragma solidity ^0.4.21;

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);

    function deposit(address _beneficiary) external payable;
    function setup(address _beneficiary, uint256 _arg1, uint256 _arg2, uint8 _state) external;
    function calc(uint256 _allValue) external;
    function getBeneficiaryCash(address _beneficiary) external;
    function getPartnerCash(uint8 _user, bool _isAdmin, address _msgsender, bool _calc, uint256 _weiTotalRaised) external;
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
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b>=a) return 0;
        return a - b;
    }
}

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract IToken{
    function setUnpausedWallet(address _wallet, bool mode) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function setPause(bool mode) public;
    function setMigrationAgent(address _migrationAgent) public;
    function migrateAll(address[] _holders) public;
    function burn(address _beneficiary, uint256 _value) public;
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount);
    function defrostDate(address _beneficiary) public view returns (uint256 Date);
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public;
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract ICreator{
    function createToken() external returns (IToken);
    function createFinancialStrategy() external returns(IFinancialStrategy);
}

contract BuzFinancialStrategy is IFinancialStrategy, Ownable{
    using SafeMath for uint256;

                              
    uint256[3] public percent = [20,        2,           3            ];
    uint256[3] public cap     = [200 ether, 1800 ether,  9999999 ether];  
    uint256[3] public debt1   = [0,0,0];
    uint256[3] public debt2   = [0,0,0];
    uint256[3] public total   = [0,0,0];                                  
    uint256[3] public took    = [0,0,0];
    uint256[3] public ready   = [0,0,0];

    address[3] public wallets= [
        0x356608b672fdB01C5077d1A2cb6a7b38fDdcd8A5,
        0xf1F3D1Dc1E5cEA08f127cad3B7Dbd29b299c88C8,
        0x55ecFbD0111ab365b6De98A01E9305EfD4a78FAA
    ];

    uint256 public benTook=0;
    uint256 public benReady=0;
    uint256 public newCash=0;
    uint256 public cashHistory=0;
    uint256 public prcSum=0;

    address public benWallet=0;

    function BuzFinancialStrategy() public {
        initialize();
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }

    function initialize() internal {
        for (uint8 i=0; i<percent.length; i++ ) prcSum+=percent[i];
    }
    
    function deposit(address _beneficiary) external onlyOwner payable {
        require(state == State.Active);
        newCash = newCash.add(msg.value);
        cashHistory += msg.value;
        emit Deposited(_beneficiary,msg.value);
    }


     
     
     
     
     
     
    function setup(address _beneficiary, uint256 _arg1, uint256 _arg2, uint8 _state) external onlyOwner {

        if (_state == 0)  {
            
             
             
             
            selfdestruct(_beneficiary);

        }
        else if (_state == 1 || _state == 3) {
             
             
             
             
             
        
            require(state == State.Active);
             
            state = State.Closed;
            benWallet=_beneficiary;
        
        }
        else if (_state == 2) {
             
             
             
            
            require(state == State.Closed);
            state = State.Active;
            benWallet=_beneficiary;
        
        }
        else if (_state == 4) {
             
             
             
            benWallet=_beneficiary;
        
        }
        else if (_state == 5) {
             
             

            for (uint8 user=0; user<cap.length; user++) cap[user]=cap[user].mul(_arg1).div(_arg2);
            benWallet=_beneficiary;

        }

    }

    function calc(uint256 _allValue) external onlyOwner {
        internalCalc(_allValue);
    }

    function internalCalc(uint256 _allValue) internal {

        uint256 free=newCash+benReady;
        uint256 common1=0;
        uint256 common2=0;
        uint256 spent=0;
        uint256 plan=0;
        uint8   user=0;

        if (free==0) return;

        for (user=0; user<percent.length; user++) {

            plan=_allValue*percent[user]/100;
            if (total[user]>=plan || total[user]>=cap[user]) {
                debt1[user]=0;
                debt2[user]=0;
                continue;
            }

            debt1[user]=plan.minus(total[user]);
            if (debt1[user]+total[user] > cap[user]) debt1[user]=cap[user].minus(total[user]);

            common1+=debt1[user];

            plan=free.mul(percent[user]).div(prcSum);
            debt2[user]=plan;
            if (debt2[user]+total[user] > cap[user]) debt2[user]=cap[user].minus(total[user]);
            
            common2+=debt2[user];

        }

        if (common1>0 && common1<=free) {
    
            for (user=0; user<percent.length; user++) {

                if (debt1[user]==0) continue;
                
                plan=free.mul(debt1[user]).div(common1);
                
                if (plan>debt1[user]) plan=debt1[user];
                ready[user]+=plan;
                total[user]+=plan;
                spent+=plan;
            }
        } 

        if (common2>0 && common1>free) {
        
            for (user=0; user<percent.length; user++) {
                
                if (debt2[user]==0) continue;

                plan=free.mul(debt2[user]).div(common2);

                if (plan>debt1[user]) plan=debt1[user];  
                ready[user]+=plan;
                total[user]+=plan;
                spent+=plan;
            }
        }

        if (spent>newCash+benReady) benReady=0;
        else benReady=newCash.add(benReady).minus(spent);
        newCash=0;

    }

     
    function getBeneficiaryCash(address _beneficiary) external onlyOwner {

        uint256 move=benReady;
        benWallet=_beneficiary;
        if (move == 0) return;

        emit Receive(_beneficiary, move);
        benReady = 0;
        benTook += move;
        
        _beneficiary.transfer(move);
    
    }


     
    function getPartnerCash(uint8 _user, bool _isAdmin, address _msgsender, bool _calc, uint256 _weiTotalRaised) external onlyOwner {

        require(_user<percent.length && _user<wallets.length);

        if (!_isAdmin) {
            for (uint8 i=0; i<wallets.length; i++) {
                if (wallets[i]==_msgsender) break;
            }
            if (i>=wallets.length) {
                return;
            }
        }

        if (_calc) internalCalc(_weiTotalRaised);

        uint256 move=ready[_user];
        if (move==0) return;

        emit Receive(wallets[_user], move);
        ready[_user]=0;
        took[_user]+=move;

        wallets[_user].transfer(move);
    
    }
}

contract ICrowdsale {
     
    enum Roles {beneficiary, accountant, manager, observer, bounty, company, team}
    address[8] public wallets;
}

contract Crowdsale is ICrowdsale{
 
 
 

    uint256 constant USER_UNPAUSE_TOKEN_TIMEOUT =  90 days;
    uint256 constant FORCED_REFUND_TIMEOUT1     = 300 days;
    uint256 constant FORCED_REFUND_TIMEOUT2     = 400 days;
    uint256 constant ROUND_PROLONGATE           =  90 days;
    uint256 constant BURN_TOKENS_TIME           =  60 days;

    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}

    TokenSaleType public TokenSale = TokenSaleType.round1;

    ICreator public creator;
    bool isBegin=false;

    IToken public token;
     
    IFinancialStrategy public financialStrategy;
    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;
    bool public chargeBonuses;
    bool public canFirstMint=true;

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


    uint256 public startTime= 1524009600;
    uint256 public endTime  = 1526601599;
    uint256 public renewal;

     
     
     
    uint256 public rate = 5000 ether;  

     
     
    uint256 public exchange  = 500 ether;

     
     
     
    uint256 public softCap = 0;

     
     
    uint256 public hardCap = 62000 ether;  

     
     
     
     
     
     
     
    uint256 public overLimit = 20 ether;

     
     
    uint256 public minPay = 20 finney;

    uint256 public maxAllProfit = 38;  

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    uint256 public totalSaledToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function Crowdsale(ICreator _creator) public
    {
        creator=_creator;
         
         
         
         
         
         
        wallets = [

         
         
        0x55d36E21b7ee114dA69a9d79D37a894d80d8Ed09,

         
         
        0xaebC3c0a722A30981F8d19BDA33eFA51a89E4C6C,

         
         
         
         
         
         
        msg.sender,

         
         
        0x8a91aC199440Da0B45B2E278f3fE616b1bCcC494,

         
        0x1f85AE08D0e1313C95D6D63e9A95c4eEeaC9D9a3,

         
        0x8A6d301742133C89f08153BC9F52B585F824A18b,

         
        0xE9B02195F38938f1462c59D7c1c2F15350ad1543

        ];
    }

    function onlyAdmin(bool forObserver) internal view {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender ||
        forObserver==true && wallets[uint8(Roles.observer)] == msg.sender);
    }

     
    function changeExchange(uint256 _ETHUSD) public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.observer)] == msg.sender);
        require(_ETHUSD >= 1 ether);

        softCap=softCap.mul(exchange).div(_ETHUSD);              
        hardCap=hardCap.mul(exchange).div(_ETHUSD);              
        minPay=minPay.mul(exchange).div(_ETHUSD);                

        rate=rate.mul(_ETHUSD).div(exchange);                    

        for (uint16 i = 0; i < bonuses.length; i++) {
            bonuses[i].value=bonuses[i].value.mul(exchange).div(_ETHUSD);    
        }

        financialStrategy.setup(wallets[uint8(Roles.beneficiary)], exchange, _ETHUSD, 5);

        exchange=_ETHUSD;

    }

     
     
     
     
     
    function begin() public
    {
        onlyAdmin(true);
        if (isBegin) return;
        isBegin=true;

        token = creator.createToken();

        financialStrategy = creator.createFinancialStrategy();

        token.setUnpausedWallet(wallets[uint8(Roles.accountant)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.manager)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.bounty)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.company)], true);
        token.setUnpausedWallet(wallets[uint8(Roles.observer)], true);

        bonuses.push(Bonus(20 ether, 2,0));
        bonuses.push(Bonus(100 ether, 5,0));
        bonuses.push(Bonus(400 ether, 8,0));

        profits.push(Profit(30,900 days));
    }



     
     
     
     
     
    function firstMintRound0(uint256 _amount  ) public {
        onlyAdmin(false);
        require(canFirstMint);
        begin();
        token.mint(wallets[uint8(Roles.manager)],_amount);
    }

     
    function totalSupply() external view returns (uint256){
        return token.totalSupply();
    }

     
    function getTokenSaleType() external view returns(string){
        return (TokenSale == TokenSaleType.round1)?'round1':'round2';
    }

     
    function forwardFunds() internal {
        financialStrategy.deposit.value(msg.value)(msg.sender);
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

            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 1); 

             
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
        else  
        {
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 3);
        }
    }

     
     
     
     
     
     
    function finalize2() public {

        onlyAdmin(false);
        require(chargeBonuses);
        chargeBonuses = false;

         
         
         
         
         

         
        token.mint(wallets[uint8(Roles.bounty)], totalSaledToken.mul(2).div(75));

         
        token.mint(wallets[uint8(Roles.company)], totalSaledToken.mul(10).div(75));

         
        token.mint(wallets[uint8(Roles.team)], totalSaledToken.mul(13).div(75));


    }

    function changeCrowdsale(address _newCrowdsale) external {
         
        require(wallets[uint8(Roles.manager)] == msg.sender);
        Ownable(token).transferOwnership(_newCrowdsale);
    }



     
     
     
     
     
     
     
     
    function initialize() public {

        onlyAdmin(false);
         
        require(!isInitialized);
        begin();


         
         
        require(now <= startTime);

        initialization();

        emit Initialized();

        renewal = 0;

        isInitialized = true;

        canFirstMint = false;
    }

    function initialization() internal {
        if (financialStrategy.state() != IFinancialStrategy.State.Active){
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 2);
        }
    }

     
     
     
     
     
    function getPartnerCash(uint8 _user, bool _calc) external {
        bool isAdmin=false;
        for (uint8 i=0; i<wallets.length; i++) {
            if (wallets[i]==msg.sender) {
                isAdmin=true;
                break;
            }
        }
        financialStrategy.getPartnerCash(_user, isAdmin, msg.sender, _calc, weiTotalRaised());
    }

    function getBeneficiaryCash() external {
        onlyAdmin(false);
         
        financialStrategy.getBeneficiaryCash(wallets[uint8(Roles.beneficiary)]);
    }

    function calcFin() external {
        onlyAdmin(true);
        financialStrategy.calc(weiTotalRaised());
    }

    function calcAndGet() public {
        onlyAdmin(true);
        
        financialStrategy.calc(weiTotalRaised());
        financialStrategy.getBeneficiaryCash(wallets[uint8(Roles.beneficiary)]);
        
        for (uint8 i=0; i<3; i++) {  
            financialStrategy.getPartnerCash(i, true, msg.sender, false, weiTotalRaised());
        }
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

     
    function weiTotalRaised() public constant returns(uint256){
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
            (msg.sender == wallets[uint8(_role)]  )
            ||
            (msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer))
        );

        wallets[uint8(_role)] = _wallet;
    }


     
     
     
     
     
     
     
 
 
 
 
 
 
 
 


     
     
     
     
     
     
     
    function massBurnTokens(address[] _beneficiary, uint256[] _value) external {
        onlyAdmin(false);
        require(endTime.add(renewal).add(BURN_TOKENS_TIME) > now);
        require(_beneficiary.length == _value.length);
        for(uint16 i; i<_beneficiary.length; i++) {
            token.burn(_beneficiary[i],_value[i]);
        }
    }

     
     
     
     
     
     
     
    function prolongate(uint256 _duration) external {
        onlyAdmin(false);
        require(now > startTime && now < endTime.add(renewal) && isInitialized);
        renewal = renewal.add(_duration);
        require(renewal <= ROUND_PROLONGATE);

    }
     
     
     
     
     
     
     

     
     

     
     

     

     
     
     
     
     
     
    function distructVault(bool mode) public {
        if(mode){
            if (wallets[uint8(Roles.beneficiary)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT1))) {
                financialStrategy.setup(wallets[uint8(Roles.beneficiary)], weiRaised(), 0, 0);
            }
            if (wallets[uint8(Roles.manager)] == msg.sender && (now > startTime.add(FORCED_REFUND_TIMEOUT2))) {
                financialStrategy.setup(wallets[uint8(Roles.manager)], weiRaised(), 0, 0);
            }
        } else {
            onlyAdmin(false);
            financialStrategy.setup(wallets[uint8(Roles.beneficiary)], 0, 0, 4);
        }
    }


     
     

     
     

     
     
     
     
     

     
     
     

     
     
     
     
     
     

     
     
     
     
     

     
     
     
     
     

     

     

     
     
     
     
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {

         
         
         
         
         

        require(wallets[uint8(Roles.observer)] == msg.sender || wallets[uint8(Roles.manager)] == msg.sender);
         
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

         
         
         
         
        uint256 totalProfit = bonus.add(ProfitProcent);
         
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

contract MigratableToken is BasicToken,Ownable {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }


    function migrateInternal(address _holder) internal{
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

contract Pausable is Ownable {

    mapping (address => bool) public unpausedWallet;

    event Pause();
    event Unpause();

    bool public paused = true;


     
    modifier whenNotPaused(address _to) {
        require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        _;
    }

    function onlyAdmin() internal view {
        require(owner == msg.sender || msg.sender == ICrowdsale(owner).wallets(uint8(ICrowdsale.Roles.manager)));
    }

     
    function setUnpausedWallet(address _wallet, bool mode) public {
        onlyAdmin();
        unpausedWallet[_wallet] = mode;
    }

     
    function setPause(bool mode) onlyOwner public {

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

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
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

    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public {
        onlyAdmin();
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function masFreezedTokens(address[] _beneficiary, uint256[] _amount, uint256[] _when) public {
        onlyAdmin();
        require(_beneficiary.length == _amount.length && _beneficiary.length == _when.length);
        for(uint16 i = 0; i < _beneficiary.length; i++){
            freeze storage _freeze = freezedTokens[_beneficiary[i]];
            _freeze.amount = _amount[i];
            _freeze.when = _when[i];
        }
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

contract Token is IToken, FreezingToken, MintableToken, MigratableToken, BurnableToken{
    string public constant name = "BUZcoin";
    string public constant symbol = "BUZ";
    uint8 public constant decimals = 18;
}

contract Creator is ICreator{
    IToken public token = new Token();
    IFinancialStrategy public financialStrategy = new BuzFinancialStrategy();

    function createToken() external returns (IToken) {
        Token(token).transferOwnership(msg.sender);
        return token;
    }

    function createFinancialStrategy() external returns(IFinancialStrategy) {
        BuzFinancialStrategy(financialStrategy).transferOwnership(msg.sender);
        return financialStrategy;
    }
}