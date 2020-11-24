 

pragma solidity ^0.4.18;

 

 
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

 

contract OracleOwnable is Ownable {

    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyOracleOrOwner() {
        require(msg.sender == oracle || msg.sender == owner);
        _;
    }

    function setOracle(address newOracle) public onlyOracleOrOwner {
        if (newOracle != address(0)) {
            oracle = newOracle;
        }

    }

}

 

 
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

   
  function balanceOf(address _owner) public view returns (uint256) {
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

 

 
contract MintableToken is StandardToken, OracleOwnable {
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

 

contract ReleasableToken is MintableToken {
    bool public released = false;

    event Release();
    event Burn(address, uint);

    modifier isReleased () {
        require(mintingFinished);
        require(released);
        _;
    }

    function release() public onlyOwner returns (bool) {
        require(mintingFinished);
        require(!released);
        released = true;
        Release();

        return true;
    }

    function transfer(address _to, uint256 _value) public isReleased returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isReleased returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function burn(address _to, uint _amount) public onlyOwner {
        totalSupply_ = totalSupply_.sub(_amount);
        balances[_to] = balances[_to].sub(_amount);
        Burn(_to, _amount);
    }
}

 

contract StageVestingToken is ReleasableToken {
    uint256 public stageCount;
    uint256 public stage;
    bool public isCheckStage;

    mapping(uint => mapping(address => uint256)) internal stageVesting;

    function StageVestingToken () public{
        stageCount = 4;
        stage = 0;
        isCheckStage = true;
    }

    function setStage(uint256 _stage) public onlyOracleOrOwner {
        stage = _stage;
    }

    function setStageCount(uint256 _stageCount) public onlyOracleOrOwner {
        stageCount = _stageCount;
    }

    function setIsCheckStage(bool _isCheckStage) public onlyOracleOrOwner {
        isCheckStage = _isCheckStage;
    }

    function getHolderLimit(address _holder) view public returns (uint256){
        return stageVesting[stage][_holder];
    }

    function canUseTokens(address _holder, uint256 _amount) view internal returns (bool){
        if (!isCheckStage) {
            return true;
        }
        return (getHolderLimit(_holder) >= _amount);
    }

    function addOnOneStage(address _to, uint256 _amount, uint256 _stage) internal {
        require(_stage < stageCount);
        stageVesting[_stage][_to] = stageVesting[_stage][_to].add(_amount);
    }

    function subOnOneStage(address _to, uint256 _amount, uint256 _stage) internal {
        require(_stage < stageCount);
        if (stageVesting[_stage][_to] >= _amount) {
            stageVesting[_stage][_to] = stageVesting[_stage][_to].sub(_amount);
        } else {
            stageVesting[_stage][_to] = 0;
        }
    }

    function addOnStage(address _to, uint256 _amount) internal returns (bool){
        return addOnStage(_to, _amount, stage);
    }

    function addOnStage(address _to, uint256 _amount, uint256 _stage) internal returns (bool){
        if (!isCheckStage) {
            return true;
        }
        for (uint256 i = _stage; i < stageCount; i++) {
            addOnOneStage(_to, _amount, i);
        }
        return true;
    }

    function subOnStage(address _to, uint256 _amount) internal returns (bool){
        return subOnStage(_to, _amount, stage);
    }

    function subOnStage(address _to, uint256 _amount, uint256 _stage) internal returns (bool){
        if (!isCheckStage) {
            return true;
        }

        for (uint256 i = _stage; i < stageCount; i++) {
            subOnOneStage(_to, _amount, i);
        }
        return true;
    }

    function mint(address _to, uint256 _amount, uint256 _stage) onlyOwner canMint public returns (bool) {
        super.mint(_to, _amount);
        addOnStage(_to, _amount, _stage);
    }

    function burn(address _to, uint _amount, uint256 _stage) public onlyOwner canMint{
        super.burn(_to, _amount);
        subOnStage(_to, _amount, _stage);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(canUseTokens(msg.sender, _value));
        require(subOnStage(msg.sender, _value));
        require(addOnStage(_to, _value));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(canUseTokens(_from, _value));
        require(subOnStage(_from, _value));
        require(addOnStage(_to, _value));
        return super.transferFrom(_from, _to, _value);
    }
}

 

contract MetabaseToken is StageVestingToken {

    string public constant name = "METABASE";
    string public constant symbol = "MBT";
    uint256 public constant decimals = 18;

}

 

contract MetabaseCrowdSale is OracleOwnable {
    using SafeMath for uint;

    MetabaseToken token;

    event Transaction(address indexed beneficiary, string currency, uint currencyAmount, uint rate, uint tokenAmount, uint stage, bool isNegative);


    address[] currencyInvestors;
    mapping(address => bool) currencyInvestorsAddresses;

    function setToken(address _token) public onlyOracleOrOwner {
        token = MetabaseToken(_token);
    }

    function addInvestorIfNotExists(address _beneficiary) internal {
        if (!currencyInvestorsAddresses[_beneficiary]) {
            currencyInvestors.push(_beneficiary);
        }
    }

    function buy(address _beneficiary, string _currency, uint _currencyAmount, uint _rate, uint _tokenAmount, uint _stage) public onlyOracleOrOwner {
        addInvestorIfNotExists(_beneficiary);

        token.mint(_beneficiary, _tokenAmount, _stage);

        Transaction(_beneficiary, _currency, _currencyAmount, _rate, _tokenAmount, _stage, false);
    }

    function refund(address _beneficiary, string _currency, uint _currencyAmount, uint _tokenAmount, uint _stage) public onlyOracleOrOwner {
        addInvestorIfNotExists(_beneficiary);

        token.burn(_beneficiary, _tokenAmount, _stage);

        Transaction(_beneficiary, _currency, _currencyAmount, 0, _tokenAmount, _stage, true);
    }

    function tokenTransferOwnership(address _owner) onlyOracleOrOwner public {
        token.transferOwnership(_owner);
    }
}