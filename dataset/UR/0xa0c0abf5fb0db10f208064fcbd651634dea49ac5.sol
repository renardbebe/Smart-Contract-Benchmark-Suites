 

pragma solidity ^0.4.13;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CryptohomaToken is StandardToken, MintableToken, BurnableToken {
    
    string public name = "CryptohomaToken";
    string public symbol = "HOMA";
    uint public decimals = 18;

    using SafeMath for uint256;

     
    uint256 public weiRaised;

    uint start = 1525132801;

    uint period = 31;

    uint256 public totalSupply = 50000000 * 1 ether;

    uint256 public totalMinted;

    uint256 public presale_tokens = 1562500 * 1 ether;
    uint public bounty_percent = 5;
    uint public airdrop_percent = 2;
    uint public organizers_percent = 15;

    address public multisig = 0xcBF6E568F588Fc198312F9587e660CbdF64DB262;
    address public presale = 0x42d8388E55A527Fa84f29A4D8768B923Dd8628E3;
    address public bounty = 0x27986d9CB66Dc4b60911D1E10f2DB6Ca3459A075;
    address public airdrop = 0xE0D7bd9a4ce64049A187b0097f86F6ae49bD19b5;
    address public organizer1 = 0x4FE7F4AA0d221827112090Ad7B90c7D8B9c08cc5;
    address public organizer2 = 0x6A7fd6308791B198739679F571bD981F7aA3a239;
    address public organizer3 = 0xCb04445D08830db4BFEB8F94fb71422C2FBAB17F;
    address public organizer4 = 0x4A44960b49816b8cB77de28FCB512AD903d62FEb;
    address public organizer5 = 0xEB27178C637336c3A6243aA312C3f197B54155f1;
    address public organizer6 = 0x84ae1B4E8c008dCbEfF91A923EA216a5fA718e25;
    address public organizer7 = 0x6de044c56D91b880C73C8e667C37A2B2A977FC3a;
    address public organizer8 = 0x5b3a08DaAcC4167e9432dCF56D3fcd147006192c;

    uint256 public rate = 0.000011 * 1 ether;
    uint256 public rate2 = 0.000015 * 1 ether;

    function CryptohomaToken() public {

        totalMinted = totalMinted.add(presale_tokens);
        super.mint(presale, presale_tokens);

        uint256 tokens = totalSupply.mul(bounty_percent).div(100);
        totalMinted = totalMinted.add(tokens);
        super.mint(bounty, tokens);

        tokens = totalSupply.mul(airdrop_percent).div(100);
        totalMinted = totalMinted.add(tokens);
        super.mint(airdrop, tokens);

        tokens = totalSupply.mul(organizers_percent).div(100);
        totalMinted = totalMinted.add(tokens);
        tokens = tokens.div(8);
        super.mint(organizer1, tokens);
        super.mint(organizer2, tokens);
        super.mint(organizer3, tokens);
        super.mint(organizer4, tokens);
        super.mint(organizer5, tokens);
        super.mint(organizer6, tokens);
        super.mint(organizer7, tokens);
        super.mint(organizer8, tokens);

    }


     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds();
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount / rate * 1 ether;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);

        require(now > start && now < start + period * 1 days);

        if (now > start.add(15 * 1 days)) {
            rate = rate2;
        }

        uint256 tokens = _getTokenAmount(_weiAmount);
        totalMinted = totalMinted.add(tokens);

        require(totalSupply >= totalMinted);

    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        super.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _forwardFunds() internal {
        multisig.transfer(msg.value);
    }

}