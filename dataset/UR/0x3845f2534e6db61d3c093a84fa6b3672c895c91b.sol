 

pragma solidity ^0.4.21;

 

 
contract MasterDepositInterface {
    address public coldWallet1;
    address public coldWallet2;
    uint public percentage;
    function fireDepositToChildEvent(uint _amount) public;
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

 

 
contract ChildDeposit {
    
     
    using SafeMath for uint;
    
     
     
    address masterAddress;

    function ChildDeposit() public {
        masterAddress = msg.sender;
         
    }

     
    function() public payable {

        MasterDepositInterface master = MasterDepositInterface(masterAddress);
         
        master.fireDepositToChildEvent(msg.value);

         
         
        uint coldWallet1Share = msg.value.mul(master.percentage()).div(100);
        
         
        master.coldWallet1().transfer(coldWallet1Share);
        master.coldWallet2().transfer(msg.value.sub(coldWallet1Share));
    }

     
    function withdraw(address _tokenAddress, uint _value, address _destination) public onlyMaster {
        ERC20(_tokenAddress).transfer(_destination, _value);
    }

    modifier onlyMaster() {
        require(msg.sender == address(masterAddress));
        _;
    }
    
}

 

 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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

 

 
contract MasterDeposit is MasterDepositInterface, Claimable, ReentrancyGuard {
    
     
    using SafeMath for uint;

     
    mapping (address => bool) public childDeposits;

     
    address public depositCreator;

     
    event CreatedDepositEvent (
    address indexed _depositAddress
    );
    
     
    event DepositToChildEvent(
    address indexed _depositAddress, 
    uint _amount
    );


     
    function MasterDeposit(address _wallet1, address _wallet2, uint _percentage) onlyValidPercentage(_percentage) public {
        require(_wallet1 != address(0));
        require(_wallet2 != address(0));
        percentage = _percentage;
        coldWallet1 = _wallet1;
        coldWallet2 = _wallet2;
    }

     
    function createChildDeposits(uint _count) public onlyDepositCreatorOrMaster {
        for (uint i = 0; i < _count; i++) {
            ChildDeposit childDeposit = new ChildDeposit();
            childDeposits[address(childDeposit)] = true;
            emit CreatedDepositEvent(address(childDeposit));    
        }
    }

     
    function setDepositCreator(address _depositCreator) public onlyOwner {
        require(_depositCreator != address(0));
        depositCreator = _depositCreator;
    }

     
    function setColdWallet1SplitPercentage(uint _percentage) public onlyOwner onlyValidPercentage(_percentage) {
        percentage = _percentage;
    }

     
    function fireDepositToChildEvent(uint _amount) public onlyChildContract {
        emit DepositToChildEvent(msg.sender, _amount);
    }

     
    function setColdWallet1(address _coldWallet1) public onlyOwner {
        require(_coldWallet1 != address(0));
        coldWallet1 = _coldWallet1;
    }

     
    function setColdWallet2(address _coldWallet2) public onlyOwner {
        require(_coldWallet2 != address(0));
        coldWallet2 = _coldWallet2;
    }

     
    function transferTokens(address[] _deposits, address _tokenContractAddress) public onlyOwner nonReentrant {
        for (uint i = 0; i < _deposits.length; i++) {
            address deposit = _deposits[i];
            uint erc20Balance = ERC20(_tokenContractAddress).balanceOf(deposit);

             
            if (erc20Balance == 0) {
                continue;
            }
            
             
             
            uint coldWallet1Share = erc20Balance.mul(percentage).div(100);
            uint coldWallet2Share = erc20Balance.sub(coldWallet1Share); 
            ChildDeposit(deposit).withdraw(_tokenContractAddress,coldWallet1Share, coldWallet1);
            ChildDeposit(deposit).withdraw(_tokenContractAddress,coldWallet2Share, coldWallet2);
        }
    }

    modifier onlyChildContract() {
        require(childDeposits[msg.sender]);
        _;
    }

    modifier onlyDepositCreatorOrMaster() {
        require(msg.sender == owner || msg.sender == depositCreator);
        _;
    }

    modifier onlyValidPercentage(uint _percentage) {
        require(_percentage >=0 && _percentage <= 100);
        _;
    }

}