 

pragma solidity ^0.4.23;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
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








 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract BntyControllerInterface {
    function destroyTokensInBntyTokenContract(address _owner, uint _amount) public returns (bool);
}




contract Bounty0xStaking is Ownable, Pausable {

    using SafeMath for uint256;

    address public Bounty0xToken;
    uint public lockTime;

    mapping (address => uint) public balances;
    mapping (uint => mapping (address => uint)) public stakes;  
    mapping (address => uint) public huntersLockDateTime;
    mapping (address => uint) public huntersLockAmount;
    
    
    event Deposit(address indexed depositor, uint amount, uint balance);
    event Withdraw(address indexed depositor, uint amount, uint balance);
    event Stake(uint indexed submissionId, address indexed hunter, uint amount, uint balance);
    event StakeReleased(uint indexed submissionId, address indexed from, address indexed to, uint amount);
    event Lock(address indexed hunter, uint amount, uint endDateTime);
    event Unlock(address indexed hunter, uint amount);


    constructor(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
        lockTime = 30 days;
    }
    

    function deposit(uint _amount) external whenNotPaused {
        require(_amount != 0);
         
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }
    
    function withdraw(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));

        emit Withdraw(msg.sender, _amount, balances[msg.sender]);
    }
    
    
    function lock(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(balances[msg.sender] >= _amount);
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], _amount);
        huntersLockDateTime[msg.sender] = SafeMath.add(now, lockTime);
        
        emit Lock(msg.sender, huntersLockAmount[msg.sender], huntersLockDateTime[msg.sender]);
    }
    
    function depositAndLock(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], _amount);
        huntersLockDateTime[msg.sender] = SafeMath.add(now, lockTime);
        
        emit Lock(msg.sender, huntersLockAmount[msg.sender], huntersLockDateTime[msg.sender]);
    }
    
    function unlock() external whenNotPaused {
        require(huntersLockDateTime[msg.sender] <= now);
        uint amountLocked = huntersLockAmount[msg.sender];
        require(amountLocked != 0);
        
        huntersLockAmount[msg.sender] = SafeMath.sub(huntersLockAmount[msg.sender], amountLocked);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], amountLocked);
        
        emit Unlock(msg.sender, amountLocked);
    }


    function stake(uint _submissionId, uint _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        stakes[_submissionId][msg.sender] = SafeMath.add(stakes[_submissionId][msg.sender], _amount);

        emit Stake(_submissionId, msg.sender, _amount, balances[msg.sender]);
    }

    function stakeToMany(uint[] _submissionIds, uint[] _amounts) external whenNotPaused {
        uint totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);

        for (uint i = 0; i < _submissionIds.length; i++) {
            stakes[_submissionIds[i]][msg.sender] = SafeMath.add(stakes[_submissionIds[i]][msg.sender], _amounts[i]);

            emit Stake(_submissionIds[i], msg.sender, _amounts[i], balances[msg.sender]);
        }
    }


    function releaseStake(uint _submissionId, address _from, address _to) external onlyOwner {
        require(stakes[_submissionId][_from] != 0);

        balances[_to] = SafeMath.add(balances[_to], stakes[_submissionId][_from]);
        emit StakeReleased(_submissionId, _from, _to, stakes[_submissionId][_from]);
        
        stakes[_submissionId][_from] = 0;
    }

    function releaseManyStakes(uint[] _submissionIds, address[] _from, address[] _to) external onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length);

        for (uint i = 0; i < _submissionIds.length; i++) {
            require(_from[i] != address(0));
            require(_to[i] != address(0));
            require(stakes[_submissionIds[i]][_from[i]] != 0);
            
            balances[_to[i]] = SafeMath.add(balances[_to[i]], stakes[_submissionIds[i]][_from[i]]);
            emit StakeReleased(_submissionIds[i], _from[i], _to[i], stakes[_submissionIds[i]][_from[i]]);
            
            stakes[_submissionIds[i]][_from[i]] = 0;
        }
    }
    

    function changeLockTime(uint _periodInSeconds) external onlyOwner {
        lockTime = _periodInSeconds;
    }
    
    
     

    address public bntyController;

    event Burn(uint indexed submissionId, address indexed from, uint amount);

    function changeBntyController(address _bntyController) external onlyOwner {
        bntyController = _bntyController;
    }


    function burnStake(uint _submissionId, address _from) external onlyOwner {
        require(stakes[_submissionId][_from] > 0);

        uint amountToBurn = stakes[_submissionId][_from];
        stakes[_submissionId][_from] = 0;

        require(BntyControllerInterface(bntyController).destroyTokensInBntyTokenContract(this, amountToBurn));
        emit Burn(_submissionId, _from, amountToBurn);
    }


     
    function emergentWithdraw() external onlyOwner {
        require(ERC20(Bounty0xToken).transfer(msg.sender, address(this).balance));
    }
    
}