 

pragma solidity ^0.4.23;


 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract BatchTransfer is Ownable {
    using SafeMath for uint256;

    event Withdraw(address indexed receiver, address indexed token, uint amount);
    event TransferEther(address indexed sender, address indexed receiver, uint256 amount);

    modifier checkArrayArgument(address[] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length && _receivers.length != 0);
        _;
    }

    function batchTransferToken(address _token, address[] _receivers, uint256[] _tokenAmounts) public checkArrayArgument(_receivers, _tokenAmounts) {
        require(_token != address(0));

        ERC20 token = ERC20(_token);
        require(allowanceForContract(_token) >= getTotalSendingAmount(_tokenAmounts));

        for (uint i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0));
            require(token.transferFrom(msg.sender, _receivers[i], _tokenAmounts[i]));
        }
    }

    function batchTransferEther(address[] _receivers, uint[] _amounts) public payable checkArrayArgument(_receivers, _amounts) {
        require(msg.value != 0 && msg.value == getTotalSendingAmount(_amounts));

        for (uint i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0));
            _receivers[i].transfer(_amounts[i]);
            emit TransferEther(msg.sender, _receivers[i], _amounts[i]);
        }
    }

    function withdraw(address _receiver, address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        uint tokenBalanceOfContract = token.balanceOf(this);
        require(_receiver != address(0) && tokenBalanceOfContract > 0);
        require(token.transfer(_receiver, tokenBalanceOfContract));
        emit Withdraw(_receiver, _token, tokenBalanceOfContract);
    }

    function balanceOfContract(address _token) public view returns (uint) {
        ERC20 token = ERC20(_token);
        return token.balanceOf(this);
    }

    function allowanceForContract(address _token) public view returns (uint) {
        ERC20 token = ERC20(_token);
        return token.allowance(msg.sender, this);
    }

    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount = totalSendingAmount.add(_amounts[i]);
        }
    }
}