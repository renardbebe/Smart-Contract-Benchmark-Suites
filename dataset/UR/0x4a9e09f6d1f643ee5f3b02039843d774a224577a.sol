 

pragma solidity ^0.5.1;

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

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


     
    function allowance(address _owner, address _spender)
        public view returns (uint256) {
        return allowed[_owner][_spender];
    }


     
    function increaseApproval(address _spender, uint256 _addedValue)
        public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue >= oldValue) allowed[msg.sender][_spender] = 0;
        else allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract BurnableToken is StandardToken, Ownable {
    event Burn(address indexed burner, uint256 value);


     
    function burn(address _who, uint256 _value) onlyOwner public {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
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


     
    function mint(address _to, uint256 _amount)
        public hasMintPermission canMint returns (bool) {
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

contract CappedToken is MintableToken {
    uint256 public cap;


    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }


     
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value)
        public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value)
        public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


    function approve(address _spender, uint256 _value)
        public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }


    function increaseApproval(address _spender, uint _addedValue)
        public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }


    function decreaseApproval(address _spender, uint _subtractedValue)
        public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract CryptoControlToken is BurnableToken, PausableToken, CappedToken {
    address public upgradedAddress;
    bool public deprecated;
    string public contactInformation = "<a class="__cf_email__" data-cfemail="fb9894958f9a988fbb9889828b8f949894958f899497d59294" href="/cdn-cgi/l/email-protection">[email protected]</a>";
    string public name = "CryptoControl";
    string public reason;
    string public symbol = "CCIO";
    uint8 public decimals = 8;

    constructor () CappedToken(100000000000000000000) public {}

     
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4), "payload too big");
        _;
    }

     
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        else return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        else return super.transferFrom(_from, _to, _value);
    }

     
    function balanceOf(address who) public view returns (uint256) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        else return super.balanceOf(who);
    }

     
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        else return super.approve(_spender, _value);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) return StandardToken(upgradedAddress).allowance(_owner, _spender);
        else return super.allowance(_owner, _spender);
    }

     
    function deprecate(address _upgradedAddress, string memory _reason) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        reason = _reason;
        emit Deprecate(_upgradedAddress, _reason);
    }

     
    event Deprecate(address newAddress, string reason);
}

contract UpgradedStandardToken is PausableToken {
     
     
    function transferByLegacy(address from, address to, uint value) public returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public returns (bool);
    function approveByLegacy(address from, address spender, uint value) public returns (bool);
}