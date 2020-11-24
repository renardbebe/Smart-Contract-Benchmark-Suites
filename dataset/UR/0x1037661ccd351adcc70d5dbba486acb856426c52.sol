 

pragma solidity ^0.5.2 <0.6.0; contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract SimpleToken is Ownable {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }


     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(value <= _balances[from]);  

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
}
contract FiatContract {
  function USD(uint _id) public pure returns (uint256);
}

contract RealToken is Ownable, SimpleToken {
  FiatContract public price;
    
  using SafeMath for uint256;

  string public constant name = "DreamPot Token";
  string public constant symbol = "DP";
  uint32 public constant decimals = 0;

  address payable public ethOwner;

  uint256 public factor;

  event GetEth(address indexed from, uint256 value);

  constructor() public {
    price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
    ethOwner = address(uint160(owner()));
    factor = 10;
  }

  function setEthOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    ethOwner = address(uint160(newOwner));
  }

  function setFactor(uint256 newFactor) public onlyOwner {
    factor = newFactor;
  }
  
   
  function calcTokens(uint256 weivalue) public view returns(uint256) {
    uint256 ethCent = price.USD(0);
    uint256 usdv = ethCent.div(factor);
    return weivalue.div(usdv);
  }

  function() external payable {
    uint256 tokens = calcTokens(msg.value);
    ethOwner.transfer(msg.value);
    emit GetEth(msg.sender, msg.value);
    _mint(msg.sender, tokens);
  }
}