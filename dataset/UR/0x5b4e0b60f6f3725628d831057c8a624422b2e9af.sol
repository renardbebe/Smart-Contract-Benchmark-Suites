 

pragma solidity ^0.4.18;

   
   
   
   

    
   
  contract ERC20Interface {
       
      function totalSupply() constant public returns (uint256 _totalSupply);

       
      function balanceOf(address _owner) constant public returns (uint256 balance);

       
      function transfer(address _to, uint256 _value) public returns (bool success);

       
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

       
      function approve(address _spender, uint256 _value) public returns (bool success);

       
      function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

       
      event Transfer(address indexed _from, address indexed _to, uint256 _value);

       
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }

    
   contract HDCToken is ERC20Interface {
      string public constant symbol = "HDCT";  
      string public constant name = "Health Data Chain Token";  
      uint8 public constant decimals = 18;  
      uint256 _totalSupply = 10000000000000000000000000000;  

       
      address public owner;

       
      mapping(address => uint256) balances;

       
      mapping(address => mapping (address => uint256)) allowed;

       
      modifier onlyOwner() {
          require (msg.sender != owner);
          _;
      }

	  bool public paused = false;

       
      modifier whenNotPaused() {
        require(!paused);
        _;
      }
    
       
      modifier whenPaused() {
        require(paused);
        _;
      }
    
       
      function pause() onlyOwner whenNotPaused public {
        paused = true;
      }
    
       
      function unpause() onlyOwner whenPaused public {
        paused = false;
      }
  
       
      constructor () public {
          owner = msg.sender;
          balances[owner] = _totalSupply;
      }

      function  totalSupply() public constant returns (uint256 totalSupplyRet) {
          totalSupplyRet = _totalSupply;
      }

       
      function balanceOf(address _owner) public constant returns (uint256 balance) {
          return balances[_owner];
      }

       
      function transfer(address _to, uint256 _amount) public whenNotPaused returns (bool success) {
          require(_to != address(0x0) );

          require (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]); 
              
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
      }

       
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
      ) public whenNotPaused returns (bool success) {
          require(_to != address(0x0) );
          
          require (balances[_from] >= _amount
              && allowed[_from][msg.sender] >= _amount
              && _amount > 0
              && balances[_to] + _amount > balances[_to]);
              
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
      }

       
      function approve(address _spender, uint256 _amount) public whenNotPaused returns (bool success) {
          allowed[msg.sender][_spender] = _amount;
          emit Approval(msg.sender, _spender, _amount);
          return true;
      }

       
      function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
      }
  }