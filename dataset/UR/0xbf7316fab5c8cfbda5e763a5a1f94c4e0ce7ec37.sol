 

 

 
 

 
 

 
 
 

contract Registry {

   

  address public nic;  
  
  struct Record {
    string value;  
		      
		      
    address holder;
    bool exists;  
    uint idx;
  }
  mapping (string => Record) records;
  mapping (uint => string) index;
  
   
  uint public maxRecords;
  uint public currentRecords;

  event debug(string indexed label, string msg);
  event created(string indexed label, string indexed name, address holder, uint block);
  event deleted(string indexed label, string indexed name, address holder, uint block);
  
   
   
   
  function register(string name, string value) {
     
    uint i;
    if (records[name].exists) {
      if (msg.sender != records[name].holder) {  
	throw;
      }
      else {
	i = records[name].idx;
      }
    }
    else {
      records[name].idx = maxRecords;
      i = maxRecords;
      maxRecords++;
    }
    records[name].value = value;
    records[name].holder = msg.sender;
    records[name].exists = true;
    currentRecords++;
    index[i] = name;
    created("CREATION", name, msg.sender, block.number);	  
  }

  function transfer(string name, address to) {
    if (records[name].exists) {
      if (msg.sender != records[name].holder) {
	throw;
      }
      records[name].holder = to;
    }
    else {
      throw;
    }
  }
  
  function get(string name) constant returns(bool exists, string value) {
    if (records[name].exists) {
      exists = true;
      value = records[name].value;
    } else {
      exists = false;
    }
  }

   
  function Registry() {
    nic = msg.sender;
    currentRecords = 0;
    maxRecords = 0;
    register("NIC", "Automatically created by for the registry");  
     
  }
  

  function whois(string name) constant returns(bool exists, string value, address holder) {
    if (records[name].exists) {
      exists = true;
      value = records[name].value;
      holder = records[name].holder;
    } else {
      exists = false;
    }
  }

  function remove(string name) {
    uint i;
    if (records[name].exists) {
      if (msg.sender != records[name].holder) {
	throw;
      }
      else {
	i = records[name].idx;
      }
    }
    else {
      throw;  
    }
    records[name].exists = false;
    currentRecords--;
    deleted("DELETION", name, msg.sender, block.number);	  
  }

  function download() returns(string all) {
    if (msg.sender != nic) {
	throw;
      }
    all = "NOT YET IMPLEMENTED";
     
     
     
    
     
     
     

     
     
     

	 
	 
	 
  }
  
}