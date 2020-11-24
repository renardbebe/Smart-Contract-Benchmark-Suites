 

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
     
     
     
    return a / b;
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
    
  using SafeMath for uint256;
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
    owner = newOwner;
  }

}

contract ERC20Basic is Ownable {
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
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    return true;
  }

}

contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Transfer(burner, address(0), _value);
  }
}

contract MintableToken is BurnableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  address public saleAddress;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier onlyManagment() {
    require(msg.sender == owner || msg.sender == saleAddress);
    _;
  }

  function transferManagment(address newSaleAddress) public onlyOwner {
    if (newSaleAddress != address(0)) {
      saleAddress = newSaleAddress;
    }
  }

   
  function mint(address _to, uint256 _amount) onlyManagment canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    return true;
  }
}

contract AfeliCoin is MintableToken {

  string public name = "Afeli Coin";
  string public symbol = "AEI";
  uint8 public decimals = 18;
  
}


 
contract Pausable is Ownable {

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
  }
}

contract AfeliCoinPresale is Pausable {
    using SafeMath for uint256;

    address public organisationWallet = 0xa56B96235903b1631BC355DC0CFD8511F31D883b;
    AfeliCoin public tokenReward;

    uint256 public tokenPrice = 1000;  
    uint256 public minimalPrice = 1000000000000000;  
    uint256 public discount = 25;
    uint256 public amountRaised;

    bool public finished = false;
    bool public presaleFail = false;

    mapping (address => uint256) public balanceOf;
    event FundTransfer(address backer, uint amount, bool isContribution);

    function AfeliCoinPresale(address _tokenReward) public {
        tokenReward = AfeliCoin(_tokenReward);
    }

    modifier whenNotFinished() {
        require(!finished);
        _;
    }

    modifier afterPresaleFail() {
        require(presaleFail);
        _;
    }

    function () public payable {
        buy(msg.sender);
    }

    function buy(address buyer) whenNotPaused whenNotFinished public payable {
        require(buyer != address(0));
        require(msg.value != 0);
        require(msg.value >= minimalPrice);

        uint256 amount = msg.value;
        uint256 tokens = amount.mul(tokenPrice).mul(discount.add(100)).div(100);

        balanceOf[buyer] = balanceOf[buyer].add(amount);

        tokenReward.mint(buyer, tokens);
        amountRaised = amountRaised.add(amount);
    }

    function updatePrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function updateMinimal(uint256 _minimalPrice) public onlyOwner {
        minimalPrice = _minimalPrice;
    }
    
    function updateDiscount(uint256 _discount) public onlyOwner {
        discount = _discount;
    }

    function finishPresale() public onlyOwner {
        organisationWallet.transfer(amountRaised.mul(3).div(100));
        owner.transfer(address(this).balance);
        finished = true;
    }

    function setPresaleFail() public onlyOwner {
        finished = true;
        presaleFail = true;
    }

    function safeWithdrawal() public afterPresaleFail {
        uint amount = balanceOf[msg.sender];
        msg.sender.transfer(amount);
        balanceOf[msg.sender] = 0;
    }

}