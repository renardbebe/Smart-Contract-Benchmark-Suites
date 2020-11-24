 

 
contract ERC20 {

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer (address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

 
contract StandardToken is ERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) private allowed;

    uint256 internal totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner,address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from,address _to,uint256 _value)public returns (bool){
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(address _spender,uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender,uint256 _subtractedValue) public returns (bool){
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

 
contract Rate  {
    
    using SafeMath for uint;
    
     
    uint public ETHUSDC;
    
     
    uint public usCentsPrice;
    
     
    uint public tokenWeiPrice;
    
     
    uint public requiredWeiAmount;
    
     
    uint public requiredDollarAmount;

     
    uint internal percentLimit;

     
    uint[] internal percentLimits = [10, 27, 53, 0];
    
     
    event LogConstructorInitiated(string  nextStep);
    
     
    event LogPriceUpdated(string price);
    
     
    event LogNewOraclizeQuery(string  description);


    function ethersToTokens(uint _ethAmount)
    public
    view
    returns(uint microTokens)
    {
        uint centsAmount = _ethAmount.mul(ETHUSDC);
        return centsToTokens(centsAmount);
    }
    
    function centsToTokens(uint _cents)
    public
    view
    returns(uint microTokens)
    {
        require(_cents > 0);
        microTokens = _cents.mul(1000000).div(usCentsPrice);
        return microTokens;
    }
    
    function tokensToWei(uint _microTokensAmount)
    public
    view
    returns(uint weiAmount) {
        uint centsWei = SafeMath.div(1 ether, ETHUSDC);
        uint microTokenWeiPrice = centsWei.mul(usCentsPrice).div(10 ** 6);
        weiAmount = _microTokensAmount.mul(microTokenWeiPrice);
        return weiAmount;
    }
    
    function tokensToCents(uint _microTokenAmount)
    public
    view
    returns(uint centsAmount) {
        centsAmount = _microTokenAmount.mul(usCentsPrice).div(1000000);
        return centsAmount;
    }
    

    function stringUpdate(string _rate) internal {
        ETHUSDC = getInt(_rate, 0);
        uint centsWei = SafeMath.div(1 ether, ETHUSDC);
        tokenWeiPrice = usCentsPrice.mul(centsWei);
        requiredWeiAmount = requiredDollarAmount.mul(100).mul(1 ether).div(ETHUSDC);
    }
    
    function getInt(string _a, uint _b) private pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        return mint;
    }
    
}

 
contract IMPERIVMCoin is StandardToken {
    
    using SafeMath for uint;
    
    string public name = "IMPERIVMCoin";
    string public symbol = "IMPC";
    uint8 public decimals = 6;
    
    address owner;
    
     
    constructor(uint _initialSupply) public {
        totalSupply_ = _initialSupply * 10 ** uint(decimals);
        owner = msg.sender;
        balances[owner] = balances[owner].add(totalSupply_);
    }
    
}  

 
contract Ownable {

     
    address public initialOwner;
    
    mapping(address => bool) owners;
    
     
    event AddOwner(address indexed admin);
    
     
    event DeleteOwner(address indexed admin);
    
     
    modifier onlyOwners() {
        require(
            msg.sender == initialOwner
            || inOwners(msg.sender)
        );
        _;
    }
    
     
    modifier onlyInitialOwner() {
        require(msg.sender == initialOwner);
        _;
    }
    
     
    function addOwner(address _wallet) public onlyInitialOwner {
        owners[_wallet] = true;
        emit AddOwner(_wallet);
    }
    
     
    function deleteOwner(address _wallet) public onlyInitialOwner {
        owners[_wallet] = false;
        emit DeleteOwner(_wallet);
    }
    
     
    function inOwners(address _wallet)
    public
    view
    returns(bool)
    {
        if(owners[_wallet]){ 
            return true;
        }
        return false;
    }
    
}

 
contract Lifecycle is Ownable, Rate {
    
     
    enum Stages {
        Private,
        PreSale,
        Sale,
        Cancel,
        Stopped
    }
    
     
    Stages public previousStage;
    
     
    Stages public crowdsaleStage;
    
     
    event ICOStopped(uint timeStamp);
    
     
    event ICOContinued(uint timeStamp);
    
     
    event CrowdsaleStarted(uint timeStamp);
    
     
    event ICOSwitched(uint timeStamp,uint newPrice,uint newRequiredDollarAmount);
    
    modifier appropriateStage() {
        require(
            crowdsaleStage != Stages.Cancel,
            "ICO is finished now"
        );
        
        require(
            crowdsaleStage != Stages.Stopped,
            "ICO is temporary stopped at the moment"
        );
        _;
    }
    
    function stopCrowdsale()
    public
    onlyOwners
    {
        require(crowdsaleStage != Stages.Stopped);
        previousStage = crowdsaleStage;
        crowdsaleStage = Stages.Stopped;
        
        emit ICOStopped(now);
    }
    
    function continueCrowdsale()
    public
    onlyOwners
    {
        require(crowdsaleStage == Stages.Stopped);
        crowdsaleStage = previousStage;
        previousStage = Stages.Stopped;
        
        emit ICOContinued(now);
    }
    
    function nextStage(
        uint _cents,
        uint _requiredDollarAmount
    )
    public
    onlyOwners
    appropriateStage
    {
        crowdsaleStage = Stages(uint(crowdsaleStage)+1);
        setUpConditions( _cents, _requiredDollarAmount);
        emit ICOSwitched(now,_cents,_requiredDollarAmount);
    }
    
     
    function setUpConditions(
        uint _cents,
        uint _requiredDollarAmount
    )
    internal
    {
        require(_cents > 0);
        require(_requiredDollarAmount > 0);
        
        percentLimit =  percentLimits[ uint(crowdsaleStage) ];
        usCentsPrice = _cents;
        requiredDollarAmount = _requiredDollarAmount;
    }
    
}



 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



 
contract Verification is Ownable {
    
     
    event AddBuyer(address indexed buyer);
    
     
    event DeleteBuyer(address indexed buyer, bool indexed success);
    
    mapping(address => bool) public approvedBuyers;
    
     
    function addBuyer(address _buyer)
    public
    onlyOwners
    returns(bool success)
    {
        approvedBuyers[_buyer] = true;
        emit AddBuyer(_buyer);
        return true;
    }  
    
     
    function deleteBuyer(address _buyer)
    public
    onlyOwners
    returns(bool success)
    {
        if (approvedBuyers[_buyer]) {
            delete approvedBuyers[_buyer];
            emit DeleteBuyer(_buyer, true);
            return true;
        } else {
            emit DeleteBuyer(_buyer, false);
            return false;
        }
    }
    
     
    function getBuyer(address _buyer) public view  returns(bool success){
        if (approvedBuyers[_buyer]){
            return true;  
        }
        return false;        
    }
    
}
 
contract IMPCrowdsale is Lifecycle, Verification {

    using SafeMath for uint;
     
     
    IMPERIVMCoin public token;
    
     
    uint public weiRaised;
    
     
    uint public totalSold;
    
     
    uint lastTimeStamp;
    
     
    event TokenPurchase(
        address indexed purchaser,
        uint value,
        uint amount
    );
    
     
    event StringUpdate(string rate);
    
    
     
    event ManualTransfer(address indexed to, uint indexed value);

    constructor(
        IMPERIVMCoin _token,
        uint _cents,
        uint _requiredDollarAmount
    )
    public
    {
        require(_token != address(0));
        token = _token;
        initialOwner = msg.sender;
        setUpConditions( _cents, _requiredDollarAmount);
        crowdsaleStage = Stages.Sale;
    }
    
     
    function () public payable {
        initialOwner.transfer(msg.value);
    }
    
     
    function buyTokens()
    public
    payable
    appropriateStage
    {
        require(approvedBuyers[msg.sender]);
        require(totalSold <= token.totalSupply().div(100).mul(percentLimit));

        uint weiAmount = msg.value;
        _preValidatePurchase(weiAmount);

         
        uint tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(tokens);
        
        emit TokenPurchase(
            msg.sender,
            weiAmount,
            tokens
        );

        _forwardFunds();
        _postValidatePurchase(tokens);
    }
    
    
     
    function stringCourse(string _rate) public payable onlyOwners {
        stringUpdate(_rate);
        lastTimeStamp = now;
        emit StringUpdate(_rate);
    }
    
    function manualTokenTransfer(address _to, uint _value)
    public
    onlyOwners
    returns(bool success)
    {
        if(approvedBuyers[_to]) {
            totalSold = totalSold.add(_value);
            token.transferFrom(initialOwner, _to, _value);
            emit ManualTransfer(_to, _value);
            return true;    
        } else {
            return false;
        }
    }
    
    function _preValidatePurchase(uint _weiAmount)
    internal
    view
    {
        require(
            _weiAmount >= requiredWeiAmount,
            "Your investment funds are less than minimum allowable amount for tokens buying"
        );
    }
    
     
    function _postValidatePurchase(uint _tokensAmount)
    internal
    {
        totalSold = totalSold.add(_tokensAmount);
    }
    
     
    function _getTokenAmount(uint _weiAmount)
    internal
    view
    returns (uint)
    {
        uint centsWei = SafeMath.div(1 ether, ETHUSDC);
        uint microTokenWeiPrice = centsWei.mul(usCentsPrice).div(10 ** uint(token.decimals()));
        uint amountTokensForInvestor = _weiAmount.div(microTokenWeiPrice);
        
        return amountTokensForInvestor;
    }
    
     
    function _deliverTokens(uint _tokenAmount) internal {
        token.transferFrom(initialOwner, msg.sender, _tokenAmount);
    }
    
     
    function _processPurchase(uint _tokenAmount) internal {
        _deliverTokens(_tokenAmount);
    }

     
    function _forwardFunds() internal {
        initialOwner.transfer(msg.value);
    }
    
    function destroy() public onlyInitialOwner {
        selfdestruct(this);
    }
}