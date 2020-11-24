 

pragma solidity ^0.4.15;

contract ERC20 {
  event Transfer(address indexed from, address indexed to, uint value);
  function balanceOf( address who ) public constant returns (uint value);
  function transfer( address to, uint value) public returns (bool ok);
  function approve( address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TerraformReserve is Owned {

   
  mapping (address => uint256) public lockedBalance;
  
   
  uint public totalLocked;
  
   
  ERC20 public manaToken;
  
   
  address public landClaim;
  
   
  bool public acceptingDeposits;

  event LockedBalance(address user, uint mana);
  event LandClaimContractSet(address target);
  event LandClaimExecuted(address user, uint value, bytes data);
  event AcceptingDepositsChanged(bool _acceptingDeposits);

  function TerraformReserve(address _token) {
    require(_token != 0);
    manaToken = ERC20(_token);
    acceptingDeposits = true;
  }

   
  function lockMana(address _from, uint256 mana) public {
    require(acceptingDeposits);
    require(mana >= 1000 * 1e18);
    require(manaToken.transferFrom(_from, this, mana));

    lockedBalance[_from] += mana; 
    totalLocked += mana;
    LockedBalance(_from, mana);
  }
  
   
  function changeContractState(bool _acceptingDeposits) public onlyOwner {
    acceptingDeposits = _acceptingDeposits;
    AcceptingDepositsChanged(acceptingDeposits);
  }
  
   
  function setTargetContract(address target) public onlyOwner {
    landClaim = target;
    manaToken.approve(landClaim, totalLocked);
    LandClaimContractSet(target);
  }

   
  function () public payable {
    revert();
  }
}