 

pragma solidity 0.5.11;


library SafeMath {
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
}

contract Token {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract LockTokenContract {
    using SafeMath for uint;
 
    
     
     
     
     
    
    
    address public AddressOne = address(0xb2a1E43e6edE0E20645bB46fdC24f29C6f8222F8);
    address public AddressTwo = address(0xD8314EA4c9B8e0340735E6b638E6D57Ac8Ca6514);
    address public GubiTokenAddress  = address(0x12b2B2331A72d375c453c160B2c8A7010EeA510A);
    uint256 AddressOneMaxWithdrawalAmount = 2100 * 1e18;
    
    
     
    uint256 public releaseTime = now + 3600 * 24;  
    
    mapping(address => uint256) public AddressWithdrawals;


    constructor() public {
    }


    function () payable external {
        require(msg.sender == AddressOne || msg.sender == AddressTwo);
        require(msg.value == 0);
        require(now > releaseTime);

        Token token = Token(GubiTokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        if (msg.sender == AddressOne) {
            uint256 rest = AddressOneMaxWithdrawalAmount.sub(AddressWithdrawals[AddressOne]);
            if (rest > 0) {
                if (rest > balance) {
                    AddressWithdrawals[msg.sender] = AddressWithdrawals[msg.sender].add(balance);
                    require(token.transfer(msg.sender, balance));
                } else {
                    AddressWithdrawals[msg.sender] = AddressWithdrawals[msg.sender].add(rest);
                    require(token.transfer(msg.sender, rest));
                }
            }
        } else if (msg.sender == AddressTwo) {
            uint256 restOne = AddressOneMaxWithdrawalAmount.sub(AddressWithdrawals[AddressOne]);
            if (balance > restOne) {
                uint256 rest = balance.sub(restOne);
                if (rest > 0) {
                    AddressWithdrawals[msg.sender] = AddressWithdrawals[msg.sender].add(rest);
                    require(token.transfer(msg.sender, rest));
                }
            }
        } 
    }
}