 

pragma solidity^0.4.24;

 

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract StandardToken  {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

     
    function mint(
        address _to,
        uint256 _amount
      )
      public
      hasMintPermission
      canMint
      returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract MobiusBlueToken is MintableToken {

    using SafeMath for uint;
    address creator = msg.sender;
    uint8 public decimals = 18;
    string public name = "Möbius BLUE";
    string public symbol = "BLU";

    uint public totalDividends;
    uint public lastRevenueBnum;

    uint public unclaimedDividends;

    struct DividendAccount {
        uint balance;
        uint lastCumulativeDividends;
        uint lastWithdrawnBnum;
    }

    mapping (address => DividendAccount) public dividendAccounts;

    modifier onlyTokenHolders{
        require(balances[msg.sender] > 0, "Not a token owner!");
        _;
    }
    
    modifier updateAccount(address _of) {
        _updateDividends(_of);
        _;
    }

    event DividendsWithdrawn(address indexed from, uint value);
    event DividendsTransferred(address indexed from, address indexed to, uint value);
    event DividendsDisbursed(uint value);
        
    function mint(address _to, uint256 _amount) public 
    returns (bool)
    {   
         
        super.mint(creator, _amount/2);
         
        return super.mint(_to, _amount);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        
        _transferDividends(msg.sender, _to, _value);
        require(super.transfer(_to, _value), "Failed to transfer tokens!");
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        
        _transferDividends(_from, _to, _value);
        require(super.transferFrom(_from, _to, _value), "Failed to transfer tokens!");
        return true;
    }

     
    function donate(address _to, uint _value) public returns (bool success) {
        require(msg.sender == creator, "You can't do that!");
        require(!mintingFinished, "ICO Period is over - use a normal transfer.");
        return super.transfer(_to, _value);
    }

    function withdrawDividends() public onlyTokenHolders {
        uint amount = _getDividendsBalance(msg.sender);
        require(amount > 0, "Nothing to withdraw!");
        unclaimedDividends = unclaimedDividends.sub(amount);
        dividendAccounts[msg.sender].balance = 0;
        dividendAccounts[msg.sender].lastWithdrawnBnum = block.number;
        msg.sender.transfer(amount);
        emit DividendsWithdrawn(msg.sender, amount);
    }

    function dividendsAvailable(address _for) public view returns(bool) {
        return lastRevenueBnum >= dividendAccounts[_for].lastWithdrawnBnum;
    }

    function getDividendsBalance(address _of) external view returns(uint) {
        uint outstanding = _dividendsOutstanding(_of);
        if (outstanding > 0) {
            return dividendAccounts[_of].balance.add(outstanding);
        }
        return dividendAccounts[_of].balance;
    }

    function disburseDividends() public payable {
        if(msg.value == 0) {
            return;
        }
        totalDividends = totalDividends.add(msg.value);
        unclaimedDividends = unclaimedDividends.add(msg.value);
        lastRevenueBnum = block.number;
        emit DividendsDisbursed(msg.value);
    }

    function () public payable {
        disburseDividends();
    }

    function _transferDividends(address _from, address _to, uint _tokensValue) internal 
    updateAccount(_from)
    updateAccount(_to) 
    {
        uint amount = dividendAccounts[_from].balance.mul(_tokensValue).div(balances[_from]);
        if(amount > 0) {
            dividendAccounts[_from].balance = dividendAccounts[_from].balance.sub(amount);
            dividendAccounts[_to].balance = dividendAccounts[_to].balance.add(amount); 
            dividendAccounts[_to].lastWithdrawnBnum = dividendAccounts[_from].lastWithdrawnBnum;
            emit DividendsTransferred(_from, _to, amount);
        }
    }
    
    function _getDividendsBalance(address _holder) internal
    updateAccount(_holder)
    returns(uint) 
    {
        return dividendAccounts[_holder].balance;
    }    

    function _updateDividends(address _holder) internal {
        require(mintingFinished, "Can't calculate balances if still minting tokens!");
        uint outstanding = _dividendsOutstanding(_holder);
        if (outstanding > 0) {
            dividendAccounts[_holder].balance = dividendAccounts[_holder].balance.add(outstanding);
        }
        dividendAccounts[_holder].lastCumulativeDividends = totalDividends;
    }

    function _dividendsOutstanding(address _holder) internal view returns(uint) {
        uint newDividends = totalDividends.sub(dividendAccounts[_holder].lastCumulativeDividends);
        
        if(newDividends == 0) {
            return 0;
        } else {
            return newDividends.mul(balances[_holder]).div(totalSupply_);
        }
    }   
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}