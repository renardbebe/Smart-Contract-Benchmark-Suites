 

pragma solidity ^0.4.13;

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

contract RBInformationStore is Ownable {
    address public profitContainerAddress;
    address public companyWalletAddress;
    uint public etherRatioForOwner;
    address public multisig;

    function RBInformationStore(address _profitContainerAddress, address _companyWalletAddress, uint _etherRatioForOwner, address _multisig) {
        profitContainerAddress = _profitContainerAddress;
        companyWalletAddress = _companyWalletAddress;
        etherRatioForOwner = _etherRatioForOwner;
        multisig = _multisig;
    }

    function setProfitContainerAddress(address _address)  {
        require(multisig == msg.sender);
        if(_address != 0x0) {
            profitContainerAddress = _address;
        }
    }

    function setCompanyWalletAddress(address _address)  {
        require(multisig == msg.sender);
        if(_address != 0x0) {
            companyWalletAddress = _address;
        }
    }

    function setEtherRatioForOwner(uint _value)  {
        require(multisig == msg.sender);
        if(_value != 0) {
            etherRatioForOwner = _value;
        }
    }

    function changeMultiSig(address newAddress){
        require(multisig == msg.sender);
        multisig = newAddress;
    }

    function changeOwner(address newOwner){
        require(multisig == msg.sender);
        owner = newOwner;
    }
}

 
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
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract Rate {
    uint public ETH_USD_rate;
    RBInformationStore public rbInformationStore;

    modifier onlyOwner() {
        if (msg.sender != rbInformationStore.owner()) {
            revert();
        }
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

 
contract SponseeTokenModelSolaCoin is StandardToken {

    string public name = "SOLA COIN";
    uint8 public decimals = 18;
    string public symbol = "SLC";
    uint public totalSupply = 500000000 * (10 ** uint256(decimals));
    uint public cap = 1000000000 * (10 ** uint256(decimals));  
    RBInformationStore public rbInformationStore;
    Rate public rate;
    uint public minimumSupport = 500;  
    uint public etherRatioForInvestor = 10;  
    address public sponseeAddress;
    address public multiSigAddress;  
    address public accountAddressForSponseeAddress;  
    bool public isPayableEnabled = false;

    event LogReceivedEther(address indexed from, address indexed to, uint etherValue, string tokenName);
    event LogTransferFromOwner(address indexed from, address indexed to, uint tokenValue, uint etherValue, uint rateUSDETH);
    event LogBuy(address indexed from, address indexed to, uint indexed value, uint paymentId);
    event LogRollbackTransfer(address indexed from, address indexed to, uint value);
    event LogExchange(address indexed from, address indexed token, uint value);
    event LogIncreaseCap(uint value);
    event LogDecreaseCap(uint value);
    event LogSetRBInformationStoreAddress(address indexed to);
    event LogSetName(string name);
    event LogSetSymbol(string symbol);
    event LogMint(address indexed to, uint value);
    event LogChangeMultiSigAddress(address indexed to);
    event LogChangeAccountAddressForSponseeAddress(address indexed to);
    event LogChangeSponseeAddress(address indexed to);
    event LogChangeIsPayableEnabled();

    modifier onlyOwner() {
        if (msg.sender != rbInformationStore.owner()) {
            revert();
        }
        _;
    }

     
    function SponseeTokenModelSolaCoin(
        address _rbInformationStoreAddress,
        address _rateAddress,
        address _sponsee,
        address _multiSig,
        address _accountForSponseeAddress,
        address _to
    ) {
        rbInformationStore = RBInformationStore(_rbInformationStoreAddress);
        rate = Rate(_rateAddress);
        sponseeAddress = _sponsee;
        multiSigAddress = _multiSig;
        accountAddressForSponseeAddress = _accountForSponseeAddress;
        balances[_to] = totalSupply;
    }

     
    function() payable {
         
        require(isPayableEnabled);

         
        if(msg.value <= 0) { revert(); }

         
        uint supportedAmount = msg.value.mul(rate.ETH_USD_rate()).div(10**18);
         
        if(supportedAmount < minimumSupport) { revert(); }

         
        uint etherRatioForOwner = rbInformationStore.etherRatioForOwner();
        uint etherRatioForSponsee = uint(100).sub(etherRatioForOwner).sub(etherRatioForInvestor);

         
         
        uint etherForOwner = msg.value.mul(etherRatioForOwner).div(100);
        uint etherForInvestor = msg.value.mul(etherRatioForInvestor).div(100);
        uint etherForSponsee = msg.value.mul(etherRatioForSponsee).div(100);

         
        address profitContainerAddress = rbInformationStore.profitContainerAddress();
        address companyWalletAddress = rbInformationStore.companyWalletAddress();

         
        if(!profitContainerAddress.send(etherForInvestor)) { revert(); }
        if(!companyWalletAddress.send(etherForOwner)) { revert(); }
        if(!sponseeAddress.send(etherForSponsee)) { revert(); }

         
         
         
        uint tokenAmount = msg.value.mul(rate.ETH_USD_rate());

         
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

         
        totalSupply = totalSupply.add(tokenAmount);

         
        if(totalSupply > cap) { revert(); }

         
        LogExchange(msg.sender, this, tokenAmount);

         
        LogReceivedEther(msg.sender, this, msg.value, name);

         
        Transfer(address(0x0), msg.sender, tokenAmount);
    }

     
    function setRBInformationStoreAddress(address _address) {
         
        require(multiSigAddress == msg.sender);

        rbInformationStore = RBInformationStore(_address);

        LogSetRBInformationStoreAddress(_address);
    }

     
    function setName(string _name) onlyOwner {
        name = _name;

        LogSetName(_name);
    }

     
    function setSymbol(string _symbol) onlyOwner {
        symbol = _symbol;

        LogSetSymbol(_symbol);
    }

     
    function mint(address _address, uint _value) {

         
        require(multiSigAddress == msg.sender);

         
        balances[_address] = balances[_address].add(_value);

         
        totalSupply = totalSupply.add(_value);

         
        if(totalSupply > cap) { revert(); }

        LogMint(_address, _value);

         
        Transfer(address(0x0), _address, _value);
    }

     
    function increaseCap(uint _value) onlyOwner {
         
        cap = cap.add(_value);

        LogIncreaseCap(_value);
    }

     
    function decreaseCap(uint _value) onlyOwner {
         
        if(totalSupply > cap.sub(_value)) { revert(); }
         
        cap = cap.sub(_value);

        LogDecreaseCap(_value);
    }

     
    function rollbackTransfer(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
         
        require(multiSigAddress == msg.sender);

        balances[_to] = balances[_to].sub(_value);
        balances[_from] = balances[_from].add(_value);

        LogRollbackTransfer(_from, _to, _value);

         
        Transfer(_from, _to, _value);
    }

     
    function buy(address _to, uint _value, uint _paymentId) {
        transfer(_to, _value);

        LogBuy(msg.sender, _to, _value, _paymentId);
    }

     
    function changeMultiSigAddress(address _newAddress) {
         
        require(multiSigAddress == msg.sender);

        multiSigAddress = _newAddress;

        LogChangeMultiSigAddress(_newAddress);

    }

     
    function changeAccountAddressForSponseeAddress(address _newAddress) {
         
        require(accountAddressForSponseeAddress == msg.sender);

        accountAddressForSponseeAddress = _newAddress;

        LogChangeAccountAddressForSponseeAddress(_newAddress);

    }

     
    function changeSponseeAddress(address _newAddress) {
         
        require(accountAddressForSponseeAddress == msg.sender);

        sponseeAddress = _newAddress;

        LogChangeSponseeAddress(_newAddress);

    }

     
    function changeIsPayableEnabled() {
         
        require(multiSigAddress == msg.sender);

        isPayableEnabled = !isPayableEnabled;

        LogChangeIsPayableEnabled();

    }
}