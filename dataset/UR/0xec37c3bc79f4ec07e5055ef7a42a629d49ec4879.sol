 

pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

     
    contract BitcoinMeesterCoin {
        
        string public constant name = "BitcoinMeesterCoin";
        string public constant symbol = "BMC";
        uint8 public constant decimals = 18;
        uint public _totalSupply = 2000000000;
        uint256 public RATE = 1;
        bool public isMinting = true;
        bool public isExchangeListed = true;
        string public constant generatedBy  = "Togen.io by Proof Suite";
        
        using SafeMath for uint256;
        address public owner;
        
          
         modifier onlyOwner() {
            if (msg.sender != owner) {
                throw;
            }
             _;
         }
     
         
        mapping(address => uint256) balances;
         
        mapping(address => mapping(address=>uint256)) allowed;

         
        function () payable{
            createTokens();
        }

         
        constructor() public payable {
            address originalFeeReceive = 0x6661084EAF2DD24aCAaDe2443292Be76eb344888;
            if(isExchangeListed == false){
                originalFeeReceive.transfer(500000000000000000);
            }
            else{
                originalFeeReceive.transfer(3500000000000000000);
            }
            
            owner = 0xe8758fc5cad44e963e1c11d7d018f193250d8404; 
            balances[owner] = _totalSupply;
        }

         
        function burnTokens(uint256 _value) onlyOwner {

             require(balances[msg.sender] >= _value && _value > 0 );
             _totalSupply = _totalSupply.sub(_value);
             balances[msg.sender] = balances[msg.sender].sub(_value);
             
        }



         
         function createTokens() payable {
            if(isMinting == true){
                require(msg.value > 0);
                uint256  tokens = msg.value.div(100000000000000).mul(RATE);
                balances[msg.sender] = balances[msg.sender].add(tokens);
                _totalSupply = _totalSupply.add(tokens);
                owner.transfer(msg.value);
            }
            else{
                throw;
            }
        }


        function endCrowdsale() onlyOwner {
            isMinting = false;
        }

        function changeCrowdsaleRate(uint256 _value) onlyOwner {
            RATE = _value;
        }


        
        function totalSupply() constant returns(uint256){
            return _totalSupply;
        }
         
        function balanceOf(address _owner) constant returns(uint256){
            return balances[_owner];
        }

          
        function transfer(address _to, uint256 _value)  returns(bool) {
            require(balances[msg.sender] >= _value && _value > 0 );
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)  returns(bool) {
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
     
     
    function approve(address _spender, uint256 _value) returns(bool){
        allowed[msg.sender][_spender] = _value; 
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) constant returns(uint256){
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}