 

 
 
 
 
 

pragma solidity ^0.4.23;    

  library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
  }

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
   
  contract Iou_Token is ERC20Interface {

      string public constant symbol = "IOU";
      string public constant name = "IOU token";
      uint8 public constant decimals = 18; 
           
      uint256 public constant maxTokens = 800*10**6*10**18; 
      uint256 public constant ownerSupply = maxTokens*30/100;
      uint256 _totalSupply = ownerSupply;  

      uint256 public constant token_price = 10**18*1/800; 
      uint256 public pre_ico_start = 1528416000; 
      uint256 public ico_start = 1531008000; 
      uint256 public ico_finish = 1541635200; 
      uint public constant minValuePre = 10**18*1/1000000; 
      uint public constant minValue = 10**18*1/1000000; 
      uint public constant maxValue = 3000*10**18;

      uint public coef = 102;

      using SafeMath for uint;
      
       
      address public owner;
      address public moderator;
   
       
      mapping(address => uint256) balances;
   
       
      mapping(address => mapping (address => uint256)) allowed;

       
      mapping(address => uint256) public orders_sell_amount;

       
      mapping(address => uint256) public orders_sell_price;

       
      address[] public orders_sell_list;

       
      event Order_sell(address indexed _owner, uint256 _max_amount, uint256 _price);      

       
      event Order_execute(address indexed _from, address indexed _to, uint256 _amount, uint256 _price);      
   
       
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }

       
      modifier onlyModerator() {
          if (msg.sender != moderator) {
              throw;
          }
          _;
      }

       
      function changeOwner(address _owner) onlyOwner returns (bool result) {                    
          owner = _owner;
          return true;
      }            

       
      function changeModerator(address _moderator) onlyOwner returns (bool result) {                    
          moderator = _moderator;
          return true;
      }            
   
       
      function Iou_Token() {
           
          owner = 0x25f701bff644601a4bb9c3daff3b9978e2455bcd;
          moderator = 0x788C45Dd60aE4dBE5055b5Ac02384D5dc84677b0;
          balances[owner] = ownerSupply;
      }
      
       
      function() payable {        
          tokens_buy();        
      }
      
      function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
      }

       
      function withdraw(uint256 _amount) onlyOwner returns (bool result) {
          uint256 balance;
          balance = this.balance;
          if(_amount > 0) balance = _amount;
          owner.send(balance);
          return true;
      }

       
      function change_coef(uint256 _coef) onlyOwner returns (bool result) {
          coef = _coef;
          return true;
      }

       
      function change_pre_ico_start(uint256 _pre_ico_start) onlyModerator returns (bool result) {
          pre_ico_start = _pre_ico_start;
          return true;
      }

       
      function change_ico_start(uint256 _ico_start) onlyModerator returns (bool result) {
          ico_start = _ico_start;
          return true;
      }

       
      function change_ico_finish(uint256 _ico_finish) onlyModerator returns (bool result) {
          ico_finish = _ico_finish;
          return true;
      }
   
       
      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }
   
       
      function transfer(address _to, uint256 _amount) returns (bool success) {          

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

       
      function tokens_buy() payable returns (bool) { 

        uint256 tnow = now;
        
        if(tnow < pre_ico_start) throw;
        if(tnow > ico_finish) throw;
        if(_totalSupply >= maxTokens) throw;
        if(!(msg.value >= token_price)) throw;
        if(!(msg.value >= minValue)) throw;
        if(msg.value > maxValue) throw;

        uint tokens_buy = (msg.value*10**18).div(token_price);
        uint tokens_buy_total;

        if(!(tokens_buy > 0)) throw;   
        
         
        uint b1 = 0;
         
        uint b2 = 0;
         
        uint b3 = 0;

        if(_totalSupply <= 10*10**6*10**18) {
          b1 = tokens_buy*30/100;
        }
        if((10*10**6*10**18 < _totalSupply)&&(_totalSupply <= 20*10**6*10**18)) {
          b1 = tokens_buy*25/100;
        }
        if((20*10**6*10**18 < _totalSupply)&&(_totalSupply <= 30*10**6*10**18)) {
          b1 = tokens_buy*20/100;
        }
        if((30*10**6*10**18 < _totalSupply)&&(_totalSupply <= 40*10**6*10**18)) {
          b1 = tokens_buy*15/100;
        }
        if((40*10**6*10**18 < _totalSupply)&&(_totalSupply <= 50*10**6*10**18)) {
          b1 = tokens_buy*10/100;
        }
        if(50*10**6*10**18 <= _totalSupply) {
          b1 = tokens_buy*5/100;
        }        

        if(tnow < ico_start) {
          b2 = tokens_buy*40/100;
        }
        if((ico_start + 86400*0 <= tnow)&&(tnow < ico_start + 86400*5)){
          b2 = tokens_buy*5/100;
        } 
        if((ico_start + 86400*5 <= tnow)&&(tnow < ico_start + 86400*10)){
          b2 = tokens_buy*4/100;        
        } 
        if((ico_start + 86400*10 <= tnow)&&(tnow < ico_start + 86400*20)){
          b2 = tokens_buy*5/100;        
        } 
        if((ico_start + 86400*20 <= tnow)&&(tnow < ico_start + 86400*30)){
          b2 = tokens_buy*2/100;        
        } 
        if(ico_start + 86400*30 <= tnow){
          b2 = tokens_buy*1/100;        
        }
        

        if((1000*10**18 <= tokens_buy)&&(5000*10**18 <= tokens_buy)) {
          b3 = tokens_buy*5/100;
        }
        if((5001*10**18 <= tokens_buy)&&(10000*10**18 < tokens_buy)) {
          b3 = tokens_buy*75/10/100;
        }
        if((10001*10**18 <= tokens_buy)&&(15000*10**18 < tokens_buy)) {
          b3 = tokens_buy*10/100;
        }
        if((15001*10**18 <= tokens_buy)&&(20000*10**18 < tokens_buy)) {
          b3 = tokens_buy*125/10/100;
        }
        if(20001*10**18 <= tokens_buy) {
          b3 = tokens_buy*15/100;
        }

        tokens_buy_total = tokens_buy.add(b1);
        tokens_buy_total = tokens_buy_total.add(b2);
        tokens_buy_total = tokens_buy_total.add(b3);        

        if(_totalSupply.add(tokens_buy_total) > maxTokens) throw;
        _totalSupply = _totalSupply.add(tokens_buy_total);
        balances[msg.sender] = balances[msg.sender].add(tokens_buy_total);         

        return true;
      }
      
             
      function orders_sell_total () constant returns (uint256) {
        return orders_sell_list.length;
      } 

       
      function get_orders_sell_amount(address _from) constant returns(uint) {

        uint _amount_max = 0;

        if(!(orders_sell_amount[_from] > 0)) return _amount_max;

        if(balanceOf(_from) > 0) _amount_max = balanceOf(_from);
        if(orders_sell_amount[_from] < _amount_max) _amount_max = orders_sell_amount[_from];

        return _amount_max;
      }

       
      function order_sell(uint256 _max_amount, uint256 _price) returns (bool) {

        if(!(_max_amount > 0)) throw;
        if(!(_price > 0)) throw;        

        orders_sell_amount[msg.sender] = _max_amount;
        orders_sell_price[msg.sender] = (_price*coef).div(100);
        orders_sell_list.push(msg.sender);        

        Order_sell(msg.sender, _max_amount, orders_sell_price[msg.sender]);      

        return true;
      }

       
      function order_buy(address _from, uint256 _max_price) payable returns (bool) {
        
        if(!(msg.value > 0)) throw;
        if(!(_max_price > 0)) throw;        
        if(!(orders_sell_amount[_from] > 0)) throw;
        if(!(orders_sell_price[_from] > 0)) throw; 
        if(orders_sell_price[_from] > _max_price) throw;

        uint _amount = (msg.value*10**18).div(orders_sell_price[_from]);
        uint _amount_from = get_orders_sell_amount(_from);

        if(_amount > _amount_from) _amount = _amount_from;        
        if(!(_amount > 0)) throw;        

        uint _total_money = (orders_sell_price[_from]*_amount).div(10**18);
        if(_total_money > msg.value) throw;

        uint _seller_money = (_total_money*100).div(coef);
        uint _buyer_money = msg.value - _total_money;

        if(_seller_money > msg.value) throw;
        if(_seller_money + _buyer_money > msg.value) throw;

        if(_seller_money > 0) _from.send(_seller_money);
        if(_buyer_money > 0) msg.sender.send(_buyer_money);

        orders_sell_amount[_from] -= _amount;        
        balances[_from] -= _amount;
        balances[msg.sender] += _amount; 

        Order_execute(_from, msg.sender, _amount, orders_sell_price[_from]);

      }
      
 }