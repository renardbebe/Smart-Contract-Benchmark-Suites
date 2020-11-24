 

pragma solidity ^0.4.25;

contract FundEIF {
  
  mapping(address => uint256) public receivedFunds;  
  uint256 public totalSent;                          
  uint256 public totalOtherReceived;                 
  uint256 public totalInterestReinvested;            
  address public EIF;
  address public PoEIF;
  event INCOMING(address indexed sender, uint amount, uint256 timestamp);
  event OUTGOING(address indexed sender, uint amount, uint256 timestamp);

  constructor() public {
    EIF = 0x35027a992A3c232Dd7A350bb75004aD8567561B2;     
    PoEIF = 0xFfB8ccA6D55762dF595F21E78f21CD8DfeadF1C8;   
  }
  
  function () external payable {
      emit INCOMING(msg.sender, msg.value, now);   
      if (msg.sender != EIF) {                     
          receivedFunds[msg.sender] += msg.value;  
          if (msg.sender != PoEIF) {               
              totalOtherReceived += msg.value;
          }
      }
  }
  
  function PayEIF() external {
      uint256 currentBalance=address(this).balance;
      totalSent += currentBalance;                                                  
      totalInterestReinvested = totalSent-receivedFunds[PoEIF]-totalOtherReceived;  
      emit OUTGOING(msg.sender, currentBalance, now);
      if(!EIF.call.value(currentBalance)()) revert();
  }
}