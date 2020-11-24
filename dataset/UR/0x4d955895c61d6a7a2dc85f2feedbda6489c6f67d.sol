 

pragma solidity ^0.4.12;

contract Log {
  struct Message {
    address Sender;
    string Data;
    uint Time;
  }

  Message[] public History;

  Message LastMsg;

  function addMessage(string memory _data) public {
    LastMsg.Sender = msg.sender;
    LastMsg.Time = now;
    LastMsg.Data = _data;
    History.push(LastMsg);
  }
}

contract Ownable {
  address public owner;
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner){
      revert();
    }
    _;
  }

  modifier protected() {
      if(msg.sender != address(this)){
        revert();
      }
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner == address(0)) {
      revert();
    }
    owner = newOwner;
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}

contract CaptureTheFlag is Ownable {
  address owner;
  event WhereAmI(address, string);
  Log TransferLog;
  uint256 public jackpot = 0;
  uint256 MinDeposit = 1 ether;
  uint256 minInvestment = 1 ether;
  uint public sumInvested;
  uint public sumDividend;
  bool inProgress = false;

  mapping(address => uint256) public balances;
  struct Osakako {
    address me;
  }
  struct investor {
    uint256 investment;
    string username;
  }
  event Transfer(
    uint amount,
    bytes32 message,
    address target,
    address currentOwner
  );

  mapping(address => investor) public investors;

  function CaptureTheFlag(address _log) public {
    TransferLog = Log(_log);
    owner = msg.sender;
  }

   
  function() public payable {
    if( msg.value >= jackpot ){
      owner = msg.sender;
    }
    jackpot += msg.value;  
  }

  modifier onlyUsers() {
    require(users[msg.sender] != false);
    _;
  }

  mapping(address => bool) users;

  function registerAllPlayers(address[] players) public onlyOwner {
    require(inProgress == false);

    for (uint32 i = 0; i < players.length; i++) {
      users[players[i]] = true;
    }
    inProgress = true;
  }

  function takeAll() external onlyOwner {
    msg.sender.transfer(this.balance);  
    jackpot = 0;  
  }
   

   
  function Deposit() public payable {
    if ( msg.value >= MinDeposit ){
      balances[msg.sender] += msg.value;
      TransferLog.addMessage(" Deposit ");
    }
  }

  function CashOut(uint amount) public onlyUsers {
    if( amount <= balances[msg.sender] ){
      if(msg.sender.call.value(amount)()){
        balances[msg.sender] -= amount;
        TransferLog.addMessage(" CashOut ");
      }
    }
  }
   

   
  function invest() public payable {
    if ( msg.value >= minInvestment ){
      investors[msg.sender].investment += msg.value;
    }
  }

  function divest(uint amount) public onlyUsers {
    if ( investors[msg.sender].investment == 0 || amount == 0) {
      revert();
    }
     
    investors[msg.sender].investment -= amount;
    sumInvested -= amount;
    this.loggedTransfer(amount, "", msg.sender, owner);
  }

  function loggedTransfer(uint amount, bytes32 message, address target, address currentOwner) public protected onlyUsers {
    if(!target.call.value(amount)()){
      revert();
    }

    Transfer(amount, message, target, currentOwner);
  }
   

  function osaka(string message) public onlyUsers {
    Osakako osakako;
    osakako.me = msg.sender;
    WhereAmI(osakako.me, message);
  }

  function tryMeLast() public payable onlyUsers {
    if ( msg.value >= 0.1 ether ) {
      uint256 multi = 0;
      uint256 amountToTransfer = 0;
      for (var i = 0; i < 2 * msg.value; i++) {
        multi = i * 2;
        if (multi < amountToTransfer) {
          break;
        }
        amountToTransfer = multi;
      }
      msg.sender.transfer(amountToTransfer);
    }
  }

  function easyMode( address addr ) external payable onlyUsers {
    if ( msg.value >= this.balance ){
      addr.transfer(this.balance + msg.value);
    }
  }
}