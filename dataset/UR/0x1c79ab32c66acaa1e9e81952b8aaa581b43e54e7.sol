 

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

 
 
 
 
 
 
 
 
 

 
 

 
 
 
 
 
 
 






contract StarTokenInterface is MintableToken {
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function openTransfer() public returns (bool);
    function toggleTransferFor(address _for) public returns (bool);
    function extraMint() public returns (bool);

    event TransferAllowed();
    event TransferAllowanceFor(address indexed who, bool indexed state);


}

 
 
 
 
 
 
 
 
 

 
 

 
 
 
 
 
 
 







contract TeamToken is StarTokenInterface {
    using SafeMath for uint256;
    
     
    string public constant name = "TEAM";
    string public constant symbol = "TEAM";
    uint public constant decimals = 4;

     
    uint256 public constant MAXSOLD_SUPPLY = 450000000000;
    uint256 public constant HARDCAPPED_SUPPLY = 750000000000;

    uint256 public investorSupply = 0;
    uint256 public extraSupply = 0;
    uint256 public freeToExtraMinting = 0;

    uint256 public constant DISTRIBUTION_INVESTORS = 60;
    uint256 public constant DISTRIBUTION_TEAM      = 20;
    uint256 public constant DISTRIBUTION_COMMUNITY = 20;

    address public teamTokensHolder;
    address public communityTokensHolder;

     
    bool public transferAllowed = false;
    mapping (address=>bool) public specialAllowed;

     
     
     

     
    event ChangeCommunityHolder(address indexed from, address indexed to);
    event ChangeTeamHolder(address indexed from, address indexed to);

     
    modifier allowTransfer() {
        require(transferAllowed || specialAllowed[msg.sender]);
        _;
    }

    function TeamToken() public {
      teamTokensHolder = msg.sender;
      communityTokensHolder = msg.sender;

      ChangeTeamHolder(0x0, teamTokensHolder);
      ChangeCommunityHolder(0x0, communityTokensHolder);
    }

     
    function setTeamTokensHolder(address _tokenHolder) onlyOwner public returns (bool) {
      require(_tokenHolder != 0);
      address temporaryEventAddress = teamTokensHolder;
      teamTokensHolder = _tokenHolder;
      ChangeTeamHolder(temporaryEventAddress, teamTokensHolder);
      return true;
    }

     
    function setCommunityTokensHolder(address _tokenHolder) onlyOwner public returns (bool) {
      require(_tokenHolder != 0);
      address temporaryEventAddress = communityTokensHolder;
      communityTokensHolder = _tokenHolder;
      ChangeCommunityHolder(temporaryEventAddress, communityTokensHolder);
      return true;
    }

     
    function () payable public {
        require(false);
    }

     
    function transfer(address _to, uint256 _value) allowTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }

    
     
    function transferFrom(address _from, address _to, uint256 _value) allowTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function openTransfer() onlyOwner public returns (bool) {
        require(!transferAllowed);
        transferAllowed = true;
        TransferAllowed();
        return true;
    }

     
    function toggleTransferFor(address _for) onlyOwner public returns (bool) {
        specialAllowed[_for] = !specialAllowed[_for];
        TransferAllowanceFor(_for, specialAllowed[_for]);
        return specialAllowed[_for];
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_amount > 0);
        totalSupply_ = totalSupply_.add(_amount);
        investorSupply = investorSupply.add(_amount);
        freeToExtraMinting = freeToExtraMinting.add(_amount);

         
        assert(investorSupply <= MAXSOLD_SUPPLY);
        assert(totalSupply_ <= HARDCAPPED_SUPPLY);

        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(this), _to, _amount);
        return true;
    }


     
    function extraMint() onlyOwner canMint public returns (bool) {
      require(freeToExtraMinting > 0);

      uint256 onePercent = freeToExtraMinting / DISTRIBUTION_INVESTORS;
      uint256 teamPart = onePercent * DISTRIBUTION_TEAM;
      uint256 communityPart = onePercent * DISTRIBUTION_COMMUNITY;
      uint256 extraTokens = teamPart.add(communityPart);

      totalSupply_ = totalSupply_.add(extraTokens);
      extraSupply = extraSupply.add(extraTokens);

      uint256 leftToNextMinting = freeToExtraMinting % DISTRIBUTION_INVESTORS;
      freeToExtraMinting = leftToNextMinting;

      assert(totalSupply_ <= HARDCAPPED_SUPPLY);
      assert(extraSupply <= HARDCAPPED_SUPPLY.sub(MAXSOLD_SUPPLY));

      balances[teamTokensHolder] = balances[teamTokensHolder].add(teamPart);
      balances[communityTokensHolder] = balances[communityTokensHolder].add(communityPart);

      Mint(teamTokensHolder, teamPart);
      Transfer(address(this), teamTokensHolder, teamPart);
      Mint(communityTokensHolder, communityPart);
      Transfer(address(this), communityTokensHolder, communityPart);

      return true;
    }

     
    function increaseApproval (address _spender, uint _addedValue)  public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function finilize() onlyOwner public returns (bool) {
        require(mintingFinished);
        require(transferAllowed);

        owner = 0x0;
        return true;
    }
}