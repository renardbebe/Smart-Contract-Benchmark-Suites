 

pragma solidity 0.4.19;

 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MinerOneToken is MintableToken {
    using SafeMath for uint256;

    string public name = "MinerOne";
    string public symbol = "MIO";
    uint8 public decimals = 18;

     
    struct Account {
         
        uint256 lastDividends;
         
        uint256 fixedBalance;
         
        uint256 remainder;
    }

     
    mapping(address => Account) internal accounts;

     
    uint256 internal totalDividends;
     
    uint256 internal reserved;

     
    event Distributed(uint256 amount);
     
    event Paid(address indexed to, uint256 amount);
     
    event FundsReceived(address indexed from, uint256 amount);

    modifier fixBalance(address _owner) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));

            account.fixedBalance = account.fixedBalance.add(numerator.div(totalSupply_));
            account.remainder = numerator % totalSupply_;
            account.lastDividends = totalDividends;
        }
        _;
    }

    modifier onlyWhenMintingFinished() {
        require(mintingFinished);
        _;
    }

    function () external payable {
        withdraw(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0);
        require(msg.value <= this.balance.sub(reserved));

        totalDividends = totalDividends.add(msg.value);
        reserved = reserved.add(msg.value);
        Distributed(msg.value);
    }

     
    function getDividends(address _owner) public view returns (uint256) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));
            return account.fixedBalance.add(numerator.div(totalSupply_));
        } else {
            return 0;
        }
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(msg.sender)
        fixBalance(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(_from)
        fixBalance(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function payoutToAddress(address[] _holders) external {
        require(_holders.length > 0);
        require(_holders.length <= 100);
        for (uint256 i = 0; i < _holders.length; i++) {
            withdraw(_holders[i], 0);
        }
    }

     
    function withdraw(address _benefeciary, uint256 _toReturn) internal
        onlyWhenMintingFinished
        fixBalance(_benefeciary) returns (bool) {

        uint256 amount = accounts[_benefeciary].fixedBalance;
        reserved = reserved.sub(amount);
        accounts[_benefeciary].fixedBalance = 0;
        uint256 toTransfer = amount.add(_toReturn);
        if (toTransfer > 0) {
            _benefeciary.transfer(toTransfer);
        }
        if (amount > 0) {
            Paid(_benefeciary, amount);
        }
        return true;
    }
}