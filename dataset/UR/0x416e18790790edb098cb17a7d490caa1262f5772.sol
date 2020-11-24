 

pragma solidity ^0.4.13;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract LoomTimeVault is Ownable {
   
   
  LoomToken public loomToken;

   
  mapping(address => uint256) public beneficiaries;  

   
  uint256 public releaseTime;

   

  event BeneficiaryAdded(address _beneficiaryAddress, uint256 _amount);
  event BeneficiaryWithdrawn(address _beneficiaryAddress, uint256 _amount);
  event OwnerWithdrawn(address _ownerAddress, uint256 _amount);

   

  modifier onlyAfterReleaseTime() {
    require(now >= releaseTime);
    _;
  }

   

  function LoomTimeVault(uint256 _releaseTime, address _loomTokenAddress) public {
    require(_releaseTime > now);
    require(_loomTokenAddress != address(0));

    owner = msg.sender;
    releaseTime = _releaseTime;
    loomToken = LoomToken(_loomTokenAddress);
  }

   

   
  function addBeneficiary(address _beneficiaryAddress, uint256 _amount)
    external
    onlyOwner
  {
    require(_beneficiaryAddress != address(0));
    require(_amount > 0);
    require(_amount <= loomToken.balanceOf(this));

    beneficiaries[_beneficiaryAddress] = _amount;
    BeneficiaryAdded(_beneficiaryAddress, _amount);
  }

   
  function withdraw()
    external
    onlyAfterReleaseTime
  {
    uint256 amount = beneficiaries[msg.sender];
    require(amount > 0);

    beneficiaries[msg.sender] = 0;

    assert(loomToken.transfer(msg.sender, amount));
    BeneficiaryWithdrawn(msg.sender, amount);
  }

   
  function ownerWithdraw()
    external
    onlyOwner
    onlyAfterReleaseTime
  {
    uint256 amount = loomToken.balanceOf(this);
    require(amount > 0);

    assert(loomToken.transfer(msg.sender, amount));
    OwnerWithdrawn(msg.sender, amount);
  }

   
  function beneficiaryAmount(address _beneficiaryAddress)
    public
    view
    returns (uint256)
  {
    return beneficiaries[_beneficiaryAddress];
  }
}

contract LoomToken is StandardToken {
  string public name    = "LoomToken";
  string public symbol  = "LOOM";
  uint8 public decimals = 18;

   
  uint256 public constant INITIAL_SUPPLY = 1000000000;

  function LoomToken() public {
    totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply_;
  }
}