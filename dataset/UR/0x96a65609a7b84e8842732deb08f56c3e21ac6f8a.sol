 

pragma solidity ^0.4.13;
    
    
    
    
    
    
    
    
  contract ERC20Interface {
       
      function totalSupply() constant returns (uint256 totalSupply);
   
       
      function balanceOf(address _owner) constant returns (uint256 balance);
   
       
      function transfer(address _to, uint256 _value) returns (bool success);
   
       
      function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
   
       
       
       
      function approve(address _spender, uint256 _value) returns (bool success);
   
       
      function allowance(address _owner, address _spender) constant returns (uint256 remaining);
   
       
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
       
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }  
   
  contract CentraToken is ERC20Interface {

      string public constant symbol = "Centra";
      string public constant name = "Centra token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = 100000000*10**18; 
      uint256 public constant ownerSupply = maxTokens*32/100;
      uint256 _totalSupply = ownerSupply;  

      uint256 public constant token_price = 1/400*10**18; 
      uint public constant ico_start = 1501891200;
      uint public constant ico_finish = 1507248000; 
      uint public constant minValuePre = 1/10*10**18; 
      uint public constant minValue = 1/10*10**18; 
      uint public constant maxValue = 3000*10**18;       

      uint public constant card_gold_minamount  = 30*10**18;
      uint public constant card_gold_first = 1000;
      mapping(address => uint) cards_gold_check; 
      address[] public cards_gold;

      uint public constant card_black_minamount = 100*10**18;
      uint public constant card_black_first = 500;
      mapping(address => uint) public cards_black_check; 
      address[] public cards_black;

      uint public constant card_titanium_minamount  = 500*10**18;
      uint public constant card_titanium_first = 200;
      mapping(address => uint) cards_titanium_check; 
      address[] public cards_titanium;

      uint public constant card_blue_minamount  = 5/10*10**18;
      uint public constant card_blue_first = 100000000;
      mapping(address => uint) cards_blue_check; 
      address[] public cards_blue;

      uint public constant card_start_minamount  = 1/10*10**18;
      uint public constant card_start_first = 100000000;
      mapping(address => uint) cards_start_check; 
      address[] public cards_start;

      using SafeMath for uint;      
      
       
      address public owner;
   
       
      mapping(address => uint256) balances;
   
       
      mapping(address => mapping (address => uint256)) allowed;
   
       
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }      
   
       
      function CentraToken() {
          owner = msg.sender;
          balances[owner] = ownerSupply;
      }
      
       
      function() payable {        
          tokens_buy();        
      }
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

       
      function withdraw() onlyOwner returns (bool result) {
          owner.send(this.balance);
          return true;
      }
   
       
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }
   
       
      function transfer(address _to, uint256 _amount) returns (bool success) {

          if(now < ico_start) throw;

          if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(msg.sender, _to, _amount);
              return true;
          } else {
              return false;
          }
      }
   
       
       
       
       
       
       
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
     ) returns (bool success) {

         if(now < ico_start) throw;

         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
      
    function cards_black_total() constant returns (uint) { 
      return cards_black.length;
    }
     
    function cards_gold_total() constant returns (uint) { 
      return cards_gold.length;
    }    
     
    function cards_titanium_total() constant returns (uint) { 
      return cards_titanium.length;
    }
     
    function cards_blue_total() constant returns (uint) { 
      return cards_blue.length;
    }

     
    function cards_start_total() constant returns (uint) { 
      return cards_start.length;
    }

       
      function tokens_buy() payable returns (bool) { 

        uint tnow = now;
        
        if(tnow > ico_finish) throw;        
        if(_totalSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;
        if(msg.value > maxValue) throw;

        uint tokens_buy = msg.value/token_price*10**18;

        if(!(tokens_buy > 0)) throw;   

        if(tnow < ico_start){
          if(!(msg.value >= minValuePre)) throw;
          tokens_buy = tokens_buy*125/100;
        } 
        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*2)){
          tokens_buy = tokens_buy*120/100;
        } 
        if((ico_start + 86400*2 <= tnow)&&(tnow < ico_start + 86400*7)){
          tokens_buy = tokens_buy*110/100;        
        } 
        if((ico_start + 86400*7 <= tnow)&&(tnow < ico_start + 86400*14)){
          tokens_buy = tokens_buy*105/100;        
        }         

        if(_totalSupply.add(tokens_buy) > maxTokens) throw;
        _totalSupply = _totalSupply.add(tokens_buy);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy); 

        if((msg.value >= card_gold_minamount)
          &&(msg.value < card_black_minamount)
          &&(cards_gold.length < card_gold_first)
          &&(cards_gold_check[msg.sender] != 1)
          ) {
          cards_gold.push(msg.sender);
          cards_gold_check[msg.sender] = 1;
        }       

        if((msg.value >= card_black_minamount)
          &&(msg.value < card_titanium_minamount)
          &&(cards_black.length < card_black_first)
          &&(cards_black_check[msg.sender] != 1)
          ) {
          cards_black.push(msg.sender);
          cards_black_check[msg.sender] = 1;
        }        

        if((msg.value >= card_titanium_minamount)
          &&(cards_titanium.length < card_titanium_first)
          &&(cards_titanium_check[msg.sender] != 1)
          ) {
          cards_titanium.push(msg.sender);
          cards_titanium_check[msg.sender] = 1;
        }

        if((msg.value >= card_blue_minamount)
          &&(msg.value < card_gold_minamount)
          &&(cards_blue.length < card_blue_first)
          &&(cards_blue_check[msg.sender] != 1)
          ) {
          cards_blue.push(msg.sender);
          cards_blue_check[msg.sender] = 1;
        }

        if((msg.value >= card_start_minamount)
          &&(msg.value < card_blue_minamount)
          &&(cards_start.length < card_start_first)
          &&(cards_start_check[msg.sender] != 1)
          ) {
          cards_start.push(msg.sender);
          cards_start_check[msg.sender] = 1;
        }

        return true;
      }
      
 }

  
  library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint a, uint b) internal returns (uint) {
       
      uint c = a / b;
       
      return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c >= a);
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
  }