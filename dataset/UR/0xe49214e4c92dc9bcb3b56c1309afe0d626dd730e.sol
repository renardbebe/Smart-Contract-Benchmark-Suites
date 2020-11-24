 

pragma solidity ^0.4.23;

 

 
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
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
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
}

 

contract ERC223 is ERC20 {
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    function transferFrom(address from, address to, uint256 value, bytes data) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
}

 

 
 
contract ERC223Receiver { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 

 
contract ERC223Token is ERC223, StandardToken, Ownable {
    using SafeMath for uint256;

     
    bool public erc223Activated;
     
     
    mapping (address => bool) public supportedContracts;
     
     
    mapping (address => mapping (address => bool)) public userAcknowledgedContracts;

    function setErc223Activated(bool _activated) external onlyOwner {
        erc223Activated = _activated;
    }

    function setSupportedContract(address _address, bool _supported) external onlyOwner {
        supportedContracts[_address] = _supported;
    }

    function setUserAcknowledgedContract(address _address, bool _acknowledged) external {
        userAcknowledgedContracts[msg.sender][_address] = _acknowledged;
    }

     
    function isContract(address _address) internal returns (bool) {
        uint256 codeLength;
        assembly {
             
            codeLength := extcodesize(_address)
        }
        return codeLength > 0;
    }

     
    function invokeTokenReceiver(address _from, address _to, uint256 _value, bytes _data) internal {
        ERC223Receiver receiver = ERC223Receiver(_to);
        receiver.tokenFallback(_from, _value, _data);
        emit Transfer(_from, _to, _value, _data);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory emptyData;
        return transfer(_to, _value, emptyData);
    }

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        bool status = super.transfer(_to, _value);

         
        if (erc223Activated 
            && isContract(_to)
            && supportedContracts[_to] == false 
            && userAcknowledgedContracts[msg.sender][_to] == false
            && status == true) {
            invokeTokenReceiver(msg.sender, _to, _value, _data);
        }
        return status;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        bytes memory emptyData;
        return transferFrom(_from, _to, _value, emptyData);
    }

     
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
        bool status = super.transferFrom(_from, _to, _value);

        if (erc223Activated 
            && isContract(_to)
            && supportedContracts[_to] == false 
            && userAcknowledgedContracts[msg.sender][_to] == false
            && status == true) {
            invokeTokenReceiver(_from, _to, _value, _data);
        }
        return status;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return super.approve(_spender, _value);
    }
}

 

 

contract PausableERC223Token is ERC223Token, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value, _data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value, _data);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }
}

 

 

contract SynchroCoin is PausableERC223Token, Claimable {
    string public constant name = "SynchroCoin";
    string public constant symbol = "SYC";
    uint8 public constant decimals = 18;
    MigrationAgent public migrationAgent;

    function SynchroCoin(address _legacySycAddress, uint256 _timelockReleaseTime) public {        
        migrationAgent = new MigrationAgent(_legacySycAddress, this, _timelockReleaseTime);
        migrationAgent.transferOwnership(msg.sender);

        ERC20 legacySycContract = ERC20(_legacySycAddress);
        totalSupply_ = legacySycContract.totalSupply();
        balances[migrationAgent] = balances[migrationAgent].add(totalSupply_);

        pause();
    }
}

 

 
contract MigrationAgent is Ownable {
    using SafeMath for uint256;

    ERC20 public legacySycContract;     
    ERC20 public sycContract;        
    uint256 public targetSupply;     
    uint256 public migratedSupply;   

    mapping (address => bool) public migrated;   

    uint256 public timelockReleaseTime;  
    TokenTimelock public tokenTimelock;  

    event Migrate(address indexed holder, uint256 balance);

    function MigrationAgent(address _legacySycAddress, address _sycAddress, uint256 _timelockReleaseTime) public {
        require(_legacySycAddress != address(0));
        require(_sycAddress != address(0));

        legacySycContract = ERC20(_legacySycAddress);
        targetSupply = legacySycContract.totalSupply();
        timelockReleaseTime = _timelockReleaseTime;
        sycContract = ERC20(_sycAddress);
    }

     
    function migrateVault(address _legacyVaultAddress) onlyOwner external { 
        require(_legacyVaultAddress != address(0));
        require(!migrated[_legacyVaultAddress]);
        require(tokenTimelock == address(0));

         
        migrated[_legacyVaultAddress] = true;        
        uint256 timelockAmount = legacySycContract.balanceOf(_legacyVaultAddress);
        tokenTimelock = new TokenTimelock(sycContract, msg.sender, timelockReleaseTime);
        sycContract.transfer(tokenTimelock, timelockAmount);
        migratedSupply = migratedSupply.add(timelockAmount);
        emit Migrate(_legacyVaultAddress, timelockAmount);
    }

     
    function migrateBalances(address[] _tokenHolders) onlyOwner external {
        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            migrateBalance(_tokenHolders[i]);
        }
    }

     
    function migrateBalance(address _tokenHolder) onlyOwner public returns (bool) {
        if (migrated[_tokenHolder]) {
            return false;    
        }

        uint256 balance = legacySycContract.balanceOf(_tokenHolder);
        if (balance == 0) {
            return false;    
        }

         
        migrated[_tokenHolder] = true;
        sycContract.transfer(_tokenHolder, balance);
        migratedSupply = migratedSupply.add(balance);
        emit Migrate(_tokenHolder, balance);
        return true;
    }

     
    function kill() onlyOwner public {
        uint256 balance = sycContract.balanceOf(this);
        sycContract.transfer(owner, balance);
        selfdestruct(owner);
    }
}