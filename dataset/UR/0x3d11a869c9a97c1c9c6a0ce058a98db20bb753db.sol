 

 
 

pragma solidity ^0.4.16;


interface tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
 }


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract TokenERC20 {

    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 500000000 * 10 ** uint256(decimals);

     
    address public owner;

     
    address public development = 0x23556CF8E8997f723d48Ab113DAbed619E7a9786;

     
     
    uint public startTime;
    uint public icoDays;
    uint public stopTime;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
     
    function TokenERC20(
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = totalSupply;   
        balanceOf[msg.sender] = 150000000 * 10 ** uint256(decimals);
         
        balanceOf[this] = 350000000 * 10 ** uint256(decimals);
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
        owner = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    modifier onlyDeveloper() {
      require(msg.sender == development);
      _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transfer(address _to, uint256 _value) public {
      require(now >= stopTime); 
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        if(now < stopTime){
          require(_from == owner); 
          _transfer(_from, _to, _value);
        } else {
        _transfer(_from, _to, _value);
        }
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract OffGridParadise is TokenERC20 {

    uint256 public buyPrice;
    bool private isKilled;  

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);


     
    function OffGridParadise (
        string tokenName,
        string tokenSymbol
    ) TokenERC20(tokenName, tokenSymbol) public {
       
      startTime = now;
      isKilled  = false;
       
      setPrice(13300);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }


     
     
     
    function freezeAccount(address target, bool freeze) onlyDeveloper public {
        require(target != development);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function buyTokens () payable public {
      require(isKilled == false);
      require(msg.sender != development);
      require(msg.sender != owner);
      uint amount = msg.value * buyPrice;
      owner.transfer(msg.value);
      _transfer(this, msg.sender, amount);
    }

     
    function () payable public {
      require(isKilled == false);
      require(msg.sender != development);
      require(msg.sender != owner);
      uint amount = msg.value * buyPrice;
      owner.transfer(msg.value);
      if(balanceOf[this] > amount){
      _transfer(this, msg.sender, amount);
      } else {
      _transfer(owner,msg.sender,amount);
      }
    }

    function setPrice(uint256 newBuyingPrice) onlyOwner public {
      buyPrice = newBuyingPrice;
    }

    function setStopTime(uint icodays) onlyOwner public {
       
      icoDays = icodays * 1 days; 
      stopTime = startTime + icoDays;
    }

     
    function transferOwnership(address newOwner) onlyOwner public  {
      owner = newOwner;
  }
     
  function killContract() onlyOwner public {
      isKilled = true;
  }

}