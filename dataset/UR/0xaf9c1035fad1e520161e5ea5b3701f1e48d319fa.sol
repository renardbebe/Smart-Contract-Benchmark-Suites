 

pragma solidity ^0.4.23;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract BurnableByOwnerToken is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);

   
  function burn(address _who, uint256 _value) public onlyOwner {
    _burn(_who, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract MultiTransferableToken is BasicToken {
    function multiTransfer(address[] _to, uint256[] _values) public returns (bool) {
        require(_to.length == _values.length);
        uint sum = 0;
        uint i;
        for (i = 0; i < _values.length; i++) {
            sum = sum.add(_values[i]);
        }
        require(sum <= balances[msg.sender]);
    
        for (i = 0; i < _to.length; i++) {
            require(_to[i] != address(0));
            
            balances[_to[i]] = balances[_to[i]].add(_values[i]);
            emit Transfer(msg.sender, _to[i], _values[i]);
        }
        
        balances[msg.sender] = balances[msg.sender].sub(sum);
        return true;
    }
}

contract ZodiaqToken is StandardToken, MintableToken, BurnableByOwnerToken, MultiTransferableToken {
    string public name = 'Zodiaq Token';
    string public symbol = 'ZOD';
    uint8 public decimals = 8;
}

contract Managable is Ownable {
    address public manager = 0x0;

    event ManagerIsChanged(address indexed previousManager, address indexed newManager);
    
    modifier onlyManager() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    function changeManager(address newManager) public onlyOwner {
        manager = newManager;
        
        emit ManagerIsChanged(manager, newManager);
    }
}

library SafeMathExtended {

     
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
    function mulToFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract ZodiaqDistribution is Managable {
    using SafeMathExtended for uint256;

    ZodiaqToken public token;
    uint256 public BASE = 10 ** 8;

    address public bountyOwner;
    address public referralProgramOwner;
    address public team;
    address public partners;

    bool    public isICOFinished = false;
    uint256 public icoFinishedDate = 0;

    uint256 public teamReward = 0;
    uint256 public partnersReward = 0;

    constructor(address zodiaqToken) public {
        require(zodiaqToken != 0x0);
        token = ZodiaqToken(zodiaqToken);
    }
    
    modifier isICORunning {
        require(!isICOFinished);
        _;
    }
    
    function init(address _bountyOwner, address _referralProgramOwner, address _team, address _partners) public onlyOwner {
         
        require(bountyOwner == 0x0);

        require(_bountyOwner != 0x0);
        require(_referralProgramOwner != 0x0);
        require(_team != 0x0);
        require(_partners != 0x0);
        
        bountyOwner = _bountyOwner;
        referralProgramOwner = _referralProgramOwner;
        team = _team;
        partners = _partners;
        
        token.mint(address(this), 240000000 * BASE);
        token.mint(bountyOwner,          9000000 * BASE);
        token.mint(referralProgramOwner, 6000000 * BASE);
    }
    
    function sendTokensTo(address[] recipients, uint256[] values) public onlyManager isICORunning {
        require(recipients.length == values.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            assert(token.transfer(recipients[i], values[i]));
        }
    }
    
    function stopICO() public onlyOwner isICORunning {
        token.burn(address(this), token.balanceOf(address(this)));
        token.burn(referralProgramOwner, token.balanceOf(referralProgramOwner));
        token.burn(bountyOwner, token.balanceOf(bountyOwner));

        uint256 totalSupply = token.totalSupply().mulToFraction(100, 85);
        teamReward = totalSupply.mulToFraction(10, 100);
        partnersReward = totalSupply.mulToFraction(5, 100);

        token.mint(address(this), teamReward + partnersReward);

        token.finishMinting();

        isICOFinished = true;
        icoFinishedDate = now;
    }

    function payPartners() public {
        require(partnersReward != 0);
        uint secondsInYear = 31536000;
        require(icoFinishedDate + secondsInYear / 2 < now);
        assert(token.transfer(partners, partnersReward));
        partnersReward = 0;
    }

    function payTeam() public {
        require(teamReward != 0);
        uint secondsInYear = 31536000;
        require(icoFinishedDate + secondsInYear * 2 < now);
        assert(token.transfer(team, teamReward));
        teamReward = 0;
    }
}