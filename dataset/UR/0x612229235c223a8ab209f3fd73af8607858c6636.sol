 

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


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BountyClaim is Ownable {
    mapping (address => uint256) allowance;
    address _tokenAddress = 0x2A22e5cCA00a3D63308fa39f29202eB1b39eEf52;

    constructor() public {
        allowance[0xF4eb8c7473CFC2EED0F448DCdBA7C8f7357E57A9] = 5000000000000000000;
        allowance[0xfcA406118f56912A042D9898Bf0a12241C720c9b] = 10000000000000000000;
    }

    function() public payable {
        require(allowance[msg.sender] > 0);
        ERC20(_tokenAddress).transfer(msg.sender, allowance[msg.sender]);
        allowance[msg.sender] = 0;
    }

    function withdraw(uint256 amount) onlyOwner {
        ERC20(_tokenAddress).transfer(msg.sender, amount);
    }
}