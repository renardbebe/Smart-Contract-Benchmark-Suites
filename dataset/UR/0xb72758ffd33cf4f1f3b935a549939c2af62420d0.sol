 

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

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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

contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract Distribution is CanReclaimToken, Claimable, Whitelist {

    using SafeERC20 for ERC20Basic;

    event Distributed(address beneficiary, uint256 amount);

    address[] public receivers;
     
    uint256 public amount = 0;
    ERC20Basic public token;

    constructor(ERC20Basic _token) public {
        token = _token;
    }

    function setReceivers(address[] _receivers, uint256 _amount) onlyWhitelisted external {
         
        require(_receivers.length <= 80);
        require(_amount > 0);

        receivers = _receivers;
        amount = _amount;
    }

    function distribute() onlyWhitelisted external {
        require(receivers.length > 0);
        require(amount > 0);
        for (uint256 i = 0; i < receivers.length; ++i) {
            address beneficiary = receivers[i];
            token.safeTransfer(beneficiary, amount);
            emit Distributed(beneficiary, amount);
        }
         
        amount = 0;
        delete receivers;
    }

    function batchDistribute(
        address[] batchReceivers,
        uint256 batchAmount
    ) onlyWhitelisted external
    {
        require(batchReceivers.length > 0);
        require(batchAmount > 0);
        for (uint256 i = 0; i < batchReceivers.length; ++i) {
            address beneficiary = batchReceivers[i];
            token.safeTransfer(beneficiary, batchAmount);
            emit Distributed(beneficiary, batchAmount);
        }
    }
    
    function batchDistributeWithAmount(
        address[] batchReceivers,
        uint256[] batchAmounts
    ) onlyWhitelisted external
    {
        require(batchReceivers.length > 0);
        require(batchAmounts.length == batchReceivers.length);
        for (uint256 i = 0; i < batchReceivers.length; ++i) {
            address beneficiary = batchReceivers[i];
            uint256 v = batchAmounts[i];
            token.safeTransfer(beneficiary, v);
            emit Distributed(beneficiary, v);
        }
    }
    

    function finished() public view returns (bool) {
        return amount == 0;
    }
}