 

pragma solidity ^0.4.17;

contract Token {
     
     
    uint256 public totalSupply;
    address public sale;
    bool public transfersAllowed;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value)
        public
        validTransfer
        returns (bool success) 
    {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        validTransfer
        returns (bool success)
      {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier validTransfer()
    {
        require(msg.sender == sale || transfersAllowed);
        _;
    }   
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
        string _tokenSymbol,
        address _sale)
        public
    {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        sale = _sale;
        transfersAllowed = false;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function reversePurchase(address _tokenHolder)
        public
        onlySale
    {
        require(!transfersAllowed);
        uint value = balances[_tokenHolder];
        balances[_tokenHolder] = SafeMath.sub(balances[_tokenHolder], value);
        balances[sale] = SafeMath.add(balances[sale], value);
        Transfer(_tokenHolder, sale, value);
    }

    function removeTransferLock()
        public
        onlySale
    {
        transfersAllowed = true;
    }

    modifier onlySale()
    {
        require(msg.sender == sale);
        _;
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
        withdrawnTokens = SafeMath.add(withdrawnTokens, _value);
        token.transfer(_to, _value);
    }

     
     
    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        uint maxTokens = SafeMath.mul(SafeMath.add(token.balanceOf(this), withdrawnTokens), SafeMath.sub(now,startDate)) / disbursementPeriod;
         
        if (withdrawnTokens >= maxTokens || startDate > now)
            return 0;
        if (SafeMath.sub(maxTokens, withdrawnTokens) > token.totalSupply())
            return token.totalSupply();
        return SafeMath.sub(maxTokens, withdrawnTokens);
    }
}


library SafeMath {
  function mul(uint256 a, uint256 b) pure internal  returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Sale {

     
    event TransferredTimelockedTokens(address beneficiary, address disbursement,uint beneficiaryTokens);
    event PurchasedTokens(address indexed purchaser, uint amount);
    event LockedUnsoldTokens(uint numTokensLocked, address disburser);

     
    uint public constant TOTAL_SUPPLY = 1000000000000000000;
    uint public constant MAX_PRIVATE = 750000000000000000;
    uint8 public constant DECIMALS = 9;
    string public constant NAME = "Leverj";
    string public constant SYMBOL = "LEV";
    address public owner;
    address public whitelistAdmin;
    address public wallet;
    HumanStandardToken public token;
    uint public freezeBlock;
    uint public startBlock;
    uint public endBlock;
    uint public price_in_wei = 333333;  
    uint public privateAllocated = 0;
    bool public setupCompleteFlag = false;
    bool public emergencyFlag = false;
    address[] public disbursements;
    mapping(address => uint) public whitelistRegistrants;
    mapping(address => bool) public whitelistRegistrantsFlag;
    bool public publicSale = false;

     
    function Sale(
        address _owner,
        uint _freezeBlock,
        uint _startBlock,
        uint _endBlock,
        address _whitelistAdmin)
        public 
        checkBlockNumberInputs(_freezeBlock, _startBlock, _endBlock)
    {
        owner = _owner;
        whitelistAdmin = _whitelistAdmin;
        token = new HumanStandardToken(TOTAL_SUPPLY, NAME, DECIMALS, SYMBOL, address(this));
        freezeBlock = _freezeBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        assert(token.transfer(this, token.totalSupply()));
        assert(token.balanceOf(this) == token.totalSupply());
        assert(token.balanceOf(this) == TOTAL_SUPPLY);
    }

    function purchaseTokens()
        public
        payable
        setupComplete
        notInEmergency
        saleInProgress
    {
        require(whitelistRegistrantsFlag[msg.sender] == true);
         
        uint purchaseAmount = msg.value / price_in_wei; 
        uint excessAmount = msg.value % price_in_wei;

        if (!publicSale){
            require(whitelistRegistrants[msg.sender] > 0 );
            uint tempWhitelistAmount = whitelistRegistrants[msg.sender];
            if (purchaseAmount > whitelistRegistrants[msg.sender]){
                uint extra = SafeMath.sub(purchaseAmount,whitelistRegistrants[msg.sender]);
                purchaseAmount = whitelistRegistrants[msg.sender];
                excessAmount = SafeMath.add(excessAmount,extra*price_in_wei);
            }
            whitelistRegistrants[msg.sender] = SafeMath.sub(whitelistRegistrants[msg.sender], purchaseAmount);
            assert(whitelistRegistrants[msg.sender] < tempWhitelistAmount);
        }  

         
        require(purchaseAmount <= token.balanceOf(this));
         
        if (excessAmount > 0){
            msg.sender.transfer(excessAmount);
        }
         
        wallet.transfer(this.balance);
         
        assert(token.transfer(msg.sender, purchaseAmount));
        PurchasedTokens(msg.sender, purchaseAmount);
    }

    function lockUnsoldTokens(address _unsoldTokensWallet)
        public
        saleEnded
        setupComplete
        onlyOwner
    {
        Disbursement disbursement = new Disbursement(
            _unsoldTokensWallet,
            1*365*24*60*60,
            block.timestamp
        );
        disbursement.setup(token);
        uint amountToLock = token.balanceOf(this);
        disbursements.push(disbursement);
        token.transfer(disbursement, amountToLock);
        LockedUnsoldTokens(amountToLock, disbursement);
    }

     
    function distributeTimelockedTokens(
        address[] _beneficiaries,
        uint[] _beneficiariesTokens,
        uint[] _timelockStarts,
        uint[] _periods
    ) 
        public
        onlyOwner
        saleNotEnded
    { 
        assert(!setupCompleteFlag);
        assert(_beneficiariesTokens.length < 11);
        assert(_beneficiaries.length == _beneficiariesTokens.length);
        assert(_beneficiariesTokens.length == _timelockStarts.length);
        assert(_timelockStarts.length == _periods.length);
        for(uint i = 0; i < _beneficiaries.length; i++) {
            require(privateAllocated + _beneficiariesTokens[i] <= MAX_PRIVATE);
            privateAllocated = SafeMath.add(privateAllocated, _beneficiariesTokens[i]);
            address beneficiary = _beneficiaries[i];
            uint beneficiaryTokens = _beneficiariesTokens[i];
            Disbursement disbursement = new Disbursement(
                beneficiary,
                _periods[i],
                _timelockStarts[i]
            );
            disbursement.setup(token);
            token.transfer(disbursement, beneficiaryTokens);
            disbursements.push(disbursement);
            TransferredTimelockedTokens(beneficiary, disbursement, beneficiaryTokens);
        }
        assert(token.balanceOf(this) >= (SafeMath.sub(TOTAL_SUPPLY, MAX_PRIVATE)));
    }

    function distributePresaleTokens(address[] _buyers, uint[] _amounts)
        public
        onlyOwner
        saleNotEnded
    {
        assert(!setupCompleteFlag);
        require(_buyers.length < 11);
        require(_buyers.length == _amounts.length);
        for(uint i=0; i < _buyers.length; i++){
            require(SafeMath.add(privateAllocated, _amounts[i]) <= MAX_PRIVATE);
            assert(token.transfer(_buyers[i], _amounts[i]));
            privateAllocated = SafeMath.add(privateAllocated, _amounts[i]);
            PurchasedTokens(_buyers[i], _amounts[i]);
        }
        assert(token.balanceOf(this) >= (SafeMath.sub(TOTAL_SUPPLY, MAX_PRIVATE)));
    }

    function removeTransferLock()
        public
        onlyOwner
    {
        token.removeTransferLock();
    }

    function reversePurchase(address _tokenHolder)
        payable
        public
        onlyOwner
    {
        uint refund = SafeMath.mul(token.balanceOf(_tokenHolder),price_in_wei);
        require(msg.value >= refund);
        uint excessAmount = SafeMath.sub(msg.value, refund);
        if (excessAmount > 0) {
            msg.sender.transfer(excessAmount);
        }

        _tokenHolder.transfer(refund);
        token.reversePurchase(_tokenHolder);
    }

    function setSetupComplete()
        public
        onlyOwner
    {
        require(wallet!=0);
        require(privateAllocated!=0);  
        setupCompleteFlag = true;
    }

    function configureWallet(address _wallet)
        public
        onlyOwner
    {
        wallet = _wallet;
    }

    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        require(_newOwner != 0);
        owner = _newOwner;
    }

    function changeWhitelistAdmin(address _newAdmin)
        public
        onlyOwner
    {
        require(_newAdmin != 0);
        whitelistAdmin = _newAdmin;
    }

    function changePrice(uint _newPrice)
        public
        onlyOwner
        notFrozen
        validPrice(_newPrice)
    {
        price_in_wei = _newPrice;
    }

    function changeStartBlock(uint _newBlock)
        public
        onlyOwner
        notFrozen
    {
        require(block.number <= _newBlock && _newBlock < startBlock);
        freezeBlock = SafeMath.sub(_newBlock , SafeMath.sub(startBlock, freezeBlock));
        startBlock = _newBlock;
    }

    function emergencyToggle()
        public
        onlyOwner
    {
        emergencyFlag = !emergencyFlag;
    }
    
    function addWhitelist(address[] _purchaser, uint[] _amount)
        public
        onlyWhitelistAdmin
        saleNotEnded
    {
        assert(_purchaser.length < 11 );
        assert(_purchaser.length == _amount.length);
        for(uint i = 0; i < _purchaser.length; i++) {
            whitelistRegistrants[_purchaser[i]] = _amount[i];
            whitelistRegistrantsFlag[_purchaser[i]] = true;
        }
    }

    function startPublicSale()
        public
        onlyOwner
    {
        if (!publicSale){
            publicSale = true;
        }
    }

     
    modifier saleEnded {
        require(block.number >= endBlock);
        _;
    }
    modifier saleNotEnded {
        require(block.number < endBlock);
        _;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyWhitelistAdmin {
        require(msg.sender == owner || msg.sender == whitelistAdmin);
        _;
    }
    modifier notFrozen {
        require(block.number < freezeBlock);
        _;
    }
    modifier saleInProgress {
        require(block.number >= startBlock && block.number < endBlock);
        _;
    }
    modifier setupComplete {
        assert(setupCompleteFlag);
        _;
    }
    modifier notInEmergency {
        assert(emergencyFlag == false);
        _;
    }
    modifier checkBlockNumberInputs(uint _freeze, uint _start, uint _end) {
        require(_freeze >= block.number
        && _start >= _freeze
        && _end >= _start);
        _;
    }
    modifier validPrice(uint _price){
        require(_price > 0);
        _;
    }
}