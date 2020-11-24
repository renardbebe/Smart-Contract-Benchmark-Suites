 

pragma solidity ^0.4.21;

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

contract Autonomy is Ownable {
    address public congress;

    modifier onlyCongress() {
        require(msg.sender == congress);
        _;
    }

     
    function initialCongress(address _congress) onlyOwner public {
        require(_congress != address(0));
        congress = _congress;
    }

     
    function changeCongress(address _congress) onlyCongress public {
        require(_congress != address(0));
        congress = _congress;
    }
}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

         
        ownedContract.claimOwnership();

        return true;
    }

     
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

     
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
}

contract MintDRCT is OwnerContract, Autonomy {
    using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY_CAP = 1000000000E18;
    bool public capInitialized = false;

    address[] internal mainAccounts = [
        0xaD5CcBE3aaB42812aa05921F0513C509A4fb5b67,  
        0xBD37616a455f1054644c27CC9B348CE18D490D9b,  
        0x4D9c90Cc719B9bd445cea9234F0d90BaA79ad629,  
        0x21000ec96084D2203C978E38d781C84F497b0edE   
    ];

    uint8[] internal mainPercentages = [30, 40, 15, 15];

    mapping (address => uint) internal accountCaps;

    modifier afterCapInit() {
        require(capInitialized);
        _;
    }

     
    function initialCaps() onlyOwner public returns (bool) {
        for (uint i = 0; i < mainAccounts.length; i = i.add(1)) {
            accountCaps[mainAccounts[i]] = TOTAL_SUPPLY_CAP * mainPercentages[i] / 100;
        }

        capInitialized = true;

        return true;
    }

     
    function mintUnderCap(uint _ind, uint256 _value) onlyOwner afterCapInit public returns (bool) {
        require(_ind < mainAccounts.length);
        address accountAddr = mainAccounts[_ind];
        uint256 accountBalance = MintableToken(ownedContract).balanceOf(accountAddr);
        require(_value <= accountCaps[accountAddr].sub(accountBalance));

        return MintableToken(ownedContract).mint(accountAddr, _value);
    }

     
    function mintAll(uint256[] _values) onlyOwner afterCapInit public returns (bool) {
        require(_values.length == mainAccounts.length);

        bool res = true;
        for(uint i = 0; i < _values.length; i = i.add(1)) {
            res = mintUnderCap(i, _values[i]) && res;
        }

        return res;
    }

     
    function mintUptoCap() onlyOwner afterCapInit public returns (bool) {
        bool res = true;
        for(uint i = 0; i < mainAccounts.length; i = i.add(1)) {
            require(MintableToken(ownedContract).balanceOf(mainAccounts[i]) == 0);
            res = MintableToken(ownedContract).mint(mainAccounts[i], accountCaps[mainAccounts[i]]) && res;
        }

        require(res);
        return MintableToken(ownedContract).finishMinting();  
    }

     
    function raiseCap(uint _ind, uint256 _value) onlyCongress afterCapInit public returns (bool) {
        require(_ind < mainAccounts.length);
        require(_value > 0);

        accountCaps[mainAccounts[_ind]] = accountCaps[mainAccounts[_ind]].add(_value);
        return true;
    }

     
    function getMainAccount(uint _ind) public view returns (address) {
        require(_ind < mainAccounts.length);
        return mainAccounts[_ind];
    }

     
    function getAccountCap(uint _ind) public view returns (uint256) {
        require(_ind < mainAccounts.length);
        return accountCaps[mainAccounts[_ind]];
    }

     
    function setMainAccount(uint _ind, address _newAddr) onlyOwner public returns (bool) {
        require(_ind < mainAccounts.length);
        require(_newAddr != address(0));

        mainAccounts[_ind] = _newAddr;
        return true;
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