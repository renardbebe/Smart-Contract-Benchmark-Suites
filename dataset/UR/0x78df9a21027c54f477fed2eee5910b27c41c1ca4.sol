 

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract God {
  address tracker_0x_address = 0x7a09ff5fb7fcd7ea013b03e62a1ba6189135410b;  
  mapping ( address => uint256 ) public balances;

  function deposit(uint tokens) public {

     
    balances[msg.sender]+= tokens;

     
    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }

  function returnTokens() public {
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
  }
}