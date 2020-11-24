 

pragma solidity ^0.4.13;

contract Token {

     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);



     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    function mint(address _to, uint256 _amount) public returns (bool);
    
    function setEndMintDate(uint256 endDate) public;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}



library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
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

  function inc(uint256 a) internal constant returns (uint256) {
    return add(a,1);
  }
  
  function onePercent(uint256 a) internal constant returns (uint256){
      return div(a,uint256(100));
  }
  
  function power(uint256 a,uint256 b) internal constant returns (uint256){
      return mul(a,10**b);
  }
}

contract StandardToken is Token {
     
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    using SafeMath for uint256;
    uint8 public decimals;                 
    uint256 endMintDate;
    
    address owner;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) minter;
    
    uint256 public _totalSupply;
    
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
  
    modifier canMint() {
        require(endMintDate>now && minter[msg.sender]);
        _;
    }
    
    modifier canTransfer() {
        require(endMintDate<now);
        _;
    }
    
    function transfer(address _to, uint256 _value) canTransfer returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && _to!=0x0) {
             
            return doTransfer(msg.sender,_to,_value);
        }  else { return false; }
    }
    
    function doTransfer(address _from,address _to,uint256 _value) internal returns (bool success) {
            balances[_from] =balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) canTransfer returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && _to!=0x0 ) {
            doTransfer(_from,_to,_value);
            allowed[_from][msg.sender] =allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function totalSupply() constant returns (uint totalSupply){
        return _totalSupply;
    }
    
     
    function mint(address _to, uint256 _amount) canMint public returns (bool) {
        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
  
    function setMinter(address _address,bool _canMint) onlyOwner public {
        minter[_address]=_canMint;
    } 
    

    function setEndMintDate(uint256 endDate) public{
        endMintDate=endDate;
    }
}
 
contract GMCToken is StandardToken {

    struct GiftData {
        address from;
        uint256 value;
        string message;
    }
    
    function () {
         
        revert();
    }

     
  
     
    string public name;                    
    string public symbol;                  
    string public version = 'H1.0';        
    mapping (address => mapping (uint256 => GiftData)) private gifts;
    mapping (address => uint256 ) private giftsCounter;
    
    function GMCToken(address _wallet) {
        uint256 initialSupply = 2000000;
        endMintDate=now+4 weeks;
        owner=msg.sender;
        minter[_wallet]=true;
        minter[msg.sender]=true;
        mint(_wallet,initialSupply.div(2));
        mint(msg.sender,initialSupply.div(2));
        
        name = "Good Mood Coin";                                    
        decimals = 4;                             
        symbol = "GMC";                                
    }

    function sendGift(address _to,uint256 _value,string _msg) payable public returns  (bool success){
        uint256 counter=giftsCounter[_to];
        gifts[_to][counter]=(GiftData({
            from:msg.sender,
            value:_value,
            message:_msg
        }));
        giftsCounter[_to]=giftsCounter[_to].inc();
        return doTransfer(msg.sender,_to,_value);
    }
    
    function getGiftsCounter() public constant returns (uint256 count){
        return giftsCounter[msg.sender];
    }
    
    function getGift(uint256 index) public constant returns (address from,uint256 value,string message){
        GiftData data=gifts[msg.sender][index];
        return (data.from,data.value,data.message);
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}