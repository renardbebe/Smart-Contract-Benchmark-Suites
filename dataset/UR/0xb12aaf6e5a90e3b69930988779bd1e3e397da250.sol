 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract TokenReceiver {
     
    function tokenFallback(address _sender, uint256 _value, bytes _data) external returns (bool);
}

 
contract Timestamped {
     
    function _currentTime() internal view returns(uint256) {
         
        return block.timestamp;
    }
}





 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}










 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}






 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}






 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}




 
contract FlipNpikToken is Timestamped, StandardToken, DetailedERC20, HasNoEther {
    using SafeMath for uint256;

     
    address public mainWallet;
     
    address public financeWallet;

     
    uint256 public reserveSize = uint256(500000000).mul(10 ** 18);
     
    mapping (address => bool) public reserveHolders;
     
    uint256 public totalUnlocked = 0;

     
    uint256 public mintSize = uint256(575000000).mul(10 ** 18);
     
    uint256 public mintStart;
     
    uint256 public totalMinted = 0;    

     
    struct MintStage {
        uint256 start;
        uint256 volume;       
    }

     
    MintStage[] public stages;

     
    event MintReserveLog(uint256 _amount);

     
    event UnlockReserveLog(uint256 _amount);

     
    constructor (uint256 _mintStart, address _mainWallet, address _financeWallet, address _owner)
        DetailedERC20("FlipNpik", "FNP", 18) public {

        require(_mainWallet != address(0), "Main address is invalid.");
        mainWallet = _mainWallet;       

        require(_financeWallet != address(0), "Finance address is invalid.");
        financeWallet = _financeWallet;        

        require(_owner != address(0), "Owner address is invalid.");
        owner = _owner;

        _setStages(_mintStart);
        _setReserveHolders();

         
        _mint(uint256(425000000).mul(10 ** 18));
    }       

     
    function mintReserve() public onlyOwner {
        require(mintStart < _currentTime(), "Minting has not been allowed yet.");
        require(totalMinted < mintSize, "No tokens are available for minting.");
        
         
        MintStage memory currentStage = _getCurrentStage();
         
        uint256 mintAmount = currentStage.volume.sub(totalMinted);

        if (mintAmount > 0 && _mint(mintAmount)) {
            emit MintReserveLog(mintAmount);
            totalMinted = totalMinted.add(mintAmount);
        }
    }

     
    function unlockReserve() public {
        require(msg.sender == owner || msg.sender == financeWallet, "Operation is not allowed for the wallet.");
        require(totalUnlocked < reserveSize, "Reserve has been unlocked.");        
        
         
        reserveHolders[msg.sender] = true;

        if (_isReserveUnlocked() && _mint(reserveSize)) {
            emit UnlockReserveLog(reserveSize);
            totalUnlocked = totalUnlocked.add(reserveSize);
        }        
    }

     
    function approveAndCall(address _to, uint256 _value, bytes _data) public returns(bool) {
        require(super.approve(_to, _value), "Approve operation failed.");

         
        if (isContract(_to)) {
            TokenReceiver receiver = TokenReceiver(_to);
            return receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    } 

     
    function _mint(uint256 _amount) private returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[mainWallet] = balances[mainWallet].add(_amount);

        emit Transfer(address(0), mainWallet, _amount);
        return true;
    }

     
    function _setStages(uint256 _mintStart) private {
        require(_mintStart >= _currentTime(), "Mint start date is invalid.");
        mintStart = _mintStart;

        stages.push(MintStage(_mintStart, uint256(200000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(365 days), uint256(325000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(2 * 365 days), uint256(450000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(3 * 365 days), uint256(575000000).mul(10 ** 18)));
    }

     
    function _setReserveHolders() private {
        reserveHolders[mainWallet] = false;
        reserveHolders[financeWallet] = false;
    }

     
    function _getCurrentStage() private view returns (MintStage) {
        uint256 index = 0;
        uint256 time = _currentTime();        

        MintStage memory result;

        while (index < stages.length) {
            MintStage memory activeStage = stages[index];

            if (time >= activeStage.start) {
                result = activeStage;
            }

            index++;             
        }

        return result;
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
         
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

     
    function _isReserveUnlocked() private view returns(bool) {
        return reserveHolders[owner] == reserveHolders[financeWallet] && reserveHolders[owner];
    }
}