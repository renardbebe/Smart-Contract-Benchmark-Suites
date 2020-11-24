 

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

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

 
contract PausableToken is ERC827Token, Pausable {

   
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
  
   
  function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
      return super.transfer(_to, _value, _data);
  }
  
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
      return super.transferFrom(_from, _to, _value, _data);
  }
  
  function approve(address _spender, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
      return super.approve(_spender, _value, _data);
  }
  
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public whenNotPaused returns (bool) {
      return super.increaseApproval(_spender, _addedValue, _data);
  }
  
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public whenNotPaused returns (bool) {
      return super.decreaseApproval(_spender, _subtractedValue, _data);
  }
}

 
contract MintableToken is PausableToken {
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

 
contract AirEX is MintableToken {
  string public constant name = "AIRX";
  string public constant symbol = "AIRX";
  uint8 public constant decimals = 18;

  uint256 public hardCap;
  uint256 public softCap;

  function AirEX(uint256 _cap) public {
    require(_cap > 0);
    hardCap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= hardCap);
    return super.mint(_to, _amount);
  }
  
  function updateHardCap(uint256 _cap) onlyOwner public {
    require(_cap > 0);
    hardCap = _cap;
  }
  
  function updateSoftCap(uint256 _cap) onlyOwner public {
    require(_cap > 0);
    softCap = _cap;  
  }

}

contract SalesManagerUpgradable is Ownable {
    using SafeMath for uint256;

 
    address public ethOwner = 0xe8290a10565CB7aDeE9246661B34BB77CB6e4024;
 
    uint public price1 = 100;
    uint public price2 = 110;
    uint public price3 = 125;

 
    uint public lev1 = 2 ether;
    uint public lev2 = 10 ether;
    
    uint public ethFundRaised;
    
    address public tokenAddress;

 
    function SalesManagerUpgradable () public {
        tokenAddress = new AirEX(5550000 ether);
    }

    function () payable public {
        if(msg.value > 0) revert();
    }

    function buyTokens(address _investor) public payable returns (bool){
        if (msg.value <= lev1) {
            uint tokens = msg.value.mul(price1);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        } else if (msg.value > lev1 && msg.value <= lev2) {
            tokens = msg.value.mul(price2);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        } else if (msg.value > lev2) {
            tokens = msg.value.mul(price3);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        }
        return false;
    }

    function sendTokens(uint _amount, uint _ethers, address _investor) private returns (bool) {
        AirEX tokenHolder = AirEX(tokenAddress);
        if (tokenHolder.mint(_investor, _amount)) {
            ethFundRaised = ethFundRaised.add(_ethers);
            ethOwner.transfer(_ethers);
            return true;
        }
        return false;
    }
    
    function generateTokensManually(uint _amount, address _to) public onlyOwner {
        AirEX tokenHolder = AirEX(tokenAddress);
        tokenHolder.mint(_to, _amount);
    }
    
    function setColdAddress(address _newAddr) public onlyOwner {
        ethOwner = _newAddr;
    }
    
    function setPrice1 (uint _price) public onlyOwner {
        price1 = _price;
    }
    
    function setPrice2 (uint _price) public onlyOwner {
        price2 = _price;
    }
    
    function setPrice3 (uint _price) public onlyOwner {
        price3 = _price;
    }

 
 
    function setLev1 (uint _price) public onlyOwner {
        lev1 = _price;
    }

    function setLev2 (uint _price) public onlyOwner {
        lev2 = _price;
    }
    
    function transferOwnershipToken(address newTokenOwnerAddress) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.transferOwnership(newTokenOwnerAddress);
    }
    
    function updateHardCap(uint256 _cap) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.updateHardCap(_cap);
    }
    
    function updateSoftCap(uint256 _cap) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.updateSoftCap(_cap);
    }
    
    function unPauseContract() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.unpause();
    }
    
    function pauseContract() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.pause();
    }
    
    function finishMinting() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.finishMinting();
    }
    
    function drop(address[] _destinations, uint256[] _amount) onlyOwner public
    returns (uint) {
        uint i = 0;
        while (i < _destinations.length) {
           AirEX(tokenAddress).mint(_destinations[i], _amount[i]);
           i += 1;
        }
        return(i);
    }
    
    function withdraw(address _to) public onlyOwner {
        _to.transfer(this.balance);
    }
    
    function destroySalesManager(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}


contract DepositManager is Ownable {
    address public actualSalesAddress;
    
    function DepositManager (address _actualAddres) public {
        actualSalesAddress = _actualAddres;
    }
    
    function () payable public {
        SalesManagerUpgradable sm = SalesManagerUpgradable(actualSalesAddress);
        if(!sm.buyTokens.value(msg.value)(msg.sender)) revert();
    }
    
    function setNewSalesManager (address _newAddr) public onlyOwner {
        actualSalesAddress = _newAddr;
    }

}