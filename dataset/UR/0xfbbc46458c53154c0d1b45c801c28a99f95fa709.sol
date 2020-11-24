 

pragma solidity ^0.4.18;

 
 
 
 
 
 


 
 
contract CrowdsaleBL{
    using SafeMath for uint256;

    enum ICOType {round1, round2}
    enum Roles {beneficiary, accountant, manager, observer, bounty, team, company}

    Token public token;

    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;

    mapping (uint8 => address) public wallets;
   

    uint256 public startTime = 1516435200;     
    uint256 public endTime = 1519171199;       

     
     
     
    uint256 public rate = 400000;  

     
     
     
    uint256 public softCap = 1240000*10**18;  

     
     
    uint256 public hardCap = 9240000*10**18;  

     
     
     
     
     
     
     
    uint256 public overLimit = 20000*10**18;  

     
     
    uint256 public minPay = 36*10**15;  

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 weiRound1;
    uint256 public tokenReserved;

    RefundVault public vault;
    SVTAllocation public lockedAllocation;
    
    
    struct BonusBlock {uint256 amount; uint256 procent;}
    BonusBlock[] public bonusPattern;

    ICOType ICO = ICOType.round2;  

    uint256 allToken;

    bool public bounty;
    bool public team;
    bool public company;
    bool public partners;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function CrowdsaleBL(Token _token, uint256 firstMint) public
    {
         
         
         
         
         
         

         
        wallets[uint8(Roles.beneficiary)] = 0xe06bD713B2e33C218FDD56295Af74d45cE8c9D98;  

         
        wallets[uint8(Roles.accountant)] = 0xddC98d7d9CdD82172daD7467c8E341cfBEb077DD;  

         
         
         
         
         
        wallets[uint8(Roles.manager)] = msg.sender;

         
        wallets[uint8(Roles.observer)] = 0x76d737F21296cd1ED6938DbCA217615681b06336;  


        wallets[uint8(Roles.bounty)] = 0x4918fc7974d7Ee6F266f9256DfcA610FD735Bf27;  

         
         
         
         
        wallets[uint8(Roles.team)] = 0xc59403026685F553f8a6937C53452b9d1DE4c707;  

         
         

        wallets[uint8(Roles.company)] = 0xc59403026685F553f8a6937C53452b9d1DE4c707;  
        
        token = _token;
        token.setOwner();

        token.pause();  

        token.addUnpausedWallet(msg.sender);
        token.addUnpausedWallet(wallets[uint8(Roles.company)]);
        token.addUnpausedWallet(wallets[uint8(Roles.bounty)]);
        token.addUnpausedWallet(wallets[uint8(Roles.accountant)]);

        if (firstMint > 0){
            token.mint(msg.sender,firstMint);
        }

    }

     
    function ICOSaleType()  public constant returns(string){
        return (ICO == ICOType.round1)?'round1':'round2';
    }

     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function validPurchase() internal constant returns (bool) {

         
        bool withinPeriod = (now > startTime && now < endTime);

         
        bool nonZeroPurchase = msg.value >= minPay;

         
        return withinPeriod && nonZeroPurchase && isInitialized && !isPausedCrowdsale;
    }

     
    function hasEnded() public constant returns (bool) {

        bool timeReached = now > endTime;

        bool capReached = token.totalSupply().add(tokenReserved) >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }
    
    function finalizeAll() external {
        finalize();
        finalize1();
        finalize2();
        finalize3();
        finalize4();
    }

     
     
     
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender|| !goalReached());
        require(!isFinalized);
        require(hasEnded());

        isFinalized = true;
        finalization();
        Finalized();
    }

     
    function finalization() internal {

         
        if (goalReached()) {

             
            vault.close(wallets[uint8(Roles.beneficiary)]);

             
            if (tokenReserved > 0) {

                 
                token.mint(wallets[uint8(Roles.accountant)],tokenReserved);

                 
                tokenReserved = 0;
            }

             
            if (ICO == ICOType.round1) {

                 
                isInitialized = false;
                isFinalized = false;

                 
                ICO = ICOType.round2;

                 
                weiRound1 = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;

            }
            else  
            {

                 
                allToken = token.totalSupply();

                 
                bounty = true;
                team = true;
                company = true;
                partners = true;

            }

        }
        else  
        {
             
            vault.enableRefunds();
        }
    }

     
     
    function finalize1() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(team);
        team = false;
        lockedAllocation = new SVTAllocation(token, wallets[uint8(Roles.team)]);
        token.addUnpausedWallet(lockedAllocation);
         
         
        token.mint(lockedAllocation, allToken.mul(6).div(77));
    }

    function finalize2() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(bounty);
        bounty = false;
         
         
        token.mint(wallets[uint8(Roles.bounty)], allToken.mul(2).div(77));
    }

    function finalize3() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(company);
        company = false;
         
         
        token.mint(wallets[uint8(Roles.company)],allToken.mul(2).div(77));
    }

    function finalize4()  public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(partners);
        partners = false;
         
         
        token.mint(wallets[uint8(Roles.accountant)],allToken.mul(13).div(77));
    }


     
     
     
     
    function initialize() public{

         
        require(wallets[uint8(Roles.manager)] == msg.sender);

         
        require(!isInitialized);

         
         
        require(now <= startTime);

        initialization();

        Initialized();

        isInitialized = true;
    }

    function initialization() internal {
	    vault = new RefundVault();
    }

     
    function claimRefund() public{
        vault.refund(msg.sender);
    }

     
    function goalReached() public constant returns (bool) {
        return token.totalSupply().add(tokenReserved) >= softCap;
    }

     
    function setup(uint256 _startTime, uint256 _endTime, uint256 _softCap, uint256 _hardCap, uint256 _rate, uint256 _overLimit, uint256 _minPay, uint256[] _amount, uint256[] _procent) public{
            changePeriod(_startTime, _endTime);
            changeRate(_rate, _minPay);
            changeCap(_softCap, _hardCap, _overLimit);
            if(_amount.length > 0)
                setBonusPattern(_amount,_procent);
    }

	 
     
    function changePeriod(uint256 _startTime, uint256 _endTime) public{

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(now <= _startTime);
        require(_startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;
    }
    

     
     
     
    function changeRate(uint256 _rate, uint256 _minPay) public {

         require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.observer)] == msg.sender);

         require(_rate > 0);

         rate = _rate;
         minPay = _minPay;
    }
    
    function changeCap(uint256 _softCap, uint256 _hardCap, uint256 _overLimit) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(!isInitialized);
        require(_hardCap > _softCap);
        softCap = _softCap;
        hardCap = _hardCap;
        overLimit = _overLimit;
    }
    
    function setBonusPattern(uint256[] _amount, uint256[] _procent) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(!isInitialized);
        require(_amount.length == _procent.length);
        bonusPattern.length = _amount.length;
        for(uint256 i = 0; i < _amount.length; i++){
            bonusPattern[i] = BonusBlock(_amount[i],_procent[i]);
        }
    }

     
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

     
    function weiTotalRaised() public constant returns(uint256){
        return weiRound1.add(weiRaised());
    }


     
     
     
     
     
     
 
 
 
 
 
 

     
     
     
     
     
    function tokenUnpause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender
        	|| (now > endTime + 30 days && ICO == ICOType.round2 && isFinalized && goalReached()));
        token.unpause();
    }

     
     
    function tokenPause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender && !isFinalized);
        token.pause();
    }

     
    function crowdsalePause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(isPausedCrowdsale == false);
        isPausedCrowdsale = true;
    }

     
    function crowdsaleUnpause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(isPausedCrowdsale == true);
        isPausedCrowdsale = false;
    }

     
     
     
     
     
     
    function unpausedWallet(address _wallet) internal constant returns(bool) {
        bool _accountant = wallets[uint8(Roles.accountant)] == _wallet;
        bool _manager = wallets[uint8(Roles.manager)] == _wallet;
        bool _bounty = wallets[uint8(Roles.bounty)] == _wallet;
        bool _company = wallets[uint8(Roles.company)] == _wallet;
        return _accountant || _manager || _bounty || _company;
    }

     
     
     
     
	 
	 
	 
	 
    function moveTokens(address _migrationAgent) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        token.setMigrationAgent(_migrationAgent);
    }

	 
	 
	 
	 
    function changeWallet(Roles _role, address _wallet) public
    {
        require(
        		(msg.sender == wallets[uint8(_role)] && _role != Roles.observer)
      		||
      			(msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer))
      	);
        address oldWallet = wallets[uint8(_role)];
        wallets[uint8(_role)] = _wallet;
        if(!unpausedWallet(oldWallet))
            token.delUnpausedWallet(oldWallet);
        if(unpausedWallet(_wallet))
            token.addUnpausedWallet(_wallet);
    }

     
     
     
     
     
     
     

	 
	 

	 
	 

	 

	 
	 
    function distructVault() public {
        require(wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(now > startTime + 400 days);
        vault.del(wallets[uint8(Roles.beneficiary)]);
    }
    
    
    
    function getBonus(uint256 _tokenValue) public constant returns (uint256 value) {
        uint256 totalToken = tokenReserved.add(token.totalSupply());
        uint256 tokenValue = _tokenValue;
        uint256 currentBonus;
        uint256 calculateBonus = 0;
        uint16 i;
        for (i = 0; i < bonusPattern.length; i++){
            if(totalToken >= bonusPattern[i].amount)
                continue;
            currentBonus = tokenValue.mul(bonusPattern[i].procent.add(100000)).div(100000);
            if(totalToken.add(calculateBonus).add(currentBonus) < bonusPattern[i].amount) {
                calculateBonus = calculateBonus.add(currentBonus);
                tokenValue = 0;
                break;
            }
            currentBonus = bonusPattern[i].amount.sub(totalToken.add(calculateBonus));
            tokenValue = tokenValue.sub(currentBonus.mul(100000).div(bonusPattern[i].procent.add(100000)));
            calculateBonus = calculateBonus + currentBonus;
        }
        return calculateBonus.add(tokenValue);
    }


	 
	 

	 
	 

	 
	 
     
     
     

	 
	 
	 

	 
	 
	 
	 
	 
	 

	 
	 
	 
	 
	 

	 
	 
	 
	 
	 

	 

     

     
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {
        require(wallets[uint8(Roles.observer)] == msg.sender);
        bool withinPeriod = (now >= startTime && now <= endTime);

        bool withinCap = token.totalSupply().add(_token) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }


     
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = getBonus(weiAmount*rate/1000);
        
         
        bool withinCap = tokens <= hardCap.sub(token.totalSupply().add(tokenReserved)).add(overLimit);
        
        require(withinCap);

         
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

}

 
 
contract SVTAllocation {
    using SafeMath for uint256;

    Token public token;

	address public owner;

    uint256 public unlockedAt;

    uint256 tokensCreated = 0;

     
     
    function SVTAllocation(Token _token, address _owner) public{

    	 
        unlockedAt = now + 1 years;
        token = _token;
        owner = _owner;
    }

     
    function unlock() public{
        require(now >= unlockedAt);
        require(token.transfer(owner,token.balanceOf(this)));
    }
}



 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    	uint256 c = a * b;
    	assert(a == 0 || c / a == b);
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

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool _paused = false;

    function paused() public constant returns(bool)
    {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!paused());
        _;
    }

     
    function pause() onlyOwner public {
        require(!_paused);
        _paused = true;
        Pause();
    }

     
    function unpause() onlyOwner public {
        require(_paused);
        _paused = false;
        Unpause();
    }
}


 
contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}



 
 
contract Token is Pausable{
    using SafeMath for uint256;

    string public constant name = "High Reward Coin";
    string public constant symbol = "HRC";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    mapping (address => bool) public unpausedWallet;

    bool public mintingFinished = false;

    uint256 public totalMigrated;
    address public migrationAgent;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     function Token() public {
         owner = 0x0;
     }

     function setOwner() public{
         require(owner == 0x0);
         owner = msg.sender;
     }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require (_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        require (_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
 
 
 
 
 

     
     
    function paused() public constant returns(bool) {
        return super.paused() && !unpausedWallet[msg.sender];
    }


     
    function addUnpausedWallet(address _wallet) public onlyOwner {
        unpausedWallet[_wallet] = true;
    }

     
    function delUnpausedWallet(address _wallet) public onlyOwner {
         unpausedWallet[_wallet] = false;
    }

     
     
    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }

     
    function migrate() public
    {
        uint256 value = balances[msg.sender];
        require(value > 0);

        totalSupply = totalSupply.sub(value);
        totalMigrated = totalMigrated.add(value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Migrate(msg.sender,migrationAgent,value);
        balances[msg.sender] = 0;
    }
}

 
 
 
 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
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
        deposited[investor] = deposited[investor].add(msg.value);
        Deposited(investor,msg.value);
    }

     
    function close(address _wallet) onlyOwner public {
        require(state == State.Active);
        require(_wallet != 0x0);
        state = State.Closed;
        Closed();
        _wallet.transfer(this.balance);
    }

     
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

     
     
     
     
    function refund(address investor) public {
        require(state == State.Refunding);
        require(deposited[investor] > 0);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }

     
     
    function del(address _wallet) external onlyOwner {
        selfdestruct(_wallet);
    }
}