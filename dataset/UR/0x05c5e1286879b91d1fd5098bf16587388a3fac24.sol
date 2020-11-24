 

pragma solidity ^0.5.8;

interface tokenRecipient { function receiveApproval (address _from, uint256 _value, address _token, bytes calldata _extradata) external; }

contract owned {
  address public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership (address newOwner) onlyOwner public {
     owner = newOwner;
  }
}

contract Blocktorial is owned {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping(address => uint256)) public allowance;

  event Transfer ( address indexed from, address indexed to, uint value );
  event Approval ( address indexed _owner, address indexed _spender, uint256 _value );
  event Burn ( address indexed from, uint256 value );

  constructor() public{
    name = "Blocktorial Token";
    symbol = "BLKT";
    decimals = 18;
    totalSupply = 88000000000000000000000000;  
    balanceOf[msg.sender] = totalSupply;
  }


  function _transfer(address _from, address _to, uint _value) internal {

    require(_to != address(0));
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);

    uint previousBalances = balanceOf[_from] + balanceOf[_to];

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    emit Transfer(_from, _to, _value);
    assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
  }


  function transfer(address _to, uint256 _value) public returns (bool success) {

    _transfer(msg.sender, _to, _value);
    return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }


  function approve (address _spender, uint256 _value) public returns (bool success){
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function approveAndCall(address _spender, uint256 _value, bytes memory _extradata) public returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);

    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, address(this), _extradata);
      return true;
    }
  }

 
 
  function burn (uint256 _value) onlyOwner public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);

    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

   
   
  function burnFrom (address _from, uint256 _value) onlyOwner public returns (bool success) {
    require(balanceOf[_from] >= _value);
    require(_value <= allowance[_from][msg.sender]);

    balanceOf[_from] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  function mintToken (address target, uint256 mintedAmount) onlyOwner public {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
  }

}