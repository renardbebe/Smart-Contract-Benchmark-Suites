 

pragma solidity ^0.4.23;
 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}


contract BatchTransferWallet is Ownable {
    using SafeMath for uint256;

     
    function batchTransferFrom(address _tokenAddress, address[] _investors, uint256[] _tokenAmounts) public {
        ERC20BasicInterface token = ERC20BasicInterface(_tokenAddress);
        require(_investors.length == _tokenAmounts.length && _investors.length != 0);

        for (uint i = 0; i < _investors.length; i++) {
            require(_tokenAmounts[i] > 0 && _investors[i] != 0x0);
            require(token.transferFrom(msg.sender,_investors[i], _tokenAmounts[i]));
        }
    }

     
    function balanceOfContract(address _tokenAddress,address _address) public view returns (uint) {
        ERC20BasicInterface token = ERC20BasicInterface(_tokenAddress);
        return token.balanceOf(_address);
    }
    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }
     
     
    event Sent(address from, address to, uint amount);
    function transferMulti(address[] receivers, uint256[] amounts) payable {
        require(msg.value != 0 && msg.value >= getTotalSendingAmount(amounts));
        for (uint256 j = 0; j < amounts.length; j++) {
            receivers[j].transfer(amounts[j]);
            emit Sent(msg.sender, receivers[j], amounts[j]);
        }
    }
     
        function withdraw(address _address) public onlyOwner {
            require(_address != address(0));
            _address.transfer(address(this).balance);
        }
}