 

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

 

contract MultipleOwners is Ownable {
    struct Owner {
        bool isOwner;
        uint256 index;
    }
    mapping(address => Owner) public owners;
    address[] public ownersLUT;

    modifier onlyOwner() {
        require(msg.sender == owner || owners[msg.sender].isOwner);
        _;
    }

    function addOwner(address newOwner) public onlyOwner {
        require(!owners[msg.sender].isOwner);
        owners[newOwner] = Owner(true, ownersLUT.length);
        ownersLUT.push(newOwner);
    }

    function removeOwner(address _owner) public onlyOwner {
        uint256 index = owners[_owner].index;
         
        ownersLUT[index] = ownersLUT[ownersLUT.length - 1];
         
        ownersLUT.length--;
         
        delete owners[_owner];
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

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
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

 

contract Hydrocoin is MintableToken, MultipleOwners {
    string public name = "HydroCoin";
    string public symbol = "HYC";
    uint8 public decimals = 18;

     
    uint256 public totalSupply = 500100000 ether;
     
    uint256 public hardCap = 1000000000 ether;

     
    uint256 public teamTransferFreeze;
    address public founders;

    function Hydrocoin(address _paymentContract, uint256 _teamTransferFreeze, address _founders)
        public
    {
        teamTransferFreeze = _teamTransferFreeze;
        founders = _founders;
         
        balances[founders] = balances[founders].add(500000000 ether);
        Transfer(0x0, founders, 500000000 ether);

         
        balances[_paymentContract] = balances[_paymentContract].add(100000 ether);
        Transfer(0x0, _paymentContract, 100000 ether);
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
        assert(totalSupply <= hardCap);
    }

    modifier validateTrasfer() {
        _;
        assert(balances[founders] >= 100000000 ether || teamTransferFreeze < now);
    }

    function transfer(address _to, uint256 _value) public validateTrasfer returns (bool) {
        super.transfer(_to, _value);
    }

}

 

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  Hydrocoin public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public hardCap;


   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _hardCap) public {
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    hardCap = _hardCap;
  }

  modifier validateHardCap() {
    _;
     
    assert(token.totalSupply() <= hardCap);
  }

   
   
  function assignTokenContract(address tokenContract) public onlyOwner {
    require(token == address(0));
    token = Hydrocoin(tokenContract);
    hardCap = hardCap.add(token.totalSupply());
    if (hardCap > token.hardCap()) {
      hardCap = token.hardCap();
    }
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable validateHardCap {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
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

 

contract Payment is Destructible {
    using SafeMath for uint256;

    Hydrocoin public token;

    address public preemption;
    Crowdsale public preIco;

    uint256 public rate = 1000;
    uint256 public lock;

    function Payment(address _preIco, address _preemption) public {
        preemption = _preemption;
        preIco = Crowdsale(_preIco);
        lock = preIco.startTime().add(7 days);
    }

    function validateLock() public {
        uint256 weiRaised = preIco.weiRaised();
        if (weiRaised >= 15 ether && now + 6 hours < lock) {
            lock = now + 6 hours;
        }
    }

    function setToken(address _tokenAddr) public onlyOwner {
        token = Hydrocoin(_tokenAddr);
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function transferToken(address _to, uint256 _value) public onlyOwner {
        require(lock <= now);
        token.transfer(_to, _value);
    }

    function () public payable {
        require(token != address(0));
        require(msg.value > 0);

        if (lock > now) {
            require(msg.sender == preemption && msg.value >= 15 ether);
            owner.transfer(msg.value);
            uint256 amount = 100000 ether;
            token.transfer(msg.sender, amount);
        } else {
            amount = msg.value.mul(rate);
            uint256 currentBal = token.balanceOf(this);
            if (currentBal >= amount) {
                owner.transfer(msg.value);
                token.transfer(msg.sender, amount);
            } else {
                amount = currentBal;
                uint256 value = amount.div(rate);
                owner.transfer(value);
                token.transfer(msg.sender, amount);
                msg.sender.transfer(msg.value.sub(value));
            }
        }
    }
}