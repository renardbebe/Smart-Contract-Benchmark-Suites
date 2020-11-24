 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
            revert();
        }
        _;
    }

     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32)  returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
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
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract RBInformationStore is Ownable {
    address public profitContainerAddress;
    address public companyWalletAddress;
    uint public etherRatioForOwner;
    address public multiSigAddress;
    address public accountAddressForSponsee;
    bool public isPayableEnabledForAll = true;

    modifier onlyMultiSig() {
        require(multiSigAddress == msg.sender);
        _;
    }

    function RBInformationStore
    (
        address _profitContainerAddress,
        address _companyWalletAddress,
        uint _etherRatioForOwner,
        address _multiSigAddress,
        address _accountAddressForSponsee
    ) {
        profitContainerAddress = _profitContainerAddress;
        companyWalletAddress = _companyWalletAddress;
        etherRatioForOwner = _etherRatioForOwner;
        multiSigAddress = _multiSigAddress;
        accountAddressForSponsee = _accountAddressForSponsee;
    }

    function changeProfitContainerAddress(address _address) onlyMultiSig {
        profitContainerAddress = _address;
    }

    function changeCompanyWalletAddress(address _address) onlyMultiSig {
        companyWalletAddress = _address;
    }

    function changeEtherRatioForOwner(uint _value) onlyMultiSig {
        etherRatioForOwner = _value;
    }

    function changeMultiSigAddress(address _address) onlyMultiSig {
        multiSigAddress = _address;
    }

    function changeOwner(address _address) onlyMultiSig {
        owner = _address;
    }

    function changeAccountAddressForSponsee(address _address) onlyMultiSig {
        accountAddressForSponsee = _address;
    }

    function changeIsPayableEnabledForAll() onlyMultiSig {
        isPayableEnabledForAll = !isPayableEnabledForAll;
    }
}


contract Rate {
    uint public ETH_USD_rate;
    RBInformationStore public rbInformationStore;

    modifier onlyOwner() {
        require(msg.sender == rbInformationStore.owner());
        _;
    }

    function Rate(uint _rate, address _address) {
        ETH_USD_rate = _rate;
        rbInformationStore = RBInformationStore(_address);
    }

    function setRate(uint _rate) onlyOwner {
        ETH_USD_rate = _rate;
    }
}



 
contract SponseeTokenModel is StandardToken {

    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint public totalSupply = 0;
    uint public cap = 100000000;                     
    uint public minimumSupport = 500;                
    uint public etherRatioForInvestor = 10;          
    address public sponseeAddress;
    bool public isPayableEnabled = true;
    RBInformationStore public rbInformationStore;
    Rate public rate;

    event LogReceivedEther(address indexed from, address indexed to, uint etherValue, string tokenName);
    event LogBuy(address indexed from, address indexed to, uint indexed value, uint paymentId);
    event LogRollbackTransfer(address indexed from, address indexed to, uint value);
    event LogExchange(address indexed from, address indexed token, uint value);
    event LogIncreaseCap(uint value);
    event LogDecreaseCap(uint value);
    event LogSetRBInformationStoreAddress(address indexed to);
    event LogSetName(string name);
    event LogSetSymbol(string symbol);
    event LogMint(address indexed to, uint value);
    event LogChangeSponseeAddress(address indexed to);
    event LogChangeIsPayableEnabled(bool flag);

    modifier onlyAccountAddressForSponsee() {
        require(rbInformationStore.accountAddressForSponsee() == msg.sender);
        _;
    }

    modifier onlyMultiSig() {
        require(rbInformationStore.multiSigAddress() == msg.sender);
        _;
    }

     
    function SponseeTokenModel(
        string _name,
        string _symbol,
        address _rbInformationStoreAddress,
        address _rateAddress,
        address _sponsee
    ) {
        name = _name;
        symbol = _symbol;
        rbInformationStore = RBInformationStore(_rbInformationStoreAddress);
        rate = Rate(_rateAddress);
        sponseeAddress = _sponsee;
    }

     
    function() payable {

         
        require(isPayableEnabled && rbInformationStore.isPayableEnabledForAll());

         
        if (msg.value <= 0) { revert(); }

         
        uint supportedAmount = msg.value.mul(rate.ETH_USD_rate()).div(10**18);

         
        if (supportedAmount < minimumSupport) { revert(); }

         
        uint etherRatioForOwner = rbInformationStore.etherRatioForOwner();
        uint etherRatioForSponsee = uint(100).sub(etherRatioForOwner).sub(etherRatioForInvestor);

         
         
        uint etherForOwner = msg.value.mul(etherRatioForOwner).div(100);
        uint etherForInvestor = msg.value.mul(etherRatioForInvestor).div(100);
        uint etherForSponsee = msg.value.mul(etherRatioForSponsee).div(100);

         
        address profitContainerAddress = rbInformationStore.profitContainerAddress();
        address companyWalletAddress = rbInformationStore.companyWalletAddress();

         
        if (!profitContainerAddress.send(etherForInvestor)) { revert(); }
        if (!companyWalletAddress.send(etherForOwner)) { revert(); }
        if (!sponseeAddress.send(etherForSponsee)) { revert(); }

         
         
        uint tokenAmount = msg.value.mul(rate.ETH_USD_rate()).div(10**18);

         
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

         
        totalSupply = totalSupply.add(tokenAmount);

         
        if (totalSupply > cap) { revert(); }

         
        LogExchange(msg.sender, this, tokenAmount);
        LogReceivedEther(msg.sender, this, msg.value, name);
        Transfer(address(0x0), msg.sender, tokenAmount);
    }

     
    function setRBInformationStoreAddress(address _address) onlyMultiSig {

        rbInformationStore = RBInformationStore(_address);

         
        LogSetRBInformationStoreAddress(_address);
    }

     
    function setName(string _name) onlyAccountAddressForSponsee {

        name = _name;

         
        LogSetName(_name);
    }

     
    function setSymbol(string _symbol) onlyAccountAddressForSponsee {

        symbol = _symbol;

         
        LogSetSymbol(_symbol);
    }

     
    function mint(address _address, uint _value) onlyAccountAddressForSponsee {

         
        balances[_address] = balances[_address].add(_value);

         
        totalSupply = totalSupply.add(_value);

         
        if (totalSupply > cap) { revert(); }

         
        LogMint(_address, _value);
        Transfer(address(0x0), _address, _value);
    }

     
    function increaseCap(uint _value) onlyAccountAddressForSponsee {

         
        cap = cap.add(_value);

         
        LogIncreaseCap(_value);
    }

     
    function decreaseCap(uint _value) onlyAccountAddressForSponsee {

         
        if (totalSupply > cap.sub(_value)) { revert(); }

         
        cap = cap.sub(_value);

         
        LogDecreaseCap(_value);
    }

     
    function rollbackTransfer(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) onlyMultiSig {

        balances[_to] = balances[_to].sub(_value);
        balances[_from] = balances[_from].add(_value);

         
        LogRollbackTransfer(_from, _to, _value);
        Transfer(_from, _to, _value);
    }

     
    function buy(address _to, uint _value, uint _paymentId) {

        transfer(_to, _value);

         
        LogBuy(msg.sender, _to, _value, _paymentId);
    }

     
    function changeSponseeAddress(address _newAddress) onlyAccountAddressForSponsee {

        sponseeAddress = _newAddress;

         
        LogChangeSponseeAddress(_newAddress);
    }

     
    function changeIsPayableEnabled() onlyMultiSig {

        isPayableEnabled = !isPayableEnabled;

         
        LogChangeIsPayableEnabled(isPayableEnabled);
    }
}