 

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

}

 
 

 
 
contract Tracker is Ownable{
     
     
    struct SimpleClient{
        uint8 ratio; 
        uint dosh; 
        string Hash; 
        uint time; 
    }
    
     
    mapping(address => SimpleClient) public Clients;
     
    uint public obligations;
    
     
     
    event ClientRegistered(address Client);
    event ClientExited(address Client);
    
     
    uint constant Period = 1 days;  
    uint constant Fee = 0.4 finney;  
    uint8 constant MininumPercent = 3;  

    
     
    function Register(uint8 ratio, string Hash) payable external {
        var NewClient = SimpleClient(ratio>=MininumPercent?ratio:MininumPercent, msg.value, Hash, now);  
         
         
        NewClient.dosh += Clients[msg.sender].dosh;  
        Clients[msg.sender] = NewClient;  
         
        ClientRegistered(msg.sender);
         
        obligations += msg.value;
        
    }
     
    function Exit() external {
        uint tosend = Clients[msg.sender].dosh;
         
        obligations -= tosend;
         
        Clients[msg.sender].dosh= 0;  
         
        ClientExited(msg.sender);
         
        msg.sender.transfer(tosend);
        
    }
     
    function ChangeNumber(string NewHash) external {  
        Clients[msg.sender].Hash = NewHash;
        ClientExited(msg.sender);
        ClientRegistered(msg.sender);  
    }
     
    function DebitClient(address client) external{ 
        uint TotalFee;
        uint timedif = now-Clients[client].time;  
        uint periodmulti = timedif/Period;  
        if(periodmulti>0){  
          TotalFee = Fee*periodmulti;  
        }else{ 
          throw;
        }
        if(Clients[client].dosh < TotalFee){  
          throw;
        }
        Clients[client].dosh -= TotalFee;
        obligations -= TotalFee;
        Clients[client].time += Period*periodmulti;  
    }
     
    function DebitClientOnce(address client) external{ 
        uint timedif = now-Clients[client].time;  
        if(timedif<Period){  
          throw;
        }
        if(Clients[client].dosh < Fee){  
          throw;
        }
        Clients[client].dosh -= Fee;
        obligations -= Fee;
        Clients[client].time += Period;  
    }
    
     
    function Withdraw(uint amount) onlyOwner external{  
        if(this.balance <= obligations){  
            throw;  
            selfdestruct(owner); 
        }
        if((this.balance - obligations) <= amount ){ 
            throw;  
        }
        owner.transfer(amount); 
    }
}