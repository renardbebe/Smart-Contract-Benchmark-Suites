 

 
 

pragma solidity ^0.4.24;

contract ERC20Basic {
  uint256 public totalSupply;
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }
  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }
  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract owned {
    address owner;

    modifier onlyOwner { if (msg.sender == owner) _ ; }

    constructor() public {
        owner = msg.sender;
    }

    function kill() public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}
 

contract GETEventContract is owned {
    using SafeERC20 for ERC20Basic;
    event TicketTransfered(address indexed from, address indexed to, uint256 ticketid);

     
    mapping (uint256 => address) public ticketOwner;

    event GETUnstaked(uint256 amount);

    function transferTicket(address _receiver, uint256 _ticketid) onlyOwner public {
         
        ticketOwner[_ticketid] = _receiver;
    }

    function unstakeGET(ERC20Basic _token) public onlyOwner {
        uint256 currentGETBalance = _token.balanceOf(address(this));
        _token.safeTransfer(owner, currentGETBalance);
        emit GETUnstaked(currentGETBalance);
    } 
}