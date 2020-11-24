 

pragma solidity ^0.4.24;

 

 
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

contract Destroyable is Ownable{
     
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address who) view external returns (uint256);
}

contract MTCMultiTransfer is Ownable, Destroyable {
    using SafeMath for uint256;

    event Dropped(uint256 transfers, uint256 amount);

    Token public token;
    uint256 public totalDropped;

    constructor(address _token) public{
        require(_token != address(0));
        token = Token(_token);
        totalDropped = 0;
    }

    function airdropTokens(address[] _recipients, uint256[] _balances) public
    onlyOwner {
        require(_recipients.length == _balances.length);

        uint airDropped = 0;
        for (uint256 i = 0; i < _recipients.length; i++)
        {
            require(token.transfer(_recipients[i], _balances[i]));
            airDropped = airDropped.add(_balances[i]);
        }

        totalDropped = totalDropped.add(airDropped);
        emit Dropped(_recipients.length, airDropped);
    }

     
    function Balance() view public returns (uint256) {
        return token.balanceOf(address(this));
    }

     
    function flushEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
        selfdestruct(owner);
    }

}