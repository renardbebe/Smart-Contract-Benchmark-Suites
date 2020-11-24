 

pragma solidity ^0.4.21;

 

 
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

 

contract Withdrawals is Claimable {
    
     
    address public withdrawCreator;

     
    event AmountWithdrawEvent(
    address _destination, 
    uint _amount, 
    address _tokenAddress 
    );

     
    function() payable public {

    }

     
    function setWithdrawCreator(address _withdrawCreator) public onlyOwner {
        withdrawCreator = _withdrawCreator;
    }

     
    function withdraw(address[] _destinations, uint[] _amounts, address[] _tokenAddresses) public onlyOwnerOrWithdrawCreator {
        require(_destinations.length == _amounts.length && _amounts.length == _tokenAddresses.length);
         
        for (uint i = 0; i < _destinations.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            uint amount = _amounts[i];
            address destination = _destinations[i];
             
            if (tokenAddress == address(0)) {
                if (this.balance < amount) {
                    continue;
                }
                if (!destination.call.gas(70000).value(amount)()) {
                    continue;
                }
                
            }else {
             
                if (ERC20(tokenAddress).balanceOf(this) < amount) {
                    continue;
                }
                ERC20(tokenAddress).transfer(destination, amount);
            }
             
            emit AmountWithdrawEvent(destination, amount, tokenAddress);                
        }

    }

    modifier onlyOwnerOrWithdrawCreator() {
        require(msg.sender == withdrawCreator || msg.sender == owner);
        _;
    }

}