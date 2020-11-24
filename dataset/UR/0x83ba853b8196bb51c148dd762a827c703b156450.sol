 

 

pragma solidity ^0.4.21;


 

contract Ownable {
    address public owner;

    function Ownable()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

contract Members is Ownable {

  mapping(address => bool) public members;  

  modifier onlyMembers() {
    require(isValidMember(msg.sender));
    _;
  }

   
  function isValidMember(address _member) public view returns(bool) {
    return members[_member];
  }

   
  function addMember(address _member) public onlyOwner {
    members[_member] = true;
  }

   
  function removeMember(address _member) public onlyOwner {
    delete members[_member];
  }
}

contract IFeeWallet {

  function getFee(
    uint amount) public view returns(uint);

  function collect(
    address _affiliate) public payable;
}

contract FeeWallet is IFeeWallet, Ownable, Members {

  address public serviceAccount;  
  uint public servicePercentage;  
  uint public affiliatePercentage;  

  mapping (address => uint) public pendingWithdrawals;  

  function FeeWallet(
    address _serviceAccount,
    uint _servicePercentage,
    uint _affiliatePercentage) public
  {
    serviceAccount = _serviceAccount;
    servicePercentage = _servicePercentage;
    affiliatePercentage = _affiliatePercentage;
  }

   
  function changeServiceAccount(address _serviceAccount) public onlyOwner {
    serviceAccount = _serviceAccount;
  }

   
  function changeServicePercentage(uint _servicePercentage) public onlyOwner {
    servicePercentage = _servicePercentage;
  }

   
  function changeAffiliatePercentage(uint _affiliatePercentage) public onlyOwner {
    affiliatePercentage = _affiliatePercentage;
  }

   
  function getFee(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, servicePercentage) / (1 ether);
  }

   
  function getAffiliateAmount(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, affiliatePercentage) / (1 ether);
  }

   
  function collect(
    address _affiliate) public payable onlyMembers
  {
    if(_affiliate == address(0))
      pendingWithdrawals[serviceAccount] += msg.value;
    else {
      uint affiliateAmount = getAffiliateAmount(msg.value);
      pendingWithdrawals[_affiliate] += affiliateAmount;
      pendingWithdrawals[serviceAccount] += SafeMath.safeSub(msg.value, affiliateAmount);
    }
  }

   
  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}