 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HumanStandardToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract Disbursement {

     
    address public owner;
    address public receiver;
    uint public disbursementPeriod;
    uint public startDate;
    uint public withdrawnTokens;
    Token public token;

     
    modifier isOwner() {
        if (msg.sender != owner)
             
            revert();
        _;
    }

    modifier isReceiver() {
        if (msg.sender != receiver)
             
            revert();
        _;
    }

    modifier isSetUp() {
        if (address(token) == 0)
             
            revert();
        _;
    }

     
     
     
     
     
    function Disbursement(address _receiver, uint _disbursementPeriod, uint _startDate)
        public
    {
        if (_receiver == 0 || _disbursementPeriod == 0)
             
            revert();
        owner = msg.sender;
        receiver = _receiver;
        disbursementPeriod = _disbursementPeriod;
        startDate = _startDate;
        if (startDate == 0)
            startDate = now;
    }

     
     
    function setup(Token _token)
        public
        isOwner
    {
        if (address(token) != 0 || address(_token) == 0)
             
            revert();
        token = _token;
    }

     
     
     
    function withdraw(address _to, uint256 _value)
        public
        isReceiver
        isSetUp
    {
        uint maxTokens = calcMaxWithdraw();
        if (_value > maxTokens)
            revert();
        withdrawnTokens += _value;
        token.transfer(_to, _value);
    }

     
     
    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        uint maxTokens = (token.balanceOf(this) + withdrawnTokens) * (now - startDate) / disbursementPeriod;
        if (withdrawnTokens >= maxTokens || startDate > now)
            return 0;
        return maxTokens - withdrawnTokens;
    }
}

contract Filter {

    event SetupAllowance(address indexed beneficiary, uint amount);

    Disbursement public disburser;
    address public owner;
    mapping(address => Beneficiary) public beneficiaries;

    struct Beneficiary {
        uint claimAmount;
        bool claimed;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Filter(
        address[] _beneficiaries,
        uint[] _beneficiaryTokens
    ) {
        owner = msg.sender;
        for(uint i = 0; i < _beneficiaries.length; i++) {
            beneficiaries[_beneficiaries[i]] = Beneficiary({
                claimAmount: _beneficiaryTokens[i],
                claimed: false
            });
            SetupAllowance(_beneficiaries[i],
                           beneficiaries[_beneficiaries[i]].claimAmount);
        }
    }

    function setup(Disbursement _disburser)
        public
        onlyOwner
    {
        require(address(disburser) == 0 && address(_disburser) != 0);
        disburser = _disburser; 
    }

    function claim()
        public
    {
        require(beneficiaries[msg.sender].claimed == false);
        beneficiaries[msg.sender].claimed = true;
        disburser.withdraw(msg.sender, beneficiaries[msg.sender].claimAmount);
    }
}

contract Sale {

     

    event PurchasedTokens(address indexed purchaser, uint amount);
    event TransferredPreBuyersReward(address indexed preBuyer, uint amount);
    event TransferredFoundersTokens(address vault, uint amount);

     

    address public owner;
    address public wallet;
    HumanStandardToken public token;
    uint public price;
    uint public startBlock;
    uint public freezeBlock;
    bool public emergencyFlag = false;
    bool public preSaleTokensDisbursed = false;
    bool public foundersTokensDisbursed = false;
    address[] public filters;

     

    modifier saleStarted {
        require(block.number >= startBlock);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notFrozen {
        require(block.number < freezeBlock);
        _;
    }

    modifier setupComplete {
        assert(preSaleTokensDisbursed && foundersTokensDisbursed);
        _;
    }

    modifier notInEmergency {
        assert(emergencyFlag == false);
        _;
    }

     

     
     
     
     
     
     
     
     
     
    function Sale(
        address _owner,
        address _wallet,
        uint256 _tokenSupply,
        string _tokenName,
        uint8 _tokenDecimals,
        string _tokenSymbol,
        uint _price,
        uint _startBlock,
        uint _freezeBlock
    ) {
        owner = _owner;
        wallet = _wallet;
        token = new HumanStandardToken(_tokenSupply, _tokenName, _tokenDecimals, _tokenSymbol);
        price = _price;
        startBlock = _startBlock;
        freezeBlock = _freezeBlock;

        assert(token.transfer(this, token.totalSupply()));
        assert(token.balanceOf(this) == token.totalSupply());
        assert(token.balanceOf(this) == 10**18);
    }

     
     
     
    function distributePreBuyersRewards(
        address[] _preBuyers,
        uint[] _preBuyersTokens
    ) 
        public
        onlyOwner
    { 
        assert(!preSaleTokensDisbursed);

        for(uint i = 0; i < _preBuyers.length; i++) {
            require(token.transfer(_preBuyers[i], _preBuyersTokens[i]));
            TransferredPreBuyersReward(_preBuyers[i], _preBuyersTokens[i]);
        }

        preSaleTokensDisbursed = true;
    }

     
     
     
     
    function distributeFoundersRewards(
        address[] _founders,
        uint[] _foundersTokens,
        uint[] _founderTimelocks
    ) 
        public
        onlyOwner
    { 
        assert(preSaleTokensDisbursed);
        assert(!foundersTokensDisbursed);

         
        uint tokensPerTranch = 0;
         
        uint tranches = _founderTimelocks.length;
         
        uint[] memory foundersTokensPerTranch = new uint[](_foundersTokens.length);

         
        for(uint i = 0; i < _foundersTokens.length; i++) {
            foundersTokensPerTranch[i] = _foundersTokens[i]/tranches;
            tokensPerTranch = tokensPerTranch + foundersTokensPerTranch[i];
        }

         
        for(uint j = 0; j < tranches; j++) {
            Filter filter = new Filter(_founders, foundersTokensPerTranch);
            filters.push(filter);
            Disbursement vault = new Disbursement(filter, 1, _founderTimelocks[j]);
             
            vault.setup(token);             
             
            filter.setup(vault);             
             
            assert(token.transfer(vault, tokensPerTranch));
            TransferredFoundersTokens(vault, tokensPerTranch);
        }

        assert(token.balanceOf(this) == 5 * 10**17);
        foundersTokensDisbursed = true;
    }

     
     
    function purchaseTokens()
        saleStarted
        payable
        setupComplete
        notInEmergency
    {
         
        uint excessAmount = msg.value % price;
        uint purchaseAmount = msg.value - excessAmount;
        uint tokenPurchase = purchaseAmount / price;

         
        require(tokenPurchase <= token.balanceOf(this));

         
        if (excessAmount > 0) {
            msg.sender.transfer(excessAmount);
        }

         
        wallet.transfer(purchaseAmount);

         
        assert(token.transfer(msg.sender, tokenPurchase));

        PurchasedTokens(msg.sender, tokenPurchase);
    }

     

    function changeOwner(address _newOwner)
        onlyOwner
    {
        require(_newOwner != 0);
        owner = _newOwner;
    }

    function changePrice(uint _newPrice)
        onlyOwner
        notFrozen
    {
        require(_newPrice != 0);
        price = _newPrice;
    }

    function changeWallet(address _wallet)
        onlyOwner
        notFrozen
    {
        require(_wallet != 0);
        wallet = _wallet;
    }

    function changeStartBlock(uint _newBlock)
        onlyOwner
        notFrozen
    {
        require(_newBlock != 0);

        freezeBlock = _newBlock - (startBlock - freezeBlock);
        startBlock = _newBlock;
    }

    function emergencyToggle()
        onlyOwner
    {
        emergencyFlag = !emergencyFlag;
    }

}