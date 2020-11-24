 

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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract Airdrop is Ownable {
    event Drop();

    ERC20Basic public token;

    constructor(address _token) public {
        require(_token != address(0));
        token = ERC20Basic(_token);
    }

    function airdrop(address[] _recipients, uint256 amountEach) external onlyOwner {
        for (uint i=0; i < _recipients.length; i++) {
            token.transfer(_recipients[i], amountEach);
        }
        emit Drop();
    }

    function withdrawRemaining(address _recipient) public onlyOwner {
        token.transfer(_recipient, token.balanceOf(this));
    }
}