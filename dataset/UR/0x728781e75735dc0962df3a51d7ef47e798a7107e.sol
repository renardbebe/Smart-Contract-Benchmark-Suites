 

pragma solidity ^0.4.16;

 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

 
contract Owned {

    address public owner;
    address public newOwner;
    modifier onlyOwner { assert(msg.sender == owner); _; }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ERC20 {
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract ERC20Token is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalTokens; 

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(_allowance, _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Wolk is ERC20Token, Owned {

     
    string  public constant name = "Wolk Protocol Token";
    string  public constant symbol = "WOLK";
    uint256 public constant decimals = 18;

     
    uint256 public reserveBalance = 0; 
    uint8  public constant percentageETHReserve = 15;

     
    address public multisigWallet;


     
    mapping (address => bool) settlers;
    modifier onlySettler { assert(settlers[msg.sender] == true); _; }

     
    address public wolkSale;
    bool    public allSaleCompleted = false;
    bool    public openSaleCompleted = false;
    modifier isTransferable { require(allSaleCompleted); _; }
    modifier onlyWolk { assert(msg.sender == wolkSale); _; }

     
    event WolkCreated(address indexed _to, uint256 _tokenCreated);
    event WolkDestroyed(address indexed _from, uint256 _tokenDestroyed);
    event LogRefund(address indexed _to, uint256 _value);
}

contract WolkTGE is Wolk {

     
    mapping (address => uint256) contribution;
    mapping (address => uint256) presaleLimit;
    mapping (address => bool) presaleContributor;
    uint256 public constant tokenGenerationMin = 50 * 10**6 * 10**decimals;
    uint256 public constant tokenGenerationMax = 150 * 10**6 * 10**decimals;
    uint256 public presale_start_block; 
    uint256 public start_block;
    uint256 public end_block;

     
     
     
     
     
     
     
    function wolkGenesis(uint256 _presaleStartBlock, uint256 _startBlock, uint256 _endBlock, address _wolkWallet, address _wolkSale) onlyOwner returns (bool success){
        require((totalTokens < 1) && (block.number <= _startBlock) && (_endBlock > _startBlock) && (_startBlock > _presaleStartBlock));
        presale_start_block = _presaleStartBlock;
        start_block = _startBlock;
        end_block = _endBlock;
        multisigWallet = _wolkWallet;
        wolkSale = _wolkSale;
        settlers[msg.sender] = true;
        return true;
    }

     
     
     
    function addParticipant(address[] _presaleParticipants, uint256[] _contributionLimits) onlyOwner returns (bool success) {
        require(_presaleParticipants.length == _contributionLimits.length);         
        for (uint cnt = 0; cnt < _presaleParticipants.length; cnt++){           
            presaleContributor[_presaleParticipants[cnt]] = true;
            presaleLimit[_presaleParticipants[cnt]] =  safeMul(_contributionLimits[cnt], 10**decimals);       
        }
        return true;
    } 

     
     
     
    function removeParticipant(address[] _presaleParticipants) onlyOwner returns (bool success){         
        for (uint cnt = 0; cnt < _presaleParticipants.length; cnt++){           
            presaleContributor[_presaleParticipants[cnt]] = false;
            presaleLimit[_presaleParticipants[cnt]] = 0;      
        }
        return true;
    }

     
     
     
    function participantBalance(address _participant) constant returns (uint256 remainingAllocation) {
        return presaleLimit[_participant];
    }
    

     
     
    function tokenGenerationEvent(address _participant) payable external {
        require( presaleContributor[_participant] && !openSaleCompleted && !allSaleCompleted && (block.number <= end_block) && msg.value > 0);

         

        uint256 rate = 1000;   

        if ( totalTokens < (50 * 10**6 * 10**decimals) ) {  
            rate = 1177;
        } else if ( totalTokens < (60 * 10**6 * 10**decimals) ) {  
            rate = 1143;
        } else if ( totalTokens < (70 * 10**6 * 10**decimals) ) {  
            rate = 1111;
        } else if ( totalTokens < (80 * 10**6 * 10**decimals) ) {  
            rate = 1081;
        } else if ( totalTokens < (90 * 10**6 * 10**decimals) ) {  
            rate = 1053;
        } else if ( totalTokens < (100 * 10**6 * 10**decimals) ) {  
            rate = 1026;
        }else{
            rate = 1000;
        }

        if ((block.number < start_block) && (block.number >= presale_start_block))  { 
            require(presaleLimit[_participant] >= msg.value);
            presaleLimit[_participant] = safeSub(presaleLimit[_participant], msg.value);
        } else {
            require(block.number >= start_block) ;
        }

        uint256 tokens = safeMul(msg.value, rate);
        uint256 checkedSupply = safeAdd(totalTokens, tokens);
        require(checkedSupply <= tokenGenerationMax);

        totalTokens = checkedSupply;
        Transfer(address(this), _participant, tokens);
        balances[_participant] = safeAdd(balances[_participant], tokens);
        contribution[_participant] = safeAdd(contribution[_participant], msg.value);
        WolkCreated(_participant, tokens);  
    }


     
    function refund() external {
        require((contribution[msg.sender] > 0) && (!allSaleCompleted) && (totalTokens < tokenGenerationMin) && (block.number > end_block));
        uint256 tokenBalance = balances[msg.sender];
        uint256 refundBalance = contribution[msg.sender];
        balances[msg.sender] = 0;
        contribution[msg.sender] = 0;
        totalTokens = safeSub(totalTokens, tokenBalance);
        WolkDestroyed(msg.sender, tokenBalance);
        LogRefund(msg.sender, refundBalance);
        msg.sender.transfer(refundBalance); 
    }

     
    function finalizeOpenSale() onlyOwner {
        require((!openSaleCompleted) && (totalTokens >= tokenGenerationMin));
        openSaleCompleted = true;
        end_block = block.number;
        reserveBalance = safeDiv(safeMul(totalTokens, percentageETHReserve), 100000);
        var withdrawalBalance = safeSub(this.balance, reserveBalance);
        msg.sender.transfer(withdrawalBalance);
    }

     
    function finalize() onlyWolk payable external {
        require((openSaleCompleted) && (!allSaleCompleted));                                                                                                    
        uint256 privateSaleTokens =  safeDiv(safeMul(msg.value, 100000), percentageETHReserve);
        uint256 checkedSupply = safeAdd(totalTokens, privateSaleTokens);                                                                                                
        totalTokens = checkedSupply;                                                                                                                         
        reserveBalance = safeAdd(reserveBalance, msg.value);                                                                                                 
        Transfer(address(this), wolkSale, privateSaleTokens);                                                                                                              
        balances[wolkSale] = safeAdd(balances[wolkSale], privateSaleTokens);                                                                                                  
        WolkCreated(wolkSale, privateSaleTokens);  
        allSaleCompleted = true;                                                                                                                                
    }
}

contract IBurnFormula {
    function calculateWolkToBurn(uint256 _value) public constant returns (uint256);
}

contract IFeeFormula {
    function calculateProviderFee(uint256 _value) public constant returns (uint256);
}

contract WolkProtocol is Wolk {

     
    address public burnFormula;
    bool    public settlementIsRunning = true;
    uint256 public burnBasisPoints = 500;   
    mapping (address => mapping (address => bool)) authorized;  
    mapping (address => uint256) feeBasisPoints;    
    mapping (address => address) feeFormulas;       
    modifier isSettleable { require(settlementIsRunning); _; }


     
    event AuthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event DeauthorizeServiceProvider(address indexed _owner, address _serviceProvider);
    event SetServiceProviderFee(address indexed _serviceProvider, uint256 _feeBasisPoints);
    event BurnTokens(address indexed _from, address indexed _serviceProvider, uint256 _value);

     
     
     
    function setBurnRate(uint256 _burnBasisPoints) onlyOwner returns (bool success) {
        require((_burnBasisPoints > 0) && (_burnBasisPoints <= 1000));
        burnBasisPoints = _burnBasisPoints;
        return true;
    }
    
     
     
     
    function setBurnFormula(address _newBurnFormula) onlyOwner returns (bool success){
        uint256 testBurning = estWolkToBurn(_newBurnFormula, 10 ** 18);
        require(testBurning > (5 * 10 ** 13));
        burnFormula = _newBurnFormula;
        return true;
    }
    
     
     
     
    function setFeeFormula(address _newFeeFormula) onlySettler returns (bool success){
        uint256 testSettling = estProviderFee(_newFeeFormula, 10 ** 18);
        require(testSettling > (5 * 10 ** 13));
        feeFormulas[msg.sender] = _newFeeFormula;
        return true;
    }
    
     
     
     
    function updateSettlementStatus(bool _isRunning) onlyOwner returns (bool success){
        settlementIsRunning = _isRunning;
        return true;
    }
    
     
     
     
     
    function setServiceFee(address _serviceProvider, uint256 _feeBasisPoints) onlyOwner returns (bool success) {
        if (_feeBasisPoints <= 0 || _feeBasisPoints > 4000){
             
            settlers[_serviceProvider] = false;
            feeBasisPoints[_serviceProvider] = 0;
            return false;
        }else{
            feeBasisPoints[_serviceProvider] = _feeBasisPoints;
            settlers[_serviceProvider] = true;
            SetServiceProviderFee(_serviceProvider, _feeBasisPoints);
            return true;
        }
    }

     
     
     
    function checkServiceFee(address _serviceProvider) constant returns (uint256 _feeBasisPoints) {
        return feeBasisPoints[_serviceProvider];
    }

     
     
     
    function checkFeeSchedule(address _serviceProvider) constant returns (address _formulaAddress) {
        return feeFormulas[_serviceProvider];
    }
    
     
     
     
    function estWolkToBurn(address _burnFormula, uint256 _value) constant internal returns (uint256){
        if(_burnFormula != 0x0){
            uint256 wolkBurnt = IBurnFormula(_burnFormula).calculateWolkToBurn(_value);
            return wolkBurnt;    
        }else{
            return 0; 
        }
    }
    
     
     
     
     
    function estProviderFee(address _serviceProvider, uint256 _value) constant internal returns (uint256){
        address ProviderFeeFormula = feeFormulas[_serviceProvider];
        if (ProviderFeeFormula != 0x0){
            uint256 estFee = IFeeFormula(ProviderFeeFormula).calculateProviderFee(_value);
            return estFee;      
        }else{
            return 0;  
        }
    }
    
     
     
     
     
    function settleBuyer(address _buyer, uint256 _value) onlySettler isSettleable returns (bool success) {
        require((burnBasisPoints > 0) && (burnBasisPoints <= 1000) && authorized[_buyer][msg.sender]);  
        require(balances[_buyer] >= _value && _value > 0);
        var WolkToBurn = estWolkToBurn(burnFormula, _value);
        var burnCap = safeDiv(safeMul(_value, burnBasisPoints), 10000);  

         
        if (WolkToBurn < 1) WolkToBurn = burnCap;
        if (WolkToBurn > burnCap) WolkToBurn = burnCap;
            
        var transferredToServiceProvider = safeSub(_value, WolkToBurn);
        balances[_buyer] = safeSub(balances[_buyer], _value);
        balances[msg.sender] = safeAdd(balances[msg.sender], transferredToServiceProvider);
        totalTokens = safeSub(totalTokens, WolkToBurn);
        Transfer(_buyer, msg.sender, transferredToServiceProvider);
        Transfer(_buyer, 0x00000000000000000000, WolkToBurn);
        BurnTokens(_buyer, msg.sender, WolkToBurn);
        return true;
    } 

     
     
     
     
    function settleSeller(address _seller, uint256 _value) onlySettler isSettleable returns (bool success) {
         
        var serviceProviderBP = feeBasisPoints[msg.sender];
        require((serviceProviderBP > 0) && (serviceProviderBP <= 4000) && (_value > 0));
        var seviceFee = estProviderFee(msg.sender, _value);
        var Maximumfee = safeDiv(safeMul(_value, serviceProviderBP), 10000);
        
         
        if (seviceFee < 1) seviceFee = Maximumfee;  
        if (seviceFee > Maximumfee) seviceFee = Maximumfee;
        var transferredToSeller = safeSub(_value, seviceFee);
        require(balances[msg.sender] >= transferredToSeller );
        balances[_seller] = safeAdd(balances[_seller], transferredToSeller);
        Transfer(msg.sender, _seller, transferredToSeller);
        return true;
    }

     
     
     
    function authorizeProvider(address _providerToAdd) returns (bool success) {
        require(settlers[_providerToAdd]);
        authorized[msg.sender][_providerToAdd] = true;
        AuthorizeServiceProvider(msg.sender, _providerToAdd);
        return true;
    }

     
     
     
    function deauthorizeProvider(address _providerToRemove) returns (bool success) {
        authorized[msg.sender][_providerToRemove] = false;
        DeauthorizeServiceProvider(msg.sender, _providerToRemove);
        return true;
    }

     
     
     
     
    function checkAuthorization(address _owner, address _serviceProvider) constant returns (bool authorizationStatus) {
        return authorized[_owner][_serviceProvider];
    }

     
     
     
     
     
    function grantService(address _owner, address _providerToAdd) onlyOwner returns (bool authorizationStatus) {
        var isPreauthorized = authorized[_owner][msg.sender];
        if (isPreauthorized && settlers[_providerToAdd]) {
            authorized[_owner][_providerToAdd] = true;
            AuthorizeServiceProvider(msg.sender, _providerToAdd);
            return true;
        }else{
            return false;
        }
    }

     
     
     
     
     
    function removeService(address _owner, address _providerToRemove) onlyOwner returns (bool authorizationStatus) {
        authorized[_owner][_providerToRemove] = false;
        DeauthorizeServiceProvider(_owner, _providerToRemove);
        return true;
    }
}

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _sellAmount) public constant returns (uint256);
}

contract WolkExchange is WolkProtocol, WolkTGE {

    uint256 public maxPerExchangeBP = 50;
    address public exchangeFormula;
    bool    public exchangeIsRunning = false;
    modifier isExchangable { require(exchangeIsRunning && allSaleCompleted); _; }
    
     
     
     
    function setExchangeFormula(address _newExchangeformula) onlyOwner returns (bool success){
        require(sellWolkEstimate(10**decimals, _newExchangeformula) > 0);
        require(purchaseWolkEstimate(10**decimals, _newExchangeformula) > 0);
        exchangeIsRunning = false;
        exchangeFormula = _newExchangeformula;
        return true;
    }
    
     
     
     
    function updateExchangeStatus(bool _isRunning) onlyOwner returns (bool success){
        if (_isRunning){
            require(sellWolkEstimate(10**decimals, exchangeFormula) > 0);
            require(purchaseWolkEstimate(10**decimals, exchangeFormula) > 0);   
        }
        exchangeIsRunning = _isRunning;
        return true;
    }
    
     
     
     
    function setMaxPerExchange(uint256 _maxPerExchange) onlyOwner returns (bool success) {
        require((_maxPerExchange >= 10) && (_maxPerExchange <= 100));
        maxPerExchangeBP = _maxPerExchange;
        return true;
    }

     
     
    function estLiquidationCap() public constant returns (uint256) {
        if (openSaleCompleted){
            var liquidationMax  = safeDiv(safeMul(totalTokens, maxPerExchangeBP), 10000);
            if (liquidationMax < 100 * 10**decimals){ 
                liquidationMax = 100 * 10**decimals;
            }
            return liquidationMax;   
        }else{
            return 0;
        }
    }

    function sellWolkEstimate(uint256 _wolkAmountest, address _formula) internal returns(uint256) {
        uint256 ethReceivable =  IBancorFormula(_formula).calculateSaleReturn(totalTokens, reserveBalance, percentageETHReserve, _wolkAmountest);
        return ethReceivable;
    }
    
    function purchaseWolkEstimate(uint256 _ethAmountest, address _formula) internal returns(uint256) {
        uint256 wolkReceivable = IBancorFormula(_formula).calculatePurchaseReturn(totalTokens, reserveBalance, percentageETHReserve, _ethAmountest);
        return wolkReceivable;
    }
    
     
     
     
    function sellWolk(uint256 _wolkAmount) isExchangable() returns(uint256) {
        uint256 sellCap = estLiquidationCap();
        require((balances[msg.sender] >= _wolkAmount));
        require(sellCap >= _wolkAmount);
        uint256 ethReceivable = sellWolkEstimate(_wolkAmount,exchangeFormula);
        require(this.balance > ethReceivable);
        balances[msg.sender] = safeSub(balances[msg.sender], _wolkAmount);
        totalTokens = safeSub(totalTokens, _wolkAmount);
        reserveBalance = safeSub(this.balance, ethReceivable);
        WolkDestroyed(msg.sender, _wolkAmount);
        Transfer(msg.sender, 0x00000000000000000000, _wolkAmount);
        msg.sender.transfer(ethReceivable);
        return ethReceivable;     
    }

     
     
    function purchaseWolk(address _buyer) isExchangable() payable returns(uint256){
        require(msg.value > 0);
        uint256 wolkReceivable = purchaseWolkEstimate(msg.value, exchangeFormula);
        require(wolkReceivable > 0);
        totalTokens = safeAdd(totalTokens, wolkReceivable);
        balances[_buyer] = safeAdd(balances[_buyer], wolkReceivable);
        reserveBalance = safeAdd(reserveBalance, msg.value);
        WolkCreated(_buyer, wolkReceivable);
        Transfer(address(this),_buyer,wolkReceivable);
        return wolkReceivable;
    }

     
     
    function () payable {
        require(msg.value > 0);
        if(!openSaleCompleted){
            this.tokenGenerationEvent.value(msg.value)(msg.sender);
        }else if (block.number >= end_block){
            this.purchaseWolk.value(msg.value)(msg.sender);
        }else{
            revert();
        }
    }
}