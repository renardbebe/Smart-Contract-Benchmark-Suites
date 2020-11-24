 

pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
}

contract LockAccount is Ownable{
    
    mapping (address => bool) public lockAccounts;
    event LockFunds(address target, bool lock);
    
    constructor() public{
        
    }
    modifier onlyUnLock{
        require(!lockAccounts[msg.sender]);
        _;
    }
    
    function lockAccounts(address target, bool lock) public onlyOwner {
      lockAccounts[target] = lock;
      emit LockFunds(target, lock);
    }
    
    
}

contract LockAccountTime {
    address lockaccount = 0x8ca132A61fd59BcD12700B3D1848075c12bBB359;
    
    uint start = 1557237300;
    
    constructor() public{
        
    }
    
    modifier onlyUnlockTime{
        if (now < start + (2*365+1) * 1 days){
            require(msg.sender !=lockaccount);
        }
       _;
    }
    
    
}

contract LockAccountAllTime {
    address destroyaccount = 0x7A052e1e18948FFBc20aB3d91f61273ad159fa0e;
    
    constructor() public{
        
    }
    
    modifier onlyUnlockAllTime{
        require(msg.sender !=destroyaccount);
        _;
    }
    
    
}


contract BasicToken is ERC20Basic, Ownable ,LockAccount,LockAccountTime,LockAccountAllTime {

    using SafeMath for uint256;
    mapping(address => uint256) balances;

    bool public transfersEnabledFlag = true;


    modifier transfersEnabled() {
        require(transfersEnabledFlag);
        _;
    }

    function enableTransfers() public onlyOwner {
        transfersEnabledFlag = true;
    }
    
    function disableTransfers() public onlyOwner {
        transfersEnabledFlag = false;
    }


    function transfer(address _to, uint256 _value) transfersEnabled onlyUnLock onlyUnlockTime onlyUnlockAllTime public returns (bool) {
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;



    function transferFrom(address _from, address _to, uint256 _value) transfersEnabled onlyUnLock onlyUnlockTime onlyUnlockAllTime public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) transfersEnabled onlyUnLock onlyUnlockTime onlyUnlockAllTime public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) transfersEnabled onlyUnLock onlyUnlockTime onlyUnlockAllTime public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) transfersEnabled onlyUnLock onlyUnlockTime onlyUnlockAllTime public  returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    mapping(address => bool) public minters;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    modifier onlyMinters() {
        require(minters[msg.sender] || msg.sender == owner);
        _;
    }
    function addMinter(address _addr) public onlyOwner {
        minters[_addr] = true;
    }

    function deleteMinter(address _addr) public onlyOwner {
        delete minters[_addr];
    }


    function mint(address _to, uint256 _amount) onlyMinters canMint public returns (bool) {
        require(_to != address(0));
        totalSupply = totalSupply.add(_amount);
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



contract CappedToken is MintableToken {

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }


    function mint(address _to, uint256 _amount) onlyMinters canMint public returns (bool) {
        require(totalSupply.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }

}


contract TokenParam is CappedToken {
    string public name;

    string public symbol;

    uint256 public decimals;

    constructor(string _name, string _symbol, uint256 _decimals, uint256 _capIntPart) public CappedToken(_capIntPart * 10 ** _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

}

contract VIASToken is TokenParam {

    constructor() public TokenParam("VIAS", "VIAS", 18, 770000000) {
    }

}