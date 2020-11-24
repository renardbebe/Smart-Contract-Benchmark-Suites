 

pragma solidity ^0.4.17;

 
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract iPromo {
    function massNotify(address[] _owners) public;
    function transferOwnership(address newOwner) public;
}

 
contract EthealPromoDistribute is Ownable {
    mapping (address => bool) public admins;
    iPromo public token;

     
    constructor(address _promo) public {
        token = iPromo(_promo);
    }

     
    function setToken(address _promo) onlyOwner public {
        token = iPromo(_promo);
    }

     
    function passToken(address _promo) onlyOwner public {
        require(_promo != address(0));
        require(address(token) != address(0));

        token.transferOwnership(_promo);
    }

     
    function setAdmin(address[] _admins, bool _v) onlyOwner public {
        for (uint256 i = 0; i<_admins.length; i++) {
            admins[ _admins[i] ] = _v;
        }
    }

     
    function massNotify(address[] _owners) external {
        require(admins[msg.sender] || msg.sender == owner);
        token.massNotify(_owners);
    }
}