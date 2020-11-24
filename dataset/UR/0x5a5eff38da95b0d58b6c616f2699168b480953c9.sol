 

 
 
 
 
 
 

contract CharlyLifeLog {
   
  uint private constant MAX_WITHDRAW_DIV = 5;  

   
  uint private constant WITHDRAW_INTERVAL = 180 days;

   
  event LogDonation(address indexed by, uint loggedAt, uint amount);
  event LogWithdrawal(address indexed by, uint loggedAt, uint amount);
  event LogPersonNew(address indexed by, uint loggedAt, uint index);
  event LogPersonUpdate(address indexed by, uint loggedAt, uint index, string field);
  event LogWhitelistAdd(address indexed by, uint loggedAt, address addr);
  event LogWhitelistRemove(address indexed by, uint loggedAt);
  event LogEvent(address indexed by, uint loggedAt, uint when, string description);

   
  struct Person {
    bool active;
    uint activatedAt;
    uint deactivatedAt;
    int dateOfBirth;
    int dateOfDeath;
    string name;
    string relation;
  }

   
  uint public nextWithdrawal = now + WITHDRAW_INTERVAL;

   
  uint public totalDonated = 0;
  uint public totalWithdrawn = 0;

   
  Person[] public people;

   
  mapping(address => uint) public donations;

   
  mapping(address => bool) public whitelist;

   
  modifier isOnWhitelist {
     
    if (!whitelist[msg.sender]) {
      throw;
    }

     
    if (msg.value > 0) {
      throw;
    }

     
    _
  }

   
  function CharlyLifeLog(string name, int dateOfBirth) {
     
    whitelist[msg.sender] = true;

     
    personAdd(name, dateOfBirth, 0, 'self');

     
    if (msg.value > 0) {
      donate();
    }
  }

   
  function log(string description, uint _when) public isOnWhitelist {
     
    uint when = _when;
    if (when == 0) {
      when = now;
    }

     
    LogEvent(msg.sender, now, when, description);
  }

   
  function personAdd(string name, int dateOfBirth, int dateOfDeath, string relation) public isOnWhitelist {
     
    LogPersonNew(msg.sender, now, people.length);

     
    people.push(
      Person({
        active: true,
        activatedAt: now,
        deactivatedAt: 0,
        dateOfBirth: dateOfBirth,
        dateOfDeath: dateOfDeath,
        name: name,
        relation: relation
      })
    );
  }

   
  function personUpdateActivity(uint index, bool active) public isOnWhitelist {
     
    people[index].active = active;

     
    if (active) {
       
      LogPersonUpdate(msg.sender, now, index, 'active');

       
      people[index].activatedAt = now;
      people[index].deactivatedAt = 0;
    } else {
       
      LogPersonUpdate(msg.sender, now, index, 'inactive');

       
      people[index].deactivatedAt = now;
    }
  }

   
  function personUpdateName(uint index, string name) public isOnWhitelist {
     
    LogPersonUpdate(msg.sender, now, index, 'name');

     
    people[index].name = name;
  }

   
  function personUpdateRelation(uint index, string relation) public isOnWhitelist {
     
    LogPersonUpdate(msg.sender, now, index, 'relation');

     
    people[index].relation = relation;
  }

   
  function personUpdateDOB(uint index, int dateOfBirth) public isOnWhitelist {
     
    LogPersonUpdate(msg.sender, now, index, 'dateOfBirth');

     
    people[index].dateOfBirth = dateOfBirth;
  }

   
  function personUpdateDOD(uint index, int dateOfDeath) public isOnWhitelist {
     
    LogPersonUpdate(msg.sender, now, index, 'dateOfDeath');

     
    people[index].dateOfDeath = dateOfDeath;
  }

   
  function whitelistAdd(address addr) public isOnWhitelist {
     
    LogWhitelistAdd(msg.sender, now, addr);

     
    whitelist[addr] = true;
  }

   
  function whitelistRemove(address addr) public isOnWhitelist {
     
    if (msg.sender != addr) {
      throw;
    }

     
    LogWhitelistRemove(msg.sender, now);

     
    whitelist[msg.sender] = false;
  }

   
  function withdraw(uint amount) public isOnWhitelist {
     
    uint max = this.balance / MAX_WITHDRAW_DIV;

     
    if (amount > max || now < nextWithdrawal) {
      throw;
    }

     
    LogWithdrawal(msg.sender, now, amount);

     
    nextWithdrawal = now + WITHDRAW_INTERVAL;
    totalWithdrawn += amount;

     
    if (!msg.sender.send(amount)) {
      throw;
    }
  }

   
  function donate() public {
     
    if (msg.value == 0) {
      throw;
    }

     
    LogDonation(msg.sender, now, msg.value);

     
    donations[msg.sender] += msg.value;
    totalDonated += msg.value;
  }

   
  function() public {
    donate();
  }
}