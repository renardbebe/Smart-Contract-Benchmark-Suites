 

pragma solidity ^0.5.1;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner external {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdrop is Ownable {

    function multisend(address _tokenAddr, address[] calldata _to, uint256[] calldata _value) external onlyOwner returns (bool _success) {
        assert(_to.length == _value.length);
         
        IERC20 token = IERC20(_tokenAddr);
        for (uint8 i = 0; i < _to.length; i++) {
            require(token.transfer(_to[i], _value[i]));
        }
        return true;
    }
    
    function refund(address _tokenAddr) external onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        uint256 _balance = token.balanceOf(address(this));
        require(_balance > 0);
        require(token.transfer(msg.sender, _balance));
    }
    
    function() external {
        revert();
    }
}