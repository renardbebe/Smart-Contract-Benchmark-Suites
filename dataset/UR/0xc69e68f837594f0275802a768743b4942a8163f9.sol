 

pragma solidity ^0.4.24;
 
library SafeMath256 {

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

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf( address who ) public constant returns (uint);
    function allowance( address owner, address spender ) public constant returns (uint);

    function transfer( address to, uint value) public returns (bool);
    function transferFrom( address from, address to, uint value) public returns (bool);
    function approve( address spender, uint value ) public returns (bool);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
    
}

contract BaseEvent {

    event OnBurn
    (
        address indexed from, 
        uint256 value
    );

    event OnFrozenAccount
    (
        address indexed target, 
        bool frozen
    );

}

interface TokenRecipient {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) external;
}

 
contract GCC is ERC20, Ownable, BaseEvent {

    uint256 _supply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    string   public  symbol = "GCC";
    string   public  name = "game continent";
    uint256  public  decimals = 18;

    using SafeMath256 for uint256;

    constructor() public {}

    function totalSupply() public constant returns (uint256) {return _supply;}
    function balanceOf(address _owner) public constant returns (uint256) {return _balances[_owner];}
    function allowance(address _owner, address _spender) public constant returns (uint256) {return _approvals[_owner][_spender];}

    function transfer(address _to, uint _val) public returns (bool) {
 
        require(_balances[msg.sender] >= _val);
        _balances[msg.sender] = _balances[msg.sender].sub(_val);
        _balances[_to] = _balances[_to].add(_val);

        emit Transfer(msg.sender, _to, _val);
        return true;
    }

    function transferFrom(address _from, address _to, uint _val) public returns (bool) {
 
        require(_balances[_from] >= _val);
        require(_approvals[_from][msg.sender] >= _val);
        _approvals[_from][msg.sender] = _approvals[_from][msg.sender].sub(_val);
        _balances[_from] = _balances[_from].sub(_val);
        _balances[_to] = _balances[_to].add(_val);

        emit Transfer(_from, _to, _val);
        return true;
    }

    function approve(address _spender, uint256 _val) public returns (bool) {
        _approvals[msg.sender][_spender] = _val;
        emit Approval(msg.sender, _spender, _val);
        return true;
    }

    function burn(uint256 _value) public returns (bool) {
 
        require(_balances[msg.sender] >= _value); 
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _supply = _supply.sub(_value);
        emit OnBurn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool) {
 
        require(_balances[_from] >= _value);
        require(_value <= _approvals[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _approvals[_from][msg.sender] = _approvals[_from][msg.sender].sub(_value);
        _supply = _supply.sub(_value);
        emit OnBurn(_from, _value);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) 
        onlyOwner()
        public
    {
 
        emit OnFrozenAccount(target, freeze);
    }
    

    function mint(address _to,uint256 _val) 
        public
        onlyOwner()
    {
        require(_val > 0);
        uint256 _val0 = _val * 10 ** uint256(decimals);
        _balances[_to] = _balances[_to].add(_val0);
        _supply = _supply.add(_val0);
    }

    function approveAndCall(address _recipient, uint256 _value, bytes _extraData)
        public
    {
        approve(_recipient, _value);
        TokenRecipient(_recipient).receiveApproval(msg.sender, _value, address(this), _extraData);
    }
}