 

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
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}

contract BatchTransferWallet is Ownable {
    using SafeMath for uint256;
    ERC20BasicInterface public token;

    event LogWithdrawal(address indexed receiver, uint amount);

     
    constructor(address _tokenAddress) public {
        token = ERC20BasicInterface(_tokenAddress);
    }

     
    function batchTransfer(address[] _investors, uint256[] _tokenAmounts) public onlyOwner {
        if (_investors.length != _tokenAmounts.length || _investors.length == 0) {
            revert();
        }

        uint decimalsForCalc = 10 ** uint256(token.decimals());

        for (uint i = 0; i < _investors.length; i++) {
            require(_tokenAmounts[i] > 0 && _investors[i] != 0x0);
            _tokenAmounts[i] = _tokenAmounts[i].mul(decimalsForCalc);
            require(token.transfer(_investors[i], _tokenAmounts[i]));
        }
    }

     
    function withdraw(address _address) public onlyOwner {
        uint tokenBalanceOfContract = token.balanceOf(this);

        require(_address != address(0) && tokenBalanceOfContract > 0);
        require(token.transfer(_address, tokenBalanceOfContract));
        emit LogWithdrawal(_address, tokenBalanceOfContract);
    }

     
    function balanceOfContract() public view returns (uint) {
        return token.balanceOf(this);
    }
}