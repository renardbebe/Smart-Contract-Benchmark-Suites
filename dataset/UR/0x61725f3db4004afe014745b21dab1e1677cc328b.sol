 

pragma solidity ^0.4.13;

contract Versioned {
    string public version;

    function Versioned(string _version) public {
        version = _version;
    }
}

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

contract Pausable is Ownable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused || msg.sender == owner);
        _;
    }

    function pause() onlyOwner public {
        paused = true;
    }

    function unpause() onlyOwner public {
        paused = false;
    }
}

contract Extractable is Ownable {
     
    function () payable public {}

     
    function extractEther(address withdrawalAddress) public onlyOwner {
        if (this.balance > 0) {
            withdrawalAddress.transfer(this.balance);
        }
    }

     
    function extractToken(address tokenAddress, address withdrawalAddress) public onlyOwner {
        ERC20Basic tokenContract = ERC20Basic(tokenAddress);
        uint256 balance = tokenContract.balanceOf(this);
        if (balance > 0) {
            tokenContract.transfer(withdrawalAddress, balance);
        }
    }
}

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

contract FloatingSupplyToken is Ownable, StandardToken {
    using SafeMath for uint256;
     
     
    function issueTranche(uint256 _amount) public onlyOwner returns (uint256) {
        require(_amount > 0);

        totalSupply = totalSupply.add(_amount);
        balances[owner] = balances[owner].add(_amount);

        emit Transfer(address(0), owner, _amount);
        return totalSupply;
    }

     
     
    function burn(uint256 _amount) public {
        require(_amount > 0);
        require(balances[msg.sender] > 0);
        require(_amount <= balances[msg.sender]);

        assert(_amount <= totalSupply);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit Transfer(msg.sender, address(0), _amount);
    }
}

contract FundToken is StandardToken {
    using SafeMath for uint256;

     
    mapping (address => mapping (address => uint256)) fundBalances;

     
     
    mapping (address => bool) public fundManagers;

     
     
    modifier onlyFundManager() {
        require(fundManagers[msg.sender]);
        _;
    }

     
     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(!fundManagers[msg.sender]);
        require(!fundManagers[_to]);

        return super.transfer(_to, _value);
    }

     

     
    event RegisterFund(address indexed _fundManager);

     
    event DissolveFund(address indexed _fundManager);

     
    event FundTransferIn(address indexed _from, address indexed _fundManager,
                         address indexed _owner, uint256 _value);

     
    event FundTransferOut(address indexed _fundManager, address indexed _from,
                          address indexed _to, uint256 _value);

     
    event FundTransferWithin(address indexed _fundManager, address indexed _from,
                             address indexed _to, uint256 _value);

     
     
    function registerFund() public {
        require(balances[msg.sender] == 0);
        require(!fundManagers[msg.sender]);

        fundManagers[msg.sender] = true;

        emit RegisterFund(msg.sender);
    }

     
    function dissolveFund() public {
        require(balances[msg.sender] == 0);
        require(fundManagers[msg.sender]);

        delete fundManagers[msg.sender];

        emit DissolveFund(msg.sender);
    }


     

     
    function fundBalanceOf(address _fundManager, address _owner) public view returns (uint256) {
        return fundBalances[_fundManager][_owner];
    }

     
    function fundTransferIn(address _fundManager, address _to, uint256 _amount) public {
        require(fundManagers[_fundManager]);
        require(!fundManagers[msg.sender]);

        require(balances[msg.sender] >= _amount);
        require(_amount > 0);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_fundManager] = balances[_fundManager].add(_amount);
        fundBalances[_fundManager][_to] = fundBalances[_fundManager][_to].add(_amount);

        emit FundTransferIn(msg.sender, _fundManager, _to, _amount);
        emit Transfer(msg.sender, _fundManager, _amount);
    }

     
    function fundTransferOut(address _from, address _to, uint256 _amount) public {
        require(!fundManagers[_to]);
        require(fundManagers[msg.sender]);

        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        require(fundBalances[msg.sender][_from] >= _amount);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        fundBalances[msg.sender][_from] = fundBalances[msg.sender][_from].sub(_amount);
        
        if (fundBalances[msg.sender][_from] == 0){
            delete fundBalances[msg.sender][_from];
        }
        
        emit FundTransferOut(msg.sender, _from, _to, _amount);
        emit Transfer(msg.sender, _to, _amount);
    }

     
    function fundTransferWithin(address _from, address _to, uint256 _amount) public {
        require(fundManagers[msg.sender]);

        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        require(fundBalances[msg.sender][_from] >= _amount);

        fundBalances[msg.sender][_from] = fundBalances[msg.sender][_from].sub(_amount);
        fundBalances[msg.sender][_to] = fundBalances[msg.sender][_to].add(_amount);

        if (fundBalances[msg.sender][_from] == 0){
            delete fundBalances[msg.sender][_from];
        }

        emit FundTransferWithin(msg.sender, _from, _to, _amount);
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!fundManagers[msg.sender]);

        return super.approve(_spender, _value);
    }

     
    function transferFrom(address _from, address _to,
                          uint256 _amount) public returns (bool success) {
        require(!fundManagers[_from]);
        require(!fundManagers[_to]);

        return super.transferFrom(_from, _to, _amount);
    }
}

contract BurnFundToken is FundToken, FloatingSupplyToken {
    using SafeMath for uint256;

     
     
    event FundBurn(address indexed _fundManager, address indexed _owner, uint256 _value);

     
     
    function burn(uint256 _amount) public {
        require(!fundManagers[msg.sender]);

        super.burn(_amount);
    }

     
     
    function fundBurn(address _fundAccount, uint256 _amount) public onlyFundManager {
        require(fundManagers[msg.sender]);
        require(balances[msg.sender] != 0);
        require(fundBalances[msg.sender][_fundAccount] > 0);
        require(_amount > 0);
        require(_amount <= fundBalances[msg.sender][_fundAccount]);

        assert(_amount <= totalSupply);
        assert(_amount <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        fundBalances[msg.sender][_fundAccount] = fundBalances[msg.sender][_fundAccount].sub(_amount);

        emit FundBurn(msg.sender, _fundAccount, _amount);
    }
}

contract PausableToken is BurnFundToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function burn(uint256 _amount) public whenNotPaused {
        return super.burn(_amount);
    }

    function fundBurn(address _fundAccount, uint256 _amount) public whenNotPaused {
        return super.fundBurn(_fundAccount, _amount);
    }

    function registerFund() public whenNotPaused {
        return super.registerFund();
    }

    function dissolveFund() public whenNotPaused {
        return super.dissolveFund();
    }

    function fundTransferIn(address _fundManager, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferIn(_fundManager, _to, _amount);
    }

    function fundTransferOut(address _from, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferOut(_from, _to, _amount);
    }

    function fundTransferWithin(address _from, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferWithin(_from, _to, _amount);
    }
}

contract DAXT is PausableToken,
    DetailedERC20("Digital Asset Exchange Token", "DAXT", 18),
    Versioned("1.2.0"),
    Destructible,
    Extractable {

}