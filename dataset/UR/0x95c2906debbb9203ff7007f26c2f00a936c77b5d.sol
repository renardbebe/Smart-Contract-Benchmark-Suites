 

pragma solidity ^0.4.6;

contract RES { 

     
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint public totalSupply;
    
     
    mapping (address => uint256) public balanceOf;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    

     

    event Bought(address from, uint amount);
    event Sold(address from, uint amount);
    event BoughtViaJohan(address from, uint amount);

     

    function RES() {
        name = "RES";     
        symbol = "RES";
        decimals = 18;
    }

}

contract SwarmRedistribution is RES {
    
    address public JohanNygren;
    bool public campaignOpen;    

    struct dividendPathway {
      address from;
      uint amount;
      uint timeStamp;
    }

    mapping(address => dividendPathway[]) public dividendPathways;
    
    mapping(address => uint256) public totalBasicIncome;

    uint taxRate;

    struct Node {
      address node;
      address parent;
      uint index;
    }
    
     
    Node[] swarmTree;
    
    mapping(address => bool) inSwarmTree;
    
    bool JohanInSwarm;

    event Swarm(address indexed leaf, address indexed node, uint256 share);

    function SwarmRedistribution() {
      
     
    taxRate = 20;
    JohanNygren = 0x948176CB42B65d835Ee4324914B104B66fB93B52;
    campaignOpen = true;
    
    }
    
    modifier onlyJohan {
      if(msg.sender != JohanNygren) throw;
      _;
    }

    modifier isOpen {
      if(campaignOpen != true) throw;
      _;
    }
    
    function closeCampaign() onlyJohan {
        campaignOpen = false;
    }

    function buy() isOpen public payable {
      balanceOf[msg.sender] += msg.value;
      totalSupply += msg.value;
      Bought(msg.sender, msg.value);
    }  

    function buyViaJohan() isOpen public payable {
      balanceOf[msg.sender] += msg.value;
      totalSupply += msg.value;  

       
      dividendPathways[msg.sender].push(dividendPathway({
                                      from: JohanNygren, 
                                      amount:  msg.value,
                                      timeStamp: now
                                    }));

      BoughtViaJohan(msg.sender, msg.value);
    }

    function sell(uint256 _value) public {
      if(balanceOf[msg.sender] < _value) throw;
      balanceOf[msg.sender] -= _value;
    
      if (!msg.sender.send(_value)) throw;

      totalSupply -= _value;
      Sold(msg.sender, _value);

    }

     
    function transfer(address _to, uint256 _value) isOpen {
         
        if(_to == msg.sender) throw;
        
         
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
         
        uint256 taxCollected = _value * taxRate / 1000;
        uint256 sentAmount;

         
        dividendPathways[_to].push(dividendPathway({
                                        from: msg.sender, 
                                        amount:  _value,
                                        timeStamp: now
                                      }));
        
        if(swarmRedistribution(_to, taxCollected) == true) {
          sentAmount = _value;
        }
        else {
           
          sentAmount = _value - taxCollected;
        }
        
           

          balanceOf[msg.sender] -= sentAmount;
          balanceOf[_to] += _value - taxCollected;
        

         
        Transfer(msg.sender, _to, sentAmount);
    }

    function swarmRedistribution(address _to, uint256 _taxCollected) internal returns (bool) {
           iterateThroughSwarm(_to, now);
           if(swarmTree.length != 0) {
           return doSwarm(_to, _taxCollected);
           }
           else return false;
      }

    function iterateThroughSwarm(address _node, uint _timeStamp) internal {
      if(dividendPathways[_node].length != 0) {
        for(uint i = 0; i < dividendPathways[_node].length; i++) {
          if(inSwarmTree[dividendPathways[_node][i].from] == false) { 
            
            uint timeStamp = dividendPathways[_node][i].timeStamp;
            if(timeStamp <= _timeStamp) {
                
              if(dividendPathways[_node][i].from == JohanNygren) JohanInSwarm = true;
    
                Node memory node = Node({
                            node: dividendPathways[_node][i].from, 
                            parent: _node,
                            index: i
                          });
                          
                  swarmTree.push(node);
                  inSwarmTree[node.node] = true;
                  iterateThroughSwarm(node.node, timeStamp);
              }
          }
        }
      }
    }

    function doSwarm(address _leaf, uint256 _taxCollected) internal returns (bool) {
      
      uint256 share;
      if(JohanInSwarm) share = _taxCollected;
      else share = 0;
    
      for(uint i = 0; i < swarmTree.length; i++) {
        
        address node = swarmTree[i].node;
        address parent = swarmTree[i].parent;
        uint index = swarmTree[i].index;
        
        bool isJohan;
        if(node == JohanNygren) isJohan = true;

        if(isJohan) {
          balanceOf[swarmTree[i].node] += share;
        totalBasicIncome[node] += share;
        }
          
        if(dividendPathways[parent][index].amount - _taxCollected > 0) {
          dividendPathways[parent][index].amount -= _taxCollected; 
        }
        else removeDividendPathway(parent, index);
        
        inSwarmTree[node] = false;
        
         
        if(isJohan) Swarm(_leaf, swarmTree[i].node, share);
      }
      delete swarmTree;
      bool JohanWasInSwarm = JohanInSwarm;
      delete JohanInSwarm;

      if(!JohanWasInSwarm) return false;
      return true;
    }
    
    function removeDividendPathway(address node, uint index) internal {
                delete dividendPathways[node][index];
                for (uint i = index; i < dividendPathways[node].length - 1; i++) {
                        dividendPathways[node][i] = dividendPathways[node][i + 1];
                }
                dividendPathways[node].length--;
        }

}