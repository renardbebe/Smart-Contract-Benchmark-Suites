 

pragma solidity ^0.4.16;        
   
  contract CentraSale { 

    using SafeMath for uint; 

    address public contract_address = 0x96a65609a7b84e8842732deb08f56c3e21ac6f8a; 

    address public owner;
    uint public cap;
    uint public constant cap_max = 90000*10**18;
    uint public constant min_value = 10**18*1/10; 
    uint public constant max_value = 10**18*3000; 
    uint public operation;
    mapping(uint => address) public operation_address;
    mapping(uint => uint) public operation_amount;

    uint256 public constant token_price = 10**18*1/200;  
    uint256 public tokens_total;  

    uint public constant contract_start = 1505793600;
    uint public constant contract_finish = 1507176000;

    uint public constant card_titanium_minamount = 500*10**18;
    uint public constant card_titanium_first = 200;
    mapping(address => uint) cards_titanium_check; 
    address[] public cards_titanium;

    uint public constant card_black_minamount = 100*10**18;
    uint public constant card_black_first = 500;
    mapping(address => uint) public cards_black_check; 
    address[] public cards_black;

    uint public constant card_metal_minamount = 40*10**18;
    uint public constant card_metal_first = 750;
    mapping(address => uint) cards_metal_check; 
    address[] public cards_metal;      

    uint public constant card_gold_minamount = 30*10**18;
    uint public constant card_gold_first = 1000;
    mapping(address => uint) cards_gold_check; 
    address[] public cards_gold;      

    uint public constant card_blue_minamount = 5/10*10**18;
    uint public constant card_blue_first = 100000000;
    mapping(address => uint) cards_blue_check; 
    address[] public cards_blue;

    uint public constant card_start_minamount = 1/10*10**18;
    uint public constant card_start_first = 100000000;
    mapping(address => uint) cards_start_check; 
    address[] public cards_start;
      
   
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }      
 
     
    function CentraSale() {
        owner = msg.sender; 
        operation = 0; 
        cap = 0;        
    }
      
     
    function() payable {    

      if(msg.value <= min_value) throw;
      if(msg.value >= max_value) throw;
      if(now < contract_start) throw;
      if(now > contract_finish) throw;                     

      if(cap + msg.value > cap_max) throw;         

      tokens_total = msg.value*10**18/token_price;
      if(!(tokens_total > 0)) throw; 
      
      if(!contract_transfer(tokens_total)) throw;                

      cap = cap.add(msg.value); 
      operations();
      get_card();      
    }    

     
    function operations() private returns (bool) {
        operation_address[operation] = msg.sender;
        operation_amount[operation] = msg.value;        
        operation = operation.add(1);        
        return true;
    } 

     
    function contract_transfer(uint _amount) private returns (bool) {      

      if(!contract_address.call(bytes4(sha3("transfer(address,uint256)")),msg.sender,_amount)) {    
        return false;
      }
      return true;
    }        

     
    function withdraw() onlyOwner returns (bool result) {
        owner.send(this.balance);
        return true;
    }

     
    function cards_titanium_total() constant returns (uint) { 
      return cards_titanium.length;
    }  
     
    function cards_black_total() constant returns (uint) { 
      return cards_black.length;
    }
     
    function cards_metal_total() constant returns (uint) { 
      return cards_metal.length;
    }        
     
    function cards_gold_total() constant returns (uint) { 
      return cards_gold.length;
    }        
     
    function cards_blue_total() constant returns (uint) { 
      return cards_blue.length;
    }

     
    function cards_start_total() constant returns (uint) { 
      return cards_start.length;
    }

     
    function get_card() private returns (bool) {

      if((msg.value >= card_titanium_minamount)
        &&(cards_titanium.length < card_titanium_first)
        &&(cards_titanium_check[msg.sender] != 1)
        ) {
        cards_titanium.push(msg.sender);
        cards_titanium_check[msg.sender] = 1;
      }

      if((msg.value >= card_black_minamount)
        &&(msg.value < card_titanium_minamount)
        &&(cards_black.length < card_black_first)
        &&(cards_black_check[msg.sender] != 1)
        ) {
        cards_black.push(msg.sender);
        cards_black_check[msg.sender] = 1;
      }                

      if((msg.value >= card_metal_minamount)
        &&(msg.value < card_black_minamount)
        &&(cards_metal.length < card_metal_first)
        &&(cards_metal_check[msg.sender] != 1)
        ) {
        cards_metal.push(msg.sender);
        cards_metal_check[msg.sender] = 1;
      }               

      if((msg.value >= card_gold_minamount)
        &&(msg.value < card_metal_minamount)
        &&(cards_gold.length < card_gold_first)
        &&(cards_gold_check[msg.sender] != 1)
        ) {
        cards_gold.push(msg.sender);
        cards_gold_check[msg.sender] = 1;
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