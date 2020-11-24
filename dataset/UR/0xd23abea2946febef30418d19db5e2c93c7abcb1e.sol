 

pragma solidity ^0.4.11;


 


 
contract ERC223TokenInterface {
    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _supply);

    function balanceOf(address _owner) constant returns (uint256 _balance);

    function approve(address _spender, uint256 _value) returns (bool _success);
    function allowance(address _owner, address spender) constant returns (uint256 _remaining);

    function transfer(address _to, uint256 _value) returns (bool _success);
    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes metadata);
}


 
contract ERC223ContractInterface {
    function erc223Fallback(address _from, uint256 _value, bytes _data){
         
        _from = _from;
        _value = _value;
        _data = _data;
         
        throw;
    }
}


 

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


     

    function name() constant returns (string _name) {
        return name;
    }

    function symbol() constant returns (string _symbol) {
        return symbol;
    }

    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() constant returns (uint256 _supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 _balance) {
        return balances[_owner];
    }


     

    function approve(address _spender, uint256 _value) returns (bool _success) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 _remaining) {
        return allowances[_owner][_spender];
    }


     

    function transfer(address _to, uint256 _value) returns (bool _success) {
        bytes memory emptyMetadata;
        __transfer(msg.sender, _to, _value, emptyMetadata);
        return true;
    }

    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success)
    {
        __transfer(msg.sender, _to, _value, _metadata);
        Transfer(msg.sender, _to, _value, _metadata);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success) {
        if (allowances[_from][msg.sender] < _value) throw;

        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        bytes memory emptyMetadata;
        __transfer(_from, _to, _value, emptyMetadata);
        return true;
    }

    function __transfer(address _from, address _to, uint256 _value, bytes _metadata) internal
    {
        if (_from == _to) throw;
        if (_value == 0) throw;
        if (balanceOf(_from) < _value) throw;

        balances[_from] = safeSub(balanceOf(_from), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);

        if (isContract(_to)) {
            ERC223ContractInterface receiverContract = ERC223ContractInterface(_to);
            receiverContract.erc223Fallback(_from, _value, _metadata);
        }

        Transfer(_from, _to, _value);
    }


     

     
    function isContract(address _addr) internal returns (bool _isContract) {
        _addr = _addr;  

        uint256 length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
}



 
contract DASToken is ERC223Token {
    mapping (address => bool) blockedAccounts;
    address public secretaryGeneral;


     
    function DASToken(
            string _name,
            string _symbol,
            uint8 _decimals,
            uint256 _totalSupply,
            address _initialTokensHolder) {
        secretaryGeneral = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[_initialTokensHolder] = _totalSupply;
    }


    modifier onlySecretaryGeneral {
        if (msg.sender != secretaryGeneral) throw;
        _;
    }


     
    function blockAccount(address _account) onlySecretaryGeneral {
        blockedAccounts[_account] = true;
    }

     
    function unblockAccount(address _account) onlySecretaryGeneral {
        blockedAccounts[_account] = false;
    }

     
    function isAccountBlocked(address _account) returns (bool){
        return blockedAccounts[_account];
    }

     
    function transfer(address _to, uint256 _value) returns (bool _success) {
        if (blockedAccounts[msg.sender]) {
            throw;
        }
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success) {
        if (blockedAccounts[msg.sender]) {
            throw;
        }
        return super.transfer(_to, _value, _metadata);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success) {
        if (blockedAccounts[_from]) {
            throw;
        }
        return super.transferFrom(_from, _to, _value);
    }
}



contract DASCrowdsale is ERC223ContractInterface {

     
     
    address public secretaryGeneral;
    address public crowdsaleBeneficiary;
    address public crowdsaleDasTokensChangeBeneficiary;
    uint256 public crowdsaleDeadline;
    uint256 public crowdsaleTokenPriceNumerator;
    uint256 public crowdsaleTokenPriceDenominator;
    DASToken public dasToken;
     
    mapping (address => uint256) public ethBalanceOf;
    uint256 crowdsaleFundsRaised;


     
    event FundsReceived(address indexed backer, uint256 indexed amount);


     
    function DASCrowdsale(
        address _secretaryGeneral,
        address _crowdsaleBeneficiary,
        address _crowdsaleDasTokensChangeBeneficiary,
        uint256 _durationInSeconds,
        uint256 _crowdsaleTokenPriceNumerator,
        uint256 _crowdsaleTokenPriceDenominator,
        address _dasTokenAddress
    ) {
        secretaryGeneral = _secretaryGeneral;
        crowdsaleBeneficiary = _crowdsaleBeneficiary;
        crowdsaleDasTokensChangeBeneficiary = _crowdsaleDasTokensChangeBeneficiary;
        crowdsaleDeadline = now + _durationInSeconds * 1 seconds;
        crowdsaleTokenPriceNumerator = _crowdsaleTokenPriceNumerator;
        crowdsaleTokenPriceDenominator = _crowdsaleTokenPriceDenominator;
        dasToken = DASToken(_dasTokenAddress);
        crowdsaleFundsRaised = 0;
    }

    function __setSecretaryGeneral(address _secretaryGeneral) onlySecretaryGeneral {
        secretaryGeneral = _secretaryGeneral;
    }

    function __setBeneficiary(address _crowdsaleBeneficiary) onlySecretaryGeneral {
        crowdsaleBeneficiary = _crowdsaleBeneficiary;
    }

    function __setBeneficiaryForDasTokensChange(address _crowdsaleDasTokensChangeBeneficiary) onlySecretaryGeneral {
        crowdsaleDasTokensChangeBeneficiary = _crowdsaleDasTokensChangeBeneficiary;
    }

    function __setDeadline(uint256 _durationInSeconds) onlySecretaryGeneral {
        crowdsaleDeadline = now + _durationInSeconds * 1 seconds;
    }

    function __setTokenPrice(
        uint256 _crowdsaleTokenPriceNumerator,
        uint256 _crowdsaleTokenPriceDenominator
    )
        onlySecretaryGeneral
    {
        crowdsaleTokenPriceNumerator = _crowdsaleTokenPriceNumerator;
        crowdsaleTokenPriceDenominator = _crowdsaleTokenPriceDenominator;
    }


     
    function() payable onlyBeforeCrowdsaleDeadline {
        uint256 receivedAmount = msg.value;

        ethBalanceOf[msg.sender] += receivedAmount;
        crowdsaleFundsRaised += receivedAmount;

        dasToken.transfer(msg.sender, receivedAmount / crowdsaleTokenPriceDenominator * crowdsaleTokenPriceNumerator);
        FundsReceived(msg.sender, receivedAmount);
    }

    function erc223Fallback(address _from, uint256 _value, bytes _data) {
         
         
        _from = _from;
        _value = _value;
        _data = _data;
    }


     
    function withdraw() onlyAfterCrowdsaleDeadline {
        uint256 ethToWithdraw = address(this).balance;
        uint256 dasToWithdraw = dasToken.balanceOf(address(this));

        if (ethToWithdraw == 0 && dasToWithdraw == 0) throw;

        if (ethToWithdraw > 0) { crowdsaleBeneficiary.transfer(ethToWithdraw); }
        if (dasToWithdraw > 0) { dasToken.transfer(crowdsaleDasTokensChangeBeneficiary, dasToWithdraw); }
    }


     
    modifier onlyBeforeCrowdsaleDeadline {
        require(now <= crowdsaleDeadline);
        _;
    }

    modifier onlyAfterCrowdsaleDeadline {
        require(now > crowdsaleDeadline);
        _;
    }

    modifier onlySecretaryGeneral {
        if (msg.sender != secretaryGeneral) throw;
        _;
    }
}