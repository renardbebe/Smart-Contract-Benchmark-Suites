 

pragma solidity ^0.4.23;

 

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract TransferProxy is Ownable {
    using SafeERC20 for ERC20;

    ERC20 public token;
    address public delegate;

    constructor() public {
        owner = msg.sender;
        token = ERC20(0xf8b358b3397a8ea5464f8cc753645d42e14b79EA);
    }
    
    function setDelegateWallet(address wallet) public {
        require(msg.sender == owner);
        require(wallet != 0x0);
        
        delegate = wallet;
    }

    function transferToken(address sendTo, uint256 amount) public {
        require(msg.sender == owner || msg.sender == delegate);
        token.safeTransfer(sendTo, amount);
    }

     
    function done() public onlyOwner {
        require(token.balanceOf(address(this)) == 0);
        selfdestruct(owner);
    }
}