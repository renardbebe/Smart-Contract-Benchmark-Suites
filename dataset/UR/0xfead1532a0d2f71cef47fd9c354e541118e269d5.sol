 

pragma solidity ^0.4.25;

 
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

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor() public
    {
       owner = msg.sender;
    }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event setNewBlockEvent(string SecretKey_Pre, string Name_New, string TxHash_Pre, string DigestCode_New, string Image_New, string Note_New);
}

contract COLLATERAL  {
    
    function decimals() pure returns (uint) {}
    function CreditRate()  pure returns (uint256) {}
    function credit(uint256 _value) public {}
    function repayment(uint256 _amount) public returns (bool) {}
}

contract StandardToken is Token {

    COLLATERAL dc;
    address public collateral_contract;
    uint public constant decimals = 8;

 function transfer(address _to, uint256 _value) returns(bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


 
contract DebitableToken is StandardToken, Ownable {
  event Debit(address collateral_contract, uint256 amount);
  event Deposit(address indexed _to_debitor, uint256 _value);  
  event DebitFinished();

  using SafeMath for uint256;
  bool public debitingFinished = false;

  modifier canDebit() {
    require(!debitingFinished);
    _;
  }

  modifier hasDebitPermission() {
    require(msg.sender == owner);
    _;
  }
  
   
  function debit(
    address _to,
    uint256 _amount
  )
    public
    hasDebitPermission
    canDebit
    returns (bool)
  {
    dc = COLLATERAL(collateral_contract);
    uint256 rate = dc.CreditRate();
    uint256 deci = 10 ** decimals; 
    uint256 _amount_1 =  _amount / deci / rate;
    uint256 _amount_2 =  _amount_1 * deci * rate;
    
    require( _amount_1 > 0);
    dc.credit( _amount_1 );  
    
    uint256 _amountx = _amount_2;
    totalSupply = totalSupply.add(_amountx);
    balances[_to] = balances[_to].add(_amountx);
    emit Debit(collateral_contract, _amountx);
    emit Deposit( _to, _amountx);
    return true;
  }

   
  function finishDebit() public onlyOwner canDebit returns (bool) {
    debitingFinished = true;
    emit DebitFinished();
    return true;
  }

  
}



 
contract RepaymentToken is StandardToken, Ownable {
    using SafeMath for uint256;
    event Repayment(address collateral_contract, uint256 value);
    event Withdraw(address debitor, uint256 value);
    
    modifier hasRepayPermission() {
      require(msg.sender == owner);
      _;
    }

    function repayment( uint256 _value )
    hasRepayPermission
    public 
    {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        dc = COLLATERAL(collateral_contract);
        address debitor = msg.sender;
        uint256 rate = dc.CreditRate();
        uint256 deci = 10 ** decimals; 
        uint256 _unitx = _value / deci / rate;
        uint256 _value1 = _unitx * deci * rate;
        balances[debitor] = balances[debitor].sub(_value1);
        totalSupply = totalSupply.sub(_value1);

        require(_unitx > 0);
        dc.repayment( _unitx );
    
        emit Repayment( collateral_contract, _value1 );
        emit Withdraw( debitor, _value1 );
    }
    
}


contract PuErhTeaAD1911 is DebitableToken, RepaymentToken  {


    constructor() public {    
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    function connectContract(address _collateral_address ) public onlyOwner {
        collateral_contract = _collateral_address;
    }
    
    function getCreditRate() public view returns (uint256 result) {
        dc = COLLATERAL( collateral_contract );
        return dc.CreditRate();
    }
    
     

     
    
    string public name = "PuErhTeaAD1911";
    string public symbol = "PT1911";
    uint256 public constant INITIAL_SUPPLY = 0 * (10 ** uint256(decimals));
    string public Image_root = "https://swarm.chainbacon.com/bzz:/4a5cde7005f3b65568605cb4d5f4a32cbb293e760c27cc43bc4f427c1a7cbfe8/";
    string public Note_root = "https://swarm.chainbacon.com/bzz:/47868d81a3757c057fde3f6eeef0151e4ae984f1eba8fb9a27303043be2ac00b/";
    string public Document_root = "none";
    string public DigestCode_root = "b38fc082005559f58845701ec906d6c67135d5e029355f81ae91deb2aa8efac5";
    function getIssuer() public pure returns(string) { return  "Mrlung"; }
    string public TxHash_root = "genesis";

    string public ContractSource = "";
    string public CodeVersion = "v0.1";
    
    string public SecretKey_Pre = "";
    string public Name_New = "";
    string public TxHash_Pre = "";
    string public DigestCode_New = "";
    string public Image_New = "";
    string public Note_New = "";
    uint256 public DebitRate = 100 * (10 ** uint256(decimals));
   
    function getName() public view returns(string) { return name; }
    function getDigestCodeRoot() public view returns(string) { return DigestCode_root; }
    function getTxHashRoot() public view returns(string) { return TxHash_root; }
    function getImageRoot() public view returns(string) { return Image_root; }
    function getNoteRoot() public view returns(string) { return Note_root; }
    function getCodeVersion() public view returns(string) { return CodeVersion; }
    function getContractSource() public view returns(string) { return ContractSource; }

    function getSecretKeyPre() public view returns(string) { return SecretKey_Pre; }
    function getNameNew() public view returns(string) { return Name_New; }
    function getTxHashPre() public view returns(string) { return TxHash_Pre; }
    function getDigestCodeNew() public view returns(string) { return DigestCode_New; }
    function getImageNew() public view returns(string) { return Image_New; }
    function getNoteNew() public view returns(string) { return Note_New; }
    function updateDebitRate(uint256 _rate) public onlyOwner returns (uint256) {
        DebitRate = _rate;
        return DebitRate;
    }

    function setNewBlock(string _SecretKey_Pre, string _Name_New, string _TxHash_Pre, string _DigestCode_New, string _Image_New, string _Note_New )  returns (bool success) {
        SecretKey_Pre = _SecretKey_Pre;
        Name_New = _Name_New;
        TxHash_Pre = _TxHash_Pre;
        DigestCode_New = _DigestCode_New;
        Image_New = _Image_New;
        Note_New = _Note_New;
        emit setNewBlockEvent(SecretKey_Pre, Name_New, TxHash_Pre, DigestCode_New, Image_New, Note_New);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        require(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}