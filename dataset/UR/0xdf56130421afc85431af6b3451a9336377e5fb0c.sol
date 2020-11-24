 

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
    mapping (address => uint256) public allowance;
    address _tokenAddress = 0x2A22e5cCA00a3D63308fa39f29202eB1b39eEf52;

    function() public payable {
        require(allowance[msg.sender] > 0);
        ERC20(_tokenAddress).transfer(msg.sender, allowance[msg.sender]);
        allowance[msg.sender] = 0;
    }

    function withdraw(uint256 amount) external onlyOwner {
        ERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function changeAllowances(address[] addresses, uint256[] values) external onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < addresses.length) {
            allowance[addresses[i]] = values[i];
            i += 1;
        }
        return(i);
    }
}