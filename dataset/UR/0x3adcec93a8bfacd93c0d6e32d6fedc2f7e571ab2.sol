 

pragma solidity ^0.5.11;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Byzantine {
  event DidSwap(address from, uint amount, uint totalSwapped, string btcAddress);
  uint256 public totalSwapped;
  uint256 totalJetted;
  address tracker_0x_address = 0x539EfE69bCDd21a83eFD9122571a64CC25e0282b;  
  address devAddress;
  mapping ( address => uint256 ) public balances;

  function deposit(uint256 tokens, string memory btcAddress) public payable {
    require(msg.value==0);
    if(block.number >= 8456789 || msg.sender == devAddress) {
         
        if(ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens)) {
              
            balances[msg.sender] += tokens;
            emit DidSwap(msg.sender, tokens, totalSwapped, btcAddress);
            totalSwapped += tokens;       
        }
    }
  }

  function jetTokens(uint256 amount) public {
    if(msg.sender == devAddress) {
        if(ERC20(tracker_0x_address).transfer(devAddress, amount)) {
            totalJetted += amount;
        }
    }
  }
  
  constructor () public {
      devAddress = msg.sender;
  }

}