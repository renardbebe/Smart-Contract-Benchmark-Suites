 

pragma solidity ^0.4.21;
 
contract SafeMath {
   

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
}




 
contract StandardToken is SafeMath {

     
    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(_to != 0X0);

         
         
        if (balances[msg.sender] >= _value && balances[msg.sender] - _value < balances[msg.sender]) {

             
            balances[msg.sender] = super.safeSub(balances[msg.sender], _value);
             
            balances[_to] = super.safeAdd(balances[_to], _value);

            emit Transfer(msg.sender, _to, _value); 
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(_to != 0X0);

         
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_from] - _value < balances[_from]) {

             
            allowed[_from][msg.sender] = super.safeSub(allowed[_from][msg.sender], _value);
             
            balances[_from] = super.safeSub(balances[_from], _value);
             
            balances[_to] = super.safeAdd(balances[_to], _value);

            emit Transfer(_from, _to, _value); 
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
         
         
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
       
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}










 
contract ArtChainToken is StandardToken {

     
    string public constant name = "Artchain Global Token";

     
    string public constant symbol = "ACG";

     
    uint public startBlock;

     
    uint public constant decimals = 8;

     
    uint256 public totalSupply = 3500000000*10**uint(decimals);  


     
    address public founder = 0x3b7ca9550a641B2bf2c60A0AeFbf1eA48891e58b;
     
     
     
     
    address public constant founder_token = 0x3b7ca9550a641B2bf2c60A0AeFbf1eA48891e58b; 


     
    address public poi = 0x98d95A8178ff41834773D3D270907942F5BE581e;
     
     
     
     
    address public constant poi_token = 0x98d95A8178ff41834773D3D270907942F5BE581e;  


     
    address public constant privateSale = 0x31F2F3361e929192aB2558b95485329494955aC4;


     
     
     
    uint public constant one_month = 185143; 
    uint public poiLockup = super.safeMul(uint(one_month), 7);   

     
    bool public halted = false;



     
    function ArtChainToken() public {
     

         
        startBlock = block.number;

         
        balances[founder] = 700000000*10**uint(decimals);  

         
        balances[poi] = 1400000000*10**uint(decimals);    

         
        balances[privateSale] = 1400000000*10**uint(decimals);  
    }


     
    function halt() public returns (bool success) {
        if (msg.sender!=founder) return false;
        halted = true;
        return true;
    }
    function unhalt() public returns (bool success) {
        if (msg.sender!=founder) return false;
        halted = false;
        return true;
    }


     
    function changeFounder(address newFounder) public returns (bool success){
         
        if (msg.sender!=founder) return false;
        founder = newFounder;
        return true;
    }
    function changePOI(address newPOI) public returns (bool success){
         
        if (msg.sender!=founder) return false;
        poi = newPOI;
        return true;
    }




     
    function transfer(address _to, uint256 _value) public returns (bool success) {

       
      if (halted==true) return false;

       
      if (msg.sender==poi_token && block.number <= startBlock + poiLockup)  return false;

       
      if (msg.sender==founder_token){
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 6)  && super.safeSub(balanceOf(msg.sender), _value)<700000000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 12) && super.safeSub(balanceOf(msg.sender), _value)<595000000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 18) && super.safeSub(balanceOf(msg.sender), _value)<490000000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 24) && super.safeSub(balanceOf(msg.sender), _value)<402500000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 30) && super.safeSub(balanceOf(msg.sender), _value)<315000000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 36) && super.safeSub(balanceOf(msg.sender), _value)<227500000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 42) && super.safeSub(balanceOf(msg.sender), _value)<140000000*10**uint(decimals)) return false;
         
        if (block.number <= startBlock + super.safeMul(uint(one_month), 48) && super.safeSub(balanceOf(msg.sender), _value)< 70000000*10**uint(decimals)) return false;
         
      }

       
      return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        if (halted==true) return false;

         
        if (_from==poi_token && block.number <= startBlock + poiLockup) return false;

         
        if (_from==founder_token){
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 6)  && super.safeSub(balanceOf(_from), _value)<700000000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 12) && super.safeSub(balanceOf(_from), _value)<595000000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 18) && super.safeSub(balanceOf(_from), _value)<490000000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 24) && super.safeSub(balanceOf(_from), _value)<402500000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 30) && super.safeSub(balanceOf(_from), _value)<315000000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 36) && super.safeSub(balanceOf(_from), _value)<227500000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 42) && super.safeSub(balanceOf(_from), _value)<140000000*10**uint(decimals)) return false;
           
          if (block.number <= startBlock + super.safeMul(uint(one_month), 48) && super.safeSub(balanceOf(_from), _value)< 70000000*10**uint(decimals)) return false;
           
        }

         
        return super.transferFrom(_from, _to, _value);
    }









     
    function burn(uint256 _value) public returns (bool success) {

       
      if (halted==true) return false;

       
      if (msg.sender==poi_token && block.number <= startBlock + poiLockup) return false;

       
      if (msg.sender==founder_token) return false;


       
      if (balances[msg.sender] < _value) return false;
       
      if (balances[msg.sender] - _value > balances[msg.sender]) return false;


       

       
      balances[msg.sender] = super.safeSub(balances[msg.sender], _value);
       
      totalSupply = super.safeSub(totalSupply, _value);

      emit Burn(msg.sender, _value);  

      return true;

    }




     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

       
      if (halted==true) return false;

       
       
      if (_from==poi_token && block.number <= startBlock + poiLockup) return false;

       
       
      if (_from==founder_token) return false;


       
      if (balances[_from] < _value) return false;
       
      if (allowed[_from][msg.sender] < _value) return false;
       
      if (balances[_from] - _value > balances[_from]) return false;


       

       
      allowed[_from][msg.sender] = super.safeSub(allowed[_from][msg.sender], _value);
       
      balances[_from] = super.safeSub(balances[_from], _value);
       
      totalSupply = super.safeSub(totalSupply, _value);

      emit Burn(_from, _value);  

      return true;
  }
}