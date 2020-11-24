 

pragma solidity ^0.4.18;

 
contract SafeMath {

     

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        return x - y;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }

     
     
     
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

}

 
contract ERC20 {
    uint256 public totalSupply;

     
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);


}


 
contract StandardToken is ERC20,SafeMath {

     

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


     
     
     
     
     

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }


     
     
     
     
     

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }


     
     
     

     

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     

    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
         
         
         
         

        require(_value == 0 && (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) public returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);

        return true;
    }


     
     
     
     
    function allowance(address _owner, address _spender) public  view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     

    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] =  safeSubtract(balances[burner],_value);
        totalSupply = safeSubtract(totalSupply,_value);
        Burn(burner, _value);
        return true;
    }


}


contract TrakToken is StandardToken {
     
    string constant public  name = "TrakInvest Token" ;
    string constant public  symbol = "TRAK";
    uint256 constant public  decimals = 18;

     
    bool public fundraising = true;

     
    address public creator;
     
    address public tokensOwner;
    mapping (address => bool) public frozenAccounts;

   
    event FrozenFund(address target ,bool frozen);

   

    modifier isCreator() { 
      require(msg.sender == creator);  
      _; 
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }


    modifier onlyOwner() {
        require(msg.sender == tokensOwner);
        _;
    }

    modifier manageTransfer() {
        if (msg.sender == tokensOwner) {
            _;
        }
        else {
            require(fundraising == false);
            _;
        }
    }

   
    function TrakToken(
      address _fundsWallet,
      uint256 initialSupply
      ) public {
      creator = msg.sender;

      if (_fundsWallet !=0) {
        tokensOwner = _fundsWallet;
      }
      else {
        tokensOwner = msg.sender;
      }

      totalSupply = initialSupply * (uint256(10) ** decimals);
      balances[tokensOwner] = totalSupply;
      Transfer(0x0, tokensOwner, totalSupply);
    }


   

    function transfer(address _to, uint256 _value)  public manageTransfer onlyPayloadSize(2 * 32) returns (bool success) {
      require(!frozenAccounts[msg.sender]);
      require(_to != address(0));
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)  public manageTransfer onlyPayloadSize(3 * 32) returns (bool success) {
      require(!frozenAccounts[msg.sender]);
      require(_to != address(0));
      require(_from != address(0));
      return super.transferFrom(_from, _to, _value);
    }


    function freezeAccount (address target ,bool freeze) public onlyOwner {
      frozenAccounts[target] = freeze;
      FrozenFund(target,freeze);  
    }

    function burn(uint256 _value) public onlyOwner returns (bool burnSuccess) {
        require(fundraising == false);
        return super.burn(_value);
    }

     
    function changeTokensWallet(address newAddress) public onlyOwner returns (bool)
    {
        require(newAddress != address(0));
        tokensOwner = newAddress;
    }

    function finalize() public  onlyOwner {
        require(fundraising != false);
         
        fundraising = false;
    }


    function() public {
        revert();
    }

}