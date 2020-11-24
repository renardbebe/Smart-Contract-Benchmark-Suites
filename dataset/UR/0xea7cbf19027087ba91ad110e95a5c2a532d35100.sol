 

pragma solidity ^0.4.13;

 


 
contract DaoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
}

contract ZiberToken {
   
  mapping (address => uint256) public balances;
   
  mapping (address => bool) public checked_in;
   
  uint256 public bounty;
   
  bool public bought_tokens;
   
  uint256 public time_bought;
   
  bool public kill_switch;
  
   
  string public name;
  string public symbol;
  uint8 public decimals;
  
   
   
   
   
  uint256 ZBR_per_eth = 17440;
   
  uint256 ZBR_total_reserve = 100000000;
   
  uint256 ZBR_dev_reserved = 10000000;
   
  uint256 ZBR_for_selling = 80000000;
   
  uint256 ZBR_for_bounty= 10000000;
   
  uint256 ETH_to_end = 50000 ether;
  uint registredTo;
  uint256 loadedRefund;
  uint256 _supply;
  string _name;
  string _symbol;
  uint8 _decimals;

   
  DaoToken public token = DaoToken(0xa9d585CE3B227d69985c3F7A866fE7d0e510da50);
   
  address developer_address = 0x00119E4b6fC1D931f63FFB26B3EaBE2C4E779533; 
   


   
    mapping (address => uint256) public balanceOf;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    function ZiberToken() {
         
        _supply = 10000000000;
        
         
        balanceOf[msg.sender] = _supply;
        name = "ZIBER CW Tokens";     
        symbol = "ZBR";
        
         
        decimals = 2;
    }


     
     
    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }

    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }


     
    function loadRefund() payable {
      if(msg.value == 0) throw;
      loadedRefund = safeAdd(loadedRefund, msg.value);
    }

     
    function refund() private  {
      uint256 weiValue = this.balance;
      if (weiValue == 0) throw;
      uint256 weiRefunded;
      weiRefunded = safeAdd(weiRefunded, weiValue);
      refund();
      if (!msg.sender.send(weiValue)) throw;
    }

     
    function transfer(address _to, uint256 _value) {
         
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
         
        Transfer(msg.sender, _to, _value);
    }
  
   
  function activate_kill_switch() {
     
    if (msg.sender != developer_address) throw;
     
    kill_switch = true;
  }
  
   
  function withdraw(){
     
    if (!bought_tokens) {
       
      uint256 eth_amount = balances[msg.sender];
       
      balances[msg.sender] = 0;
       
      msg.sender.transfer(eth_amount);
    }
     
    else {
       
      uint256 ZBR_amount = balances[msg.sender] * ZBR_per_eth;
       
      balances[msg.sender] = 0;
       
      uint256 fee = 0;
       
      if (!checked_in[msg.sender]) {
        fee = ZBR_amount / 100;
         
        if(!token.transfer(developer_address, fee)) throw;
      }
       
      if(!token.transfer(msg.sender, ZBR_amount - fee)) throw;
    }
  }
  
   
  function add_to_bounty() payable {
     
    if (msg.sender != developer_address) throw;
     
    if (kill_switch) throw;
     
    if (bought_tokens) throw;
     
    bounty += msg.value;
  }
  
   
  function claim_bounty(){
     
    if (bought_tokens) return;
     
    if (kill_switch) throw;
     
    bought_tokens = true;
     
    time_bought = now + 1 days;
     
     
     
    token.proxyPayment.value(this.balance - bounty)(address(this));
     
    if(this.balance > ETH_to_end)
    {
        msg.sender.transfer(bounty);
    }
    else {
        time_bought = now +  1 days * 9;
        if(this.balance > ETH_to_end) {
          msg.sender.transfer(bounty);
        }
      }
  }

     
  modifier onlyOwner() {
    if (msg.sender != developer_address) {
      throw;
    }
    _;
  }
  
   
  function withdrawEth() onlyOwner {        
        msg.sender.transfer(this.balance);
  }
  
   
  function kill() onlyOwner {        
        selfdestruct(developer_address);
  }
  
   
  function default_helper() payable {
     
    if (now < 1500400350 ) throw; 
    else {
       
      if (msg.value <= 1 finney) {
         
        if (bought_tokens) {
           
          if (token.totalEthers() >= token.CAP()) throw;
           
          checked_in[msg.sender] = true;
        }
         
        else {
          withdraw();
        }
      }
       
      else {
         
        if (kill_switch) throw;
         
        if (bought_tokens) throw;
         
        balances[msg.sender] += msg.value;
      }
    }
  }
  
   
  function () payable {
     
    default_helper();
  }
  
}