 

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
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
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

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
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

contract Sale {

     

    event PurchasedTokens(address indexed purchaser, uint amount);
    event TransferredPreBuyersReward(address indexed preBuyer, uint amount);
    event TransferredTimelockedTokens(address beneficiary, address disburser, uint amount);

     

    address public owner;
    address public wallet;
    HumanStandardToken public token;
    uint public price;
    uint public startBlock;
    uint public freezeBlock;
    uint public endBlock;

    uint public totalPreBuyers;
    uint public preBuyersDispensedTo = 0;
    uint public totalTimelockedBeneficiaries;
    uint public timeLockedBeneficiariesDisbursedTo = 0;

    bool public emergencyFlag = false;
    bool public preSaleTokensDisbursed = false;
    bool public timelockedTokensDisbursed = false;

     

    modifier saleStarted {
        require(block.number >= startBlock);
        _;
    }

    modifier saleEnded {
         require(block.number > endBlock);
         _;
    }

    modifier saleNotEnded {
        require(block.number <= endBlock);
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
        assert(preSaleTokensDisbursed && timelockedTokensDisbursed);
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
        uint _freezeBlock,
        uint _totalPreBuyers,
        uint _totalTimelockedBeneficiaries,
        uint _endBlock
    ) {
        owner = _owner;
        wallet = _wallet;
        token = new HumanStandardToken(_tokenSupply, _tokenName, _tokenDecimals, _tokenSymbol);
        price = _price;
        startBlock = _startBlock;
        freezeBlock = _freezeBlock;
        totalPreBuyers = _totalPreBuyers;
        totalTimelockedBeneficiaries = _totalTimelockedBeneficiaries;
        endBlock = _endBlock;

        token.transfer(this, token.totalSupply());
        assert(token.balanceOf(this) == token.totalSupply());
        assert(token.balanceOf(this) == _tokenSupply);
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
            token.transfer(_preBuyers[i], _preBuyersTokens[i]);
            preBuyersDispensedTo += 1;
            TransferredPreBuyersReward(_preBuyers[i], _preBuyersTokens[i]);
        }

        if(preBuyersDispensedTo == totalPreBuyers) {
          preSaleTokensDisbursed = true;
        }
    }

     
     
     
     
     
    function distributeTimelockedTokens(
        address[] _beneficiaries,
        uint[] _beneficiariesTokens,
        uint[] _timelocks,
        uint[] _periods
    )
        public
        onlyOwner
    {
        assert(preSaleTokensDisbursed);
        assert(!timelockedTokensDisbursed);

        for(uint i = 0; i < _beneficiaries.length; i++) {
          address beneficiary = _beneficiaries[i];
          uint beneficiaryTokens = _beneficiariesTokens[i];

          Disbursement disbursement = new Disbursement(
            beneficiary,
            _periods[i],
            _timelocks[i]
          );

          disbursement.setup(token);
          token.transfer(disbursement, beneficiaryTokens);
          timeLockedBeneficiariesDisbursedTo += 1;

          TransferredTimelockedTokens(beneficiary, disbursement, beneficiaryTokens);
        }

        if(timeLockedBeneficiariesDisbursedTo == totalTimelockedBeneficiaries) {
          timelockedTokensDisbursed = true;
        }
    }

     
     
    function purchaseTokens()
        saleStarted
        saleNotEnded
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

         
        token.transfer(msg.sender, tokenPurchase);

        PurchasedTokens(msg.sender, tokenPurchase);
    }

     

    function changeOwner(address _newOwner)
        onlyOwner
    {
        require(_newOwner != 0);
        owner = _newOwner;
    }

    function withdrawRemainder()
         onlyOwner
         saleEnded
     {
         uint remainder = token.balanceOf(this);
         token.transfer(wallet, remainder);
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

    function changeEndBlock(uint _newBlock)
        onlyOwner
        notFrozen
    {
        require(_newBlock > startBlock);
        endBlock = _newBlock;
    }

    function emergencyToggle()
        onlyOwner
    {
        emergencyFlag = !emergencyFlag;
    }

}