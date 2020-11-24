 

pragma solidity ^0.4.11;

 
 
 
 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    	uint256 c = a * b;
    	assert(a == 0 || c / a == b);
    	return c;
	}

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
    
    string public constant name = "ZABERcoin";
    string public constant symbol = "ZAB";
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
    
    function Token(){
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
  
	uint8 public round = 0;

	enum State { Active, Refunding, Closed }
  
    mapping (uint8 => mapping (address => uint256)) public deposited;

    State public state;
  
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
  
    function RefundVault() public {
        state = State.Active;
    }
  
     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
		deposited[round][investor] = deposited[round][investor].add(msg.value);
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
		uint256 depositedValue = deposited[round][investor];
		deposited[round][investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }

	function restart() onlyOwner public{
	    require(state == State.Closed);
	    round += 1;
	    state = State.Active;
	}
  
     
     
    function del(address _wallet) public onlyOwner {
        selfdestruct(_wallet);
    }
}


contract DistributorRefundVault is RefundVault{
 
    address public taxCollector;
    uint256 public taxValue;
    
    function DistributorRefundVault(address _taxCollector, uint256 _taxValue) RefundVault() public{
        taxCollector = _taxCollector;
        taxValue = _taxValue;
    }
   
    function close(address _wallet) onlyOwner public {
    
        require(state == State.Active);
        require(_wallet != 0x0);
        
        state = State.Closed;
        Closed();
        uint256 allPay = this.balance;
        uint256 forTarget1;
        uint256 forTarget2;
        if(taxValue <= allPay){
           forTarget1 = taxValue;
           forTarget2 = allPay.sub(taxValue);
           taxValue = 0;
        }else {
            taxValue = taxValue.sub(allPay);
            forTarget1 = allPay;
            forTarget2 = 0;
        }
        if(forTarget1 != 0){
            taxCollector.transfer(forTarget1);
        }
       
        if(forTarget2 != 0){
            _wallet.transfer(forTarget2);
        }

    }

}


 
 
contract Crowdsale{
    using SafeMath for uint256;

    enum ICOType {preSale, sale}
    enum Roles {beneficiary,accountant,manager,observer,team}

    Token public token;

    bool public isFinalized = false;
    bool public isInitialized = false;
    bool public isPausedCrowdsale = false;

    mapping (uint8 => address) public wallets;

    uint256 public maxProfit;    
    uint256 public minProfit;    
    uint256 public stepProfit;   

    uint256 public startTime;         
    uint256 public endDiscountTime;   
    uint256 public endTime;           

     
     
     
    uint256 public rate;        
      
     
     
     
    uint256 public softCap;

     
     
    uint256 public hardCap;

     
     
     
     
     
     
     
    uint256 public overLimit;

     
     
    uint256 public minPay;

    uint256 ethWeiRaised;
    uint256 nonEthWeiRaised;
    uint256 weiPreSale;
    uint256 public tokenReserved;

    DistributorRefundVault public vault;

    SVTAllocation public lockedAllocation;

    ICOType ICO = ICOType.preSale;

    uint256 allToken;

    bool public team = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function Crowdsale(Token _token) public
    {

         
         
         
         
         
         

         
        wallets[uint8(Roles.beneficiary)] = 0x8d6b447f443ce7cAA12399B60BC9E601D03111f9; 

         
        wallets[uint8(Roles.accountant)] = 0x99a280Dc34A996474e5140f34434CE59b5e65879;

         
         
         
         
         
        wallets[uint8(Roles.manager)] = msg.sender; 

         
        wallets[uint8(Roles.observer)] = 0x8baf8F18256952362E485fEF1D0909F21f9a886C;

         
         
         
         
        wallets[uint8(Roles.team)] = 0x25365d4B293Ec34c39C00bBac3e5C5Ff2dC81F4F;

         
        changePeriod(1510311600, 1511607600, 1511607600);

         
        changeTargets(0 ether, 51195 ether);  

         
        changeRate(61250, 500 ether, 10 ether);

         
        changeDiscount(0,0,0);
 
        token = _token;
        token.setOwner();

        token.pause();  

        token.addUnpausedWallet(msg.sender);

         
        vault = new DistributorRefundVault(0x793ADF4FB1E8a74Dfd548B5E2B5c55b6eeC9a3f8, 10 ether);
    }

     
    function ICOSaleType()  public constant returns(string){
        return (ICO == ICOType.preSale)?'pre ICO':'ICO';
    }

     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function validPurchase() internal constant returns (bool) {

         
        bool withinPeriod = (now > startTime && now < endTime);

         
        bool nonZeroPurchase = msg.value >= minPay;

         
        bool withinCap = msg.value <= hardCap.sub(weiRaised()).add(overLimit);

         
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isPausedCrowdsale;
    }

     
    function hasEnded() public constant returns (bool) {

        bool timeReached = now > endTime;

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }

     
     
     
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender || !goalReached());
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

             
            if (ICO == ICOType.preSale) {

                 
                isInitialized = false;
                isFinalized = false;

                 
                ICO = ICOType.sale;

                 
                weiPreSale = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;

                 
                vault.restart();


            } 
            else  
            { 

                 
                allToken = token.totalSupply();

                 
                team = true;
            }

        }
        else  
        { 
             
            vault.enableRefunds();
        }
    }

     
     
    function finalize1()  public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(team);
        team = false;
        lockedAllocation = new SVTAllocation(token, wallets[uint8(Roles.team)]);
        token.addUnpausedWallet(lockedAllocation);
         
         
        token.mint(lockedAllocation,allToken.mul(20).div(80));
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
	     
    }

     
    function claimRefund() public{
        vault.refund(msg.sender);
    }

     
    function goalReached() public constant returns (bool) {
        return weiRaised() >= softCap;
    }

     
    function setup(uint256 _startTime, uint256 _endDiscountTime, uint256 _endTime, uint256 _softCap, uint256 _hardCap, uint256 _rate, uint256 _overLimit, uint256 _minPay, uint256 _minProfit, uint256 _maxProfit, uint256 _stepProfit) public{
            changePeriod(_startTime, _endDiscountTime, _endTime);
            changeTargets(_softCap, _hardCap);
            changeRate(_rate, _overLimit, _minPay);
            changeDiscount(_minProfit, _maxProfit, _stepProfit);
    }  

	 
     
    function changePeriod(uint256 _startTime, uint256 _endDiscountTime, uint256 _endTime) public{

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(now <= _startTime);
        require(_endDiscountTime > _startTime && _endDiscountTime <= _endTime);

        startTime = _startTime;
        endTime = _endTime;
        endDiscountTime = _endDiscountTime;

    }

     
     
    function changeTargets(uint256 _softCap, uint256 _hardCap) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(_softCap <= _hardCap);

        softCap = _softCap;
        hardCap = _hardCap;
    }

     
     
     
    function changeRate(uint256 _rate, uint256 _overLimit, uint256 _minPay) public {

         require(wallets[uint8(Roles.manager)] == msg.sender);

         require(!isInitialized);

         require(_rate > 0);

         rate = _rate;
         overLimit = _overLimit;
         minPay = _minPay;
    }

     
     
    function changeDiscount(uint256 _minProfit, uint256 _maxProfit, uint256 _stepProfit) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(_stepProfit <= _maxProfit.sub(_minProfit));

         
        if(_stepProfit > 0){
             
             
            maxProfit = _maxProfit.sub(_minProfit).div(_stepProfit).mul(_stepProfit).add(_minProfit);
        }else{
             
            maxProfit = _minProfit;
        }

        minProfit = _minProfit;
        stepProfit = _stepProfit;
    }

     
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

     
    function weiTotalRaised() public constant returns(uint256){
        return weiPreSale.add(weiRaised());
    }

     
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }

     
    function getProfitPercentForData(uint256 timeNow) public constant returns (uint256)
    {
         
        if(maxProfit == 0 || stepProfit == 0 || timeNow > endDiscountTime) {
            return minProfit.add(100);
        }

         
        if(timeNow<=startTime) {
            return maxProfit.add(100);
        }

         
        uint256 range = endDiscountTime.sub(startTime);

         
        uint256 profitRange = maxProfit.sub(minProfit);

         
        uint256 timeRest = endDiscountTime.sub(timeNow);

         
        uint256 profitProcent = profitRange.div(stepProfit).mul(timeRest.mul(stepProfit.add(1)).div(range));
        return profitProcent.add(minProfit).add(100);
    }

     
     
     
     
     
     
    function fastICO(uint256 _totalSupply) public {
      require(wallets[uint8(Roles.manager)] == msg.sender);
      require(ICO == ICOType.preSale && !isInitialized);
      token.mint(wallets[uint8(Roles.accountant)], _totalSupply);
      ICO = ICOType.sale;
    }
    
     
     
     
     
     
    function tokenUnpause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender 
        	|| (now > endTime + 120 days && ICO == ICOType.sale && isFinalized && goalReached()));
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
        return _accountant;
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


	 
	 

	 
	 

	 
	 
     
     
     
	
	 
	 
	 

	 
	 
	 
	 
	 
	 
	
	 
	 
	 
	 
	 
	
	 
	 
	 
	 
	 
	
	 

     

     
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {
        require(wallets[uint8(Roles.observer)] == msg.sender);
        bool withinPeriod = (now >= startTime && now <= endTime);
        
        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }

     
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 ProfitProcent = getProfitPercent();
         
        uint256 tokens = weiAmount.mul(rate).mul(ProfitProcent).div(100000);

         
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

    	 
        unlockedAt = now + 365 days;  
        token = _token;
        owner = _owner;
    }

     
    function unlock() public{
        require(now >= unlockedAt);
        require(token.transfer(owner,token.balanceOf(this)));
    }
}