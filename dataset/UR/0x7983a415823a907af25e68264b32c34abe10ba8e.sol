 

pragma solidity ^0.4.18;


 
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
  uint256 public totalSupply;
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

contract NodeToken is StandardToken {
    string public name = "NodePower";
    string public symbol = "NODE";
    uint8 public decimals = 2;
    bool public mintingFinished = false;
    mapping (address => bool) owners;
    mapping (address => bool) minters;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event MinterAdded(address indexed newMinter);
    event MinterRemoved(address indexed removedMinter);
    event Burn(address indexed burner, uint256 value);

    function NodeToken() public {
        owners[msg.sender] = true;
    }

     
    function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {
        require(!mintingFinished);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        MintFinished();
        return true;
    }

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

     
    function addOwner(address _address) onlyOwner public {
        owners[_address] = true;
        OwnerAdded(_address);
    }

     
    function delOwner(address _address) onlyOwner public {
        owners[_address] = false;
        OwnerRemoved(_address);
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

     
    function addMinter(address _address) onlyOwner public {
        minters[_address] = true;
        MinterAdded(_address);
    }

     
    function delMinter(address _address) onlyOwner public {
        minters[_address] = false;
        MinterRemoved(_address);
    }

     
    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }
}


 
contract NodeCrowdsale {
    using SafeMath for uint256;

     
    NodeToken public token;

     
    address public wallet;

     
    address public owner;

     
    uint256 public rateUSDcETH;

     
    uint public constant bonusTokensPercent = 45;

     
    uint256 public constant endTime = 1517443199;

     
    uint256 public constant minContributionUSDc = 1000;


     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event RateUpdate(uint256 rate);

    function NodeCrowdsale(address _tokenAddress, uint256 _initialRate) public {
        require(_tokenAddress != address(0));
        token = NodeToken(_tokenAddress);
        rateUSDcETH = _initialRate;
        wallet = msg.sender;
        owner = msg.sender;
    }


     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);
        require(now <= endTime);

        uint256 weiAmount = msg.value;

        require(calculateUSDcValue(weiAmount) >= minContributionUSDc);

         
        uint256 tokens = calculateTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function setRate(uint256 _rateUSDcETH) public onlyOwner {
         
        assert(_rateUSDcETH < rateUSDcETH.mul(110).div(100));
        assert(_rateUSDcETH > rateUSDcETH.mul(90).div(100));
        rateUSDcETH = _rateUSDcETH;
        RateUpdate(rateUSDcETH);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function calculateUSDcValue(uint256 _weiDeposit) public view returns (uint256) {

         
        uint256 weiPerUSDc = 1 ether/rateUSDcETH;

         
        uint256 depositValueInUSDc = _weiDeposit.div(weiPerUSDc);
        return depositValueInUSDc;
    }

     
     
    function calculateTokenAmount(uint256 _weiDeposit) public view returns (uint256) {
        uint256 mainTokens = calculateUSDcValue(_weiDeposit);
        uint256 bonusTokens = mainTokens.mul(bonusTokensPercent).div(100);
        return mainTokens.add(bonusTokens);
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }



}