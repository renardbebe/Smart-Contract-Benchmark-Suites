 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
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

contract CLUBERC20  is ERC20 {
    function lockBalanceOf(address who) public view returns (uint256);
}

 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract ClubTransferContract is owned {
    using SafeERC20 for CLUBERC20;
    using SafeMath for uint;

    string public constant name = "ClubTransferContract";

    CLUBERC20 public clubToken = CLUBERC20(0x9e85C5b1A66C0bb6ce2Ffb41ce0F918b19bf3c8D);

    function ClubTransferContract() public {}
    
    function getBalance() constant public returns(uint256) {
        return clubToken.balanceOf(this);
    }

    function transferClub(address _to, uint _amount) onlyOwner public {
        require (_to != 0x0);
        require(clubToken.balanceOf(this) >= _amount);
        
        clubToken.safeTransfer(_to, _amount);
    }
    
    function transferBack() onlyOwner public {
        clubToken.safeTransfer(owner, clubToken.balanceOf(this));
    }
}