 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 


contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

}

contract SafeMath {
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }

}

contract ERC20 {
  uint public totalSupply;
  
 
 

 
 
 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
 
  uint256 private _totalSupply;

  function transfer(address to, uint256 value) public payable {
    _transfer(msg.sender, to, value);
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool){
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = sub(_allowed[from][msg.sender], value);
    _transfer(from, to, value);
    return true;
  }


  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = add(_totalSupply, value);
    _balances[account] = add(_balances[account], value);
    emit Transfer(address(0), account, value);
  }

 
  function allowance(address owner, address spender) public view returns (uint256){
    return _allowed[owner][spender];
  }
  
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = sub(_balances[from], value);
    _balances[to] = add(_balances[to], value);
    emit Transfer(from, to, value);
  }


}

contract UbetCoins is Ownable, StandardToken {
    
    string public constant name = "Ubet Coins";                 
    string public constant symbol = "UBETS";                 
    uint public constant decimals = 18;                        

    uint256 internal constant INITIAL_SUPPLY = 4000000000000000000000000000;
    
    uint256 public totalSupply =  INITIAL_SUPPLY;     
    uint256 public tokenSupplyFromCheck = 0;          
    
    string public constant UBETCOINS_LEDGER_TO_LEDGER_ENTRY_INSTRUMENT_DOCUMENT_PATH = "https://s3.amazonaws.com/s3-ubetcoin-user-signatures/document/LEDGER-TO-LEDGER-ENTRY-FOR-UBETCOINS.pdf";
    string public constant UBETCOINS_LEDGER_TO_LEDGER_ENTRY_INSTRUMENT_DOCUMENT_SHA512 = "c8f0ae2602005dd88ef908624cf59f3956107d0890d67d3baf9c885b64544a8140e282366cae6a3af7bfbc96d17f856b55fc4960e2287d4a03d67e646e0e88c6";
        
     
    uint256 public ratePerOneEther = 135;
    uint256 public totalUBetCheckAmounts = 0;

     
    uint64 public issueIndex = 0;

     
    event Issue(uint64 issueIndex, address addr, uint256 tokenAmount);
    
     
    address public moneyWallet = 0xe5688167Cb7aBcE4355F63943aAaC8bb269dc953;

     
    event UbetCheckIssue(string chequeIndex);
      
    struct UBetCheck {
      string accountId;
      string accountNumber;
      string fullName;
      string routingNumber;
      string institution;
      uint256 amount;
      uint256 tokens;
      string checkFilePath;
      string digitalCheckFingerPrint;
    }
    
    mapping (address => UBetCheck) UBetChecks;
    address[] public uBetCheckAccts;
    
    mapping (address => uint256) _balances;
    
     
    constructor() public {
      _balances[msg.sender] = INITIAL_SUPPLY;
    }
    
     
    
     
     
     
     
     
     
     
     
     
     
     
    function registerUBetCheck(address _beneficiary, string _accountId,  string _accountNumber, string _routingNumber, string _institution, string _fullname,  uint256 _amount, string _checkFilePath, string _digitalCheckFingerPrint, uint256 _tokens) public payable onlyOwner {
      
      require(_beneficiary != address(0));
      require(bytes(_accountId).length != 0);
      require(bytes(_accountNumber).length != 0);
      require(bytes(_routingNumber).length != 0);
      require(bytes(_institution).length != 0);
      require(bytes(_fullname).length != 0);
      require(_amount > 0);
      require(_tokens > 0);
      require(bytes(_checkFilePath).length != 0);
      require(bytes(_digitalCheckFingerPrint).length != 0);
      
      uint256 __conToken = _tokens * (10**(decimals));
      
      UBetChecks[_beneficiary].accountId = _accountId;
      UBetChecks[_beneficiary].accountNumber = _accountNumber;
      UBetChecks[_beneficiary].routingNumber = _routingNumber;
      UBetChecks[_beneficiary].institution = _institution;
      UBetChecks[_beneficiary].fullName = _fullname;
      UBetChecks[_beneficiary].amount = _amount;
      UBetChecks[_beneficiary].tokens = _tokens;
      
      UBetChecks[_beneficiary].checkFilePath = _checkFilePath;
      UBetChecks[_beneficiary].digitalCheckFingerPrint = _digitalCheckFingerPrint;
      
      totalUBetCheckAmounts = add(totalUBetCheckAmounts, _amount);
      tokenSupplyFromCheck = add(tokenSupplyFromCheck, _tokens);
      
      uBetCheckAccts.push(_beneficiary) -1;
      
       
      doIssueTokens(_beneficiary, __conToken);
      
       
      emit UbetCheckIssue(_accountId);
    }
    
     
    function getUBetChecks() public view returns (address[]) {
      return uBetCheckAccts;
    }
    
     
    function getUBetCheck(address _address) public view returns(string, string, string, string, uint256, string, string) {
            
      return (UBetChecks[_address].accountNumber,
              UBetChecks[_address].routingNumber,
              UBetChecks[_address].institution,
              UBetChecks[_address].fullName,
              UBetChecks[_address].amount,
              UBetChecks[_address].checkFilePath,
              UBetChecks[_address].digitalCheckFingerPrint);
    }
    
     
     
    function () public payable {
      purchaseTokens(msg.sender);
    }

     
    function countUBetChecks() public view returns (uint) {
        return uBetCheckAccts.length;
    }
    

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
      require(_beneficiary != address(0));    

       
      uint256 increasedTotalSupply = add(totalSupply, _tokens);
     
       
      totalSupply = increasedTotalSupply;
      
       
      _balances[_beneficiary] = add(_balances[_beneficiary], _tokens);
      
      emit Transfer(msg.sender, _beneficiary, _tokens);
    
       
      emit Issue(
          issueIndex++,
          _beneficiary,
          _tokens
      );
    }
    
     
     
    function purchaseTokens(address _beneficiary) public payable {
       
      require(msg.value >= 0.00104 ether);
     
      uint _tokens = div(mul(msg.value, ratePerOneEther), (10**(18-decimals)));
      doIssueTokens(_beneficiary, _tokens);

       
      moneyWallet.transfer(address(this).balance);
    }
    
    
     
     
    function setMoneyWallet(address _address) public onlyOwner {
        moneyWallet = _address;
    }
    
     
     
    function setRatePerOneEther(uint256 _value) public onlyOwner {
      require(_value >= 1);
      ratePerOneEther = _value;
    }
    
}