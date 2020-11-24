 

pragma solidity ^0.5.0;


contract ERC20 {

    string public  name = "VDH Token";
    string public  symbol = "VDH";
    uint8 public  decimals = 18;

    uint public totalSupply = 2500000000 * 10 ** uint(decimals);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() public {
       balanceOf[msg.sender] = totalSupply;
       emit Transfer(address(0), msg.sender, totalSupply);
    }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
      require(_to != address(0));
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);    


      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;

       
      emit Transfer(msg.sender, _to, _value);

      return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_to != address(0));
      require(allowed[_from][msg.sender] >= _value);
      require(balanceOf[_from] >= _value);
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);

      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;

      allowed[_from][msg.sender] -= _value;

      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }
}