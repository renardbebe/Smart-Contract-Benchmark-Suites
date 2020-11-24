 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;



contract ManagerLock is Ownable {

    event Release(address from, uint256 value);
    event Unlock();
    event Lock();

     
    ERC20 public token;

     
    address public beneficiary;

     
    bool public locked = true;

    constructor(ERC20 _token, address _owner, address _beneficiary)
    public {
        token = _token;
        beneficiary = _beneficiary;
        owner = _owner;
    }

    modifier notLocked() {
        require(locked == false);
        _;
    }

     
    function release() external {
        uint256 balance = token.balanceOf(address(this));
        partialRelease(balance);
    }

     
    function partialRelease(uint256 _amount) notLocked public {
         
        require(msg.sender == beneficiary);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount);
        require(_amount > 0);

        require(token.transfer(beneficiary, _amount));
        emit Release(beneficiary, _amount);
    }

    function unLock() onlyOwner public {
        locked = false;
        emit Unlock();
    }

    function lock() onlyOwner public {
        locked = true;
        emit Lock();
    }
}