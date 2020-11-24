 

pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    
     
     
     
    
    event Transfer(address indexed from, address indexed to, uint tokens);
     
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


contract ZRO4 is ERC20Interface, Ownable{
    string public name = "ZERO404 O41";
    string public symbol = "ZRO4";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;


 event Transfer(address indexed from, address indexed to, uint tokens);


    constructor() public{
        supply = 10000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }
     
     
     
    function transfer(address to, uint tokens) public returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
     
     
     function burn(uint256 _value) public returns (bool success) {
        require(balances[founder] >= _value);    
        balances[founder] -= _value;             
        supply -= _value;                       
        return true;
    }

     function mint(uint256 _value) public returns (bool success) {
        require(balances[founder] >= _value);    
        balances[founder] += _value;             
        supply += _value;                       
        return true;
    }
     
}