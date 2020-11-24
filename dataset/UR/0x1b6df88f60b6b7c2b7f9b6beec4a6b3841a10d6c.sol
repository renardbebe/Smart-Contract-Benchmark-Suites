 

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


contract Primacorp is Ownable {

    mapping (address => uint256) public allowance;
    uint256 public contributionInWei;
    address _tokenAddress = 0x2A22e5cCA00a3D63308fa39f29202eB1b39eEf52;
    address _wallet = 0x269D55Ef8AcFdf0B83cCd08278ab440f87f9E9D8;

    constructor(uint256 _contributionInWei) public {
        contributionInWei = _contributionInWei;
    }

    function() public payable {
        require(allowance[msg.sender] > 0);
        require(msg.value >= contributionInWei);
        ERC20(_tokenAddress).transfer(msg.sender, allowance[msg.sender]);
        allowance[msg.sender] = 0;
        _wallet.transfer(msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        ERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function changeAllowance(address _address, uint256 value) external onlyOwner {
        allowance[_address] = value;
    }

    function setWalletAddress(address newWalletAddress) external onlyOwner {
        _wallet = newWalletAddress;
    }

    function setContributionInWei(uint256 _valueInWei) external onlyOwner {
        contributionInWei = _valueInWei;
    }

}