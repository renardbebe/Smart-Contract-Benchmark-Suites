 

pragma solidity ^0.4.21;

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract FlyDropToken is Claimable {
    using SafeMath for uint256;

    ERC20 internal erc20tk;
    bytes[] internal approveRecords;

    event ReceiveApproval(address _from, uint256 _value, address _token, bytes _extraData);

     
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        erc20tk = ERC20(_token);
        require(erc20tk.transferFrom(_from, this, _value));  
        approveRecords.push(_extraData);
        ReceiveApproval(_from, _value, _token, _extraData);
    }

     
    function multiSend(address[] _destAddrs, uint256[] _values) onlyOwner public returns (uint256) {
        require(_destAddrs.length == _values.length);

        uint256 i = 0;
        for (; i < _destAddrs.length; i = i.add(1)) {
            if (!erc20tk.transfer(_destAddrs[i], _values[i])) {
                break;
            }
        }

        return (i);
    }

     
    function multiSendFrom(address _from, address[] _destAddrs, uint256[] _values) onlyOwner public returns (uint256) {
        require(_destAddrs.length == _values.length);

        uint256 i = 0;
        for (; i < _destAddrs.length; i = i.add(1)) {
            if (!erc20tk.transferFrom(_from, _destAddrs[i], _values[i])) {
                break;
            }
        }

        return (i);
    }

     
    function getApproveRecord(uint _ind) onlyOwner public view returns (bytes) {
        require(_ind < approveRecords.length);

        return approveRecords[_ind];
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