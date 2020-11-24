 

pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     

     
     
     
     
     
}

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

contract AirdropToken is BaseToken, Ownable {
     
    address public airSender;
     
     

     

     

     
     
     

     
     
     

     
     
     

     
     
     

     
     
     
     
     
     
     
     
     
     

    function airdropToAdresses(address[] _tos, uint _amount) public onlyOwner {
        uint total = _amount * _tos.length;
        require(total >= _amount && balanceOf[airSender] >= total);
        balanceOf[airSender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            balanceOf[_tos[i]] += _amount;
            emit Transfer(airSender, _tos[i], _amount);
        }
    }
}

contract CustomToken is BaseToken, AirdropToken {
    constructor() public {
        totalSupply = 10000000000000000000000000000;
        name = 'T0703';
        symbol = 'T0703';
        decimals = 18;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), address(msg.sender), totalSupply);

         
         
        airSender = msg.sender;
         
    }

    function() public payable {
         
    }
}