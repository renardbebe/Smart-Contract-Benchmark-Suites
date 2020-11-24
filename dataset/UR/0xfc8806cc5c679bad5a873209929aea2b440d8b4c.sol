 

pragma solidity 0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract ClubMatesCom is StandardToken, Claimable {
  using SafeMath for uint256;
  uint8 public constant PERCENT_BONUS=15;

   
   
   
  enum StatusName {Pending, OneSign, TwoSign, Minted}

  struct MintStatus {
    StatusName status;
    address    beneficiary;
    uint256    amount;
    address    firstSign;
    address    secondSign;
  }
  
  MintStatus public additionalMint;

  string  public name;
  string  public symbol;
  uint8   public decimals;
  address public accICO;
  address public accBonusTokens;
  address public accMinterOne; 
  address public accMinterTwo;

   
   
   
  event BatchDistrib(uint8 cnt , uint256 batchAmount);
  event NewMintPending(address _beneficiary, uint256 mintAmount, uint64 timestamp);
  event FirstSign(address _signer, uint64 timestamp);
  event SecondSign(address _signer, uint64 timestamp);
  event Minted(address _to, uint256 _amount);

  constructor (
      address _accICO, 
      address _accBonusTokens, 
      address _accMinterOne, 
      address _accMinterTwo,
      uint256 _initialSupply)
  public 
  {
      name           = "ClubMatesCom_TEST";
      symbol         = "CMC";
      decimals       = 18;
      accICO         = _accICO;
      accBonusTokens = _accBonusTokens;
      accMinterOne   = _accMinterOne; 
      accMinterTwo   = _accMinterTwo;
      totalSupply_   = _initialSupply * (10 ** uint256(decimals)); 
       
      balances[_accICO]         = totalSupply()/100*(100-PERCENT_BONUS);
      balances[_accBonusTokens] = totalSupply()/100*PERCENT_BONUS;
      emit Transfer(address(0), _accICO, totalSupply()/100*(100-PERCENT_BONUS));
      emit Transfer(address(0), _accBonusTokens, totalSupply()/100*PERCENT_BONUS);
       
      additionalMint.status     = StatusName.Minted;
      additionalMint.amount     = totalSupply();
      additionalMint.firstSign  = address(0);
      additionalMint.secondSign = address(0);
  }

  modifier onlyTrustedSign() {
      require(msg.sender == accMinterOne || msg.sender == accMinterTwo);
      _;
  }

  modifier onlyTokenKeeper() {
      require(msg.sender == accICO || msg.sender == accBonusTokens);
      _;
  }


  function() public { } 


   
  function multiTransfer(address[] _investors, uint256[] _value )  
      public 
      onlyTokenKeeper 
      returns (uint256 _batchAmount)
  {
      require(_investors.length <= 255);  
      require(_value.length == _investors.length);
      uint8      cnt = uint8(_investors.length);
      uint256 amount = 0;
      for (uint i=0; i<cnt; i++){
        amount = amount.add(_value[i]);
        require(_investors[i] != address(0));
        balances[_investors[i]] = balances[_investors[i]].add(_value[i]);
        emit Transfer(msg.sender, _investors[i], _value[i]);
      }
      require(amount <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(amount);
      emit BatchDistrib(cnt, amount);
      return amount;
  }

  function requestNewMint(address _beneficiary, uint256 _amount) public onlyOwner  {
      require(_beneficiary != address(0) && _beneficiary != address(this));
      require(_amount > 0);
      require(
          additionalMint.status == StatusName.Minted  ||
          additionalMint.status == StatusName.Pending || 
          additionalMint.status == StatusName.OneSign 
      );
      additionalMint.status      = StatusName.Pending;
      additionalMint.beneficiary = _beneficiary;
      additionalMint.amount      = _amount;
      additionalMint.firstSign   = address(0);
      additionalMint.secondSign  = address(0);
      emit NewMintPending(_beneficiary,  _amount, uint64(now));
  }

   
  function sign() public onlyTrustedSign  returns (bool) {
      require(
          additionalMint.status == StatusName.Pending || 
          additionalMint.status == StatusName.OneSign ||
          additionalMint.status == StatusName.TwoSign  
      );

      if (additionalMint.status == StatusName.Pending) {
          additionalMint.firstSign = msg.sender;
          additionalMint.status    = StatusName.OneSign;
          emit FirstSign(msg.sender, uint64(now));
          return true;
      }

      if (additionalMint.status == StatusName.OneSign) {
        if (additionalMint.firstSign != msg.sender) {
            additionalMint.secondSign = msg.sender;
            additionalMint.status     = StatusName.TwoSign;
            emit SecondSign(msg.sender, uint64(now));
        }    
      }
        
      if (additionalMint.status == StatusName.TwoSign) {
          if (mint(additionalMint.beneficiary, additionalMint.amount)) {
              additionalMint.status = StatusName.Minted;
              emit   Minted(additionalMint.beneficiary, additionalMint.amount);
          }    
      }
      return true;
  }

   
  function mint(address _to, uint256 _amount) internal returns (bool) {
      totalSupply_  = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Transfer(address(0), _to, _amount);
      return true;
  }
}